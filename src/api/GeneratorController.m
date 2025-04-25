n    % GeneratorController Orchestrates Iterative LLM-Driven Data Generation and Persistence
nn        % Constants for Database Storage Modes
        STORAGE_MODE_MEMORY = 'memory';
        STORAGE_MODE_FILE = 'file';
nnnn            % opts.mode = 'iterative';
            % opts. order = {'process_definitions', 'modules', 'parts', 'subparts'};
            % opts.batchsize = 10;
n            % Initialize API environment
            if exist('initapien vironment', 'file') == 2
nnn            % Load standard API options
nn            % Overwrite optional API settings when specified
            if isfield(opts, 'model') 
nnn            if isfield(opts, 'temperature')
nnn            if isfield(opts, 'debug')
nnn            % Determine Storage Mode
n            if isfield(opts, 'storage fashion')
nnn            % Create Project Name from output file or product description
            projectName = 'default_project';
            if isfield(opts, 'output file')
n            elseif isfield(opts, 'product description')
                % Create a Safe Filename from product description
                projectName = regexprep(opts.productDescription, '[\\/:*?"<>|]',,'_');
                projectName = regexprep(projectName, '\ s+', '_');
nnnnnn            % Initialize Database Connector
n                % Ensure DB Directory is in the Path
                dbPath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'DB');
nnnn                % Initialize DatageneratorConnector
n                if isfield(opts, 'dbpath')
nnnnn                % Initialize Project with Product Description
                if isfield(opts, 'product description')
n                    fprintf('Using Project ID: %S \n', projectData.processId);
nn                warning('GeneratorController: Databaseinit', 'Could not initialize database: %s', ME.message);
                fprintf('Continuing with in-memory storage only \n');
nnn            % Load Full Scheme Metadata
nn            % Initialize Context for Parent Ids and Phase Definitions
n            % Optionally: Productdescription -> Phasees
            if isfield(opts,'product description')
nnnn                % Store in Database If Available
                if exist('dbconnector', 'var') && ~isempty(dbConnector)
nnnn            % Hierarchical Generation: Process, Modules, Parts, SubParts
nnn                    case 'Process_definitions'
                        % Create Top-Level Process Entries
nnnn                        % Show Data BEING Processed
                        if isfield(apiOpts, 'debug') && apiOpts.debug
                            fprintf('Generated process_definitions data: \n');
nnn                        % Store Generated Rows for Validation
                        context.([level 'Rows']) = rows;
n                        % Use Database System If Available
                        if exist('dbconnector', 'var') && ~isempty(dbConnector)
nnn                            % Fall back to original method
nnnn                        % 1) Create subProcess/element entries in bpmn_elements for this level
nnnn                        % Store element rows
                        context.([level 'Rows']) = eRows;
n                        % Use Database System If Available
                        if exist('dbconnector', 'var') && ~isempty(dbConnector)
                            dbConnector.insertLLMData('bpmn_elements', eRows, level);
nn                            % Fall back to original method
                            ValidationLayer.validate('bpmn_elements', eRows, schema, context);
                            eIDs = BPMNDatabaseConnector.insertRows('bpmn_elements', eRows);
nnn                        % 2) Generate phase-specific bpmn enttities under this level
nnnn                        % Store Phase Entity Rows
                        context.([level '_Phaserows']) = pRows;
n                        % Use Database System If Available
                        if exist('dbconnector', 'var') && ~isempty(dbConnector)
                            dbConnector.insertLLMData('bpmn_elements', pRows, [level '_entities']);
                            context.([level '_entities']) = dbConnector.getContext().([level '_entities']);
n                            % Fall back to original method
                            ValidationLayer.validate('bpmn_elements', pRows, schema, context);
                            pIDs = BPMNDatabaseConnector.insertRows('bpmn_elements', pRows);
                            context.([level '_entities']) = pIDs;
nnnn            % After Core Hierarchy, Generates Flows and Resources
nnnn            % Store Flow Rows for Semantic Validation
nn            % Use Database System If Available
            if exist('dbconnector', 'var') && ~isempty(dbConnector)
                dbConnector.insertLLMData('sequence_flows', flows);
nn                % Fall back to original method
                ValidationLayer.validate('sequenceFlows', flows, schema, context);
                context.sequenceFlows = BPMNDatabaseConnector.insertRows('sequenceFlows', flows);
