classdef FileBasedBPMNDatabase < handle
    % FileBasedBPMNDatabase Provides persistent file-based storage for BPMN data
    % This class saves generated BPMN data to files and retrieves it when needed
    % allowing for projects that exceed LLM token limits by storing data across sessions
    
    properties
        BasePath        % Base directory for data storage
        ProjectName     % Current project name (used as subdirectory)
        CurrentSession  % Current generation session identifier
        DataRegistry    % Registry of saved data files and their metadata
        IsInitialized   % Flag indicating if the database is initialized
        AutoSave        % Whether to automatically save after each insertion
    end
    
    methods
        function obj = FileBasedBPMNDatabase(projectName, options)
            % Constructor creates a new file-based database for BPMN data
            % projectName: Name of the project (used for directory naming)
            % options: Optional configuration parameters
            
            if nargin < 1
                projectName = 'default_project';
            end
            
            if nargin < 2
                options = struct();
            end
            
            % Set default base path to db directory in the workspace
            currentDir = fileparts(mfilename('fullpath'));
            obj.BasePath = fullfile(currentDir, 'storage');
            
            % Apply options if provided
            if isfield(options, 'basePath')
                obj.BasePath = options.basePath;
            end
            
            obj.ProjectName = sanitizeFileName(projectName);
            obj.CurrentSession = datestr(now, 'yyyymmdd_HHMMSS');
            obj.DataRegistry = struct();
            obj.IsInitialized = false;
            obj.AutoSave = true;
            
            % Initialize file system for this project
            initializeFileSystem(obj);
        end
        
        function initializeFileSystem(obj)
            % Create necessary directories and registry files
            
            try
                % Create base directory if it doesn't exist
                if ~exist(obj.BasePath, 'dir')
                    mkdir(obj.BasePath);
                    fprintf('Created database directory: %s\n', obj.BasePath);
                end
                
                % Create project directory
                obj.ProjectName = sanitizeFileName(obj.ProjectName);
                projectPath = fullfile(obj.BasePath, obj.ProjectName);
                if ~exist(projectPath, 'dir')
                    mkdir(projectPath);
                    fprintf('Created project directory: %s\n', projectPath);
                end
                
                % Create sessions directory
                sessionsPath = fullfile(projectPath, 'sessions');
                if ~exist(sessionsPath, 'dir')
                    mkdir(sessionsPath);
                end
                
                % Create session-specific directory
                sessionPath = fullfile(sessionsPath, obj.CurrentSession);
                if ~exist(sessionPath, 'dir')
                    mkdir(sessionPath);
                    fprintf('Created session directory: %s\n', sessionPath);
                end
                
                % Create metadata directory
                metadataPath = fullfile(projectPath, 'metadata');
                if ~exist(metadataPath, 'dir')
                    mkdir(metadataPath);
                end
                
                % Create or load registry file
                registryFile = fullfile(metadataPath, 'registry.json');
                if exist(registryFile, 'file')
                    try
                        registryText = fileread(registryFile);
                        obj.DataRegistry = jsondecode(registryText);
                        fprintf('Loaded existing registry with %d entries\n', numel(fieldnames(obj.DataRegistry)));
                    catch ME
                        warning('Failed to load registry, creating new one: %s', ME.message);
                        obj.DataRegistry = struct('tables', struct(), 'lastUpdate', datestr(now));
                        saveRegistry(obj);
                    end
                else
                    % Initialize empty registry
                    obj.DataRegistry = struct('tables', struct(), 'lastUpdate', datestr(now));
                    saveRegistry(obj);
                end
                
                obj.IsInitialized = true;
                fprintf('FileBasedBPMNDatabase initialized for project: %s, session: %s\n', ...
                    obj.ProjectName, obj.CurrentSession);
                
            catch ME
                obj.IsInitialized = false;
                error('FileBasedBPMNDatabase:InitFailed', ...
                      'Failed to initialize file system: %s', ME.message);
            end
        end
        
        function saveRegistry(obj)
            % Save the data registry to disk
            metadataPath = fullfile(obj.BasePath, obj.ProjectName, 'metadata');
            registryFile = fullfile(metadataPath, 'registry.json');
            
            % Update timestamp
            obj.DataRegistry.lastUpdate = datestr(now);
            
            % Write to file
            registryJson = jsonencode(obj.DataRegistry, 'PrettyPrint', true);
            fid = fopen(registryFile, 'w');
            if fid == -1
                error('FileBasedBPMNDatabase:SaveError', 'Cannot open registry file for writing');
            end
            fprintf(fid, '%s', registryJson);
            fclose(fid);
        end
        
        function insertedIds = insertData(obj, tableName, data)
            % Insert data into a table, saving to disk
            % tableName: Name of the table (collection)
            % data: Structure array of data to insert
            % Returns: Array of inserted IDs
            
            if ~obj.IsInitialized
                error('FileBasedBPMNDatabase:NotInitialized', 'Database not initialized');
            end
            
            try
                % Ensure tables registry exists
                if ~isfield(obj.DataRegistry, 'tables')
                    obj.DataRegistry.tables = struct();
                end
                
                % Create table entry if it doesn't exist
                if ~isfield(obj.DataRegistry.tables, tableName)
                    obj.DataRegistry.tables.(tableName) = struct('count', 0, 'files', {{}}, 'lastUpdate', datestr(now));
                end
                
                % Generate file path for this table and session
                sessionPath = fullfile(obj.BasePath, obj.ProjectName, 'sessions', obj.CurrentSession);
                fileName = sprintf('%s_%s_%03d.json', tableName, obj.CurrentSession, ...
                                   obj.DataRegistry.tables.(tableName).count + 1);
                filePath = fullfile(sessionPath, fileName);
                
                % Generate IDs if not present
                numItems = numel(data);
                insertedIds = cell(numItems, 1);
                
                % Determine ID field name based on table name
                idField = determineIdField(obj, tableName);
                
                % Assign IDs if not present
                for i = 1:numItems
                    if ~isfield(data, idField) || isempty(data(i).(idField))
                        % Generate new ID combining table, timestamp and counter
                        newId = sprintf('%s_%s_%d', upper(tableName), obj.CurrentSession, ...
                                       obj.DataRegistry.tables.(tableName).count + i);
                        data(i).(idField) = newId;
                    end
                    insertedIds{i} = data(i).(idField);
                end
                
                % Save data to file
                dataJson = jsonencode(data, 'PrettyPrint', true);
                fid = fopen(filePath, 'w');
                if fid == -1
                    error('FileBasedBPMNDatabase:SaveError', 'Cannot open file for writing: %s', filePath);
                end
                fprintf(fid, '%s', dataJson);
                fclose(fid);
                
                % Update registry
                obj.DataRegistry.tables.(tableName).count = obj.DataRegistry.tables.(tableName).count + numItems;
                obj.DataRegistry.tables.(tableName).lastUpdate = datestr(now);
                obj.DataRegistry.tables.(tableName).files{end+1} = fileName;
                
                % Save registry if auto-save is enabled
                if obj.AutoSave
                    saveRegistry(obj);
                end
                
                fprintf('Inserted %d items into %s, saved to %s\n', numItems, tableName, fileName);
                
            catch ME
                error('FileBasedBPMNDatabase:InsertError', ...
                      'Failed to insert data: %s', ME.message);
            end
        end
        
        function data = fetchData(obj, tableName, filter)
            % Fetch data from the specified table
            % tableName: Name of the table to fetch from
            % filter: Optional filtering criteria (not implemented yet)
            % Returns: Structure array with all data from the table
            
            if nargin < 3
                filter = struct();
            end
            
            if ~obj.IsInitialized
                error('FileBasedBPMNDatabase:NotInitialized', 'Database not initialized');
            end
            
            try
                % Check if table exists
                if ~isfield(obj.DataRegistry, 'tables') || ~isfield(obj.DataRegistry.tables, tableName)
                    warning('FileBasedBPMNDatabase:TableNotFound', 'Table %s not found', tableName);
                    data = [];
                    return;
                end
                
                tableInfo = obj.DataRegistry.tables.(tableName);
                allData = [];
                
                % Loop through all files for this table
                for i = 1:numel(tableInfo.files)
                    fileName = tableInfo.files{i};
                    
                    % Determine which session this file belongs to
                    parts = strsplit(fileName, '_');
                    if numel(parts) >= 2
                        sessionId = parts{2};
                        filePath = fullfile(obj.BasePath, obj.ProjectName, 'sessions', sessionId, fileName);
                    else
                        % Fallback to current session if file naming doesn't match expected pattern
                        filePath = fullfile(obj.BasePath, obj.ProjectName, 'sessions', obj.CurrentSession, fileName);
                    end
                    
                    % Read and parse file
                    if exist(filePath, 'file')
                        fileContent = fileread(filePath);
                        fileData = jsondecode(fileContent);
                        
                        % Initialize or append data
                        if isempty(allData)
                            allData = fileData;
                        else
                            % Ensure consistent fields
                            allFields = union(fieldnames(allData), fieldnames(fileData));
                            
                            % Add missing fields to existing data
                            for k = 1:numel(allFields)
                                fld = allFields{k};
                                if ~isfield(allData, fld)
                                    [allData.(fld)] = deal([]);
                                end
                                if ~isfield(fileData, fld)
                                    [fileData.(fld)] = deal([]);
                                end
                            end
                            
                            % Append new data
                            allData = [allData; fileData];
                        end
                    else
                        warning('FileBasedBPMNDatabase:FileNotFound', 'File not found: %s', filePath);
                    end
                end
                
                % Apply filtering (basic implementation)
                if ~isempty(allData) && ~isempty(fieldnames(filter))
                    filterFields = fieldnames(filter);
                    indices = true(numel(allData), 1);
                    
                    for i = 1:numel(filterFields)
                        field = filterFields{i};
                        value = filter.(field);
                        
                        if isfield(allData, field)
                            for j = 1:numel(allData)
                                if ~isequal(allData(j).(field), value)
                                    indices(j) = false;
                                end
                            end
                        end
                    end
                    
                    data = allData(indices);
                else
                    data = allData;
                end
                
                fprintf('Fetched %d items from table %s\n', numel(data), tableName);
                
            catch ME
                error('FileBasedBPMNDatabase:FetchError', ...
                      'Failed to fetch data: %s', ME.message);
            end
        end
        
        function data = fetchAllTables(obj)
            % Fetch data from all tables
            % Returns: Structure where each field corresponds to a table
            
            if ~obj.IsInitialized
                error('FileBasedBPMNDatabase:NotInitialized', 'Database not initialized');
            end
            
            data = struct();
            
            if ~isfield(obj.DataRegistry, 'tables')
                return;
            end
            
            tableNames = fieldnames(obj.DataRegistry.tables);
            for i = 1:numel(tableNames)
                tableName = tableNames{i};
                data.(tableName) = fetchData(obj, tableName);
            end
            
            fprintf('Fetched data from %d tables\n', numel(tableNames));
        end
        
        function exportToFile(obj, outputPath)
            % Export all data to a single consolidated JSON file
            % outputPath: Path where to save the file
            
            if ~obj.IsInitialized
                error('FileBasedBPMNDatabase:NotInitialized', 'Database not initialized');
            end
            
            if nargin < 2 || isempty(outputPath)
                outputPath = fullfile(obj.BasePath, obj.ProjectName, [obj.ProjectName '_consolidated.json']);
            end
            
            try
                data = fetchAllTables(obj);
                
                % Add metadata
                data.metadata = struct(...
                    'projectName', obj.ProjectName, ...
                    'exportDate', datestr(now), ...
                    'sessions', obj.CurrentSession);
                
                % Write to file
                dataJson = jsonencode(data, 'PrettyPrint', true);
                fid = fopen(outputPath, 'w');
                if fid == -1
                    error('FileBasedBPMNDatabase:ExportError', 'Cannot open file for writing: %s', outputPath);
                end
                fprintf(fid, '%s', dataJson);
                fclose(fid);
                
                fprintf('Exported all data to %s\n', outputPath);
                
            catch ME
                error('FileBasedBPMNDatabase:ExportError', ...
                      'Failed to export data: %s', ME.message);
            end
        end
        
        function summary = getSummary(obj)
            % Get a summary of the database contents
            
            if ~obj.IsInitialized
                error('FileBasedBPMNDatabase:NotInitialized', 'Database not initialized');
            end
            
            summary = struct(...
                'projectName', obj.ProjectName, ...
                'currentSession', obj.CurrentSession, ...
                'tables', struct(), ...
                'totalItems', 0);
            
            if isfield(obj.DataRegistry, 'tables')
                tableNames = fieldnames(obj.DataRegistry.tables);
                for i = 1:numel(tableNames)
                    tableName = tableNames{i};
                    tableInfo = obj.DataRegistry.tables.(tableName);
                    
                    summary.tables.(tableName) = struct(...
                        'count', tableInfo.count, ...
                        'lastUpdate', tableInfo.lastUpdate, ...
                        'fileCount', numel(tableInfo.files));
                    
                    summary.totalItems = summary.totalItems + tableInfo.count;
                end
            end
            
            return;
        end
    end
    
    methods(Static)
        function idField = determineIdField(tableName)
            % Determine the appropriate ID field name based on table name
            
            % Common patterns:
            % - singular_id for plural table name (processes -> process_id)
            % - table_id for generic table name (element -> element_id)
            
            if endsWith(tableName, 's')
                % Try to make singular: processes -> process_id
                singular = tableName(1:end-1);
                idField = [singular '_id'];
            else
                % Just append _id
                idField = [tableName '_id'];
            end
            
            % Special cases
            if strcmpi(tableName, 'bpmn_elements')
                idField = 'element_id';
            elseif strcmpi(tableName, 'sequence_flows')
                idField = 'flow_id';
            elseif strcmpi(tableName, 'resources')
                idField = 'resource_id';
            end
        end
        
        function fileName = sanitizeFileName(name)
            % Sanitize a string to be safe for use as a file name
            fileName = regexprep(name, '[\\/:*?"<>|]', '_');
            fileName = regexprep(fileName, '\s+', '_');
            fileName = lower(fileName);
        end
    end
end

function idField = determineIdField(obj, tableName)
    % Determine the appropriate ID field name based on table name
    idField = FileBasedBPMNDatabase.determineIdField(tableName);
end

function fileName = sanitizeFileName(name)
    % Sanitize a string to be safe for use as a file name
    fileName = FileBasedBPMNDatabase.sanitizeFileName(name);
end