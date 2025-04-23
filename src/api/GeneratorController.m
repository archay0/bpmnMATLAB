classdef GeneratorController
    % GeneratorController orchestrates iterative LLM-driven data generation and persistence

    methods(Static)
        function generateIterative(opts)
            % opts.mode = 'iterative';
            % opts.order = {'process_definitions','modules','parts','subparts'};
            % opts.batchSize = 10;

            % API-Umgebung initialisieren
            if exist('initAPIEnvironment', 'file') == 2
                initAPIEnvironment();
            end

            % Standard-API-Optionen laden
            apiOpts = APIConfig.getDefaultOptions();
            
            % Optionale API-Einstellungen überschreiben, wenn angegeben
            if isfield(opts, 'model') 
                apiOpts.model = opts.model;
            end
            
            if isfield(opts, 'temperature')
                apiOpts.temperature = opts.temperature;
            end
            
            if isfield(opts, 'debug')
                apiOpts.debug = opts.debug;
            end

            % Load full schema metadata
            schema = SchemaLoader.load();

            % Initialize context for parent IDs and phase definitions
            context = struct();
            % Optionally: productDescription -> phases
            if isfield(opts,'productDescription')
                procMapPrompt = PromptBuilder.buildProcessMapPrompt(opts.productDescription);
                procMapPrompt = APIConfig.formatPrompt(procMapPrompt); % Format-Anweisung hinzufügen
                context.phases = DataGenerator.callLLM(procMapPrompt, apiOpts);
            end

            % Hierarchical generation: process, modules, parts, subparts
            for idx = 1:numel(opts.order)
                level = opts.order{idx};
                switch level
                    case 'process_definitions'
                        % Create top-level process entries
                        prompt = PromptBuilder.buildEntityPrompt(level, schema.(level), context, opts.batchSize);
                        prompt = APIConfig.formatPrompt(prompt); % Format-Anweisung hinzufügen
                        rows = DataGenerator.callLLM(prompt, apiOpts);
                        % Store generated rows for validation
                        context.([level 'Rows']) = rows;
                        ValidationLayer.validate(level, rows, schema, context);
                        context.(level) = BPMNDatabaseConnector.insertRows(level, rows);
                    otherwise
                        % 1) Create subprocess/element entries in bpmn_elements for this level
                        ePrompt = PromptBuilder.buildEntityPrompt(level, schema.bpmn_elements, context, opts.batchSize);
                        ePrompt = APIConfig.formatPrompt(ePrompt); % Format-Anweisung hinzufügen
                        eRows = DataGenerator.callLLM(ePrompt, apiOpts);
                        % Store element rows
                        context.([level 'Rows']) = eRows;
                        ValidationLayer.validate('bpmn_elements', eRows, schema, context);
                        eIDs = BPMNDatabaseConnector.insertRows('bpmn_elements', eRows);
                        context.(level) = eIDs;
                        % 2) Generate phase-specific BPMN entities under this level
                        phasePrompt = PromptBuilder.buildPhaseEntitiesPrompt(level, '', context.(level), opts.batchSize);
                        phasePrompt = APIConfig.formatPrompt(phasePrompt); % Format-Anweisung hinzufügen
                        pRows = DataGenerator.callLLM(phasePrompt, apiOpts);
                        % Store phase entity rows
                        context.([level '_phaseRows']) = pRows;
                        ValidationLayer.validate('bpmn_elements', pRows, schema, context);
                        pIDs = BPMNDatabaseConnector.insertRows('bpmn_elements', pRows);
                        context.([level '_entities']) = pIDs;
                end
            end

            % After core hierarchy, generate flows and resources
            flowPrompt = PromptBuilder.buildFlowPrompt(context);
            flowPrompt = APIConfig.formatPrompt(flowPrompt); % Format-Anweisung hinzufügen
            flows = DataGenerator.callLLM(flowPrompt, apiOpts);
            % Store flow rows for semantic validation
            context.flowRows = flows;
            ValidationLayer.validate('sequenceFlows', flows, schema, context);
            context.sequenceFlows = BPMNDatabaseConnector.insertRows('sequenceFlows', flows);

            resourcePrompt = PromptBuilder.buildResourcePrompt(context, schema.resources);
            resourcePrompt = APIConfig.formatPrompt(resourcePrompt); % Format-Anweisung hinzufügen
            resources = DataGenerator.callLLM(resourcePrompt, apiOpts);
            % Store resource rows
            context.resourceRows = resources;
            ValidationLayer.validate('resources', resources, schema, context);
            context.resources = BPMNDatabaseConnector.insertRows('resources', resources);

            % Integrity check
            integrityPrompt = PromptBuilder.buildIntegrityPrompt(context);
            integrityPrompt = APIConfig.formatPrompt(integrityPrompt); % Format-Anweisung hinzufügen
            report = DataGenerator.callLLM(integrityPrompt, apiOpts);
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
                if endsWith(fn, 'Rows') && ~strcmp(fn, 'flowRows') && ~strcmp(fn, 'resourceRows')
                    rows = context.(fn);
                    if isstruct(rows) && isfield(rows, 'element_id') % Check if it has element_id
                        % Ensure consistent fields before concatenating (add missing fields with default values)
                        if ~isempty(rows)
                             if ~isfield(rows, 'attached_to_ref')
                                 [rows.attached_to_ref] = deal('');
                             end
                             if ~isfield(rows, 'process_id')
                                 [rows.process_id] = deal(''); % Or infer based on level if possible
                             end
                             if ~isfield(rows, 'element_subtype')
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
                tempDir = 'doc/temporary'; % Define the target directory
                tempFileName = 'temp_generated_data.json';
                tempFilePath = fullfile(tempDir, tempFileName);

                fprintf('Storing generated data temporarily to %s...\n', tempFilePath);

                % Ensure the directory exists
                if ~exist(tempDir, 'dir')
                    mkdir(tempDir);
                    fprintf('Created directory: %s\n', tempDir);
                end

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

                if ~isempty(fieldnames(tempDataToStore))
                    jsonStr = jsonencode(tempDataToStore, 'PrettyPrint', true);
                    fid = fopen(tempFilePath, 'w'); % Use the full path
                    if fid == -1
                        error('GeneratorController:TempFileError', 'Cannot open %s for writing.', tempFilePath);
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

            % Define final output path
            finalOutputDir = 'doc/temporary';
            if ~exist(finalOutputDir, 'dir')
                mkdir(finalOutputDir);
            end
            finalOutputPath = fullfile(finalOutputDir, opts.outputFile);
            fprintf('Final BPMN will be saved to: %s\n', finalOutputPath);

            % Fetch all and export
            % Fetch based on original context fields, not the aggregated ones
            fetchFields = setdiff(fieldnames(context), {'allElementRows', 'allFlowRows'});
            allData = BPMNDatabaseConnector.fetchAll(fetchFields);
            BPMNDiagramExporter.export(allData, finalOutputPath); % Use the full path
        end

        function generateAll(opts)
            % One-shot generation stub (to be implemented)
            error('generateAll not yet implemented');
        end
    end
end