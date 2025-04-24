classdef DatabaseManager < handle
    % DatabaseManager handles organization and access to stored BPMN project data
    % This class provides methods for working with project data in a structured way,
    % regardless of the underlying storage mechanism (memory or file-based)
    
    properties
        ProjectName     % Name of the current project
        StorageMode     % Storage mode - 'memory' or 'file'
        Connector       % Database connector instance
        DataStructure   % Current project's data structure specification
    end
    
    methods
        function obj = DatabaseManager(projectName, storageMode, options)
            % Constructor initializes the database manager
            % projectName: Name of the project 
            % storageMode: Storage mode ('memory' or 'file')
            % options: Optional configuration parameters
            
            if nargin < 1 || isempty(projectName)
                projectName = 'default_project';
            end
            
            if nargin < 2 || isempty(storageMode)
                storageMode = DatabaseConnectorFactory.MODE_FILE;
            end
            
            if nargin < 3
                options = struct();
            end
            
            % Set properties
            obj.ProjectName = projectName;
            obj.StorageMode = storageMode;
            
            % Add project name to options
            options.projectName = projectName;
            
            % Get connector from factory
            obj.Connector = DatabaseConnectorFactory.getConnector(storageMode, options);
            
            % Initialize data structure specification
            obj.initDataStructure();
            
            fprintf('DatabaseManager initialized for project "%s" using %s storage\n', ...
                projectName, storageMode);
        end
        
        function initDataStructure(obj)
            % Initialize or load data structure specification for the project
            % This defines the expected structure of tables and columns
            
            % Try to load existing schema
            schema = SchemaLoader.load();
            obj.DataStructure = schema;
            
            % Default table specifications to ensure required fields are present
            ensureProcessDefinitionFields(obj);
            ensureElementFields(obj);
            ensureFlowFields(obj);
        end
        
        function ensureProcessDefinitionFields(obj)
            % Ensure process_definitions has required fields
            
            % Required fields for process_definitions table
            requiredFields = {'process_id', 'process_name', 'description', 'version'};
            
            % Add default specification for process_definitions if not in schema
            if ~isfield(obj.DataStructure, 'process_definitions')
                fprintf('Adding default specification for process_definitions table\n');
                obj.DataStructure.process_definitions = struct();
                obj.DataStructure.process_definitions.columns = struct();
                
                % Add required columns
                for i = 1:numel(requiredFields)
                    fieldName = requiredFields{i};
                    obj.DataStructure.process_definitions.columns(i) = struct(...
                        'name', fieldName, ...
                        'type', 'VARCHAR', ...
                        'description', sprintf('Required field: %s', fieldName));
                end
            end
        end
        
        function ensureElementFields(obj)
            % Ensure bpmn_elements has required fields
            
            % Required fields for bpmn_elements table
            requiredFields = {'element_id', 'process_id', 'element_type', 'element_name'};
            
            % Add default specification for bpmn_elements if not in schema
            if ~isfield(obj.DataStructure, 'bpmn_elements')
                fprintf('Adding default specification for bpmn_elements table\n');
                obj.DataStructure.bpmn_elements = struct();
                obj.DataStructure.bpmn_elements.columns = struct();
                
                % Add required columns
                for i = 1:numel(requiredFields)
                    fieldName = requiredFields{i};
                    obj.DataStructure.bpmn_elements.columns(i) = struct(...
                        'name', fieldName, ...
                        'type', 'VARCHAR', ...
                        'description', sprintf('Required field: %s', fieldName));
                end
            end
        end
        
        function ensureFlowFields(obj)
            % Ensure sequence_flows has required fields
            
            % Required fields for sequence_flows table
            requiredFields = {'flow_id', 'source_ref', 'target_ref', 'process_id'};
            
            % Add default specification for sequence_flows if not in schema
            if ~isfield(obj.DataStructure, 'sequence_flows')
                fprintf('Adding default specification for sequence_flows table\n');
                obj.DataStructure.sequence_flows = struct();
                obj.DataStructure.sequence_flows.columns = struct();
                
                % Add required columns
                for i = 1:numel(requiredFields)
                    fieldName = requiredFields{i};
                    obj.DataStructure.sequence_flows.columns(i) = struct(...
                        'name', fieldName, ...
                        'type', 'VARCHAR', ...
                        'description', sprintf('Required field: %s', fieldName));
                end
            end
        end
        
        function data = createNewProject(obj, projectDescription)
            % Create a new project with initial process definition
            % projectDescription: Text description of the project/process
            % Returns: Initial data structure for the project
            
            % Create process definition
            processId = sprintf('PROC_%s_%s', ...
                                obj.ProjectName, ...
                                datestr(now, 'yyyymmddHHMMSS'));
            
            processData = struct(...
                'process_id', processId, ...
                'process_name', obj.ProjectName, ...
                'description', projectDescription, ...
                'version', '1.0', ...
                'is_executable', true, ...
                'created_date', datestr(now), ...
                'updated_date', datestr(now));
            
            % Insert into storage
            insertedIds = obj.Connector.insertRows('process_definitions', processData);
            
            % Return the created data
            data = struct('processId', insertedIds{1}, ...
                          'projectName', obj.ProjectName, ...
                          'projectDescription', projectDescription);
            
            fprintf('Created new project "%s" with process ID: %s\n', ...
                obj.ProjectName, insertedIds{1});
        end
        
        function insertedIds = insertData(obj, tableName, data)
            % Insert data into a table, ensuring required fields are present
            % tableName: Name of the table to insert into
            % data: Structure array of data to insert
            % Returns: Array of inserted IDs
            
            % Ensure data has required fields
            validatedData = obj.validateAndPrepareData(tableName, data);
            
            % Insert into storage
            insertedIds = obj.Connector.insertRows(tableName, validatedData);
        end
        
        function data = fetchData(obj, tableName)
            % Fetch data from a specific table
            % tableName: Name of the table to fetch from
            % Returns: Structure array with data from the table
            
            result = obj.Connector.fetchAll({tableName});
            
            if isfield(result, tableName)
                data = result.(tableName);
            else
                data = [];
            end
        end
        
        function allData = fetchAllData(obj)
            % Fetch all data from all tables
            % Returns: Structure where each field is a table
            
            % Get schema table names
            schemaFields = fieldnames(obj.DataStructure);
            
            % Filter out non-table fields
            tableNames = {};
            for i = 1:numel(schemaFields)
                field = schemaFields{i};
                if isfield(obj.DataStructure, field) && ...
                   isstruct(obj.DataStructure.(field)) && ...
                   isfield(obj.DataStructure.(field), 'columns')
                    tableNames{end+1} = field;
                end
            end
            
            % Fetch data
            allData = obj.Connector.fetchAll(tableNames);
        end
        
        function result = validateAndPrepareData(obj, tableName, data)
            % Validate data against schema and add missing required fields
            % tableName: Name of the table
            % data: Structure array of data to validate
            % Returns: Updated data with required fields
            
            % Check if we have schema for this table
            if ~isfield(obj.DataStructure, tableName)
                fprintf('Warning: No schema found for table %s. Using data as-is.\n', tableName);
                result = data;
                return;
            end
            
            % Ensure the table has columns defined
            if ~isfield(obj.DataStructure.(tableName), 'columns')
                fprintf('Warning: No columns defined for table %s. Using data as-is.\n', tableName);
                result = data;
                return;
            end
            
            % Get required fields (all schema fields are considered required)
            schemaColumns = obj.DataStructure.(tableName).columns;
            requiredFields = cell(1, numel(schemaColumns));
            for i = 1:numel(schemaColumns)
                requiredFields{i} = schemaColumns(i).name;
            end
            
            % Create a deep copy of data to modify
            result = data;
            
            % Check for process_id special case
            if strcmp(tableName, 'process_definitions')
                idField = 'process_id';
            elseif strcmp(tableName, 'bpmn_elements')
                idField = 'element_id';
            elseif strcmp(tableName, 'sequence_flows')
                idField = 'flow_id';
            else
                idField = ''; % No special case for other tables
            end
            
            % Ensure each required field exists
            for i = 1:numel(requiredFields)
                fieldName = requiredFields{i};
                
                if ~isfield(result, fieldName) || isempty(result(1).(fieldName))
                    % If it's an ID field, we'll let the storage system assign it
                    if strcmp(fieldName, idField)
                        continue;
                    end
                    
                    % For non-ID fields, generate placeholder values
                    for j = 1:numel(result)
                        if strcmp(fieldName, 'process_id')
                            % Try to get the most recent process_id
                            processes = obj.fetchData('process_definitions');
                            if ~isempty(processes)
                                result(j).process_id = processes(1).process_id;
                            else
                                result(j).process_id = sprintf('PROC_DEFAULT_%s', datestr(now, 'yyyymmddHHMMSS'));
                            end
                            
                        elseif endsWith(fieldName, 'name')
                            % For name fields, use descriptive placeholder
                            result(j).(fieldName) = sprintf('%s_%d', tableName, j);
                            
                        elseif strcmp(fieldName, 'element_type')
                            % For element_type, use 'task' as default
                            result(j).(fieldName) = 'task';
                            
                        elseif strcmp(fieldName, 'description')
                            % For description fields, use generic description
                            result(j).(fieldName) = sprintf('Auto-generated %s item %d', tableName, j);
                            
                        elseif strcmp(fieldName, 'version')
                            % For version fields, use 1.0
                            result(j).(fieldName) = '1.0';
                            
                        elseif endsWith(fieldName, 'date')
                            % For date fields, use current date
                            result(j).(fieldName) = datestr(now);
                            
                        elseif startsWith(fieldName, 'is_')
                            % For boolean fields, default to false
                            result(j).(fieldName) = false;
                            
                        else
                            % For other fields, use empty string
                            result(j).(fieldName) = '';
                        }
                    end
                    
                    fprintf('Added missing required field "%s" to table "%s"\n', ...
                        fieldName, tableName);
                end
            end
        end
        
        function export(obj, outputPath)
            % Export all data to a consolidated file
            % outputPath: Path where to save the file
            
            if obj.StorageMode == DatabaseConnectorFactory.MODE_FILE && ...
               isfield(obj.Connector, 'exportToFile')
                % Use dedicated export method for file-based storage
                obj.Connector.exportToFile(outputPath);
            else
                % Generic export for any storage mode
                allData = obj.fetchAllData();
                
                % Add metadata
                allData.metadata = struct(...
                    'projectName', obj.ProjectName, ...
                    'exportDate', datestr(now), ...
                    'storageMode', obj.StorageMode);
                
                % Write to file
                dataJson = jsonencode(allData, 'PrettyPrint', true);
                fid = fopen(outputPath, 'w');
                if fid == -1
                    error('DatabaseManager:ExportError', 'Cannot open file for writing: %s', outputPath);
                end
                fprintf(fid, '%s', dataJson);
                fclose(fid);
            end
            
            fprintf('Exported project data to: %s\n', outputPath);
        end
    end
    
    methods(Static)
        function instance = getInstance(projectName, storageMode, options)
            % Get (or create) a singleton instance of DatabaseManager
            % This provides a singleton-like access pattern
            
            persistent dbManager;
            
            if isempty(dbManager) || ~isvalid(dbManager) || ...
                    (nargin > 0 && ~strcmp(dbManager.ProjectName, projectName))
                if nargin < 1
                    projectName = 'default_project';
                end
                if nargin < 2
                    storageMode = DatabaseConnectorFactory.MODE_FILE;
                end
                if nargin < 3
                    options = struct();
                end
                
                dbManager = DatabaseManager(projectName, storageMode, options);
            end
            
            instance = dbManager;
        end
    end
end