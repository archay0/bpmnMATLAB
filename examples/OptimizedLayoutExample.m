% Optimizedlayoutexample.M
% Demonstrates the Advanced Layout Optimization Features for BPMN Diagrams
%

% This example creates a complex bpmn process with multiple Paths,
% Subprocesses and gateways, then Applies the Layout Optimization to Improve
% Diagram Readability.

% Add SRC Directory to Path
addpath('../src');

% Initialize BPMN generator
bpmnGen = BPMNGenerator();

% Define the Process (Placeholder - Method Might Not Exist)
% fprintf ('Defing Process ... \ n');
% try
% bpmngen.Createdefinitions ('Optimized LayoutProcess', 'Urn: Sample: Optimizedlayout: 1.0');
% Catch me
% Warning ('Could not Create Definitions (Method Might Be Missing): %S', Me.Message);
% end

% Create a Business Process with Multiple Paths
bpmnGen.createProcess('Process1', 'Optimized Layout Process');

% CREATE START Event
startId = bpmnGen.createStartEvent('start', 'Start Process');
bpmnGen.setElementPosition(startId, 100, 200, 36, 36);

% Create Initial Task
task1Id = bpmnGen.createTask('task1', 'Analyze Request');
bpmnGen.setElementPosition(task1Id, 200, 180, 100, 80);

% Create parallel gateway
gatewayId = bpmnGen.createParallelGateway('Gateway1', 'Split flow');
bpmnGen.setElementPosition(gatewayId, 350, 200, 50, 50);

% Create multiple tasks after the gateway (Deliberately positioned to createl overlap)
task2Id = bpmnGen.createTask('task2', 'Process Documents');
bpmnGen.setElementPosition(task2Id, 450, 100, 100, 80);

task3Id = bpmnGen.createTask('task3', 'Verify information');
bpmnGen.setElementPosition(task3Id, 450, 200, 100, 80);

task4Id = bpmnGen.createTask('task4', 'Check compliance');
bpmnGen.setElementPosition(task4Id, 450, 300, 100, 80);

% Create converging gateway
gateway2Id = bpmnGen.createParallelGateway('gateway2', 'Merge flow');
bpmnGen.setElementPosition(gateway2Id, 600, 200, 50, 50);

% Create Final Task
task5Id = bpmnGen.createTask('task5', 'Complete processing');
bpmnGen.setElementPosition(task5Id, 700, 180, 100, 80);

% Create End event
endId = bpmnGen.createEndEvent('end', 'End process');
bpmnGen.setElementPosition(endId, 850, 200, 36, 36);

% CREATE SUBPROCESS with internal activities (Deliberately Misaligned)
subProcessId = bpmnGen.createSubProcess('subprocess1', 'Document Processing');
bpmnGen.setElementPosition(subProcessId, 450, 400, 250, 150);

% Add Elements to the subprocess
subStart = bpmnGen.createStartEvent('substrate', 'Start Subprocess');
bpmnGen.setElementPosition(subStart, 470, 440, 30, 30);
subTask = bpmnGen.createTask('subtask', 'Process Document');
bpmnGen.setElementPosition(subTask, 530, 430, 80, 60);
subEnd = bpmnGen.createEndEvent('subend', 'End subprocess');
bpmnGen.setElementPosition(subEnd, 650, 450, 30, 30);

% Connect All Elements with Sequence Flows
bpmnGen.createSequenceFlow('flow1', startId, task1Id);
bpmnGen.createSequenceFlow('flow2', task1Id, gatewayId);
bpmnGen.createSequenceFlow('flow3', gatewayId, task2Id);
bpmnGen.createSequenceFlow('flow4', gatewayId, task3Id);
bpmnGen.createSequenceFlow('flow5', gatewayId, task4Id);
bpmnGen.createSequenceFlow('flow6', task2Id, gateway2Id);
bpmnGen.createSequenceFlow('flow7', task3Id, gateway2Id);
bpmnGen.createSequenceFlow('flow8', task4Id, gateway2Id);
bpmnGen.createSequenceFlow('flow9', gateway2Id, task5Id);
bpmnGen.createSequenceFlow('Flow10', task5Id, endId);
bpmnGen.createSequenceFlow('Flow11', gatewayId, subProcessId);
bpmnGen.createSequenceFlow('Flow12', subProcessId, gateway2Id);

% Connect subprocess elements
bpmnGen.createSequenceFlow('Subflow1', subStart, subTask);
bpmnGen.createSequenceFlow('Subflow2', subTask, subEnd);

% Save the initial diagram before optimization
initialFilePath = 'output/before_optimization.bpmn';
bpmnGen.saveToFile(initialFilePath);
fprintf('Initial diagram saved to %s \ n', initialFilePath);

% Apply layout optimization with custom parameters
optimizationParams = struct();
optimizationParams.minElementDistance = 50;
optimizationParams.flowOptimizationLevel = 'high';
optimizationParams.gridAlignment = true;
optimizationParams.gridSize = 20;
optimizationParams.horizontalPreference = 1.5; % Prefer horizontal flows

% Save the Optimized Diagram
optimizedFilePath = 'output/after_optimization.bpmn';
bpmnGen.saveToFile(optimizedFilePath);

% Apply layout optimization
bpmnGen.optimizeLayout(optimizationParams);

fprintf('Optimized Diagram saved to %s \ n', optimizedFilePath);
disp('Run this example and compare the Before and after bpmn files to see the effect of layout optimization.');