n    % Filebasedbpmndatabase Provides Persistent File-based Storage for BPMN Data
    % This Class Saves Generated BPMN Data to Files and Retrieves It When Needed
    % Allowing for projects that exced llm token limits by storing data across sessions
nnnnnnnnnnnn            % Constructor Creates a New File-Base Database for BPMN Data
            % ProjectName: Name of the Project (Used for Directory Naming)
            % Options: Optional Configuration Parameters
nn                projectName = 'default_project';
nnnnnn            % Set Default Base Path to DB Directory in the WorkSpace
            currentDir = fileparts(mfilename('fullpath'));
            obj.BasePath = fullfile(currentDir, 'storage');
n            % Apply options IF Provided
            if isfield(options, 'baseepath')
nnnn            obj.CurrentSession = datestr(now, 'yyyymmdd_hhmmss');
nnnn            % Initialize File System for this Project
nnnn            % Create Necessary Directories and Registry Files
nn                % Create base directory if it does not exist
                if ~exist(obj.BasePath, 'you')
n                    fprintf('Created Database Directory: %s \n', obj.BasePath);
nn                % Create Project Directory
nn                if ~exist(projectPath, 'you')
n                    fprintf('Created Project Directory: %S \n', projectPath);
nn                % Create sessions Directory
                sessionsPath = fullfile(projectPath, 'sessions');
                if ~exist(sessionsPath, 'you')
nnn                % Create Session-Specific Directory
n                if ~exist(sessionPath, 'you')
n                    fprintf('Created session directory: %s \n', sessionPath);
nn                % Create Metadata Directory
                metadataPath = fullfile(projectPath, 'metadata');
                if ~exist(metadataPath, 'you')
nnn                % Create or Load Registry File
                registryFile = fullfile(metadataPath, 'Registry.json');
                if exist(registryFile, 'file')
nnn                        fprintf('Loaded Existing Registry with %d Entries \n', numel(fieldnames(obj.DataRegistry)));
n                        warning('Failed to Load Registry, Creating New One: %S', ME.message);
                        obj.DataRegistry = struct('tablet', struct(), 'loadupdate', datestr(now));
nnn                    % Initialize Empty Registry
                    obj.DataRegistry = struct('tablet', struct(), 'loadupdate', datestr(now));
