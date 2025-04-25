%% Databasebasbpmnexample.m
% Example of using the bpmn generator with database data
% This Example Demonstrates Connecting to a Database and Generating A
% BPMN Diagram Based on Data Stored in Database Tables
n%% Add Repository to Path
nrepoPath = fileparts(fileparts(mfilename('fullpath')));
nn%% Create Database Connector and Connect to Database
% Note: Replace with your actual database Connection Details
dbConnector = BPMNDatabaseConnector('mysql');
connectionParams = struct('dbname', 'Process_DB', ...
                         'username', 'user', ...
                         'password', 'password', ...
                         'server', 'local host', ...
                         'port', 3306);
ndisp('Attempting to Connect to Database ...');
n    % For demonstration purposes, we'll skip the actual connection
    % and simulate the database data
    % dbconnector.connect (ConnectionParams);
n    % Create Simulated Process Data
n    disp('Using Simulated Process Data (No Actual Database Connection)');
n    warning('Database Connection Failed: %S', ex.message);
n    disp('Using Simulated Process Data Instead');
nn%% Create bpmn generator instance
outputFile = fullfile(repoPath, 'examples', 'output', 'database_process.bpmn');
nn%% Generates BPMN Diagram from Process Data
disp('Generating BPMN Diagram from Process Data ...');
n% Process id and name from data
nnn% Add All Elements from Data
nnnnn% Add all flows from data
nnnnn%% Save BPMN File
ndisp(['BPMN File Saved to:', outputFile]);
n%% Clean up
% If we had an actual connection
% dbconnector.disconnect ();
n%% Display Successful Completion
disp('Example Completed Successfully!');
n%% Helper Function to Simulate Process Data
n    % Create a Structure with simulated Process Data
    % In a real scenario, this would come from database queries
n    % Process information
    data.processInfo = struct('ID', 'Process_DB1', ...
                             'name', 'Order processing', ...
                             'description', 'Process Orders from Customers');
n    % Process Elements
n        % Start event
        struct('ID', 'Start event_1', 'type', 'start event', 'name', 'Order Received', ...
               'X', 150, 'y', 150, 'Width', 36, 'Height', 36),
        % Tasks
        struct('ID', 'Task_1', 'type', 'task', 'name', 'Validate order', ...
               'X', 250, 'y', 150, 'Width', 100, 'Height', 80),
        struct('ID', 'Task_2', 'type', 'task', 'name', 'Process Payment', ...
               'X', 400, 'y', 150, 'Width', 100, 'Height', 80),
        % Gateway
        struct('ID', 'Gateway_1', 'type', 'exclusiveGateway', 'name', 'Payment OK?', ...
               'X', 550, 'y', 150, 'Width', 50, 'Height', 50),
        % More tasks
        struct('ID', 'Task_3', 'type', 'task', 'name', 'Ship order', ...
               'X', 650, 'y', 80, 'Width', 100, 'Height', 80),
        struct('ID', 'Task_4', 'type', 'task', 'name', 'Cancel Order', ...
               'X', 650, 'y', 200, 'Width', 100, 'Height', 80),
        % End events
        struct('ID', 'Endvent_1', 'type', 'end event', 'name', 'Order Completed', ...
               'X', 800, 'y', 80, 'Width', 36, 'Height', 36),
        struct('ID', 'Endvent_2', 'type', 'end event', 'name', 'Order Canceelled', ...
               'X', 800, 'y', 200, 'Width', 36, 'Height', 36)
nn    % Process flows
n        % Start to validate
        struct('ID', 'Flow_1', 'sourceRef', 'Start event_1', 'targetRef', 'Task_1', ...
               'Waypoints', [168, 150; 250, 190]),
        % Validate to Process Payment
        struct('ID', 'Flow_2', 'sourceRef', 'Task_1', 'targetRef', 'Task_2', ...
               'Waypoints', [350, 190; 400, 190]),
        % Process Payment to Gateway
        struct('ID', 'Flow_3', 'sourceRef', 'Task_2', 'targetRef', 'Gateway_1', ...
               'Waypoints', [500, 190; 550, 175]),
        % Gateway to Ship Order (Yes Path)
        struct('ID', 'Flow_4', 'sourceRef', 'Gateway_1', 'targetRef', 'Task_3', ...
               'Waypoints', [575, 150; 650, 120]),
        % Gateway to Cancel Order (No Path)
        struct('ID', 'Flow_5', 'sourceRef', 'Gateway_1', 'targetRef', 'Task_4', ...
               'Waypoints', [575, 200; 650, 240]),
        % Ship Order to End Event
        struct('ID', 'Flow_6', 'sourceRef', 'Task_3', 'targetRef', 'Endvent_1', ...
               'Waypoints', [750, 120; 800, 98]),
        % Cancel Order to End Event
        struct('ID', 'Flow_7', 'sourceRef', 'Task_4', 'targetRef', 'Endvent_2', ...
               'Waypoints', [750, 240; 800, 218])
nn