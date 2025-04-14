%% SimpleProcessExample.m
% Example of using the BPMN Generator to create a simple process
% This example creates a simple business process with start/end events,
% tasks, gateways, and sequence flows

%% Add repository to path
currentDir = pwd;
repoPath = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(repoPath));

%% Create BPMN Generator instance
outputFile = fullfile(repoPath, 'examples', 'output', 'simple_process.bpmn');
bpmn = BPMNGenerator(outputFile);

%% Create process elements
% Add start event
startEventId = 'StartEvent_1';
startX = 150;
startY = 150;
bpmn.addTask(startEventId, 'Start Process', startX, startY, 36, 36);

% Add first task
task1Id = 'Task_1';
task1X = 250;
task1Y = 150;
bpmn.addTask(task1Id, 'Review Application', task1X, task1Y, 100, 80);

% Add gateway
gatewayId = 'Gateway_1';
gatewayX = 400;
gatewayY = 150;
bpmn.addTask(gatewayId, 'Decision', gatewayX, gatewayY, 50, 50);

% Add approval task
task2Id = 'Task_2';
task2X = 500;
task2Y = 80;
bpmn.addTask(task2Id, 'Approve Application', task2X, task2Y, 100, 80);

% Add rejection task
task3Id = 'Task_3';
task3X = 500;
task3Y = 200;
bpmn.addTask(task3Id, 'Reject Application', task3X, task3Y, 100, 80);

% Add end event
endEventId = 'EndEvent_1';
endX = 650;
endY = 150;
bpmn.addTask(endEventId, 'End Process', endX, endY, 36, 36);

%% Add sequence flows
% Start -> Task 1
flow1Id = 'Flow_1';
flow1Points = [startX+18, startY; task1X, task1Y+40];
bpmn.addSequenceFlow(flow1Id, startEventId, task1Id, flow1Points);

% Task 1 -> Gateway
flow2Id = 'Flow_2';
flow2Points = [task1X+100, task1Y+40; gatewayX, gatewayY+25];
bpmn.addSequenceFlow(flow2Id, task1Id, gatewayId, flow2Points);

% Gateway -> Approve Task
flow3Id = 'Flow_3';
flow3Points = [gatewayX+25, gatewayY; task2X, task2Y+40];
bpmn.addSequenceFlow(flow3Id, gatewayId, task2Id, flow3Points);

% Gateway -> Reject Task
flow4Id = 'Flow_4';
flow4Points = [gatewayX+25, gatewayY+50; task3X, task3Y+40];
bpmn.addSequenceFlow(flow4Id, gatewayId, task3Id, flow4Points);

% Approve Task -> End Event
flow5Id = 'Flow_5';
flow5Points = [task2X+100, task2Y+40; endX, endY+18];
bpmn.addSequenceFlow(flow5Id, task2Id, endEventId, flow5Points);

% Reject Task -> End Event
flow6Id = 'Flow_6';
flow6Points = [task3X+100, task3Y+40; endX, endY+18];
bpmn.addSequenceFlow(flow6Id, task3Id, endEventId, flow6Points);

%% Save BPMN file
bpmn.saveToBPMNFile();
disp(['BPMN file saved to: ', outputFile]);

%% Display successful completion
disp('Example completed successfully!');