nnnn                fprintf('Filebasedbpmndatabase initialized for project: %s, session: %s \n', ...
nnnn                error('Filebasedbpmndatabase: Initfailed', ...
                      'Failed to initialize file system: %s', ME.message);
nnnn            % Save the Data Registry to Disk
            metadataPath = fullfile(obj.BasePath, obj.ProjectName, 'metadata');
            registryFile = fullfile(metadataPath, 'Registry.json');
n            % Update Timestamp
nn            % Write to file
            registryJson = jsonencode(obj.DataRegistry, 'Prettyprint', true);
            fid = fopen(registryFile, 'W');
n                error('File Based BPMN Database: File Error', 'Cannot Open Registry File for Writing');
n            fprintf(fid, '%s', registryJson);
nnnn            % Insert data into a table, saving to disk
            % Tablename: Name of the Table (Collection)
            % Data: Structure Array of Data to Insert
            % Returns: Array of inserted IDS
nn                error('Filebasedbpmndatabase: Notinitialized', 'Database not initialized');
nnn                % Ensure Tables Registry Exists
                if ~isfield(obj.DataRegistry, 'tablet')
nnn                % Create Table Entry if it does not exist
n                    obj.DataRegistry.tables.(tableName) = struct('count', 0, 'files', {{}}, 'loadupdate', datestr(now));
nn                % Generate File Path for this table and session
                sessionPath = fullfile(obj.BasePath, obj.ProjectName, 'sessions', obj.CurrentSession);
                fileName = sprintf('%s_%s_%03d.json', tableName, obj.CurrentSession, ...
nnn                % Generates IDS IF not present
nnn                % Determine id field name Based on Table Name
nn                % Assign ids if not present
nn                        % Generates New ID Combining Table, Timestamp and Counter
                        newId = sprintf('%s_%s_%d', upper(tableName), obj.CurrentSession, ...
nnnnnn                % Save Data to File
                dataJson = jsonencode(data, 'Prettyprint', true);
                fid = fopen(filePath, 'W');
n                    error('File Based BPMN Database: File Error', 'Cannot Open File for Writing: %S', filePath);
n                fprintf(fid, '%s', dataJson);
nn                % Update registry
nnnn                % Save registry if auto-save is enabled
nnnn                fprintf('Inserted %d items ino %s, saved to %s \n', numItems, tableName, fileName);
nn                error('Filebasedbpmndatabase: Insertror', ...
                      'Failed to insert data: %s', ME.message);
nnnn            % Fetch Data from the Specified Table
            % Tablename: Name of the Table to fetch from
            % Filter: Optional Filtering Criteria (Not Implemented Yet)
            % Returns: Structure Array with all data from the table
nnnnnn                error('Filebasedbpmndatabase: Notinitialized', 'Database not initialized');
nnn                % Check If IF Table Exists
                if ~isfield(obj.DataRegistry, 'tablet') || ~isfield(obj.DataRegistry.tables, tableName)
                    warning('Filebasedbpmndatabase: Tablenotfound', 'Table %s not found', tableName);
nnnnnnn                % Loop through all files for this table
nnn                    % Determine which session this file Belongs to
                    parts = strsplit(fileName, '_');
nn                        filePath = fullfile(obj.BasePath, obj.ProjectName, 'sessions', sessionId, fileName);
n                        % Fallback to current session if file naming does not match Expected Pattern
                        filePath = fullfile(obj.BasePath, obj.ProjectName, 'sessions', obj.CurrentSession, fileName);
nn                    % Read and Parse File
                    if exist(filePath, 'file')
nnn                        % Initialize or append data
nnn                            % Ensure Consistent Fields
nn                            % Add Missing Fields to Existing Data
nnnnnnnnnn                            % Append New Data
nnn                        warning('Filebasedbpmndatabase: Filenotfound', 'File not found: %s', filePath);
nnn                % Apply Filtering (Basic Implementation)
nnnnnnnnnnnnnnnnnnnnnn                fprintf('Fetched %d items from table %s \n', numel(data), tableName);
nn                error('Filebasedbpmndatabase: Fetcheror', ...
                      'Failed to fetch data: %s', ME.message);
nnnn            % Fetch data from all tables
            % Returns: Structure Where Each Field Corresponds to a Table
nn                error('Filebasedbpmndatabase: Notinitialized', 'Database not initialized');
nnnn            if ~isfield(obj.DataRegistry, 'tablet')
nnnnnnnnn            fprintf('Fetched data from %d tables \n', numel(tableNames));
nnn            % Export All Data to a Single Consolidated Json File
            % Outputpath: Path Where to Save the File
nn                error('Filebasedbpmndatabase: Notinitialized', 'Database not initialized');
nnn                outputPath = fullfile(obj.BasePath, obj.ProjectName, [obj.ProjectName '_consolidated.json']);
nnnnn                % Add Metadata
n                    'project name', obj.ProjectName, ...
                    'export date', datestr(now), ...
                    'sessions', obj.CurrentSession);
n                % Write to file
                dataJson = jsonencode(data, 'Prettyprint', true);
                fid = fopen(outputPath, 'W');
n                    error('Filebasedbpmndatabase: Exporterror', 'Cannot Open File for Writing: %S', outputPath);
n                fprintf(fid, '%s', dataJson);
nn                fprintf('Exported all data to %s \n', outputPath);
nn                error('Filebasedbpmndatabase: Exporterror', ...
                      'Failed to export data: %s', ME.message);
nnnn            % Get a Summary of the Database Contents
nn                error('Filebasedbpmndatabase: Notinitialized', 'Database not initialized');
nnn                'project name', obj.ProjectName, ...
                'Current session', obj.CurrentSession, ...
                'tablet', struct(), ...
                'totalitems', 0);
n            if isfield(obj.DataRegistry, 'tablet')
nnnnnn                        'count', tableInfo.count, ...
                        'loadupdate', tableInfo.lastUpdate, ...
                        'filecount', numel(tableInfo.files));
nnnnnnnnnnn            % Determine the appropriate id field name Based on Table Name
n            % Common patterns:
            % - Singular_id for Plural Table Name (Processes -> Process_ID)
            % - Table_id for Generic Table Name (element -> element_id)
n            if endsWith(tableName, 'S')
                % Try to Make Singular: Processes -> Process_ID
n                idField = [singular '_id'];
n                % Just append _id
                idField = [tableName '_id'];
nn            % Special case
            if strcmpi(tableName, 'bpmn_elements')
                idField = 'element_id';
            elseif strcmpi(tableName, 'sequence_flows')
                idField = 'Flow_id';
            elseif strcmpi(tableName, 'resources')
                idField = 'resource_id';
nnnn            % Sanitize a string to be safe for use as a file name
            fileName = regexprep(name, '[\\/:*?"<>|]',,'_');
            fileName = regexprep(fileName, '\ s+', '_');
nnnnnn    % Determine the appropriate id field name Based on Table Name
nnnn    % Sanitize a string to be safe for use as a file name
nn