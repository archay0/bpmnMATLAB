classdef BPMNDatabaseConnector < handle
    % BPMNDatabaseConnector Class for database interactions
    % This class provides methods for connecting to databases and extracting
    % process information for BPMN generation
    
    properties
        Connection      % Database connection object
        DbType          % Type of database (mysql, postgresql, etc.)
        Connected       % Boolean flag indicating if connected
        QueryCache      % Cache for commonly used queries
        EnvVars         % Environment variables loaded from .env file
    end
    
    methods
        function obj = BPMNDatabaseConnector(dbType)
            % Constructor for BPMNDatabaseConnector
            % dbType: Type of database (mysql, postgresql, etc.)
            
            if nargin > 0
                obj.DbType = dbType;
            else
                % Try to load from environment file
                try
                    obj.loadEnvironmentVars();
                    if isfield(obj.EnvVars, 'DB_TYPE')
                        obj.DbType = obj.EnvVars.DB_TYPE;
                    else
                        obj.DbType = '';
                    end
                catch ex
                    fprintf('Could not load environment variables: %s\n', ex.message);
                    obj.DbType = '';
                end
            end
            
            obj.Connected = false;
            obj.QueryCache = containers.Map();
        end
        
        function loadEnvironmentVars(obj, envFilePath)
            % Load environment variables from the .env file
            % envFilePath: Optional path to the .env file
            
            try
                if nargin < 2
                    % Use the default loadEnvironment function to get the variables
                    utilPath = fileparts(mfilename('fullpath'));
                    utilFolder = fullfile(utilPath, 'util');
                    
                    % Ensure the util folder is on the path
                    if ~any(contains(path, utilFolder))
                        addpath(utilFolder);
                    end
                    
                    obj.EnvVars = loadEnvironment();
                else
                    obj.EnvVars = loadEnvironment(envFilePath);
                end
                fprintf('Environment variables loaded successfully\n');
            catch ex
                warning('Error loading environment variables: %s', ex.message);
                obj.EnvVars = struct();
            end
        end
        
        function success = connectWithEnvFile(obj, envFilePath)
            % Connect to database using credentials from the .env file
            % envFilePath: Optional path to the .env file
            
            try
                % Load environment variables if not already loaded
                if isempty(obj.EnvVars) || ~isfield(obj.EnvVars, 'DB_HOST')
                    if nargin < 2
                        obj.loadEnvironmentVars();
                    else
                        obj.loadEnvironmentVars(envFilePath);
                    end
                end
                
                % Set database type if specified in the environment
                if isfield(obj.EnvVars, 'DB_TYPE') && isempty(obj.DbType)
                    obj.DbType = obj.EnvVars.DB_TYPE;
                end
                
                % Build connection parameters from environment variables
                connectionParams = struct();
                
                if isfield(obj.EnvVars, 'DB_NAME')
                    connectionParams.dbName = obj.EnvVars.DB_NAME;
                else
                    error('DB_NAME not found in environment variables');
                end
                
                if isfield(obj.EnvVars, 'DB_USER')
                    connectionParams.username = obj.EnvVars.DB_USER;
                else
                    connectionParams.username = '';
                end
                
                if isfield(obj.EnvVars, 'DB_PASSWORD')
                    connectionParams.password = obj.EnvVars.DB_PASSWORD;
                else
                    connectionParams.password = '';
                end
                
                if isfield(obj.EnvVars, 'DB_HOST')
                    connectionParams.server = obj.EnvVars.DB_HOST;
                else
                    connectionParams.server = 'localhost';
                end
                
                if isfield(obj.EnvVars, 'DB_PORT')
                    connectionParams.port = obj.EnvVars.DB_PORT;
                else
                    connectionParams.port = 3306;
                end
                
                % Additional configuration for SQLite
                if strcmpi(obj.DbType, 'sqlite') && isfield(obj.EnvVars, 'DB_FILE_PATH')
                    connectionParams.filePath = obj.EnvVars.DB_FILE_PATH;
                end
                
                % Additional configuration for ODBC
                if strcmpi(obj.DbType, 'odbc') && isfield(obj.EnvVars, 'DB_DSN')
                    connectionParams.dsn = obj.EnvVars.DB_DSN;
                end
                
                % Connect using the standard connect method
                success = obj.connect(connectionParams);
                
            catch ex
                success = false;
                error('Error connecting with environment file: %s', ex.message);
            end
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
        
    end % End of regular methods block - Ensure this is present and correctly placed
    
    methods(Static) % Start of static methods block
        function dataStore = getSetTempStore(data)
            % Helper function to manage a persistent temporary data store
            persistent TempDataStore;
            if isempty(TempDataStore)
                TempDataStore = struct(); % Initialize if first time
            end

            if nargin == 1 % Set data
                TempDataStore = data;
            end
            dataStore = TempDataStore; % Return current store
        end % End of getSetTempStore

        function insertedIDs = insertRows(tableName, rows)
            % insertRows - Static method to insert data rows into a temporary store
            % tableName: Name of the table (field name in the store)
            % rows: Struct array of data to insert
            % Returns: Array of dummy IDs for the inserted rows

            fprintf('--- Inserting %d rows into temporary store for table: %s ---\n', numel(rows), tableName);

            if isempty(rows)
                 insertedIDs = {};
                 fprintf('--- No rows provided for table: %s. Skipping insertion. ---\n', tableName);
                 return;
            end

            % Ensure rows is a struct array
            if ~isstruct(rows)
                 warning('BPMNDatabaseConnector:insertRows:InvalidInput', ...
                         'Input "rows" for table %s is not a struct array. Skipping insertion.', tableName);
                 insertedIDs = {};
                 return;
            end

            tempStore = BPMNDatabaseConnector.getSetTempStore(); % Get current store

            % Generate dummy IDs
            numExisting = 0;
            if isfield(tempStore, tableName) && isstruct(tempStore.(tableName))
                numExisting = numel(tempStore.(tableName));
            end
            insertedIDs = arrayfun(@(x) sprintf('%s_ID_%d', upper(tableName), numExisting + x), 1:numel(rows), 'UniformOutput', false);

            % Add dummy IDs to the rows if an 'id' field is expected (heuristic)
            idField = '';
            if endsWith(tableName, 's') % e.g., processes -> process_id
                idField = [tableName(1:end-1) '_id'];
            elseif strcmp(tableName, 'bpmn_elements')
                idField = 'element_id';
            % Add more specific cases if needed

            if ~isempty(idField) && isfield(rows, idField)
                 for i = 1:numel(rows)
                     % Only assign if the field is empty or non-existent,
                     % assuming LLM might sometimes provide one.
                     if ~isfield(rows(i), idField) || isempty(rows(i).(idField))
                         rows(i).(idField) = insertedIDs{i};
                     else
                         % If LLM provided an ID, use that instead of overwriting
                         insertedIDs{i} = rows(i).(idField);
                     end
                 end
            elseif ~isempty(idField) && ~isfield(rows, idField)
                 % Add the ID field if it doesn't exist at all
                 for i = 1:numel(rows)
                     rows(i).(idField) = insertedIDs{i};
                 end
            end


            % Append rows to the store
            if isfield(tempStore, tableName) && ~isempty(tempStore.(tableName))
                % Ensure consistent fields before concatenating
                 existingFields = fieldnames(tempStore.(tableName));
                 newFields = fieldnames(rows);
                 allFields = union(existingFields, newFields);

                 % Add missing fields to existing data
                 for k = 1:numel(existingFields)
                     fld = existingFields{k};
                     if ~isfield(rows, fld)
                         [rows.(fld)] = deal([]); % Add missing field with default empty
                     end
                 end
                 % Add missing fields to new data
                 for k = 1:numel(newFields)
                     fld = newFields{k};
                     if ~isfield(tempStore.(tableName), fld)
                          [tempStore.(tableName).(fld)] = deal([]); % Add missing field with default empty
                     end
                 end

                 % Reorder fields to match before concatenating
                 rows = orderfields(rows, tempStore.(tableName)(1)); % Match order of existing data

                tempStore.(tableName) = [tempStore.(tableName); rows(:)];
            else
                tempStore.(tableName) = rows(:);
            end

            BPMNDatabaseConnector.getSetTempStore(tempStore); % Save updated store

            fprintf('--- Temp insertRows finished for table: %s. Total rows: %d ---\n', tableName, numel(tempStore.(tableName)));
        end % End of insertRows

        function allData = fetchAll(tableNames)
             % fetchAll - Static method to fetch data from the temporary store
             % tableNames: Cell array of table names to fetch from
             % Returns: Struct where each field is a table name containing fetched data

             fprintf('--- Fetching data from temporary store for tables: %s ---\n', strjoin(tableNames, ', '));
             allData = struct();
             tempStore = BPMNDatabaseConnector.getSetTempStore(); % Get current store

             if ~iscell(tableNames)
                 tableNames = {tableNames}; % Ensure it's a cell array
             end

             for i = 1:numel(tableNames)
                 tableName = tableNames{i};
                 if isfield(tempStore, tableName)
                     allData.(tableName) = tempStore.(tableName);
                     fprintf('--- Fetched %d rows for table %s ---\n', numel(allData.(tableName)), tableName);
                 else
                     allData.(tableName) = struct([]); % Return empty struct array if table not found
                     fprintf('--- Table %s not found in temporary store ---\n', tableName);
                 end
             end
             fprintf('--- Temp fetchAll finished ---\n');
        end % End of fetchAll

    end % End of static methods block

end % End of classdef BPMNDatabaseConnector