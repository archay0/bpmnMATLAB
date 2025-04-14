%% Advanced BPMN Features Example
% This example demonstrates the advanced BPMN features including:
% - Transaction boundaries
% - Parallel Event-based Gateways
% - Groups
% - Import/Export capabilities
% - SVG/PNG Export

%% Initialize the BPMN Generator
clear;
close all;

% Create output directory if it doesn't exist
if ~exist('output', 'dir')
    mkdir('output');
end

% Create a new BPMN generator
bpmn = BPMNGenerator('output/advanced_bpmn_example.bpmn');

%% Create a complex process with transactions and compensation

% Add start event
bpmn.addEvent('StartEvent_1', 'Start Process', 'startEvent', '', 100, 100, 36, 36);

% Add first task
bpmn.addTask('Task_1', 'Prepare Order', 200, 100, 100, 80);

% Add a transaction boundary
transactionId = 'Transaction_1';
transactionName = 'Payment Processing';
transactionX = 350;
transactionY = 50;
transactionWidth = 400;
transactionHeight = 200;

% Define child elements for the transaction
childElements = struct();

% Transaction tasks
childElements.tasks{1} = struct('id', 'Task_Payment', 'name', 'Process Payment', ...
    'type', 'task', 'x', 50, 'y', 70, 'width', 100, 'height', 80);
childElements.tasks{2} = struct('id', 'Task_Confirmation', 'name', 'Send Confirmation', ...
    'type', 'task', 'x', 250, 'y', 70, 'width', 100, 'height', 80);

% Transaction flows
childElements.flows{1} = struct('id', 'Flow_InTransaction_1', ...
    'sourceRef', 'Task_Payment', 'targetRef', 'Task_Confirmation', ...
    'waypoints', [150, 110; 250, 110]);

% Add the complete transaction with compensation
bpmn.addCompleteTransaction(transactionId, transactionName, transactionX, transactionY, ...
    transactionWidth, transactionHeight, true, childElements);

% Add sequence flows
bpmn.addSequenceFlow('Flow_1', 'StartEvent_1', 'Task_1', [136, 118; 200, 118]);
bpmn.addSequenceFlow('Flow_2', 'Task_1', 'Transaction_1', [300, 118; 350, 118]);

% Add compensation handler task
bpmn.addSpecificTask('Task_Compensation', 'Payment Rollback', 'serviceTask', ...
    struct('isForCompensation', 'true'), 350, 300, 100, 80);

% Add association from compensation boundary to compensation handler
compBoundaryEventId = [transactionId, '_CompensationBoundary'];
bpmn.addAssociation('Assoc_Comp_1', compBoundaryEventId, 'Task_Compensation', ...
    [550, 235; 550, 300; 450, 300], 'One');

% Add a parallel event-based gateway
bpmn.addGateway('Gateway_Parallel', 'Parallel Events', 'parallelEventBasedGateway', 800, 100, 50, 50);

% Add outgoing event paths from gateway
bpmn.addEvent('Event_Timer', 'Wait 24h', 'intermediateCatchEvent', 'timerEventDefinition', 900, 100, 36, 36);
bpmn.addEvent('Event_Message', 'Receive Update', 'intermediateCatchEvent', 'messageEventDefinition', 800, 200, 36, 36);

% Connect gateway to events
bpmn.addSequenceFlow('Flow_3', 'Transaction_1', 'Gateway_Parallel', [750, 118; 800, 118]);
bpmn.addSequenceFlow('Flow_4', 'Gateway_Parallel', 'Event_Timer', [850, 118; 900, 118]);
bpmn.addSequenceFlow('Flow_5', 'Gateway_Parallel', 'Event_Message', [825, 150; 825, 200; 818, 200]);

% Add end tasks
bpmn.addTask('Task_Complete', 'Complete Order', 1000, 100, 100, 80);
bpmn.addTask('Task_Update', 'Update Order', 900, 200, 100, 80);

% Connect events to end tasks
bpmn.addSequenceFlow('Flow_6', 'Event_Timer', 'Task_Complete', [936, 118; 1000, 118]);
bpmn.addSequenceFlow('Flow_7', 'Event_Message', 'Task_Update', [836, 200; 900, 200]);

% Add end events
bpmn.addEvent('EndEvent_1', 'Order Completed', 'endEvent', '', 1150, 100, 36, 36);
bpmn.addEvent('EndEvent_2', 'Order Updated', 'endEvent', '', 1050, 200, 36, 36);

% Connect to end events
bpmn.addSequenceFlow('Flow_8', 'Task_Complete', 'EndEvent_1', [1100, 118; 1150, 118]);
bpmn.addSequenceFlow('Flow_9', 'Task_Update', 'EndEvent_2', [1000, 200; 1050, 200]);

% Add a group around the events
bpmn.addGroup('Group_1', 'Event Handling', '', 780, 70, 180, 180);

% Add text annotation
bpmn.addTextAnnotation('TextAnnotation_1', 'Transaction requires compensation on failure', 400, 300, 180, 40);
bpmn.addAssociation('Assoc_1', 'TextAnnotation_1', 'Transaction_1', [450, 300; 450, 250], 'None');

%% Save the BPMN file
bpmn.saveToBPMNFile();
fprintf('BPMN file with advanced features saved to: %s\n', bpmn.FilePath);

%% Export to SVG and PNG
% Create a diagram exporter 
exporter = BPMNDiagramExporter(bpmn.FilePath);

% Set diagram properties
exporter.Width = 1300;
exporter.Height = 600;
exporter.BackgroundColor = [1, 1, 1]; % White background

% Export to SVG
svgFilePath = 'output/advanced_bpmn_example.svg';
exporter.OutputFilePath = svgFilePath;
exporter.generateSVG();
fprintf('SVG exported to: %s\n', svgFilePath);

% Export to PNG
pngFilePath = 'output/advanced_bpmn_example.png';
exporter.exportToPNG(pngFilePath);
fprintf('PNG export complete.\n');

%% Test Import functionality
% Create a new generator
importedBpmn = BPMNGenerator();

% Import the file we just created
importedBpmn.importFromFile(bpmn.FilePath);

% Modify an element in the imported diagram
importedBpmn.modifyElement('Task_1', struct('name', 'Prepare Customer Order'));

% Save the modified file
importedBpmn.saveToBPMNFile('output/modified_bpmn_example.bpmn');
fprintf('Modified BPMN file saved to: %s\n', importedBpmn.FilePath);

fprintf('Advanced BPMN features demonstration completed.\n');