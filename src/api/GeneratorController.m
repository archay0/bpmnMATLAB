classdef GeneratorController
    % GeneratorController orchestrates iterative LLM-driven data generation and persistence

    methods(Static)
        function generateIterative(opts)
            % opts.mode = 'iterative';
            % opts.order = {'process_definitions','modules','parts','subparts'};
            % opts.batchSize = 10;

            % Load full schema metadata
            schema = SchemaLoader.load();

            % Initialize context for parent IDs and phase definitions
            context = struct();
            % Optionally: productDescription -> phases
            if isfield(opts,'productDescription')
                procMapPrompt = PromptBuilder.buildProcessMapPrompt(opts.productDescription);
                context.phases = DataGenerator.callLLM(procMapPrompt);
            end

            % Hierarchical generation: process, modules, parts, subparts
            for idx = 1:numel(opts.order)
                level = opts.order{idx};
                switch level
                    case 'process_definitions'
                        % Create top-level process entries
                        prompt = PromptBuilder.buildEntityPrompt(level, schema.(level), context, opts.batchSize);
                        rows = DataGenerator.callLLM(prompt);
                        % Store generated rows for validation
                        context.([level 'Rows']) = rows;
                        ValidationLayer.validate(level, rows, schema, context);
                        context.(level) = BPMNDatabaseConnector.insertRows(level, rows);
                    otherwise
                        % 1) Create subprocess/element entries in bpmn_elements for this level
                        ePrompt = PromptBuilder.buildEntityPrompt(level, schema.bpmn_elements, context, opts.batchSize);
                        eRows = DataGenerator.callLLM(ePrompt);
                        % Store element rows
                        context.([level 'Rows']) = eRows;
                        ValidationLayer.validate('bpmn_elements', eRows, schema, context);
                        eIDs = BPMNDatabaseConnector.insertRows('bpmn_elements', eRows);
                        context.(level) = eIDs;
                        % 2) Generate phase-specific BPMN entities under this level
                        phasePrompt = PromptBuilder.buildPhaseEntitiesPrompt(level, '', context.(level), opts.batchSize);
                        pRows = DataGenerator.callLLM(phasePrompt);
                        % Store phase entity rows
                        context.([level '_phaseRows']) = pRows;
                        ValidationLayer.validate('bpmn_elements', pRows, schema, context);
                        pIDs = BPMNDatabaseConnector.insertRows('bpmn_elements', pRows);
                        context.([level '_entities']) = pIDs;
                end
            end

            % After core hierarchy, generate flows and resources
            flowPrompt = PromptBuilder.buildFlowPrompt(context);
            flows = DataGenerator.callLLM(flowPrompt);
            % Store flow rows for semantic validation
            context.flowRows = flows;
            ValidationLayer.validate('sequenceFlows', flows, schema, context);
            context.sequenceFlows = BPMNDatabaseConnector.insertRows('sequenceFlows', flows);

            resourcePrompt = PromptBuilder.buildResourcePrompt(context, schema.resources);
            resources = DataGenerator.callLLM(resourcePrompt);
            % Store resource rows
            context.resourceRows = resources;
            ValidationLayer.validate('resources', resources, schema, context);
            context.resources = BPMNDatabaseConnector.insertRows('resources', resources);

            % Integrity check
            integrityPrompt = PromptBuilder.buildIntegrityPrompt(context);
            report = DataGenerator.callLLM(integrityPrompt);
            if ~isempty(report)
                error('Integrity issues: %s', jsonencode(report));
            end

            % --- Aggregate all generated elements and flows for semantic validation ---
            context.allElementRows = [];
            context.allFlowRows = [];
            if isfield(context, 'flowRows')
                context.allFlowRows = context.flowRows;
            end

            fields = fieldnames(context);
            for i = 1:numel(fields)
                fn = fields{i};
                % Collect all rows that look like element tables
                if endsWith(fn, 'Rows') && !strcmp(fn, 'flowRows') && !strcmp(fn, 'resourceRows') % Exclude known non-element tables
                    rows = context.(fn);
                    if isstruct(rows) && isfield(rows, 'element_id') % Check if it has element_id
                        % Ensure consistent fields before concatenating (add missing fields with default values)
                        if !isempty(rows)
                             if !isfield(rows, 'attached_to_ref')
                                 [rows.attached_to_ref] = deal('');
                             end
                             if !isfield(rows, 'process_id')
                                 [rows.process_id] = deal(''); % Or infer based on level if possible
                             end
                             if !isfield(rows, 'element_subtype')
                                 [rows.element_subtype] = deal('');
                             end
                             % Select common fields for aggregation
                             commonFields = {'element_id', 'element_type', 'element_subtype', 'process_id', 'attached_to_ref'};
                             rows = rmfield(rows, setdiff(fieldnames(rows), commonFields));
                             context.allElementRows = [context.allElementRows; rows(:)];
                        end
                    end
                end
            end

            % Semantic validation: ensure proper start/end events and flow connectivity
            % Pass the aggregated elements and flows
            ValidationLayer.validateSemantic(struct('allElementRows', context.allElementRows, 'allFlowRows', context.allFlowRows));

            % --- Store Generated Data Temporarily ---
            try
                fprintf('Storing generated data temporarily to temp_generated_data.json...\n');
                tempDataToStore = struct();
                if isfield(context, 'allElementRows')
                    tempDataToStore.allElements = context.allElementRows;
                end
                if isfield(context, 'allFlowRows')
                    tempDataToStore.allFlows = context.allFlowRows;
                end
                % Add other relevant context fields if needed, e.g., resources
                if isfield(context, 'resourceRows')
                    tempDataToStore.resources = context.resourceRows;
                end
                 % Add process definitions if available
                 if isfield(context, 'process_definitionsRows')
                     tempDataToStore.processDefinitions = context.process_definitionsRows;
                 end

                if !isempty(fieldnames(tempDataToStore))
                    jsonStr = jsonencode(tempDataToStore, 'PrettyPrint', true);
                    fid = fopen('temp_generated_data.json', 'w');
                    if fid == -1
                        error('GeneratorController:TempFileError', 'Cannot open temp_generated_data.json for writing.');
                    end
                    fprintf(fid, '%s', jsonStr);
                    fclose(fid);
                    fprintf('Temporary data stored successfully.\n');
                else
                    warning('GeneratorController:TempFileWarning', 'No relevant data found in context to store temporarily.');
                end
            catch ME
                warning('GeneratorController:TempFileFailed', 'Failed to store temporary data: %s', ME.message);
            end
            % --- End Temporary Storage ---

            % Fetch all and export
            % Fetch based on original context fields, not the aggregated ones
            fetchFields = setdiff(fieldnames(context), {'allElementRows', 'allFlowRows'});
            allData = BPMNDatabaseConnector.fetchAll(fetchFields);
            BPMNDiagramExporter.export(allData, opts.outputFile);
        end

        function generateAll(opts)
            % One-shot generation stub (to be implemented)
            error('generateAll not yet implemented');
        end
    end
end