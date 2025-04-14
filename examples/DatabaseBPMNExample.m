%% DatabaseBPMNExample.m
% Example of using the BPMN Generator with database data
% This example demonstrates connecting to a database and generating a 
% BPMN diagram based on data stored in database tables

%% Add repository to path
currentDir = pwd;
repoPath = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(repoPath));

%% Create database connector and connect to database
% Note: Replace with your actual database connection details
dbConnector = BPMNDatabaseConnector('mysql');
connectionParams = struct('dbName', 'process_db', ...
                         'username', 'user', ...
                         'password', 'password', ...
                         'server', 'localhost', ...
                         'port', 3306);
                     
disp('Attempting to connect to database...');
try
    % For demonstration purposes, we'll skip the actual connection
    % and simulate the database data
    % dbConnector.connect(connectionParams);
    
    % Create simulated process data
    processData = simulateProcessData();
    disp('Using simulated process data (no actual database connection)');
catch ex
    warning('Database connection failed: %s', ex.message);
    processData = simulateProcessData();
    disp('Using simulated process data instead');
end

%% Create BPMN Generator instance
outputFile = fullfile(repoPath, 'examples', 'output', 'database_process.bpmn');
bpmn = BPMNGenerator(outputFile);

%% Generate BPMN diagram from process data
disp('Generating BPMN diagram from process data...');

% Process ID and name from data
processId = processData.processInfo.id;
processName = processData.processInfo.name;

% Add all elements from data
for i = 1:length(processData.elements)
    element = processData.elements{i};
    bpmn.addTask(element.id, element.name, element.x, element.y, element.width, element.height);
end

% Add all flows from data
for i = 1:length(processData.flows)
    flow = processData.flows{i};
    bpmn.addSequenceFlow(flow.id, flow.sourceRef, flow.targetRef, flow.waypoints);
end

%% Save BPMN file
bpmn.saveToBPMNFile();
disp(['BPMN file saved to: ', outputFile]);

%% Clean up
% If we had an actual connection
% dbConnector.disconnect();

%% Display successful completion
disp('Example completed successfully!');

%% Helper function to simulate process data
function data = simulateProcessData()
    % Create a structure with simulated process data
    % In a real scenario, this would come from database queries
    
    % Process information
    data.processInfo = struct('id', 'Process_DB1', ...
                             'name', 'Order Processing', ...
                             'description', 'Process orders from customers');
                         
    % Process elements
    data.elements = {
        % Start event
        struct('id', 'StartEvent_1', 'type', 'startEvent', 'name', 'Order Received', ...
               'x', 150, 'y', 150, 'width', 36, 'height', 36),
        % Tasks
        struct('id', 'Task_1', 'type', 'task', 'name', 'Validate Order', ...
               'x', 250, 'y', 150, 'width', 100, 'height', 80),
        struct('id', 'Task_2', 'type', 'task', 'name', 'Process Payment', ...
               'x', 400, 'y', 150, 'width', 100, 'height', 80),
        % Gateway
        struct('id', 'Gateway_1', 'type', 'exclusiveGateway', 'name', 'Payment OK?', ...
               'x', 550, 'y', 150, 'width', 50, 'height', 50),
        % More tasks
        struct('id', 'Task_3', 'type', 'task', 'name', 'Ship Order', ...
               'x', 650, 'y', 80, 'width', 100, 'height', 80),
        struct('id', 'Task_4', 'type', 'task', 'name', 'Cancel Order', ...
               'x', 650, 'y', 200, 'width', 100, 'height', 80),
        % End events
        struct('id', 'EndEvent_1', 'type', 'endEvent', 'name', 'Order Completed', ...
               'x', 800, 'y', 80, 'width', 36, 'height', 36),
        struct('id', 'EndEvent_2', 'type', 'endEvent', 'name', 'Order Cancelled', ...
               'x', 800, 'y', 200, 'width', 36, 'height', 36)
    };
    
    % Process flows
    data.flows = {
        % Start to Validate
        struct('id', 'Flow_1', 'sourceRef', 'StartEvent_1', 'targetRef', 'Task_1', ...
               'waypoints', [168, 150; 250, 190]),
        % Validate to Process Payment
        struct('id', 'Flow_2', 'sourceRef', 'Task_1', 'targetRef', 'Task_2', ...
               'waypoints', [350, 190; 400, 190]),
        % Process Payment to Gateway
        struct('id', 'Flow_3', 'sourceRef', 'Task_2', 'targetRef', 'Gateway_1', ...
               'waypoints', [500, 190; 550, 175]),
        % Gateway to Ship Order (yes path)
        struct('id', 'Flow_4', 'sourceRef', 'Gateway_1', 'targetRef', 'Task_3', ...
               'waypoints', [575, 150; 650, 120]),
        % Gateway to Cancel Order (no path)
        struct('id', 'Flow_5', 'sourceRef', 'Gateway_1', 'targetRef', 'Task_4', ...
               'waypoints', [575, 200; 650, 240]),
        % Ship Order to End Event
        struct('id', 'Flow_6', 'sourceRef', 'Task_3', 'targetRef', 'EndEvent_1', ...
               'waypoints', [750, 120; 800, 98]),
        % Cancel Order to End Event
        struct('id', 'Flow_7', 'sourceRef', 'Task_4', 'targetRef', 'EndEvent_2', ...
               'waypoints', [750, 240; 800, 218])
    };
end