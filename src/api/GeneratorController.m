classdef GeneratorController
    % GeneratorController orchestrates iterative LLM-driven data generation and persistence
    
    properties(Constant)
        % Constants for database storage modes
        STORAGE_MODE_MEMORY = 'memory';
        STORAGE_MODE_FILE = 'file';
    end

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
            
            % Determine storage mode
            storageMode = GeneratorController.STORAGE_MODE_FILE;  % Default to file storage
            if isfield(opts, 'storageMode')
                storageMode = opts.storageMode;
            end
            
            % Create project name from output file or product description
            projectName = 'default_project';
            if isfield(opts, 'outputFile')
                [~, projectName, ~] = fileparts(opts.outputFile);
            elseif isfield(opts, 'productDescription')
                % Create a safe filename from product description
                projectName = regexprep(opts.productDescription, '[\\/:*?"<>|]', '_');
                projectName = regexprep(projectName, '\s+', '_');
                projectName = lower(projectName);
                if length(projectName) > 50
                    projectName = projectName(1:50);
                end
            end
            
            % Initialize database connector
            try
                % Ensure db directory is in the path
                dbPath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'db');
                if ~contains(path, dbPath)
                    addpath(dbPath);
                end
                
                % Initialize DataGeneratorConnector
                dbOptions = struct();
                if isfield(opts, 'dbPath')
                    dbOptions.basePath = opts.dbPath;
                end
                
                dbConnector = DataGeneratorConnector.getInstance(projectName, storageMode, dbOptions);
                
                % Initialize project with product description
                if isfield(opts, 'productDescription')
                    projectData = dbConnector.initializeProject(opts.productDescription);
                    fprintf('Using project ID: %s\n', projectData.processId);
                end
            catch ME
                warning('GeneratorController:DatabaseInit', 'Could not initialize database: %s', ME.message);
                fprintf('Continuing with in-memory storage only\n');
                dbConnector = [];
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
                
                % Store in database if available
                if exist('dbConnector', 'var') && ~isempty(dbConnector)
                    dbConnector.setContext(context);
                end
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
                        
                        % Show data being processed
                        if isfield(apiOpts, 'debug') && apiOpts.debug
                            fprintf('Generated process_definitions data:\n');
                            disp(rows);
                        end
                        
                        % Store generated rows for validation
                        context.([level 'Rows']) = rows;
                        
                        % Use database system if available
                        if exist('dbConnector', 'var') && ~isempty(dbConnector)
                            dbConnector.insertLLMData(level, rows);
                            context.(level) = dbConnector.getContext().(level);
                        else
                            % Fall back to original method
                            ValidationLayer.validate(level, rows, schema, context);
                            context.(level) = BPMNDatabaseConnector.insertRows(level, rows);
                        end
                    otherwise
                        % 1) Create subprocess/element entries in bpmn_elements for this level
                        ePrompt = PromptBuilder.buildEntityPrompt(level, schema.bpmn_elements, context, opts.batchSize);
                        ePrompt = APIConfig.formatPrompt(ePrompt); % Format-Anweisung hinzufügen
                        eRows = DataGenerator.callLLM(ePrompt, apiOpts);
                        
                        % Store element rows
                        context.([level 'Rows']) = eRows;
                        
                        % Use database system if available
                        if exist('dbConnector', 'var') && ~isempty(dbConnector)
                            dbConnector.insertLLMData('bpmn_elements', eRows, level);
                            context.(level) = dbConnector.getContext().(level);
                        else
                            % Fall back to original method
                            ValidationLayer.validate('bpmn_elements', eRows, schema, context);
                            eIDs = BPMNDatabaseConnector.insertRows('bpmn_elements', eRows);
                            context.(level) = eIDs;
                        end
                        
                        % 2) Generate phase-specific BPMN entities under this level
                        phasePrompt = PromptBuilder.buildPhaseEntitiesPrompt(level, '', context.(level), opts.batchSize);
                        phasePrompt = APIConfig.formatPrompt(phasePrompt); % Format-Anweisung hinzufügen
                        pRows = DataGenerator.callLLM(phasePrompt, apiOpts);
                        
                        % Store phase entity rows
                        context.([level '_phaseRows']) = pRows;
                        
                        % Use database system if available
                        if exist('dbConnector', 'var') && ~isempty(dbConnector)
                            dbConnector.insertLLMData('bpmn_elements', pRows, [level '_entities']);
                            context.([level '_entities']) = dbConnector.getContext().([level '_entities']);
                        else
                            % Fall back to original method
                            ValidationLayer.validate('bpmn_elements', pRows, schema, context);
                            pIDs = BPMNDatabaseConnector.insertRows('bpmn_elements', pRows);
                            context.([level '_entities']) = pIDs;
                        end
                end
            end

            % After core hierarchy, generate flows and resources
            flowPrompt = PromptBuilder.buildFlowPrompt(context);
            flowPrompt = APIConfig.formatPrompt(flowPrompt); % Format-Anweisung hinzufügen
            flows = DataGenerator.callLLM(flowPrompt, apiOpts);
            
            % Store flow rows for semantic validation
            context.flowRows = flows;
            
            % Use database system if available
            if exist('dbConnector', 'var') && ~isempty(dbConnector)
                dbConnector.insertLLMData('sequence_flows', flows);
                context.sequenceFlows = dbConnector.getContext().sequence_flows;
            else
                % Fall back to original method
                ValidationLayer.validate('sequenceFlows', flows, schema, context);
                context.sequenceFlows = BPMNDatabaseConnector.insertRows('sequenceFlows', flows);
            end

            resourcePrompt = PromptBuilder.buildResourcePrompt(context, schema.resources);
            resourcePrompt = APIConfig.formatPrompt(resourcePrompt); % Format-Anweisung hinzufügen
            resources = DataGenerator.callLLM(resourcePrompt, apiOpts);
            
            % Store resource rows
            context.resourceRows = resources;
            
            % Use database system if available
            if exist('dbConnector', 'var') && ~isempty(dbConnector)
                dbConnector.insertLLMData('resources', resources);
                context.resources = dbConnector.getContext().resources;
            else
                % Fall back to original method
                ValidationLayer.validate('resources', resources, schema, context);
                context.resources = BPMNDatabaseConnector.insertRows('resources', resources);
            end

            % Integrity check
            integrityPrompt = PromptBuilder.buildIntegrityPrompt(context);
            integrityPrompt = APIConfig.formatPrompt(integrityPrompt); % Format-Anweisung hinzufügen
            report = DataGenerator.callLLM(integrityPrompt, apiOpts);
            if ~isempty(report)
                fprintf('Integrity issues: %s\n', jsonencode(report));
                % Continue despite integrity issues
            end

            % --- Aggregate all generated elements and flows for semantic validation ---
            % If using database system, build context from stored data
            if exist('dbConnector', 'var') && ~isempty(dbConnector)
                dbConnector.setContext(context);
                dbConnector.buildPromptContext();
                context.allElementRows = dbConnector.getContext().allElementRows;
                context.allFlowRows = dbConnector.getContext().allFlowRows;
            else
                % Original code for aggregating elements and flows
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
                                 fieldsToKeep = intersect(fieldnames(rows), commonFields);
                                 if ~isempty(fieldsToKeep)
                                     rows = rmfield(rows, setdiff(fieldnames(rows), fieldsToKeep));
                                     context.allElementRows = [context.allElementRows; rows(:)];
                                 end
                            end
                        end
                    end
                end
            end

            % Semantic validation: ensure proper start/end events and flow connectivity
            try
                % Pass the aggregated elements and flows
                ValidationLayer.validateSemantic(struct('allElementRows', context.allElementRows, 'allFlowRows', context.allFlowRows));
            catch ME
                warning('GeneratorController:SemanticValidation', 'Semantic validation issue: %s', ME.message);
                % Continue despite validation issues for partial results
            end

            % --- Store Generated Data via Database System ---
            if exist('dbConnector', 'var') && ~isempty(dbConnector)
                try
                    tempDir = 'doc/temporary'; % Define the target directory
                    tempFileName = 'temp_generated_data.json';
                    tempFilePath = fullfile(tempDir, tempFileName);
                    
                    % Ensure the directory exists
                    if ~exist(tempDir, 'dir')
                        mkdir(tempDir);
                    end
                    
                    % Export data from database
                    dbConnector.exportData(tempFilePath);
                    fprintf('Project data exported to: %s\n', tempFilePath);
                catch ME
                    warning('GeneratorController:ExportFailed', 'Failed to export data: %s', ME.message);
                end
            else
                % Original temporary storage code
                try
                    tempDir = 'doc/temporary';
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
            if exist('dbConnector', 'var') && ~isempty(dbConnector)
                % Get all data from database
                allData = dbConnector.DatabaseManager.fetchAllData();
            else
                % Fetch based on original context fields
                fetchFields = setdiff(fieldnames(context), {'allElementRows', 'allFlowRows'});
                allData = BPMNDatabaseConnector.fetchAll(fetchFields);
            end
            
            % Export BPMN diagram
            BPMNDiagramExporter.export(allData, finalOutputPath);
        end

        function generateAll(opts)
            % One-shot generation stub (to be implemented)
            error('generateAll not yet implemented');
        end
    end
end