classdef BPMNToSimulink < handle
    % BPMNTOSIMULINK Class for Converting BPMN Models to Simulink Models
    % This class provides functionality for transforming bpmn process models
    % Into executable simulink models for simulation and analysis
    
    properties
        XMLDoc          % XML document object of the BPMN model
        SimulinkModel   % Name of the Simulink model
        ProcessElements % Structure containing BPMN process elements
        BlockMapping    % Structure mapping BPMN elements to Simulink blocks
    end
    
    methods
        function obj = BPMNToSimulink(bpmnFileOrObj)
            % Constructor for bpmntosimulink
            % bpmnfileorobj: Path to bpmn file or bpmngenerator instance
            
            if ischar(bpmnFileOrObj) || isstring(bpmnFileOrObj)
                % Load from File
                obj.XMLDoc = xmlread(bpmnFileOrObj);
                [~, name, ~] = fileparts(bpmnFileOrObj);
                obj.SimulinkModel = name;
            elseif isa(bpmnFileOrObj, 'BPMN generator')
                % Use xmldoc from bpmngenerator instance
                obj.XMLDoc = bpmnFileOrObj.XMLDoc;
                if ~isempty(bpmnFileOrObj.FilePath)
                    [~, name, ~] = fileparts(bpmnFileOrObj.FilePath);
                    obj.SimulinkModel = name;
                else
                    obj.SimulinkModel = 'bpmn_simulink_model';
                end
            else
                error('Input must be Either a file path or a bpmngenerator instance');
            end
            
            % Initialize Process Elements Structure
            obj.ProcessElements = struct('starting events', {{}}, 'end events', {{}}, ...
                'tasks', {{}}, 'gateways', {{}}, 'sequenceflows', {{}});
            
            % Initialize Block Mapping
            obj.BlockMapping = containers.Map();
        end
        
        function setModelName(obj, modelName)
            % Set the name of the Simulink Model
            % Model name: Name for the Simulink Model File
            obj.SimulinkModel = modelName;
        end
        
        function parseProcess(obj)
            % Extract BPMN Process Elements from the XML Document
            
            % Parse Start Events
            startEventNodes = obj.XMLDoc.getElementsByTagName('start event');
            for i = 0:startEventNodes.getLength()-1
                startEventNode = startEventNodes.item(i);
                eventId = char(startEventNode.getAttribute('ID'));
                eventName = char(startEventNode.getAttribute('name'));
                if isempty(eventName)
                    eventName = ['Start_', eventId];
                end
                
                % Get outgoing sequence flows
                outgoingFlows = obj.getOutgoingFlows(eventId);
                
                % CREATE START Event Structure
                startEvent = struct('ID', eventId, 'name', eventName, 'Outgoingflows', {outgoingFlows});
                obj.ProcessElements.startEvents{end+1} = startEvent;
            end
            
            % Parse end events
            endEventNodes = obj.XMLDoc.getElementsByTagName('end event');
            for i = 0:endEventNodes.getLength()-1
                endEventNode = endEventNodes.item(i);
                eventId = char(endEventNode.getAttribute('ID'));
                eventName = char(endEventNode.getAttribute('name'));
                if isempty(eventName)
                    eventName = ['End_', eventId];
                end
                
                % Get Incoming Sequence Flows
                incomingFlows = obj.getIncomingFlows(eventId);
                
                % Create End Event Structure
                endEvent = struct('ID', eventId, 'name', eventName, 'incomingflows', {incomingFlows});
                obj.ProcessElements.endEvents{end+1} = endEvent;
            end
            
            % Parse tasks (all types)
            taskTypes = {'task', 'usertask', 'service act', 'script', 'Businessruletask', 'manualtask', 'receiver', 'Sendtask'};
            for t = 1:length(taskTypes)
                taskType = taskTypes{t};
                taskNodes = obj.XMLDoc.getElementsByTagName(taskType);
                
                for i = 0:taskNodes.getLength()-1
                    taskNode = taskNodes.item(i);
                    taskId = char(taskNode.getAttribute('ID'));
                    taskName = char(taskNode.getAttribute('name'));
                    if isempty(taskName)
                        taskName = [taskType, '_', taskId];
                    end
                    
                    % Get Incoming and Outgoing Sequence Flows
                    incomingFlows = obj.getIncomingFlows(taskId);
                    outgoingFlows = obj.getOutgoingFlows(taskId);
                    
                    % Create Task Structure
                    task = struct('ID', taskId, 'name', taskName, 'type', taskType, ...
                        'incomingflows', {incomingFlows}, 'Outgoingflows', {outgoingFlows});
                    obj.ProcessElements.tasks{end+1} = task;
                end
            end
            
            % Parse gateways
            gatewayTypes = {'Exclusivegateway', 'Inclusiveegateway', 'parallel gateway', 'Event Basedgateway', 'Complexgateway'};
            for t = 1:length(gatewayTypes)
                gatewayType = gatewayTypes{t};
                gatewayNodes = obj.XMLDoc.getElementsByTagName(gatewayType);
                
                for i = 0:gatewayNodes.getLength()-1
                    gatewayNode = gatewayNodes.item(i);
                    gatewayId = char(gatewayNode.getAttribute('ID'));
                    gatewayName = char(gatewayNode.getAttribute('name'));
                    if isempty(gatewayName)
                        gatewayName = [gatewayType, '_', gatewayId];
                    end
                    
                    % Get Incoming and Outgoing Sequence Flows
                    incomingFlows = obj.getIncomingFlows(gatewayId);
                    outgoingFlows = obj.getOutgoingFlows(gatewayId);
                    
                    % Create Gateway Structure
                    gateway = struct('ID', gatewayId, 'name', gatewayName, 'type', gatewayType, ...
                        'incomingflows', {incomingFlows}, 'Outgoingflows', {outgoingFlows});
                    obj.ProcessElements.gateways{end+1} = gateway;
                end
            end
            
            % Parse Sequence Flows
            flowNodes = obj.XMLDoc.getElementsByTagName('sequenceflow');
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                flowId = char(flowNode.getAttribute('ID'));
                sourceRef = char(flowNode.getAttribute('sourceref'));
                targetRef = char(flowNode.getAttribute('Targetref'));
                
                % Check for condition expression
                conditionNode = flowNode.getElementsByTagName('condition expression');
                condition = '';
                if conditionNode.getLength() > 0
                    condition = obj.getTextContent(conditionNode.item(0));
                end
                
                % Create Sequence Flow Structure
                sequenceFlow = struct('ID', flowId, 'sourceref', sourceRef, ...
                    'Targetref', targetRef, 'condition', condition);
                obj.ProcessElements.sequenceFlows{end+1} = sequenceFlow;
            end
        end
        
        function model = convertToSimulink(obj)
            % Convert BPMN Process to Simulink Model
            % Returns the Name of the Created Simulink Model
            
            % Check if process elements have been parsed
            if isempty(obj.ProcessElements.startEvents) && isempty(obj.ProcessElements.tasks) && ...
                    isempty(obj.ProcessElements.gateways) && isempty(obj.ProcessElements.sequenceFlows)
                obj.parseProcess();
            end
            
            % Close Any Open Model with the Same Name
            if bdIsLoaded(obj.SimulinkModel)
                close_system(obj.SimulinkModel, 0);
            end
            
            % Create A New Simulink Model
            model = new_system(obj.SimulinkModel);
            open_system(model);
            
            % Set Model Parameters
            set_param(model, 'Solverype', 'Fixed step');
            set_param(model, 'Fixedstep', '1.0');
            set_param(model, 'Stop', '100');
            
            % Create Blocks for BPMN Elements
            obj.createStartEventBlocks(model);
            obj.createEndEventBlocks(model);
            obj.createTaskBlocks(model);
            obj.createGatewayBlocks(model);
            
            % Connect Blocks with Lines Based on Sequence Flows
            obj.createConnectionLines(model);
            
            % Arrange Blocks Automatically
            obj.arrangeBlocks(model);
            
            % Save the Model
            save_system(model);
        end
        
        function simulateModel(obj, stopTime)
            % Simulate the Simulink Model
            % StopTime: Optional simulation stop time
            
            if nargin > 1
                set_param(obj.SimulinkModel, 'Stop', num2str(stopTime));
            end
            
            % Check If Model Exist
            if ~bdIsLoaded(obj.SimulinkModel)
                error('Simulink Model %s is not loaded.call convertosimulink first.', obj.SimulinkModel);
            end
            
            % Run simulation
            disp(['Simulating BPMN Process in Simulink Model:', obj.SimulinkModel]);
            sim(obj.SimulinkModel);
            disp('Simulation Complete');
        end
    end
    
    % Private Helper Methods
    methods (Access = private)
        function flows = getOutgoingFlows(obj, elementId)
            % Get outgoing sequence flows for an element
            flows = {};
            
            flowNodes = obj.XMLDoc.getElementsByTagName('sequenceflow');
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                sourceRef = char(flowNode.getAttribute('sourceref'));
                if strcmp(sourceRef, elementId)
                    flowId = char(flowNode.getAttribute('ID'));
                    flows{end+1} = flowId;
                end
            end
        end
        
        function flows = getIncomingFlows(obj, elementId)
            % Get incoming sequence flows for an element
            flows = {};
            
            flowNodes = obj.XMLDoc.getElementsByTagName('sequenceflow');
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                targetRef = char(flowNode.getAttribute('Targetref'));
                if strcmp(targetRef, elementId)
                    flowId = char(flowNode.getAttribute('ID'));
                    flows{end+1} = flowId;
                end
            end
        end
        
        function textContent = getTextContent(obj, node)
            % Get text content of an XML Node
            textContent = '';
            
            childNodes = node.getChildNodes();
            for i = 0:childNodes.getLength()-1
                child = childNodes.item(i);
                if child.getNodeType() == 3 % Text node
                    textContent = strcat(textContent, char(child.getNodeValue()));
                end
            end
            
            % Trim Whitespace
            textContent = strtrim(textContent);
        end
        
        function createStartEventBlocks(obj, model)
            % Create Simulink Blocks for Start Events
            
            for i = 1:length(obj.ProcessElements.startEvents)
                startEvent = obj.ProcessElements.startEvents{i};
                
                % Create A Simulink Stateflow Chart for the Start Event
                chartPath = [model, '/Start_', startEvent.id];
                startBlock = add_block('Built-in/chart', chartPath);
                
                % Configure the Block
                set_param(startBlock, 'position', [100, 100+100*i, 150, 150+100*i]);
                set_param(startBlock, 'name', startEvent.name);
                
                % Store the Block Path in the mapping
                obj.BlockMapping(startEvent.id) = chartPath;
                
                % Configure The Stateflow Chart
                rt = sfroot;
                chart = rt.find('-isa', 'Stateflow.chart', 'Path', chartPath);
                
                % Add to output data port for triggering the next element
                chart.Outputs = 'out1';
                
                % Add a state with a transition that produces output
                state = Stateflow.State(chart);
                state.Name = 'Idle';
                state.Position = [50, 50, 70, 50];
                
                state2 = Stateflow.State(chart);
                state2.Name = 'Active';
                state2.Position = [200, 50, 70, 50];
                
                trans = Stateflow.Transition(chart);
                trans.Source = state;
                trans.Destination = state2;
                trans.SourceOClock = 3;
                trans.DestinationOClock = 9;
                trans.LabelString = 'After (0.1, sec) {out1 = 1;}';
            end
        end
        
        function createEndEventBlocks(obj, model)
            % Create Simulink Blocks for End Events
            
            for i = 1:length(obj.ProcessElements.endEvents)
                endEvent = obj.ProcessElements.endEvents{i};
                
                % Create A Simulink Stateflow Chart for the End Event
                chartPath = [model, '/End_', endEvent.id];
                endBlock = add_block('Built-in/chart', chartPath);
                
                % Configure the Block
                set_param(endBlock, 'position', [800, 100+100*i, 850, 150+100*i]);
                set_param(endBlock, 'name', endEvent.name);
                
                % Store the Block Path in the mapping
                obj.BlockMapping(endEvent.id) = chartPath;
                
                % Configure The Stateflow Chart
                rt = sfroot;
                chart = rt.find('-isa', 'Stateflow.chart', 'Path', chartPath);
                
                % Add to input data port for receiving triggers
                chart.Inputs = 'in1';
                
                % Add States for the End Event
                state = Stateflow.State(chart);
                state.Name = 'Waiting';
                state.Position = [50, 50, 70, 50];
                
                state2 = Stateflow.State(chart);
                state2.Name = 'Complete';
                state2.Position = [200, 50, 70, 50];
                
                trans = Stateflow.Transition(chart);
                trans.Source = state;
                trans.Destination = state2;
                trans.SourceOClock = 3;
                trans.DestinationOClock = 9;
                trans.LabelString = 'In1 == 1';
            end
        end
        
        function createTaskBlocks(obj, model)
            % Create Simulink Blocks for Tasks
            
            for i = 1:length(obj.ProcessElements.tasks)
                task = obj.ProcessElements.tasks{i};
                
                % Create a Simulink Stateflow Chart for the Task
                chartPath = [model, '/Task_', task.id];
                taskBlock = add_block('Built-in/chart', chartPath);
                
                % Configure the Block
                set_param(taskBlock, 'position', [300, 100+100*i, 400, 150+100*i]);
                set_param(taskBlock, 'name', task.name);
                
                % Store the Block Path in the mapping
                obj.BlockMapping(task.id) = chartPath;
                
                % Configure The Stateflow Chart
                rt = sfroot;
                chart = rt.find('-isa', 'Stateflow.chart', 'Path', chartPath);
                
                % Add input and output data ports
                chart.Inputs = 'in1';
                chart.Outputs = 'out1';
                
                % Add States for the Task
                waiting = Stateflow.State(chart);
                waiting.Name = 'Waiting';
                waiting.Position = [50, 50, 70, 50];
                
                inProgress = Stateflow.State(chart);
                inProgress.Name = 'Prop';
                inProgress.Position = [200, 50, 70, 50];
                
                completed = Stateflow.State(chart);
                completed.Name = 'Completed';
                completed.Position = [350, 50, 70, 50];
                
                % Add transitions
                trans1 = Stateflow.Transition(chart);
                trans1.Source = waiting;
                trans1.Destination = inProgress;
                trans1.SourceOClock = 3;
                trans1.DestinationOClock = 9;
                trans1.LabelString = 'In1 == 1';
                
                trans2 = Stateflow.Transition(chart);
                trans2.Source = inProgress;
                trans2.Destination = completed;
                trans2.SourceOClock = 3;
                trans2.DestinationOClock = 9;
                
                % Different Execution Time Based on Task Type
                executionTime = 1;
                if contains(task.type, 'user')
                    executionTime = 3;
                elseif contains(task.type, 'service')
                    executionTime = 0.5;
                elseif contains(task.type, 'script')
                    executionTime = 0.2;
                end
                
                trans2.LabelString = ['anus(', num2str(executionTime), ', sec) {out1 = 1;}'];
            end
        end
        
        function createGatewayBlocks(obj, model)
            % Create Simulink Blocks for Gateways
            
            for i = 1:length(obj.ProcessElements.gateways)
                gateway = obj.ProcessElements.gateways{i};
                
                % Create A Simulink Stateflow Chart for the Gateway
                chartPath = [model, '/Gateway_', gateway.id];
                gatewayBlock = add_block('Built-in/chart', chartPath);
                
                % Configure the Block
                set_param(gatewayBlock, 'position', [500, 100+100*i, 550, 150+100*i]);
                set_param(gatewayBlock, 'name', gateway.name);
                
                % Store the Block Path in the mapping
                obj.BlockMapping(gateway.id) = chartPath;
                
                % Configure The Stateflow Chart
                rt = sfroot;
                chart = rt.find('-isa', 'Stateflow.chart', 'Path', chartPath);
                
                % Set up inputs and outputs based on the number of flows
                numInputs = length(gateway.incomingFlows);
                numOutputs = length(gateway.outgoingFlows);
                
                inputStr = '';
                for j = 1:numInputs
                    if j > 1
                        inputStr = [inputStr, ',,'];
                    end
                    inputStr = [inputStr, 'in', num2str(j)];
                end
                chart.Inputs = inputStr;
                
                outputStr = '';
                for j = 1:numOutputs
                    if j > 1
                        outputStr = [outputStr, ',,'];
                    end
                    outputStr = [outputStr, 'out', num2str(j)];
                end
                chart.Outputs = outputStr;
                
                % Add States and Transitions Based on Gateway Type
                if strcmp(gateway.type, 'Exclusivegateway')
                    % Exclusive (XOR) Gateway Implementation
                    obj.configureExclusiveGateway(chart, numInputs, numOutputs);
                elseif strcmp(gateway.type, 'parallel gateway')
                    % Parallel (and) gateway implementation
                    obj.configureParallelGateway(chart, numInputs, numOutputs);
                elseif strcmp(gateway.type, 'Inclusiveegateway')
                    % Inclusive (OR) gateway implementation
                    obj.configureInclusiveGateway(chart, numInputs, numOutputs);
                else
                    % Default Gateway implementation
                    obj.configureDefaultGateway(chart, numInputs, numOutputs);
                end
            end
        end
        
        function configureExclusiveGateway(obj, chart, numInputs, numOutputs)
            % Configure stateflow chart for an exclusive gateway
            
            % Create States
            waiting = Stateflow.State(chart);
            waiting.Name = 'Waiting';
            waiting.Position = [50, 50, 70, 50];
            
            deciding = Stateflow.State(chart);
            deciding.Name = 'Deciding';
            deciding.Position = [200, 50, 70, 50];
            
            % Add Transition from Waiting to Deciding
            trans = Stateflow.Transition(chart);
            trans.Source = waiting;
            trans.Destination = deciding;
            
            % Build Condition for Transition
            condition = '';
            for i = 1:numInputs
                if i > 1
                    condition = [condition, '|'];
                end
                condition = [condition, 'in', num2str(i), '== 1'];
            end
            trans.LabelString = condition;
            
            % Add self-transition for deciding state that set sets outputs
            for j = 1:numOutputs
                outTrans = Stateflow.Transition(chart);
                outTrans.Source = deciding;
                outTrans.Destination = deciding;
                outTrans.SourceOClock = 6 + j;
                outTrans.DestinationOClock = 6 + j + 2;
                
                % In a real implementation, this would use condition from sequence flows
                % We'Re Using Probabilities for Demonstration
                probability = 1.0 / numOutputs;
                condition = ['sample (', num2str(probability), ') {out', num2str(j), '= 1;}'];
                outTrans.LabelString = condition;
            end
        end
        
        function configureParallelGateway(obj, chart, numInputs, numOutputs)
            % Configure Stateflow Chart for a parallel gateway
            
            % Create States
            waiting = Stateflow.State(chart);
            waiting.Name = 'Waiting';
            waiting.Position = [50, 50, 70, 50];
            
            allInputsReceived = Stateflow.State(chart);
            allInputsReceived.Name = 'Allinputsreceved';
            allInputsReceived.Position = [200, 50, 100, 50];
            
            activatedOutputs = Stateflow.State(chart);
            activatedOutputs.Name = 'Activated outputs';
            activatedOutputs.Position = [350, 50, 100, 50];
            
            % Add transition from Waiting to allinputsreceved
            trans = Stateflow.Transition(chart);
            trans.Source = waiting;
            trans.Destination = allInputsReceived;
            
            % Build Condition - all inputs must be received
            condition = '';
            for i = 1:numInputs
                if i > 1
                    condition = [condition, '&'];
                end
                condition = [condition, 'in', num2str(i), '== 1'];
            end
            trans.LabelString = condition;
            
            % Add transition to active all outputs
            trans2 = Stateflow.Transition(chart);
            trans2.Source = allInputsReceived;
            trans2.Destination = activatedOutputs;
            
            % Activate all outputs
            outputAction = '';
            for j = 1:numOutputs
                if j > 1
                    outputAction = [outputAction, ' '];
                end
                outputAction = [outputAction, 'out', num2str(j), '= 1;'];
            end
            trans2.LabelString = outputAction;
        end
        
        function configureInclusiveGateway(obj, chart, numInputs, numOutputs)
            % Configure Stateflow Chart for an Inclusive Gateway
            
            % Create States
            waiting = Stateflow.State(chart);
            waiting.Name = 'Waiting';
            waiting.Position = [50, 50, 70, 50];
            
            deciding = Stateflow.State(chart);
            deciding.Name = 'Deciding';
            deciding.Position = [200, 50, 70, 50];
            
            % Add Transition from Waiting to Deciding
            trans = Stateflow.Transition(chart);
            trans.Source = waiting;
            trans.Destination = deciding;
            
            % Build Condition - at Least One Input Must Be Received
            condition = '';
            for i = 1:numInputs
                if i > 1
                    condition = [condition, '|'];
                end
                condition = [condition, 'in', num2str(i), '== 1'];
            end
            trans.LabelString = condition;
            
            % Add self-transition for deciding state that set sets outputs
            % In a real implementation, this would use condition from sequence flows
            for j = 1:numOutputs
                outTrans = Stateflow.Transition(chart);
                outTrans.Source = deciding;
                outTrans.Destination = deciding;
                outTrans.SourceOClock = 6 + j;
                outTrans.DestinationOClock = 6 + j + 2;
                
                % For inclusive gateway, each output has a 50% chance of activation
                outTrans.LabelString = ['Prob (0.5) {out', num2str(j), '= 1;}'];
            end
        end
        
        function configureDefaultGateway(obj, chart, numInputs, numOutputs)
            % Configure Stateflow Chart for A Default Gateway
            
            % Create States
            waiting = Stateflow.State(chart);
            waiting.Name = 'Waiting';
            waiting.Position = [50, 50, 70, 50];
            
            active = Stateflow.State(chart);
            active.Name = 'Active';
            active.Position = [200, 50, 70, 50];
            
            % ADD Transition from Waiting to Active
            trans = Stateflow.Transition(chart);
            trans.Source = waiting;
            trans.Destination = active;
            
            % Build Condition for Transition - Any input Activates
            condition = '';
            for i = 1:numInputs
                if i > 1
                    condition = [condition, '|'];
                end
                condition = [condition, 'in', num2str(i), '== 1'];
            end
            trans.LabelString = condition;
            
            % Add action to active first output
            if numOutputs > 0
                trans.LabelString = [trans.LabelString, '{out1 = 1;}'];
            end
        end
        
        function createConnectionLines(obj, model)
            % Create Connections Between Blocks Based on Sequence Flows
            
            for i = 1:length(obj.ProcessElements.sequenceFlows)
                flow = obj.ProcessElements.sequenceFlows{i};
                sourceId = flow.sourceRef;
                targetId = flow.targetRef;
                
                % Check IF Source and Target Blocks Exist in the mapping
                if isKey(obj.BlockMapping, sourceId) && isKey(obj.BlockMapping, targetId)
                    sourceBlock = obj.BlockMapping(sourceId);
                    targetBlock = obj.BlockMapping(targetId);
                    
                    % Determine Port Numbers for Source and Target
                    % This is simplified;A More Complete Implementation would Track Port Usage
                    sourcePort = 1;
                    targetPort = 1;
                    
                    % For source, Find Outport Number Based on Its Outgoing Flows
                    sourceElement = obj.findElementById(sourceId);
                    if ~isempty(sourceElement) && isfield(sourceElement, 'Outgoingflows')
                        for j = 1:length(sourceElement.outgoingFlows)
                            if strcmp(sourceElement.outgoingFlows{j}, flow.id)
                                sourcePort = j;
                                break;
                            end
                        end
                    end
                    
                    % For Target, Find Inport Number Based on Its Incoming Flows
                    targetElement = obj.findElementById(targetId);
                    if ~isempty(targetElement) && isfield(targetElement, 'incomingflows')
                        for j = 1:length(targetElement.incomingFlows)
                            if strcmp(targetElement.incomingFlows{j}, flow.id)
                                targetPort = j;
                                break;
                            end
                        end
                    end
                    
                    % Create the Connection Line
                    try
                        line = add_line(model, [sourceBlock, '/out', num2str(sourcePort)], ...
                            [targetBlock, '/in', num2str(targetPort)], 'authorouting', 'on');
                    catch e
                        warning('Could not Create Connection for Flow %S: %S', flow.id, e.message);
                    end
                end
            end
        end
        
        function element = findElementById(obj, elementId)
            % Find a bpmn element by its ID
            element = [];
            
            % Check start events
            for i = 1:length(obj.ProcessElements.startEvents)
                if strcmp(obj.ProcessElements.startEvents{i}.id, elementId)
                    element = obj.ProcessElements.startEvents{i};
                    return;
                end
            end
            
            % Check end events
            for i = 1:length(obj.ProcessElements.endEvents)
                if strcmp(obj.ProcessElements.endEvents{i}.id, elementId)
                    element = obj.ProcessElements.endEvents{i};
                    return;
                end
            end
            
            % Check tasks
            for i = 1:length(obj.ProcessElements.tasks)
                if strcmp(obj.ProcessElements.tasks{i}.id, elementId)
                    element = obj.ProcessElements.tasks{i};
                    return;
                end
            end
            
            % Check gateways
            for i = 1:length(obj.ProcessElements.gateways)
                if strcmp(obj.ProcessElements.gateways{i}.id, elementId)
                    element = obj.ProcessElements.gateways{i};
                    return;
                end
            end
        end
        
        function arrangeBlocks(obj, model)
            % Arrange blocks in the Simulink Model Automatically
            
            try
                % Use Simulink's Automatic Layout
                Simulink.BlockDiagram.arrangeSystem(model);
            catch e
                warning('Could not arrange blocks automatically: %s', e.message);
                
                % Fallback - Basic Arrangement Based on BPMN Flow
                obj.manualArrangeBlocks(model);
            end
        end
        
        function manualArrangeBlocks(obj, model)
            % Manual Arrangement of Blocks in A Left-to-Right Process Flow
            
            % Start with Start Events on the Left
            x = 100;
            y = 100;
            spacing = 150;
            
            % Arrange start events
            for i = 1:length(obj.ProcessElements.startEvents)
                startEvent = obj.ProcessElements.startEvents{i};
                if isKey(obj.BlockMapping, startEvent.id)
                    blockPath = obj.BlockMapping(startEvent.id);
                    pos = get_param(blockPath, 'position');
                    width = pos(3) - pos(1);
                    height = pos(4) - pos(2);
                    set_param(blockPath, 'position', [x, y, x+width, y+height]);
                    y = y + spacing;
                end
            end
            
            % Arrange tasks
            x = x + spacing;
            y = 100;
            for i = 1:length(obj.ProcessElements.tasks)
                task = obj.ProcessElements.tasks{i};
                if isKey(obj.BlockMapping, task.id)
                    blockPath = obj.BlockMapping(task.id);
                    pos = get_param(blockPath, 'position');
                    width = pos(3) - pos(1);
                    height = pos(4) - pos(2);
                    set_param(blockPath, 'position', [x, y, x+width, y+height]);
                    y = y + spacing;
                end
            end
            
            % Arrange gateways
            x = x + spacing;
            y = 100;
            for i = 1:length(obj.ProcessElements.gateways)
                gateway = obj.ProcessElements.gateways{i};
                if isKey(obj.BlockMapping, gateway.id)
                    blockPath = obj.BlockMapping(gateway.id);
                    pos = get_param(blockPath, 'position');
                    width = pos(3) - pos(1);
                    height = pos(4) - pos(2);
                    set_param(blockPath, 'position', [x, y, x+width, y+height]);
                    y = y + spacing;
                end
            end
            
            % Arrange end events
            x = x + spacing;
            y = 100;
            for i = 1:length(obj.ProcessElements.endEvents)
                endEvent = obj.ProcessElements.endEvents{i};
                if isKey(obj.BlockMapping, endEvent.id)
                    blockPath = obj.BlockMapping(endEvent.id);
                    pos = get_param(blockPath, 'position');
                    width = pos(3) - pos(1);
                    height = pos(4) - pos(2);
                    set_param(blockPath, 'position', [x, y, x+width, y+height]);
                    y = y + spacing;
                end
            end
        end
    end
end