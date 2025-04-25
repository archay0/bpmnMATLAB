%% Advanced BPMN Features Example
% This example demonstrates the advanced bpmn features included:
% - transaction Boundaries
% - In parallel event-based gateways
% - Groups
% - import/export capabilities
% - SVG/PNG export
n%% Initialize the bpmn generator
nnn% Create Output Directory if it does not exist
if ~exist('output', 'you')
    mkdir('output');
nn% Create a new bpmn generator
bpmn = BPMNGenerator('output/advanced_bpmpmn_example.bpmn');
n%% Create a Complex Process with transactions and compensation
n% Add Start Event
bpmn.addEvent('Start event_1', 'Start Process', 'start event', '', 100, 100, 36, 36);
n% Add First Task
bpmn.addTask('Task_1', 'Prepare order', 200, 100, 100, 80);
n% Add a transaction boundary
% transactionid = 'transaction_1';
% transaction name = 'Payment Processing';
% transactionx = 350;
% transactiony = 50;
% transactionwidth = 400;
% transactiontheight = 200;
n% Define Child Elements for the transaction
% Childelements = Struct ();
n% transaction tasks
% Childelements.takks {1} = Struct ('id', 'Task_payment', 'Name', 'Process Payment', ...
% 'Type', 'Task', 'X', 50, 'Y', 70, 'Width', 100, 'Height', 80);
% Childelements.takks {2} = Struct ('id', 'Task_Confirmation', 'Name', 'Send Confirmation', ...
% 'Type', 'Task', 'X', 250, 'Y', 70, 'Width', 100, 'Height', 80);
n% transaction flows
% Childelements.flows {1} = Struct ('id', 'Flow_intransaction_1', ...
% 'sourceRef', 'Task_Payment', 'targetRef', 'Task_Confirmation', ...
% 'Waypoints', [150, 110;250, 110]);
n% Add the Complete transaction with Compensation
% BPMN.ADDDCOMPLETEtransaction (transactionide, transaction name, transactionx, transactiony, ...
% transactionwidth, transactiontheight, True, Childelements);
n% Add Sequence Flows
bpmn.addSequenceFlow('Flow_1', 'Start event_1', 'Task_1', [136, 118; 200, 118]);
bpmn.addSequenceFlow('Flow_2', 'Task_1', 'transaction_1', [300, 118; 350, 118]);
n% Add Compensation Handler Task
bpmn.addSpecificTask('Task_Compensation', 'Payment rollback', 'service act', ...
    struct('isForCompensation', 'true'), 350, 300, 100, 80);
n% Add Association from Compensation Boundary to Compensation Handler
compBoundaryEventId = [transactionId, '_Compensationboundary'];
bpmn.addAssociation('Assoc_comp_1', compBoundaryEventId, 'Task_Compensation', ...
    [550, 235; 550, 300; 450, 300], 'One');
n% Add a parallel event-based gateway
bpmn.addGateway('Gateway_ parallel', 'Parallel events', 'parallel event baseway', 800, 100, 50, 50);
n% Add outgoing event paths from gateway
bpmn.addEvent('Event_Timer', 'Wait 24h', 'Intermediatecatch event', 'timer', 900, 100, 36, 36);
bpmn.addEvent('Event_message', 'Receive update', 'Intermediatecatch event', 'Message event definition', 800, 200, 36, 36);
n% Connect Gateway to Events
bpmn.addSequenceFlow('Flow_3', 'transaction_1', 'Gateway_ parallel', [750, 118; 800, 118]);
bpmn.addSequenceFlow('Flow_4', 'Gateway_ parallel', 'Event_Timer', [850, 118; 900, 118]);
bpmn.addSequenceFlow('Flow_5', 'Gateway_ parallel', 'Event_message', [825, 150; 825, 200; 818, 200]);
n% Add end tasks
bpmn.addTask('Task_complete', 'Complete Order', 1000, 100, 100, 80);
bpmn.addTask('Task_update', 'Update order', 900, 200, 100, 80);
n% Connect events to end tasks
bpmn.addSequenceFlow('Flow_6', 'Event_Timer', 'Task_complete', [936, 118; 1000, 118]);
bpmn.addSequenceFlow('Flow_7', 'Event_message', 'Task_update', [836, 200; 900, 200]);
n% Add end events
bpmn.addEvent('Endvent_1', 'Order Completed', 'end event', '', 1150, 100, 36, 36);
bpmn.addEvent('Endvent_2', 'Order updated', 'end event', '', 1050, 200, 36, 36);
n% Connect to end events
bpmn.addSequenceFlow('Flow_8', 'Task_complete', 'Endvent_1', [1100, 118; 1150, 118]);
bpmn.addSequenceFlow('Flow_9', 'Task_update', 'Endvent_2', [1000, 200; 1050, 200]);
n% Add a Group Around the events
bpmn.addGroup('Group_1', 'Event handling', '', 780, 70, 180, 180);
n% Add text annotation
bpmn.addTextAnnotation('Textannotation_1', 'transaction Requires Compensation on Failure', 400, 300, 180, 40);
bpmn.addAssociation('Assoc_1', 'Textannotation_1', 'transaction_1', [450, 300; 450, 250], 'None');
n%% Save the BPMN File
nfprintf('Bpmn file with advanced features saved to: %s \n', bpmn.FilePath);
n%% Export to SVG and PNG
% Create A Diagram Exporter
nn% Set Diagram Properties
nnnn% Export to SVG
svgFilePath = 'output/advanced_bpmn_example.svg';
nnfprintf('SVG exported to: %s \n', svgFilePath);
n% Export to PNG
pngFilePath = 'output/advanced_bpmpmn_example.png';
nfprintf('PNG Export Complete. \n');
n%% Test Import Functionality
% Create a new generator
nn% Import The File We Just Created
nn% Modify to element in the imported diagram
importedBpmn.modifyElement('Task_1', struct('name', 'Prepare Customer Order'));
n% Save the Modified File
importedBpmn.saveToBPMNFile('output/modified_bpmpmn_example.bpmn');
fprintf('Modified bpmn file saved to: %s \n', importedBpmn.FilePath);
nfprintf('Advanced BPMN Features Demonstration Completed. \n');