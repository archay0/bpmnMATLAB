classdef FileBPMNDatabaseBridge < handle
    % FileBPMNDatabaseBridge Bridges between BPMNDatabaseConnector and FileBasedBPMNDatabase
    % This class provides methods that match BPMNDatabaseConnector's static methods
    % while forwarding calls to a FileBasedBPMNDatabase instance
    
    properties
        FileDB          % The FileBasedBPMNDatabase instance
        ProjectName     % Name of the current project
        IsInitialized   % Flag indicating if the bridge is initialized
    end
    
    methods
        function obj = FileBPMNDatabaseBridge(projectName, options)
            % Constructor initializes the bridge and underlying FileBasedBPMNDatabase
            % projectName: Name of the project (used for directory naming)
            % options: Optional configuration parameters
            
            if nargin < 1
                projectName = 'default_project';
            end
            
            if nargin < 2
                options = struct();
            end
            
            obj.ProjectName = projectName;
            obj.IsInitialized = false;
            
            try
                % Initialize the file-based database
                obj.FileDB = FileBasedBPMNDatabase(projectName, options);
                obj.IsInitialized = true;
                
                fprintf('FileBPMNDatabaseBridge initialized for project: %s\n', obj.ProjectName);
            catch ME
                error('FileBPMNDatabaseBridge:InitError', ...
                      'Failed to initialize database bridge: %s', ME.message);
            end
        end
        
        function insertedIDs = insertRows(obj, tableName, rows)
            % Insert rows into a table, matching BPMNDatabaseConnector.insertRows interface
            % tableName: Name of the table (collection)
            % rows: Structure array of data to insert
            % Returns: Array of inserted IDs
            
            if ~obj.IsInitialized
                error('FileBPMNDatabaseBridge:NotInitialized', 'Bridge not initialized');
            end
            
            try
                % Forward the call to the file-based database
                insertedIDs = obj.FileDB.insertData(tableName, rows);
            catch ME
                error('FileBPMNDatabaseBridge:InsertError', ...
                      'Failed to insert rows: %s', ME.message);
            end
        end
        
        function allData = fetchAll(obj, tableNames)
            % Fetch data from specified tables, matching BPMNDatabaseConnector.fetchAll interface
            % tableNames: Cell array of table names to fetch from
            % Returns: Structure where each field corresponds to a table
            
            if ~obj.IsInitialized
                error('FileBPMNDatabaseBridge:NotInitialized', 'Bridge not initialized');
            end
            
            try
                % Ensure tableNames is a cell array
                if ~iscell(tableNames)
                    tableNames = {tableNames};
                end
                
                % Initialize result structure
                allData = struct();
                
                % Fetch data for each table
                for i = 1:numel(tableNames)
                    tableName = tableNames{i};
                    data = obj.FileDB.fetchData(tableName);
                    
                    % Store in result structure
                    allData.(tableName) = data;
                end
            catch ME
                error('FileBPMNDatabaseBridge:FetchError', ...
                      'Failed to fetch data: %s', ME.message);
            end
        end
        
        function exportToFile(obj, outputPath)
            % Export all data to a single consolidated JSON file
            % outputPath: Path where to save the file
            
            if ~obj.IsInitialized
                error('FileBPMNDatabaseBridge:NotInitialized', 'Bridge not initialized');
            end
            
            try
                obj.FileDB.exportToFile(outputPath);
            catch ME
                error('FileBPMNDatabaseBridge:ExportError', ...
                      'Failed to export data: %s', ME.message);
            end
        end
        
        function summary = getSummary(obj)
            % Get a summary of the database contents
            
            if ~obj.IsInitialized
                error('FileBPMNDatabaseBridge:NotInitialized', 'Bridge not initialized');
            end
            
            try
                summary = obj.FileDB.getSummary();
            catch ME
                error('FileBPMNDatabaseBridge:SummaryError', ...
                      'Failed to get summary: %s', ME.message);
            end
        end
    end
    
    methods(Static)
        % Static methods that mirror those in BPMNDatabaseConnector
        
        function instance = getInstance(projectName, options)
            % Get or create an instance of the bridge
            % This provides a singleton-like access pattern similar to BPMNDatabaseConnector
            
            persistent bridgeInstance;
            
            if isempty(bridgeInstance) || ~isvalid(bridgeInstance) || ...
                    (nargin > 0 && ~strcmp(bridgeInstance.ProjectName, projectName))
                if nargin < 1
                    projectName = 'default_project';
                end
                if nargin < 2
                    options = struct();
                end
                
                bridgeInstance = FileBPMNDatabaseBridge(projectName, options);
            end
            
            instance = bridgeInstance;
        end
        
        function insertedIDs = insertRows(tableName, rows)
            % Static version of insertRows that uses the singleton instance
            % tableName: Name of the table (collection)
            % rows: Structure array of data to insert
            % Returns: Array of inserted IDs
            
            instance = FileBPMNDatabaseBridge.getInstance();
            insertedIDs = instance.insertRows(tableName, rows);
        end
        
        function allData = fetchAll(tableNames)
            % Static version of fetchAll that uses the singleton instance
            % tableNames: Cell array of table names to fetch from
            % Returns: Structure where each field corresponds to a table
            
            instance = FileBPMNDatabaseBridge.getInstance();
            allData = instance.fetchAll(tableNames);
        end
        
        function exportToFile(outputPath)
            % Static version of exportToFile that uses the singleton instance
            % outputPath: Path where to save the file
            
            instance = FileBPMNDatabaseBridge.getInstance();
            instance.exportToFile(outputPath);
        end
        
        function summary = getSummary()
            % Static version of getSummary that uses the singleton instance
            
            instance = FileBPMNDatabaseBridge.getInstance();
            summary = instance.getSummary();
        end
    end
end