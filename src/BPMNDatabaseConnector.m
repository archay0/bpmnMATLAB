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
        
        function data = fetchElements(obj, processId)
            % Fetch all BPMN elements with their attributes for a process
            % processId: ID of the process to fetch elements for
            % Returns a table with element data according to DatabaseSchema.md
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            % Check if we have the schema that matches DatabaseSchema.md
            tables = obj.listTables();
            
            % Check if we have the modern schema structure
            if ismember('bpmn_elements', tables)
                % Use the schema from DatabaseSchema.md
                query = ['SELECT e.*, t.implementation, t.script, t.script_format, ', ...
                         'ev.event_definition_type, ev.is_interrupting, ev.attached_to_ref, ', ...
                         'g.gateway_direction, p.container_type, p.process_ref, p.parent_id, ', ...
                         'ep.x, ep.y, ep.width, ep.height, ep.is_expanded ', ...
                         'FROM bpmn_elements e ', ...
                         'LEFT JOIN tasks t ON e.element_id = t.task_id ', ...
                         'LEFT JOIN events ev ON e.element_id = ev.event_id ', ...
                         'LEFT JOIN gateways g ON e.element_id = g.gateway_id ', ...
                         'LEFT JOIN pools_and_lanes p ON e.element_id = p.container_id ', ...
                         'LEFT JOIN element_positions ep ON e.element_id = ep.element_id ', ...
                         'WHERE e.process_id = ''', processId, ''' ', ...
                         'ORDER BY e.element_id'];
            else
                % Use a generic query for backwards compatibility
                query = ['SELECT element_id, element_type, element_name, properties ', ...
                         'FROM process_elements ', ...
                         'WHERE process_id = ''', processId, ''' ', ...
                         'ORDER BY element_id'];
            end
            
            data = exec(obj.Connection, query);
            data = fetch(data);
            
            % Cache the result
            cacheKey = ['elements_', processId];
            if height(data) < 1000
                obj.QueryCache(cacheKey) = data;
            end
        end
        
        function data = fetchSequenceFlows(obj, processId)
            % Fetch sequence flows with waypoints for a process
            % processId: ID of the process to fetch flows for
            % Returns a table with flow data and associated waypoints
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            tables = obj.listTables();
            
            % Check if we have the modern schema structure
            if ismember('sequence_flows', tables) && ismember('waypoints', tables)
                % Join with waypoints table to get the path data
                query = ['SELECT sf.*, GROUP_CONCAT(CONCAT(wp.sequence, ":", wp.x, ":", wp.y) ', ...
                         'ORDER BY wp.sequence SEPARATOR ";") as waypoints_data ', ...
                         'FROM sequence_flows sf ', ...
                         'LEFT JOIN waypoints wp ON sf.flow_id = wp.flow_id ', ...
                         'WHERE sf.process_id = ''', processId, ''' ', ...
                         'GROUP BY sf.flow_id ', ...
                         'ORDER BY sf.flow_id'];
            else
                % Fallback to generic query
                query = ['SELECT flow_id, source_ref, target_ref, condition_expr ', ...
                         'FROM process_flows ', ...
                         'WHERE process_id = ''', processId, ''' ', ...
                         'ORDER BY flow_id'];
            end
            
            data = exec(obj.Connection, query);
            data = fetch(data);
            
            % Cache the result
            cacheKey = ['flows_', processId];
            if height(data) < 1000
                obj.QueryCache(cacheKey) = data;
            end
        end
        
        function data = fetchMessageFlows(obj)
            % Fetch message flows between pools/participants
            % Returns a table with message flow data
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            tables = obj.listTables();
            
            % Check if we have the modern schema structure
            if ismember('message_flows', tables) && ismember('waypoints', tables)
                query = ['SELECT mf.*, GROUP_CONCAT(CONCAT(wp.sequence, ":", wp.x, ":", wp.y) ', ...
                         'ORDER BY wp.sequence SEPARATOR ";") as waypoints_data ', ...
                         'FROM message_flows mf ', ...
                         'LEFT JOIN waypoints wp ON mf.flow_id = wp.flow_id ', ...
                         'GROUP BY mf.flow_id ', ...
                         'ORDER BY mf.flow_id'];
                         
                data = exec(obj.Connection, query);
                data = fetch(data);
            else
                % Return empty table if the schema doesn't support message flows
                data = table();
            end
            
            % Cache the result
            if height(data) < 1000
                obj.QueryCache('message_flows') = data;
            end
        end
        
        function data = fetchDataObjects(obj, processId)
            % Fetch data objects and associations for a process
            % processId: ID of the process to fetch data objects for
            % Returns a table with data object information
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            tables = obj.listTables();
            
            % Check if we have the modern schema structure
            if ismember('data_objects', tables)
                query = ['SELECT do.*, ep.x, ep.y, ep.width, ep.height ', ...
                         'FROM data_objects do ', ...
                         'LEFT JOIN element_positions ep ON do.data_object_id = ep.element_id ', ...
                         'WHERE do.process_id = ''', processId, ''' ', ...
                         'ORDER BY do.data_object_id'];
                         
                data = exec(obj.Connection, query);
                data = fetch(data);
                
                % Cache the result
                cacheKey = ['data_objects_', processId];
                if height(data) < 1000
                    obj.QueryCache(cacheKey) = data;
                end
            else
                % Return empty table if schema doesn't support data objects
                data = table();
            end
        end
        
        function data = fetchDataAssociations(obj)
            % Fetch data associations with waypoints
            % Returns a table with data association information
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            tables = obj.listTables();
            
            % Check if we have the modern schema structure
            if ismember('data_associations', tables) && ismember('waypoints', tables)
                query = ['SELECT da.*, GROUP_CONCAT(CONCAT(wp.sequence, ":", wp.x, ":", wp.y) ', ...
                         'ORDER BY wp.sequence SEPARATOR ";") as waypoints_data ', ...
                         'FROM data_associations da ', ...
                         'LEFT JOIN waypoints wp ON da.association_id = wp.flow_id ', ...
                         'GROUP BY da.association_id ', ...
                         'ORDER BY da.association_id'];
                
                data = exec(obj.Connection, query);
                data = fetch(data);
                
                % Cache the result
                if height(data) < 1000
                    obj.QueryCache('data_associations') = data;
                end
            else
                % Return empty table if schema doesn't support data associations
                data = table();
            end
        end
        
        function data = fetchDiagramInfo(obj, processId)
            % Fetch diagram information (element positions and waypoints)
            % processId: ID of the process to fetch diagram info for
            % Returns a table with diagram positioning data
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            tables = obj.listTables();
            
            % Check if we have the modern schema structure
            if ismember('element_positions', tables)
                query = ['SELECT ep.* ', ...
                         'FROM element_positions ep ', ...
                         'JOIN bpmn_elements e ON ep.element_id = e.element_id ', ...
                         'WHERE e.process_id = ''', processId, ''' ', ...
                         'ORDER BY ep.element_id'];
                
                data = exec(obj.Connection, query);
                data = fetch(data);
                
                % Cache the result
                cacheKey = ['diagram_info_', processId];
                if height(data) < 1000
                    obj.QueryCache(cacheKey) = data;
                end
            else
                % Return empty table if schema doesn't support element positions
                data = table();
            end
        end
        
        function data = fetchAnnotations(obj, processId)
            % Fetch text annotations for a process
            % processId: ID of the process to fetch annotations for
            % Returns a table with text annotation data
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            % Try to find text annotations in the elements table
            query = ['SELECT e.*, ep.x, ep.y, ep.width, ep.height ', ...
                     'FROM bpmn_elements e ', ...
                     'LEFT JOIN element_positions ep ON e.element_id = ep.element_id ', ...
                     'WHERE e.element_type = ''textAnnotation'' ', ...
                     'AND e.process_id = ''', processId, ''' ', ...
                     'ORDER BY e.element_id'];
            
            data = exec(obj.Connection, query);
            data = fetch(data);
            
            % If no annotations found, return empty table
            if isempty(data)
                data = table();
            else
                % Cache the result
                cacheKey = ['annotations_', processId];
                if height(data) < 1000
                    obj.QueryCache(cacheKey) = data;
                end
            end
        end
        
        function data = fetchAssociations(obj, processId)
            % Fetch non-data associations for a process (like text annotation connections)
            % processId: ID of the process to fetch associations for
            % Returns a table with association data
            
            if ~obj.Connected
                error('Database connection not established. Call connect first.');
            end
            
            tables = obj.listTables();
            
            % Try to query associations
            if ismember('sequence_flows', tables)
                query = ['SELECT sf.*, GROUP_CONCAT(CONCAT(wp.sequence, ":", wp.x, ":", wp.y) ', ...
                         'ORDER BY wp.sequence SEPARATOR ";") as waypoints_data ', ...
                         'FROM sequence_flows sf ', ...
                         'LEFT JOIN waypoints wp ON sf.flow_id = wp.flow_id ', ...
                         'WHERE sf.process_id = ''', processId, ''' ', ...
                         'AND sf.flow_type = ''association'' ', ... % Assuming flow_type column exists
                         'GROUP BY sf.flow_id ', ...
                         'ORDER BY sf.flow_id'];
                
                data = exec(obj.Connection, query);
                data = fetch(data);
                
                % Cache the result
                cacheKey = ['associations_', processId];
                if height(data) < 1000
                    obj.QueryCache(cacheKey) = data;
                end
            else
                % Return empty table if schema doesn't have flow_type column
                data = table();
            end
        end
    end
end