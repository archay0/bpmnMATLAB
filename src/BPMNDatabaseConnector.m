classdef BPMNDatabaseConnector < handle
    % BPMNDatabaseConnector Class for database interactions
    % This class provides methods for connecting to databases and extracting
    % process information for BPMN generation
    
    properties
        Connection      % Database connection object
        DbType          % Type of database (mysql, postgresql, etc.)
        Connected       % Boolean flag indicating if connected
        QueryCache      % Cache for commonly used queries
    end
    
    methods
        function obj = BPMNDatabaseConnector(dbType)
            % Constructor for BPMNDatabaseConnector
            % dbType: Type of database (mysql, postgresql, etc.)
            
            if nargin > 0
                obj.DbType = dbType;
            else
                obj.DbType = '';
            end
            obj.Connected = false;
            obj.QueryCache = containers.Map();
        end
        
        function success = connect(obj, connectionParams)
            % Connect to database
            % connectionParams: Structure with connection parameters
            %   - dbName: Database name
            %   - username: Database username
            %   - password: Database password
            %   - server: Database server address
            %   - port: Database port number
            
            try
                % Use MATLAB Database Toolbox to establish connection
                switch lower(obj.DbType)
                    case 'mysql'
                        obj.Connection = database(connectionParams.dbName, ...
                                                connectionParams.username, ...
                                                connectionParams.password, ...
                                                'Vendor', 'MySQL', ...
                                                'Server', connectionParams.server, ...
                                                'PortNumber', connectionParams.port);
                    case 'postgresql'
                        obj.Connection = database(connectionParams.dbName, ...
                                                connectionParams.username, ...
                                                connectionParams.password, ...
                                                'Vendor', 'PostgreSQL', ...
                                                'Server', connectionParams.server, ...
                                                'PortNumber', connectionParams.port);
                    case 'sqlite'
                        obj.Connection = database(connectionParams.dbName, '', '', ...
                                                'Vendor', 'SQLite', ...
                                                'DataSource', connectionParams.filePath);
                    case 'odbc'
                        obj.Connection = database('', connectionParams.username, ...
                                                connectionParams.password, ...
                                                'Vendor', 'ODBC', ...
                                                'DataSource', connectionParams.dsn);
                    otherwise
                        error('Unsupported database type: %s', obj.DbType);
                end
                
                if ~isempty(obj.Connection.Message)
                    error('Database connection failed: %s', obj.Connection.Message);
                end
                
                obj.Connected = true;
                success = true;
                fprintf('Successfully connected to %s database\n', obj.DbType);
            catch ex
                obj.Connected = false;
                success = false;
                error('Error connecting to database: %s', ex.message);
            end
        end
        
        function disconnect(obj)
            % Disconnect from database
            if obj.Connected && ~isempty(obj.Connection)
                close(obj.Connection);
                obj.Connected = false;
                fprintf('Disconnected from %s database\n', obj.DbType);
            end
        end
        
        function data = queryProcessDefinitions(obj)
            % Query process definitions from database
            % Returns a table of process definitions
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            % Query depends on database structure - this is a generic example
            query = ['SELECT process_id, process_name, description ', ...
                     'FROM process_definitions ', ...
                     'ORDER BY process_id'];
            
            data = exec(obj.Connection, query);
            data = fetch(data);
        end
        
        function data = queryProcessElements(obj, processId)
            % Query process elements for a specific process
            % processId: ID of the process to query elements for
            % Returns a table of process elements
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            % Query depends on database structure - this is a generic example
            query = ['SELECT element_id, element_type, element_name, properties ', ...
                     'FROM process_elements ', ...
                     'WHERE process_id = ''', processId, ''' ', ...
                     'ORDER BY element_id'];
            
            data = exec(obj.Connection, query);
            data = fetch(data);
        end
        
        function data = querySequenceFlows(obj, processId)
            % Query sequence flows for a specific process
            % processId: ID of the process to query flows for
            % Returns a table of sequence flows
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            % Query depends on database structure - this is a generic example
            query = ['SELECT flow_id, source_ref, target_ref, condition_expr ', ...
                     'FROM process_flows ', ...
                     'WHERE process_id = ''', processId, ''' ', ...
                     'ORDER BY flow_id'];
            
            data = exec(obj.Connection, query);
            data = fetch(data);
        end
        
        function schemaInfo = getTableSchema(obj, tableName)
            % Get schema information for a specific table
            % tableName: Name of the table to get schema for
            % Returns structure with table schema information
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            % Get table information
            tableInfo = obj.Connection.sqltables('TableType', 'TABLE', 'Table', tableName);
            
            % Get column information
            columnInfo = obj.Connection.sqlcolumns('Table', tableName);
            
            % Combine into schema info structure
            schemaInfo = struct('tableName', tableName, ...
                               'columns', columnInfo, ...
                               'tableInfo', tableInfo);
        end
        
        function tables = listTables(obj)
            % List all tables in the current database
            % Returns a cell array of table names
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            % Get all tables
            tableInfo = obj.Connection.sqltables('TableType', 'TABLE');
            
            if isempty(tableInfo)
                tables = {};
            else
                tables = tableInfo.TABLE_NAME;
            end
        end
        
        function result = executeCustomQuery(obj, query)
            % Execute a custom SQL query
            % query: SQL query string to execute
            % Returns query results
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            % Check if query is in cache
            if obj.QueryCache.isKey(query)
                result = obj.QueryCache(query);
            else
                % Execute query
                result = exec(obj.Connection, query);
                result = fetch(result);
                
                % Cache result if it's not too large
                if height(result) < 1000
                    obj.QueryCache(query) = result;
                end
            end
        end
    end
end