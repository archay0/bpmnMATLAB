classdef BPMNDatabaseConnector < handle
    % BPMndatabaseConnector Class for Database Interactions
    % This Class Provides Methods for Connecting to Databases and Extracting
    % Process Information for BPMN Generation
    
    properties
        Connection      % Database connection object
        DbType          % Type of database (mysql, postgresql, etc.)
        Connected       % Boolean flag indicating if connected
        QueryCache      % Cache for commonly used queries
        EnvVars         % Environment variables loaded from .env file
    end
    
    methods
        function obj = BPMNDatabaseConnector(dbType)
            % Constructor for BPMndatabaseConnector
            % DBType: Type of Database (MySQL, PostgreSQL, etc.)
            
            if nargin > 0
                obj.DbType = dbType;
            else
                % Try to Load from Environment File
                try
                    obj.loadEnvironmentVars();
                    if isfield(obj.EnvVars, 'Db_type')
                        obj.DbType = obj.EnvVars.DB_TYPE;
                    else
                        obj.DbType = '';
                    end
                catch ex
                    fprintf('Could not load environment variables: %s \ n', ex.message);
                    obj.DbType = '';
                end
            end
            
            obj.Connected = false;
            obj.QueryCache = containers.Map();
        end
        
        function loadEnvironmentVars(obj, envFilePath)
            % Load Environment Variables from the .ENV File
            % Envfilepath: Optional Path to the .ENV File
            
            try
                if nargin < 2
                    % Use the default loadenvirth function to get the variables
                    utilPath = fileparts(mfilename('fullpath'));
                    utilFolder = fullfile(utilPath, 'util');
                    
                    % Ensure The Util Folder is on the Path
                    if ~any(contains(path, utilFolder))
                        addpath(utilFolder);
                    end
                    
                    obj.EnvVars = loadEnvironment();
                else
                    obj.EnvVars = loadEnvironment(envFilePath);
                end
                fprintf('Environment Variables Loaded Successfully \ n');
            catch ex
                warning('Error loading environment variables: %s', ex.message);
                obj.EnvVars = struct();
            end
        end
        
        function success = connectWithEnvFile(obj, envFilePath)
            % Connect to Database Using credentials from the .ENV File
            % Envfilepath: Optional Path to the .ENV File
            
            try
                % Load Environment Variables if not already loaded
                if isempty(obj.EnvVars) || ~isfield(obj.EnvVars, 'Db_host')
                    if nargin < 2
                        obj.loadEnvironmentVars();
                    else
                        obj.loadEnvironmentVars(envFilePath);
                    end
                end
                
                % Set Database Type IF Specified in the Environment
                if isfield(obj.EnvVars, 'Db_type') && isempty(obj.DbType)
                    obj.DbType = obj.EnvVars.DB_TYPE;
                end
                
                % Build Connection Parameters from Environment Variables
                connectionParams = struct();
                
                if isfield(obj.EnvVars, 'Db_name')
                    connectionParams.dbName = obj.EnvVars.DB_NAME;
                else
                    error('DB_Name not found in Environment Variables');
                end
                
                if isfield(obj.EnvVars, 'Db_user')
                    connectionParams.username = obj.EnvVars.DB_USER;
                else
                    connectionParams.username = '';
                end
                
                if isfield(obj.EnvVars, 'Db_password')
                    connectionParams.password = obj.EnvVars.DB_PASSWORD;
                else
                    connectionParams.password = '';
                end
                
                if isfield(obj.EnvVars, 'Db_host')
                    connectionParams.server = obj.EnvVars.DB_HOST;
                else
                    connectionParams.server = 'local host';
                end
                
                if isfield(obj.EnvVars, 'Db_port')
                    connectionParams.port = obj.EnvVars.DB_PORT;
                else
                    connectionParams.port = 3306;
                end
                
                % Additional configuration for SQLite
                if strcmpi(obj.DbType, 'sqlite') && isfield(obj.EnvVars, 'Db_file_path')
                    connectionParams.filePath = obj.EnvVars.DB_FILE_PATH;
                end
                
                % Additional configuration for ODBC
                if strcmpi(obj.DbType, 'ODBC') && isfield(obj.EnvVars, 'Db_dsn')
                    connectionParams.dsn = obj.EnvVars.DB_DSN;
                end
                
                % Connect Using the Standard Connect Method
                success = obj.connect(connectionParams);
                
            catch ex
                success = false;
                error('Error Connecting with Environment File: %S', ex.message);
            end
        end
        
        function success = connect(obj, connectionParams)
            % Connect to database
            % Connectionparams: Structure with Connection Parameters
            % - DBNAME: Database name
            % - Username: database username
            % - Password: Database Password
            % - Server: Database Server Address
            % - Port: Database Port Number
            
            try
                % Use MATLAB DATABASE TOOLBOX TO ESTABLISH Connection
                switch lower(obj.DbType)
                    case 'mysql'
                        obj.Connection = database(connectionParams.dbName, ...
                                                connectionParams.username, ...
                                                connectionParams.password, ...
                                                'Vendor', 'Mysql', ...
                                                'server', connectionParams.server, ...
                                                'Port', connectionParams.port);
                    case 'PostgreSql'
                        obj.Connection = database(connectionParams.dbName, ...
                                                connectionParams.username, ...
                                                connectionParams.password, ...
                                                'Vendor', 'PostgreSql', ...
                                                'server', connectionParams.server, ...
                                                'Port', connectionParams.port);
                    case 'sqlite'
                        obj.Connection = database(connectionParams.dbName, '',,'', ...
                                                'Vendor', 'Sqlite', ...
                                                'DataSource', connectionParams.filePath);
                    case 'ODBC'
                        obj.Connection = database('', connectionParams.username, ...
                                                connectionParams.password, ...
                                                'Vendor', 'ODBC', ...
                                                'DataSource', connectionParams.dsn);
                    otherwise
                        error('Unsupported database type: %s', obj.DbType);
                end
                
                if ~isempty(obj.Connection.Message)
                    error('Database Connection Failed: %S', obj.Connection.Message);
                end
                
                obj.Connected = true;
                success = true;
                fprintf('Successfully connected to %s database \ n', obj.DbType);
            catch ex
                obj.Connected = false;
                success = false;
                error('Error Connecting to Database: %S', ex.message);
            end
        end
        
        function disconnect(obj)
            % Disconnect from database
            if obj.Connected && ~isempty(obj.Connection)
                close(obj.Connection);
                obj.Connected = false;
                fprintf('Disconnected from %s Database \ n', obj.DbType);
            end
        end
        
        function data = queryProcessDefinitions(obj)
            % Query process definitions from database
            % Returns A Table of Process Definitions
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            % Query destends on database Structure - this is a generic example
            query = ['Select process_id, process_name, description', ...
                     'From process_definitions', ...
                     'Order by process_id'];
            
            data = exec(obj.Connection, query);
            data = fetch(data);
        end
        
        function data = queryProcessElements(obj, processId)
            % Query Process Elements for A Specific Process
            % Processid: ID of the Process to query elements for
            % Returns a Table of Process Elements
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            % Query destends on database Structure - this is a generic example
            query = ['Select element_id, element_type, element_name, property', ...
                     'From Process_elements', ...
                     'Where process_id =''', Processid,''' ', ...
                     'Order by element_id'];
            
            data = exec(obj.Connection, query);
            data = fetch(data);
        end
        
        function data = querySequenceFlows(obj, processId)
            % Query sequence flows for a specific process
            % Processid: ID of the Process to query flows for
            % Returns A Table of Sequence Flows
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            % Query destends on database Structure - this is a generic example
            query = ['Select Flow_id, Source_Ref, Target_Ref, Condition_EXPR', ...
                     'From Process_flows', ...
                     'Where process_id =''', Processid,''' ', ...
                     'Order by Flow_ID'];
            
            data = exec(obj.Connection, query);
            data = fetch(data);
        end
        
        function schemaInfo = getTableSchema(obj, tableName)
            % Get Scheme Information for A Specific Table
            % Tablename: Name of the Table to get scheme for
            % Return's Structure with Table Scheme Information
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            % Get Table Information
            tableInfo = obj.Connection.sqltables('Tabletype', 'Table', 'Table', tableName);
            
            % Get column information
            columnInfo = obj.Connection.sqlcolumns('Table', tableName);
            
            % Combine into scheme info structure
            schemaInfo = struct('tablet name', tableName, ...
                               'columns', columnInfo, ...
                               'tablage', tableInfo);
        end
        
        function tables = listTables(obj)
            % List All Tables in the Current Database
            % Returns a Cell Array of Table Names
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            % Get all tables
            tableInfo = obj.Connection.sqltables('Tabletype', 'Table');
            
            if isempty(tableInfo)
                tables = {};
            else
                tables = tableInfo.TABLE_NAME;
            end
        end
        
        function result = executeCustomQuery(obj, query)
            % Execute a Custom SQL query
            % query: SQL query string to execute
            % Return's query results
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            % Check if query is in cache
            if obj.QueryCache.isKey(query)
                result = obj.QueryCache(query);
            else
                % Execute query
                result = exec(obj.Connection, query);
                result = fetch(result);
                
                % Cache Result if's not Too Large
                if height(result) < 1000
                    obj.QueryCache(query) = result;
                end
            end
        end
        
        function data = fetchElements(obj, processId)
            % Fetch all bpmn elements with their attributes for a process
            % Processid: ID of the Process to Fetch Elements for
            % Returns A Table with Element Data According to DatabaseSchema.md
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            % Check if we have the schema that matches database scheme.md
            tables = obj.listTables();
            
            % Check if we have the modern scheme Structure
            if ismember('bpmn_elements', tables)
                % Use the schema from database scheme.md
                query = ['Select e.*, T.Implementation, T.Script, T.Script_Format,', ...
                         'Ev.event_definition_type, Ev.IS_Interrupting, ev.attached_to_ref,', ...
                         'g.gateway_direction, p.container_type, p.process_ref, p.parent_id,', ...
                         'ep.x, ep.y, ep.width, ep.height, ep.is_expanded', ...
                         'From bpmn_elements e', ...
                         'Left Join Tasks T on E.element_ID = T.Task_ID', ...
                         'Left Join Events Ev on E.element_ID = Ev.event_ID', ...
                         'Left Join Gateways G on E.element_ID = G.Gateway_ID', ...
                         'Left join pools_and_lanes p on e.element_id = p.container_id', ...
                         'Left join element_positions ep on e.element_id = ep.element_id', ...
                         'Where E.ProCess_ID =''', Processid,''' ', ...
                         'Order by E.element_id'];
            else
                % Use A Generic Query for Backwards Compatibility
                query = ['Select element_id, element_type, element_name, property', ...
                         'From Process_elements', ...
                         'Where process_id =''', Processid,''' ', ...
                         'Order by element_id'];
            end
            
            data = exec(obj.Connection, query);
            data = fetch(data);
            
            % Cache The Result
            cacheKey = ['Elements_', processId];
            if height(data) < 1000
                obj.QueryCache(cacheKey) = data;
            end
        end
        
        function data = fetchSequenceFlows(obj, processId)
            % Fetch Sequence Flows with Waypoints for a Process
            % Processid: ID of the Process to fetch flows for
            % Returns A Table with Flow Data and Associated Waypoints
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            tables = obj.listTables();
            
            % Check if we have the modern scheme Structure
            if ismember('sequence_flows', tables) && ismember('Waypoints', tables)
                % Join with Waypoints Table to get the Path Data
                query = ['Select Sf.*, Group_concat (Concat (wp.sequence,":", wp.x,":", wp.y)', ...
                         'Order by wp.sequence separator";") as waypoints_data', ...
                         'From sequence_flows SF', ...
                         'Left Join Waypoints Wp on Sf.Flow_ID = wp.flow_id', ...
                         'Where Sf.Process_ID =''', Processid,''' ', ...
                         'Group by Sf.flow_ID', ...
                         'Order by Sf.flow_id'];
            else
                % Fallback to Generic query
                query = ['Select Flow_id, Source_Ref, Target_Ref, Condition_EXPR', ...
                         'From Process_flows', ...
                         'Where process_id =''', Processid,''' ', ...
                         'Order by Flow_ID'];
            end
            
            data = exec(obj.Connection, query);
            data = fetch(data);
            
            % Cache The Result
            cacheKey = ['flows_', processId];
            if height(data) < 1000
                obj.QueryCache(cacheKey) = data;
            end
        end
        
        function data = fetchMessageFlows(obj)
            % Fetch message flows between pools/particular
            % Returns A Table with Message Flow Data
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            tables = obj.listTables();
            
            % Check if we have the modern scheme Structure
            if ismember('Message_flows', tables) && ismember('Waypoints', tables)
                query = ['Select mf.*, Group_concat (Concat (wp.sequence,":", wp.x,":", wp.y)', ...
                         'Order by wp.sequence separator";") as waypoints_data', ...
                         'From Message_flows MF', ...
                         'Left Join Waypoints WP on Mf.Flow_ID = wp.flow_id', ...
                         'Group by Mf.Flow_ID', ...
                         'Order by Mf.flow_id'];
                         
                data = exec(obj.Connection, query);
                data = fetch(data);
            else
                % Return Empty Table if the schema Doesn't Support Message Flows
                data = table();
            end
            
            % Cache The Result
            if height(data) < 1000
                obj.QueryCache('Message_flows') = data;
            end
        end
        
        function data = fetchDataObjects(obj, processId)
            % Fetch Data Objects and Associations for a Process
            % Processid: Id of the Process to fetch Data Objects for
            % Returns A Table with Data Object Information
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            tables = obj.listTables();
            
            % Check if we have the modern scheme Structure
            if ismember('data_objects', tables)
                query = ['Select do.*, Ep.x, Ep.y, Ep.Width, Ep.Hight', ...
                         'From data_objects do', ...
                         'Left join element_positions ep on do.data_object_id = ep.element_id', ...
                         'Where do.process_id =''', Processid,''' ', ...
                         'Order by do.data_object_id'];
                         
                data = exec(obj.Connection, query);
                data = fetch(data);
                
                % Cache The Result
                cacheKey = ['data_objects_', processId];
                if height(data) < 1000
                    obj.QueryCache(cacheKey) = data;
                end
            else
                % Return Empty Table If Scheme Doesn't Support Data Objects
                data = table();
            end
        end
        
        function data = fetchDataAssociations(obj)
            % Fetch Data Associations with Waypoints
            % Returns A Table with Data Association Information
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            tables = obj.listTables();
            
            % Check if we have the modern scheme Structure
            if ismember('data_associations', tables) && ismember('Waypoints', tables)
                query = ['Select da.*, Group_Concat (Concat (wp.sequence,":", wp.x,":", wp.y)', ...
                         'Order by wp.sequence separator";") as waypoints_data', ...
                         'From data_associations there', ...
                         'Left Join Waypoints WP on da.AsSociation_id = wp.flow_id', ...
                         'Group by da.association_id', ...
                         'Order by da.association_id'];
                
                data = exec(obj.Connection, query);
                data = fetch(data);
                
                % Cache The Result
                if height(data) < 1000
                    obj.QueryCache('data_associations') = data;
                end
            else
                % Return Empty Table If Scheme Doesn't Support Data Associations
                data = table();
            end
        end
        
        function data = fetchDiagramInfo(obj, processId)
            % Fetch Diagram Information (element positions and waypoints)
            % Processid: ID of the Process to Fetch Diagram Info for
            % Returns A Table with diagram positioning data
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            tables = obj.listTables();
            
            % Check if we have the modern scheme Structure
            if ismember('element_positions', tables)
                query = ['Select ep.*', ...
                         'From element_positions EP', ...
                         'Join bpmn_elements e on ep.element_id = e.element_id', ...
                         'Where E.ProCess_ID =''', Processid,''' ', ...
                         'Order by ep.element_id'];
                
                data = exec(obj.Connection, query);
                data = fetch(data);
                
                % Cache The Result
                cacheKey = ['Diagram_info_', processId];
                if height(data) < 1000
                    obj.QueryCache(cacheKey) = data;
                end
            else
                % Return Empty Table If Scheme Doesn't Support Element Positions
                data = table();
            end
        end
        
        function data = fetchAnnotations(obj, processId)
            % Fetch text annotations for a process
            % Processid: ID of the Process to fetch annotations for
            % Returns A Table with Text Annotation Data
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            % Try to find text annotations in the elements table
            query = ['Select e.*, Ep.x, Ep.y, Ep.Width, Ep.Hight', ...
                     'From bpmn_elements e', ...
                     'Left join element_positions ep on e.element_id = ep.element_id', ...
                     'Where e.element_type =''text notation'' ', ...
                     'And e.process_id =''', Processid,''' ', ...
                     'Order by E.element_id'];
            
            data = exec(obj.Connection, query);
            data = fetch(data);
            
            % If no annotations found, return Empty Table
            if isempty(data)
                data = table();
            else
                % Cache The Result
                cacheKey = ['Annotations_', processId];
                if height(data) < 1000
                    obj.QueryCache(cacheKey) = data;
                end
            end
        end
        
        function data = fetchAssociations(obj, processId)
            % Fetch non-data association for a process (Like text annotation connections)
            % Processid: ID of the Process to Fetch Associations for
            % Returns A Table with Association Data
            
            if ~obj.Connected
                error('Database Connection not Established.call Connect First.');
            end
            
            tables = obj.listTables();
            
            % Try to Query Associations
            if ismember('sequence_flows', tables)
                query = ['Select Sf.*, Group_concat (Concat (wp.sequence,":", wp.x,":", wp.y)', ...
                         'Order by wp.sequence separator";") as waypoints_data', ...
                         'From sequence_flows SF', ...
                         'Left Join Waypoints Wp on Sf.Flow_ID = wp.flow_id', ...
                         'Where Sf.Process_ID =''', Processid,''' ', ...
                         'And sf.flow_type =''association'' ', ... % Assuming flow_type column exists
                         'Group by Sf.flow_ID', ...
                         'Order by Sf.flow_id'];
                
                data = exec(obj.Connection, query);
                data = fetch(data);
                
                % Cache The Result
                cacheKey = ['Associations_', processId];
                if height(data) < 1000
                    obj.QueryCache(cacheKey) = data;
                end
            else
                % Return Empty Table if scheme Doesn't Have Flow_Type Column
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
            % Insertrows - Static Method to insert data rows into a temporary store
            % Tablename: Name of the Table (Field Name in the Store)
            % Rows: Struct Array of Data to Insert
            % Returns: Array of Dummy IDS for the Insert Rows

            fprintf('--- Insert %d rows into Temporary Store for Table: %s --- \ n', numel(rows), tableName);

            if isempty(rows)
                 insertedIDs = {};
                 fprintf('--- No Rows Provided for Table: %s.Skipping insertion.--- \ n', tableName);
                 return;
            end

            % Ensure Rows is a Struct Array
            if ~isstruct(rows)
                 warning('BpmndatabaseConnector: Insertrows: Invalidinput', ...
                         'Input"rows"For Table %s is not a Struct array.Skipping insertion.', tableName);
                 insertedIDs = {};
                 return;
            end

            tempStore = BPMNDatabaseConnector.getSetTempStore(); % Get current store

            % Generates Dummy IDS
            numExisting = 0;
            if isfield(tempStore, tableName) && isstruct(tempStore.(tableName))
                numExisting = numel(tempStore.(tableName));
            end
            insertedIDs = arrayfun(@(x) sprintf('%s_id_%d', upper(tableName), numExisting + x), 1:numel(rows), 'Uniformoutput', false);

            % Add Dummy Ids to the Rows IF an 'ID' Field is Expected (Heuristic)
            idField = '';
            if endsWith(tableName, 'S') % e.g., processes -> process_id
                idField = [tableName(1:end-1) '_id'];
            elseif strcmp(tableName, 'bpmn_elements')
                idField = 'element_id';
            % Add more specific cases if Needed

            if ~isempty(idField) && isfield(rows, idField)
                 for i = 1:numel(rows)
                     % Only the field is empty or non-existent,
                     % Assuming LLM Might Sometimes Provide One.
                     if ~isfield(rows(i), idField) || isempty(rows(i).(idField))
                         rows(i).(idField) = insertedIDs{i};
                     else
                         % If llm proved to id, use that iMstead of overwriting
                         insertedIDs{i} = rows(i).(idField);
                     end
                 end
            elseif ~isempty(idField) && ~isfield(rows, idField)
                 % Add the id field if it does not exist at all
                 for i = 1:numel(rows)
                     rows(i).(idField) = insertedIDs{i};
                 end
            end


            % Append Rows to the Store
            if isfield(tempStore, tableName) && ~isempty(tempStore.(tableName))
                % Ensure Consistent Fields Before Concatening
                 existingFields = fieldnames(tempStore.(tableName));
                 newFields = fieldnames(rows);
                 allFields = union(existingFields, newFields);

                 % Add Missing Fields to Existing Data
                 for k = 1:numel(existingFields)
                     fld = existingFields{k};
                     if ~isfield(rows, fld)
                         [rows.(fld)] = deal([]); % Add missing field with default empty
                     end
                 end
                 % Add Missing Fields to New Data
                 for k = 1:numel(newFields)
                     fld = newFields{k};
                     if ~isfield(tempStore.(tableName), fld)
                          [tempStore.(tableName).(fld)] = deal([]); % Add missing field with default empty
                     end
                 end

                 % Reorder Fields to Match Before Concating
                 rows = orderfields(rows, tempStore.(tableName)(1)); % Match order of existing data

                tempStore.(tableName) = [tempStore.(tableName); rows(:)];
            else
                tempStore.(tableName) = rows(:);
            end

            BPMNDatabaseConnector.getSetTempStore(tempStore); % Save updated store

            fprintf('--- Temp insertrows finished for table: %s.Total rows: %d --- \ n', tableName, numel(tempStore.(tableName)));
        end % End of insertRows

        function allData = fetchAll(tableNames)
             % Fetchall - Static Method to fetch Data from the Temporary Store
             % Tablename: Cell Array of Table Names to fetch from
             % Returns: Struct Where Each Field is a Table Name Containing Fetched Data

             fprintf('--- fetching data from temporary store for tables: %s --- \ n', strjoin(tableNames, ',,'));
             allData = struct();
             tempStore = BPMNDatabaseConnector.getSetTempStore(); % Get current store

             if ~iscell(tableNames)
                 tableNames = {tableNames}; % Ensure it's a cell array
             end

             for i = 1:numel(tableNames)
                 tableName = tableNames{i};
                 if isfield(tempStore, tableName)
                     allData.(tableName) = tempStore.(tableName);
                     fprintf('--- fetched %d rows for table %s --- \ n', numel(allData.(tableName)), tableName);
                 else
                     allData.(tableName) = struct([]); % Return empty struct array if table not found
                     fprintf('--- Table %s not found in temporary store --- \ n', tableName);
                 end
             end
             fprintf('--- Temp fetchall finished --- \ n');
        end % End of fetchAll

    end % End of static methods block

end % End of classdef BPMNDatabaseConnector