nnnnnn            % Store Resource Rows
nn            % Use Database System If Available
            if exist('dbconnector', 'var') && ~isempty(dbConnector)
                dbConnector.insertLLMData('resources', resources);
nn                % Fall back to original method
                ValidationLayer.validate('resources', resources, schema, context);
                context.resources = BPMNDatabaseConnector.insertRows('resources', resources);
nn            % Integrity check
nnnn                fprintf('Integrity issues: %s \n', jsonencode(report));
                % Continue Despite Integrity Issues
nn            % --- Agregate All Generated Elements and Flows for Semantic Validation ---
            % If using database system, build context from stored data
            if exist('dbconnector', 'var') && ~isempty(dbConnector)
nnnnn                % Original code for aggregating elements and flows
nn                if isfield(context, 'Flowrows')
nnnnnn                    % Collect all rows that look like element tables
                    if endsWith(fn, 'Rows') && ~strcmp(fn, 'Flowrows') && ~strcmp(fn, 'Resourcerows')
n                        if isstruct(rows) && isfield(rows, 'element_id') % Check if it has element_id
                            % Ensure Consistent Fields Before Concatening (Add Missing Fields with Default Values)
n                                 if ~isfield(rows, 'Attached_to_ref')
nn                                 if ~isfield(rows, 'Process_id')
nn                                 if ~isfield(rows, 'element_subype')
nn                                 % Select Common Fields for Aggregation
                                 commonFields = {'element_id', 'element_type', 'element_subype', 'Process_id', 'Attached_to_ref'};
nnnnnnnnnnn            % Semantic Validation: Ensure Proper Start/End Events and Flow Connectivity
n                % Pass the aggregated elements and flows
                ValidationLayer.validateSemantic(struct('Allelementrows', context.allElementRows, 'Allflowrows', context.allFlowRows));
n                warning('Generator Controller: Semantic Validation', 'Semantic validation issue: %s', ME.message);
                % Continue Despite Validation Issues for Partial Results
nn            % --- Store generated data via the database system ---
            if exist('dbconnector', 'var') && ~isempty(dbConnector)
n                    tempDir = 'Doc/Temporary'; % Define the target directory
                    tempFileName = 'temp_generated_data.json';
nn                    % Ensure the Directory Exists
                    if ~exist(tempDir, 'you')
nnn                    % Export data from database
n                    fprintf('Project data exported to: %s \n', tempFilePath);
n                    warning('GeneratorController: Exportfailed', 'Failed to export data: %s', ME.message);
nn                % Original temporary storage code
n                    tempDir = 'Doc/Temporary';
                    tempFileName = 'temp_generated_data.json';
nn                    fprintf('Storing generated data temporarily to %s ... \n', tempFilePath);
n                    % Ensure the Directory Exists
                    if ~exist(tempDir, 'you')
n                        fprintf('Created directory: %s \n', tempDir);
nnn                    if isfield(context, 'Allelementrows')
nn                    if isfield(context, 'Allflowrows')
nn                    % Add other relevant context field IF Needed, e.G., Resources
                    if isfield(context, 'Resourcerows')
nn                     % Add process definitions if Available
                     if isfield(context, 'Process_definitionsrows')
nnnn                        jsonStr = jsonencode(tempDataToStore, 'Prettyprint', true);
                        fid = fopen(tempFilePath, 'W'); % Use the full path
n                            error('GeneratorController: Tecommenerror', 'Cannot Open %S for Writing.', tempFilePath);
n                        fprintf(fid, '%s', jsonStr);
n                        fprintf('Temporary Data Stored Successfully. \n');
n                        warning('GeneratorController: Tempfilwarning', 'No relevant data found in context to store temporarily.');
nn                    warning('GeneratorController: Tempfilefailed', 'Failed to store temporary data: %s', ME.message);
nn            % --- end temporary storage ---
n            % Define Final Output Path
            finalOutputDir = 'Doc/Temporary';
            if ~exist(finalOutputDir, 'you')
nnn            fprintf('Final BPMN wants to be saved to: %s \n', finalOutputPath);
n            % Fetch all and export
            if exist('dbconnector', 'var') && ~isempty(dbConnector)
                % Get all data from database
nn                % Fetch Based on Original Context Fields
                fetchFields = setdiff(fieldnames(context), {'Allelementrows', 'Allflowrows'});
nnn            % Export BPMN Diagram
nnnn            % One-Shot Generation Stub (to be implemented)
            error('Generateall not Yet implemented');
nnn