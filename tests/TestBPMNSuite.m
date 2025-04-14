classdef TestBPMNSuite < matlab.unittest.TestCase
    % TestBPMNSuite Comprehensive test suite for bpmnMATLAB
    %   This class tests all components of the bpmnMATLAB library
    
    properties
        TestOutputDir     % Directory for test outputs
        SampleBPMNFile    % Path to a sample BPMN file
        TestGenerator     % BPMNGenerator instance for testing
    end
    
    methods(TestMethodSetup)
        function setupTest(testCase)
            % Setup for each test - creates output directories and test objects
            
            % Get the root directory of the repository
            currentDir = fileparts(mfilename('fullpath'));
            rootDir = fullfile(currentDir, '..');
            
            % Setup test output directory
            testCase.TestOutputDir = fullfile(rootDir, 'tests', 'output');
            if ~exist(testCase.TestOutputDir, 'dir')
                mkdir(testCase.TestOutputDir);
            end
            
            % Create a sample BPMN file path
            testCase.SampleBPMNFile = fullfile(testCase.TestOutputDir, 'sample.bpmn');
            
            % Create a test generator
            testCase.TestGenerator = BPMNGenerator(testCase.SampleBPMNFile);
        end
    end
    
    methods(TestMethodTeardown)
        function cleanupTest(testCase)
            % Cleanup after each test
            
            % Delete any generated files
            if exist(testCase.SampleBPMNFile, 'file')
                delete(testCase.SampleBPMNFile);
            end
        end
    end
    
    methods (Test)
        function testBPMNGeneratorCreation(testCase)
            % Test that BPMNGenerator is created correctly
            
            testCase.verifyClass(testCase.TestGenerator, 'BPMNGenerator');
            testCase.verifyEqual(testCase.TestGenerator.FilePath, testCase.SampleBPMNFile);
            testCase.verifyEqual(testCase.TestGenerator.BPMNVersion, '2.0');
            testCase.verifyTrue(~isempty(testCase.TestGenerator.ProcessElements));
        end
        
        function testCreateEmptyBPMN(testCase)
            % Test creating an empty BPMN file
            
            % Initialize an empty BPMN
            generator = BPMNGenerator(testCase.SampleBPMNFile);
            generator.initializeEmptyBPMN();
            generator.saveBPMNFile();
            
            % Verify file exists
            testCase.verifyTrue(exist(testCase.SampleBPMNFile, 'file') > 0);
            
            % Validate the created file
            validator = BPMNValidator(testCase.SampleBPMNFile);
            validator.validate();
            results = validator.getValidationResults();
            
            % Basic structure should be valid (may have warnings about no start/end events)
            testCase.verifyTrue(~isempty(results));
            testCase.verifyTrue(isfield(results, 'errors'));
        end
        
        function testAddProcess(testCase)
            % Test adding a process to the BPMN
            
            % Create a process
            processId = 'Process_1';
            processName = 'Test Process';
            generator = testCase.TestGenerator;
            
            % Add a process
            generator.addProcess(processId, processName, true);
            
            % Verify process was added
            rootNode = generator.XMLDoc.getDocumentElement();
            processes = rootNode.getElementsByTagName('process');
            
            testCase.verifyEqual(processes.getLength(), 1);
            process = processes.item(0);
            testCase.verifyEqual(char(process.getAttribute('id')), processId);
            testCase.verifyEqual(char(process.getAttribute('name')), processName);
        end
        
        function testAddTaskWithElements(testCase)
            % Test adding tasks and connecting elements
            
            % Setup
            generator = testCase.TestGenerator;
            processId = 'Process_1';
            generator.addProcess(processId, 'Test Process', true);
            
            % Add start event
            startEventId = 'StartEvent_1';
            generator.addStartEvent(startEventId, 'Start', processId);
            
            % Add task
            taskId = 'Task_1';
            generator.addTask(taskId, 'Test Task', processId);
            
            % Add end event
            endEventId = 'EndEvent_1';
            generator.addEndEvent(endEventId, 'End', processId);
            
            % Connect elements
            flow1Id = 'Flow_1';
            flow2Id = 'Flow_2';
            generator.addSequenceFlow(flow1Id, startEventId, taskId, processId);
            generator.addSequenceFlow(flow2Id, taskId, endEventId, processId);
            
            % Add positions for elements
            generator.addShapeToVisualization(startEventId, 100, 100, 36, 36);
            generator.addShapeToVisualization(taskId, 200, 80, 100, 80);
            generator.addShapeToVisualization(endEventId, 350, 100, 36, 36);
            
            % Save the file
            generator.saveBPMNFile();
            
            % Verify file exists
            testCase.verifyTrue(exist(testCase.SampleBPMNFile, 'file') > 0);
            
            % Validate with our validator
            validator = BPMNValidator(testCase.SampleBPMNFile);
            validator.validate();
            results = validator.getValidationResults();
            
            % Check that we have no errors about missing nodes or flows
            testCase.verifyTrue(~any(contains(results.errors, 'non-existent')));
            
            % Verify we have the correct number of elements in the XML
            doc = xmlread(testCase.SampleBPMNFile);
            root = doc.getDocumentElement();
            
            elements = root.getElementsByTagName('startEvent');
            testCase.verifyEqual(elements.getLength(), 1);
            
            elements = root.getElementsByTagName('task');
            testCase.verifyEqual(elements.getLength(), 1);
            
            elements = root.getElementsByTagName('endEvent');
            testCase.verifyEqual(elements.getLength(), 1);
            
            elements = root.getElementsByTagName('sequenceFlow');
            testCase.verifyEqual(elements.getLength(), 2);
        end
        
        function testGatewayCreation(testCase)
            % Test creation of gateways
            
            % Setup
            generator = testCase.TestGenerator;
            processId = 'Process_1';
            generator.addProcess(processId, 'Gateway Test Process', true);
            
            % Add elements
            startEventId = 'StartEvent_1';
            gateway1Id = 'Gateway_1';
            task1Id = 'Task_1';
            task2Id = 'Task_2';
            gateway2Id = 'Gateway_2';
            endEventId = 'EndEvent_1';
            
            generator.addStartEvent(startEventId, 'Start', processId);
            generator.addExclusiveGateway(gateway1Id, 'Split', processId);
            generator.addTask(task1Id, 'Path A', processId);
            generator.addTask(task2Id, 'Path B', processId);
            generator.addParallelGateway(gateway2Id, 'Join', processId);
            generator.addEndEvent(endEventId, 'End', processId);
            
            % Add sequence flows
            generator.addSequenceFlow('Flow_1', startEventId, gateway1Id, processId);
            generator.addSequenceFlow('Flow_2', gateway1Id, task1Id, processId);
            generator.addSequenceFlow('Flow_3', gateway1Id, task2Id, processId);
            generator.addSequenceFlow('Flow_4', task1Id, gateway2Id, processId);
            generator.addSequenceFlow('Flow_5', task2Id, gateway2Id, processId);
            generator.addSequenceFlow('Flow_6', gateway2Id, endEventId, processId);
            
            % Add conditions to gateway flows
            generator.addConditionToSequenceFlow('Flow_2', 'path == "A"');
            generator.addConditionToSequenceFlow('Flow_3', 'path == "B"');
            
            % Add default flow to gateway
            generator.addDefaultFlowToGateway(gateway1Id, 'Flow_2');
            
            % Save the BPMN file
            generator.saveBPMNFile();
            
            % Verify file exists
            testCase.verifyTrue(exist(testCase.SampleBPMNFile, 'file') > 0);
            
            % Load and check gateway properties
            doc = xmlread(testCase.SampleBPMNFile);
            root = doc.getDocumentElement();
            
            % Verify exclusive gateway has default flow
            exclusiveGateways = root.getElementsByTagName('exclusiveGateway');
            testCase.verifyEqual(exclusiveGateways.getLength(), 1);
            exclusiveGateway = exclusiveGateways.item(0);
            defaultFlow = char(exclusiveGateway.getAttribute('default'));
            testCase.verifyEqual(defaultFlow, 'Flow_2');
            
            % Verify conditions on flows
            flows = root.getElementsByTagName('sequenceFlow');
            for i = 0:flows.getLength()-1
                flow = flows.item(i);
                flowId = char(flow.getAttribute('id'));
                
                if strcmp(flowId, 'Flow_2') || strcmp(flowId, 'Flow_3')
                    conditions = flow.getElementsByTagName('conditionExpression');
                    testCase.verifyEqual(conditions.getLength(), 1);
                end
            end
        end
        
        function testBoundaryEvents(testCase)
            % Test creation of boundary events
            
            % Setup
            generator = testCase.TestGenerator;
            processId = 'Process_1';
            generator.addProcess(processId, 'Boundary Event Test', true);
            
            % Add elements
            startEventId = 'StartEvent_1';
            taskId = 'Task_1';
            boundaryEventId = 'BoundaryEvent_1';
            errorTaskId = 'ErrorTask_1';
            endEventId = 'EndEvent_1';
            errorEndEventId = 'EndEvent_2';
            
            generator.addStartEvent(startEventId, 'Start', processId);
            generator.addTask(taskId, 'Main Task', processId);
            generator.addEndEvent(endEventId, 'Normal End', processId);
            generator.addTask(errorTaskId, 'Error Handler', processId);
            generator.addEndEvent(errorEndEventId, 'Error End', processId);
            
            % Add boundary event
            generator.addBoundaryEvent(boundaryEventId, 'Error Boundary', taskId, processId, true);
            generator.addErrorEventDefinition(boundaryEventId, 'Error_1', 'Test Error');
            
            % Add sequence flows
            generator.addSequenceFlow('Flow_1', startEventId, taskId, processId);
            generator.addSequenceFlow('Flow_2', taskId, endEventId, processId);
            generator.addSequenceFlow('Flow_3', boundaryEventId, errorTaskId, processId);
            generator.addSequenceFlow('Flow_4', errorTaskId, errorEndEventId, processId);
            
            % Save the BPMN file
            generator.saveBPMNFile();
            
            % Verify file exists
            testCase.verifyTrue(exist(testCase.SampleBPMNFile, 'file') > 0);
            
            % Load and check boundary event properties
            doc = xmlread(testCase.SampleBPMNFile);
            boundaryEvents = doc.getElementsByTagName('boundaryEvent');
            
            testCase.verifyEqual(boundaryEvents.getLength(), 1);
            
            boundaryEvent = boundaryEvents.item(0);
            testCase.verifyEqual(char(boundaryEvent.getAttribute('id')), boundaryEventId);
            testCase.verifyEqual(char(boundaryEvent.getAttribute('attachedToRef')), taskId);
            
            % Check for error event definition
            errorDefs = boundaryEvent.getElementsByTagName('errorEventDefinition');
            testCase.verifyEqual(errorDefs.getLength(), 1);
        end
        
        function testCollaborationAndPools(testCase)
            % Test creation of collaborations with pools and lanes
            
            % Setup
            generator = testCase.TestGenerator;
            
            % Add a collaboration
            collaborationId = 'Collaboration_1';
            generator.addCollaboration(collaborationId);
            
            % Add processes
            process1Id = 'Process_1';
            process2Id = 'Process_2';
            generator.addProcess(process1Id, 'Process 1', true);
            generator.addProcess(process2Id, 'Process 2', true);
            
            % Add pools
            pool1Id = 'Pool_1';
            pool2Id = 'Pool_2';
            generator.addPool(pool1Id, 'Customer', process1Id);
            generator.addPool(pool2Id, 'Supplier', process2Id);
            
            % Add lanes to first pool
            lane1Id = 'Lane_1';
            lane2Id = 'Lane_2';
            generator.addLane(lane1Id, 'Sales', pool1Id);
            generator.addLane(lane2Id, 'Support', pool1Id);
            
            % Add elements to process 1
            start1Id = 'Start_1';
            task1Id = 'Task_1';
            end1Id = 'End_1';
            generator.addStartEvent(start1Id, 'Start1', process1Id);
            generator.addTask(task1Id, 'Customer Task', process1Id);
            generator.addEndEvent(end1Id, 'End1', process1Id);
            
            % Add elements to process 2
            start2Id = 'Start_2';
            task2Id = 'Task_2';
            end2Id = 'End_2';
            generator.addStartEvent(start2Id, 'Start2', process2Id);
            generator.addTask(task2Id, 'Supplier Task', process2Id);
            generator.addEndEvent(end2Id, 'End2', process2Id);
            
            % Assign lane references
            generator.addElementToLane(lane1Id, start1Id);
            generator.addElementToLane(lane1Id, task1Id);
            generator.addElementToLane(lane2Id, end1Id);
            
            % Connect with sequence flows
            generator.addSequenceFlow('Flow_1_1', start1Id, task1Id, process1Id);
            generator.addSequenceFlow('Flow_1_2', task1Id, end1Id, process1Id);
            generator.addSequenceFlow('Flow_2_1', start2Id, task2Id, process2Id);
            generator.addSequenceFlow('Flow_2_2', task2Id, end2Id, process2Id);
            
            % Add a message flow between pools
            messageFlowId = 'MessageFlow_1';
            generator.addMessageFlow(messageFlowId, task1Id, task2Id, 'Request');
            
            % Save the BPMN file
            generator.saveBPMNFile();
            
            % Verify file exists
            testCase.verifyTrue(exist(testCase.SampleBPMNFile, 'file') > 0);
            
            % Load and check collaboration properties
            doc = xmlread(testCase.SampleBPMNFile);
            root = doc.getDocumentElement();
            
            % Check for collaboration
            collaborations = root.getElementsByTagName('collaboration');
            testCase.verifyEqual(collaborations.getLength(), 1);
            
            % Check for pools
            participants = root.getElementsByTagName('participant');
            testCase.verifyEqual(participants.getLength(), 2);
            
            % Check for lanes
            lanes = root.getElementsByTagName('lane');
            testCase.verifyEqual(lanes.getLength(), 2);
            
            % Check for message flows
            messageFlows = root.getElementsByTagName('messageFlow');
            testCase.verifyEqual(messageFlows.getLength(), 1);
            
            % Validate the created file
            validator = BPMNValidator(testCase.SampleBPMNFile);
            validator.validate();
            results = validator.getValidationResults();
            
            % We should have no errors about message flows being invalid
            testCase.verifyFalse(any(contains(results.errors, 'messageFlow')));
        end
        
        function testDataObjectsAndAssociations(testCase)
            % Test creation of data objects and associations
            
            % Setup
            generator = testCase.TestGenerator;
            processId = 'Process_1';
            generator.addProcess(processId, 'Data Object Test', true);
            
            % Add process elements
            startId = 'Start_1';
            taskId = 'Task_1';
            endId = 'End_1';
            generator.addStartEvent(startId, 'Start', processId);
            generator.addTask(taskId, 'Process Data', processId);
            generator.addEndEvent(endId, 'End', processId);
            
            % Add data elements
            dataObjectId = 'DataObject_1';
            dataStoreId = 'DataStore_1';
            generator.addDataObject(dataObjectId, 'Input Data', processId);
            generator.addDataStore(dataStoreId, 'Database', processId);
            
            % Add associations
            association1Id = 'Association_1';
            association2Id = 'Association_2';
            generator.addAssociation(association1Id, dataObjectId, taskId, processId);
            generator.addAssociation(association2Id, taskId, dataStoreId, processId);
            
            % Connect process elements
            generator.addSequenceFlow('Flow_1', startId, taskId, processId);
            generator.addSequenceFlow('Flow_2', taskId, endId, processId);
            
            % Save the BPMN file
            generator.saveBPMNFile();
            
            % Verify file exists
            testCase.verifyTrue(exist(testCase.SampleBPMNFile, 'file') > 0);
            
            % Load and check data objects
            doc = xmlread(testCase.SampleBPMNFile);
            root = doc.getDocumentElement();
            
            % Check for data objects
            dataObjects = root.getElementsByTagName('dataObject');
            testCase.verifyTrue(dataObjects.getLength() > 0);
            
            % Check for data stores
            dataStores = root.getElementsByTagName('dataStore');
            testCase.verifyTrue(dataStores.getLength() > 0);
            
            % Check for associations
            associations = root.getElementsByTagName('association');
            testCase.verifyEqual(associations.getLength(), 2);
        end
        
        function testValidatorWithInvalidBPMN(testCase)
            % Test the validator with an invalid BPMN file
            
            % Create a basic but invalid BPMN file (with disconnected nodes)
            generator = testCase.TestGenerator;
            processId = 'Process_1';
            generator.addProcess(processId, 'Invalid Process', true);
            
            % Add disconnected elements (missing flows)
            startId = 'Start_1';
            taskId = 'Task_1';
            endId = 'End_1';
            generator.addStartEvent(startId, 'Start', processId);
            generator.addTask(taskId, 'Task', processId);
            generator.addEndEvent(endId, 'End', processId);
            
            % No sequence flows added - this should cause validation warnings
            
            % Save the BPMN file
            generator.saveBPMNFile();
            
            % Validate with our validator
            validator = BPMNValidator(testCase.SampleBPMNFile);
            validator.validate();
            results = validator.getValidationResults();
            
            % Check that we have warnings about disconnected nodes
            testCase.verifyTrue(~isempty(results.warnings));
            hasDisconnectedWarning = any(contains(results.warnings, 'no outgoing sequence flows'));
            testCase.verifyTrue(hasDisconnectedWarning);
        end
        
        % The following tests require database connectivity and would be added
        % if you have a test database setup
        %
        % function testDatabaseConnector(testCase)
        %     % Test database connector functionality
        %     % This would require a test database with the correct schema
        % end
    end
end