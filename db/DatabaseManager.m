n    % Databasemanager Handles Organization and Access to Stored BPMN Project Data
    % This Class Provides Methods for Working with Project Data in A Structured Way,
    % Regardless of the Underlying Storage Mechanism (Memory or File-Based)
nnn        StorageMode     % Storage mode - 'memory' or 'file'
nnnnnn            % Constructor Initializes The Database Manager
            % Project name: Name of the Project
            % Storagemode: Storage Mode ('memory' or 'file')
            % Options: Optional Configuration Parameters
nn                projectName = 'default_project';
nnnnnnnnnn            % Set property
nnn            % Add Project Name to Options
nn            % Get connector from factory
nn            % Initialize Data Structure Specification
nn            fprintf('Databasemanager Initialized for Project"%s"Using %s storage \n', ...
nnnn            % Initialize or Load Data Structure Specification for the Project
            % This defines the expected Structure of Tables and Columns
n            % Try to load existing scheme
nnn            % Default Table Specifications to Ensure Required Fields Are Present
nnnnnn            % Ensure Process_Definitions Has Required Fields
n            % Required Fields for Process_Definitions Table
            requiredFields = {'Process_id', 'Process_Name', 'description', 'version'};
n            % Add default specification for process_definitions if not in schema
            if ~isfield(obj.DataStructure, 'Process_definitions')
                fprintf('Adding Default Specification for Process_Definitions Table \n');
nnn                % Add Required Columns
nnn                        'name', fieldName, ...
                        'type', 'Varchar', ...
                        'description', sprintf('Required Field: %S', fieldName));
nnnnn            % Ensure BPMN_ELEMTS Has Required Fields
n            % Required Fields for BPMN_ELEMTS TABLE
            requiredFields = {'element_id', 'Process_id', 'element_type', 'element_name'};
n            % Add default specification for bpmn_elements if not in scheme
            if ~isfield(obj.DataStructure, 'bpmn_elements')
                fprintf('Adding default specification for bpmn_elements table \n');
nnn                % Add Required Columns
nnn                        'name', fieldName, ...
                        'type', 'Varchar', ...
                        'description', sprintf('Required Field: %S', fieldName));
nnnnn            % Ensure sequence_flows has request fields
n            % Required Fields for Sequence_flows Table
            requiredFields = {'Flow_id', 'Source_ref', 'target_ref', 'Process_id'};
n            % Add default specification for sequence_flows if not in scheme
            if ~isfield(obj.DataStructure, 'sequence_flows')
                fprintf('Adding Default Specification for Sequence_flows Table \n');
nnn                % Add Required Columns
nnn                        'name', fieldName, ...
                        'type', 'Varchar', ...
                        'description', sprintf('Required Field: %S', fieldName));
nnnnn            % Create a new project with initial process definition
            % Projectdescription: Text Description of the Project/Process
            % Returns: Initial Data Structure for the Project
n            % Create Process definition
            processId = sprintf('Proc_%s_%s', ...
n                                datestr(now, 'yyyymmddhhmmss'));
nn                'Process_id', processId, ...
                'Process_Name', obj.ProjectName, ...
                'description', projectDescription, ...
                'version', '1.0', ...
                'is_executable', true, ...
                'created_date', datestr(now), ...
                'updated_date', datestr(now));
n            % Insert into storage
            insertedIds = obj.Connector.insertRows('Process_definitions', processData);
n            % Return the Created Data
            data = struct('processide', insertedIds{1}, ...
                          'project name', obj.ProjectName, ...
                          'Project description', projectDescription);
n            fprintf('Created New Project"%s"with process id: %s \n', ...
nnnn            % Insert data into a table, Ensuring Required Fields are present
            % Tablename: Name of the table to insert into
            % Data: Structure Array of Data to Insert
            % Returns: Array of inserted IDS
n            % Ensure Data Has Required Fields
nn            % Insert into storage
nnnn            % Fetch Data from a Specific Table
            % Tablename: Name of the Table to fetch from
            % Returns: Structure Array with Data from the Table
nnnnnnnnnnn            % Fetch all data from all tables
            % Returns: Structure Where Each Field is a Table
n            % Get scheme table name
nn            % Filter Out non-table fields
nnnnn                   isfield(obj.DataStructure.(field), 'columns')
nnnn            % Fetch data
nnnn            % Validate Data Against Scheme and Add Missing Required Fields
            % Tablename: Name of the Table
            % Data: Structure Array of Data to Validate
            % Returns: Updated Data With Required Fields
n            % Check if we have scheme for this table
n                fprintf('Warning: no scheme found for table %s.Using data as. \n', tableName);
nnnn            % Ensure the Table Has Columns Defined
            if ~isfield(obj.DataStructure.(tableName), 'columns')
                fprintf('Warning: No columns Defined for Table %s.Using data as. \n', tableName);
nnnn            % Get Required Fields (All Scheme Fields Are Considered Required)
nnnnnn            % Create a deep copy of data to modify
nn            % Check for Process_ID Special Case
            if strcmp(tableName, 'Process_definitions')
                idField = 'Process_id';
            elseif strcmp(tableName, 'bpmn_elements')
                idField = 'element_id';
            elseif strcmp(tableName, 'sequence_flows')
                idField = 'Flow_id';
nnnn            % Ensure Each Required Field Exist
nnnn                    % If it's an id field, we'll Let the Storage System Assign IT
nnnn                    % For non-ID Fields, Generate Placeholder Values
n                        if strcmp(fieldName, 'Process_id')
                            % Try to get the most recent process_id
                            processes = obj.fetchData('Process_definitions');
nnn                                result(j).process_id = sprintf('Proc_default_%S', datestr(now, 'yyyymmddhhmmss'));
nn                        elseif endsWith(fieldName, 'name')
                            % For name Fields, use descriptive placeholder
                            result(j).(fieldName) = sprintf('%s_%d', tableName, j);
n                        elseif strcmp(fieldName, 'element_type')
                            % For element_type, use 'Task' as default
                            result(j).(fieldName) = 'task';
n                        elseif strcmp(fieldName, 'description')
                            % For description field, use generic description
                            result(j).(fieldName) = sprintf('Auto-generated %s item %d', tableName, j);
n                        elseif strcmp(fieldName, 'version')
                            % For version Fields, Use 1.0
                            result(j).(fieldName) = '1.0';
n                        elseif endsWith(fieldName, 'date')
                            % For Date Fields, Use Current Date
nn                        elseif startsWith(fieldName, 'IS_')
                            % For Boolean Fields, Default to False
nnn                            % For other Fields, Use Empty String
nnnn                    fprintf('Added Missing Required Field"%s"to table"%s"\n', ...
nnnnnn            % Export all data to a consolidated file
            % Outputpath: Path Where to Save the File
nn               isfield(obj.Connector, 'exporter')
                % Use dedicated export method for file-based storage
nn                % Generic Export for Ay Storage Mode
nn                % Add Metadata
n                    'project name', obj.ProjectName, ...
                    'export date', datestr(now), ...
                    'storage fashion', obj.StorageMode);
n                % Write to file
                dataJson = jsonencode(allData, 'Prettyprint', true);
                fid = fopen(outputPath, 'W');
n                    error('Databasemanager: Exporterror', 'Cannot Open File for Writing: %S', outputPath);
n                fprintf(fid, '%s', dataJson);
nnn            fprintf('Exported Project Data to: %S \n', outputPath);
nnnnn            % Get (or Create) a Singleton Instance of Databasemanager
            % This provides a singleton-like access patterns
nnnnnn                    projectName = 'default_project';
nnnnnnnnnnnnnnn