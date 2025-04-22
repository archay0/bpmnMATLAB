% OptimizedLayoutExample.m
% Demonstrates the advanced layout optimization features for BPMN diagrams
%
% This example creates a complex BPMN process with multiple parallel paths,
% subprocesses and gateways, then applies the layout optimization to improve
% diagram readability.

% Add src directory to path
addpath('../src');

% Initialize BPMN Generator
bpmnGen = BPMNGenerator();

% Create a business process with multiple paths
bpmnGen.createDefinitions('OptimizedLayoutProcess', 'urn:sample:optimizedlayout:1.0');
bpmnGen.createProcess('process1', 'Optimized Layout Process');

% Create start event
startId = bpmnGen.createStartEvent('start', 'Start Process');
bpmnGen.setElementPosition(startId, 100, 200, 36, 36);

% Create initial task
task1Id = bpmnGen.createTask('task1', 'Analyze Request');
bpmnGen.setElementPosition(task1Id, 200, 180, 100, 80);

% Create parallel gateway
gatewayId = bpmnGen.createParallelGateway('gateway1', 'Split Flow');
bpmnGen.setElementPosition(gatewayId, 350, 200, 50, 50);

% Create multiple tasks after the gateway (deliberately positioned to create overlap)
task2Id = bpmnGen.createTask('task2', 'Process Documents');
bpmnGen.setElementPosition(task2Id, 450, 100, 100, 80);

task3Id = bpmnGen.createTask('task3', 'Verify Information');
bpmnGen.setElementPosition(task3Id, 450, 200, 100, 80);

task4Id = bpmnGen.createTask('task4', 'Check Compliance');
bpmnGen.setElementPosition(task4Id, 450, 300, 100, 80);

% Create converging gateway
gateway2Id = bpmnGen.createParallelGateway('gateway2', 'Merge Flow');
bpmnGen.setElementPosition(gateway2Id, 600, 200, 50, 50);

% Create final task
task5Id = bpmnGen.createTask('task5', 'Complete Processing');
bpmnGen.setElementPosition(task5Id, 700, 180, 100, 80);

% Create end event
endId = bpmnGen.createEndEvent('end', 'End Process');
bpmnGen.setElementPosition(endId, 850, 200, 36, 36);

% Create subprocess with internal activities (deliberately misaligned)
subProcessId = bpmnGen.createSubProcess('subprocess1', 'Document Processing');
bpmnGen.setElementPosition(subProcessId, 450, 400, 250, 150);

% Add elements to the subprocess
subStart = bpmnGen.createStartEvent('subStart', 'Start Subprocess');
bpmnGen.setElementPosition(subStart, 470, 440, 30, 30);
subTask = bpmnGen.createTask('subTask', 'Process Document');
bpmnGen.setElementPosition(subTask, 530, 430, 80, 60);
subEnd = bpmnGen.createEndEvent('subEnd', 'End Subprocess');
bpmnGen.setElementPosition(subEnd, 650, 450, 30, 30);

% Connect all elements with sequence flows
bpmnGen.createSequenceFlow('flow1', startId, task1Id);
bpmnGen.createSequenceFlow('flow2', task1Id, gatewayId);
bpmnGen.createSequenceFlow('flow3', gatewayId, task2Id);
bpmnGen.createSequenceFlow('flow4', gatewayId, task3Id);
bpmnGen.createSequenceFlow('flow5', gatewayId, task4Id);
bpmnGen.createSequenceFlow('flow6', task2Id, gateway2Id);
bpmnGen.createSequenceFlow('flow7', task3Id, gateway2Id);
bpmnGen.createSequenceFlow('flow8', task4Id, gateway2Id);
bpmnGen.createSequenceFlow('flow9', gateway2Id, task5Id);
bpmnGen.createSequenceFlow('flow10', task5Id, endId);
bpmnGen.createSequenceFlow('flow11', gatewayId, subProcessId);
bpmnGen.createSequenceFlow('flow12', subProcessId, gateway2Id);

% Connect subprocess elements
bpmnGen.createSequenceFlow('subflow1', subStart, subTask);
bpmnGen.createSequenceFlow('subflow2', subTask, subEnd);

% Save the initial diagram before optimization
initialFilePath = 'output/before_optimization.bpmn';
bpmnGen.saveToFile(initialFilePath);
fprintf('Initial diagram saved to %s\n', initialFilePath);

% Apply layout optimization with custom parameters
optimizationParams = struct();
optimizationParams.minElementDistance = 50;
optimizationParams.flowOptimizationLevel = 'high';
optimizationParams.gridAlignment = true;
optimizationParams.gridSize = 20;
optimizationParams.horizontalPreference = 1.5; % Prefer horizontal flows

% Save the optimized diagram
optimizedFilePath = 'output/after_optimization.bpmn';
bpmnGen.saveToFile(optimizedFilePath);

% Apply layout optimization
bpmnGen.optimizeLayout(optimizationParams);

fprintf('Optimized diagram saved to %s\n', optimizedFilePath);
disp('Run this example and compare the before and after BPMN files to see the effect of layout optimization.');