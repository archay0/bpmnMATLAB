classdef DatabaseConnectorFactory
    % DatabaseConnectorFactory provides a way to create database connectors
    % This factory allows switching between different storage implementations:
    % 1. In-memory storage (original BPMNDatabaseConnector)
    % 2. File-based storage (FileBPMNDatabaseBridge)
    
    properties (Constant)
        MODE_MEMORY = 'memory'; % Use in-memory storage
        MODE_FILE = 'file';     % Use file-based storage
    end
    
    methods (Static)
        function connector = getConnector(mode, options)
            % Get a database connector based on specified mode
            % mode: Storage mode ('memory' or 'file')
            % options: Configuration options for the connector
            %   For file mode: options.projectName, options.basePath
            % Returns: A connector with BPMNDatabaseConnector-compatible interface
            
            if nargin < 1 || isempty(mode)
                mode = DatabaseConnectorFactory.MODE_MEMORY;
            end
            
            if nargin < 2
                options = struct();
            end
            
            % Get or create singleton connector based on mode
            switch lower(mode)
                case DatabaseConnectorFactory.MODE_MEMORY
                    % Use original in-memory BPMNDatabaseConnector
                    connector = struct();
                    connector.insertRows = @BPMNDatabaseConnector.insertRows;
                    connector.fetchAll = @BPMNDatabaseConnector.fetchAll;
                    
                case DatabaseConnectorFactory.MODE_FILE
                    % Use file-based storage
                    projectName = 'default_project';
                    if isfield(options, 'projectName')
                        projectName = options.projectName;
                    end
                    
                    % Create options for FileBPMNDatabaseBridge
                    bridgeOpts = struct();
                    if isfield(options, 'basePath')
                        bridgeOpts.basePath = options.basePath;
                    end
                    
                    % Get FileBPMNDatabaseBridge instance
                    bridge = FileBPMNDatabaseBridge.getInstance(projectName, bridgeOpts);
                    
                    % Return wrapper with static method interface
                    connector = struct();
                    connector.insertRows = @FileBPMNDatabaseBridge.insertRows;
                    connector.fetchAll = @FileBPMNDatabaseBridge.fetchAll;
                    connector.exportToFile = @FileBPMNDatabaseBridge.exportToFile;
                    connector.getSummary = @FileBPMNDatabaseBridge.getSummary;
                    
                otherwise
                    error('DatabaseConnectorFactory:InvalidMode', ...
                          'Invalid storage mode: %s', mode);
            end
        end
    end
end