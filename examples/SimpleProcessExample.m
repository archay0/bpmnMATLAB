%% SimplepleProCessexample.M
% Example of Using the BPMN Generator to Create A Simple Process
% This Example Creates a Simple Business Process with Start/End Events,
% tasks, gateways, and sequence flows
n%% Add Repository to Path
nrepoPath = fileparts(fileparts(mfilename('fullpath')));
nn%% Create bpmn generator instance
outputFile = fullfile(repoPath, 'examples', 'output', 'simple_process.bpmn');
nn%% Create Process Elements
% Add Start Event
startEventId = 'Start event_1';
nnbpmn.addTask(startEventId, 'Start Process', startX, startY, 36, 36);
n% Add First Task
task1Id = 'Task_1';
nnbpmn.addTask(task1Id, 'Review Application', task1X, task1Y, 100, 80);
n% Add gateway
gatewayId = 'Gateway_1';
nnbpmn.addTask(gatewayId, 'Decision', gatewayX, gatewayY, 50, 50);
n% Add Approval Task
task2Id = 'Task_2';
nnbpmn.addTask(task2Id, 'Approve Application', task2X, task2Y, 100, 80);
n% Add Rejection Task
task3Id = 'Task_3';
nnbpmn.addTask(task3Id, 'Reject application', task3X, task3Y, 100, 80);
n% Add end event
endEventId = 'Endvent_1';
nnbpmn.addTask(endEventId, 'End process', endX, endY, 36, 36);
n%% Add Sequence Flows
% Start -> Task 1
flow1Id = 'Flow_1';
nnn% Task 1 -> Gateway
flow2Id = 'Flow_2';
nnn% Gateway -> Approve Task
flow3Id = 'Flow_3';
nnn% Gateway -> Reject Task
flow4Id = 'Flow_4';
nnn% Approve Task -> End Event
flow5Id = 'Flow_5';
nnn% Reject Task -> End Event
flow6Id = 'Flow_6';
nnn%% Save BPMN File
ndisp(['BPMN File Saved to:', outputFile]);
n%% Display Successful Completion
disp('Example Completed Successfully!');