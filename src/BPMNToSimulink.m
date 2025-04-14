classdef BPMNToSimulink < handle
    % BPMNToSimulink Class for converting BPMN models to Simulink models
    %   This class provides functionality for transforming BPMN process models
    %   into executable Simulink models for simulation and analysis
    
    properties
        XMLDoc          % XML document object of the BPMN model
        SimulinkModel   % Name of the Simulink model
        ProcessElements % Structure containing BPMN process elements
        BlockMapping    % Structure mapping BPMN elements to Simulink blocks
    end
    
    methods
        function obj = BPMNToSimulink(bpmnFileOrObj)
            % Constructor for BPMNToSimulink
            % bpmnFileOrObj: Path to BPMN file or BPMNGenerator instance
            
            if ischar(bpmnFileOrObj) || isstring(bpmnFileOrObj)
                % Load from file
                obj.XMLDoc = xmlread(bpmnFileOrObj);
                [~, name, ~] = fileparts(bpmnFileOrObj);
                obj.SimulinkModel = name;
            elseif isa(bpmnFileOrObj, 'BPMNGenerator')
                % Use XMLDoc from BPMNGenerator instance
                obj.XMLDoc = bpmnFileOrObj.XMLDoc;
                if ~isempty(bpmnFileOrObj.FilePath)
                    [~, name, ~] = fileparts(bpmnFileOrObj.FilePath);
                    obj.SimulinkModel = name;
                else
                    obj.SimulinkModel = 'bpmn_simulink_model';
                end
            else
                error('Input must be either a file path or a BPMNGenerator instance');
            end
            
            % Initialize process elements structure
            obj.ProcessElements = struct('startEvents', {{}}, 'endEvents', {{}}, ...
                'tasks', {{}}, 'gateways', {{}}, 'sequenceFlows', {{}});
            
            % Initialize block mapping
            obj.BlockMapping = containers.Map();
        end
        
        function setModelName(obj, modelName)
            % Set the name of the Simulink model
            % modelName: Name for the Simulink model file
            obj.SimulinkModel = modelName;
        end
        
        function parseProcess(obj)
            % Extract BPMN process elements from the XML document
            
            % Parse start events
            startEventNodes = obj.XMLDoc.getElementsByTagName('startEvent');
            for i = 0:startEventNodes.getLength()-1
                startEventNode = startEventNodes.item(i);
                eventId = char(startEventNode.getAttribute('id'));
                eventName = char(startEventNode.getAttribute('name'));
                if isempty(eventName)
                    eventName = ['Start_', eventId];
                end
                
                % Get outgoing sequence flows
                outgoingFlows = obj.getOutgoingFlows(eventId);
                
                % Create start event structure
                startEvent = struct('id', eventId, 'name', eventName, 'outgoingFlows', {outgoingFlows});
                obj.ProcessElements.startEvents{end+1} = startEvent;
            end
            
            % Parse end events
            endEventNodes = obj.XMLDoc.getElementsByTagName('endEvent');
            for i = 0:endEventNodes.getLength()-1
                endEventNode = endEventNodes.item(i);
                eventId = char(endEventNode.getAttribute('id'));
                eventName = char(endEventNode.getAttribute('name'));
                if isempty(eventName)
                    eventName = ['End_', eventId];
                end
                
                % Get incoming sequence flows
                incomingFlows = obj.getIncomingFlows(eventId);
                
                % Create end event structure
                endEvent = struct('id', eventId, 'name', eventName, 'incomingFlows', {incomingFlows});
                obj.ProcessElements.endEvents{end+1} = endEvent;
            end
            
            % Parse tasks (all types)
            taskTypes = {'task', 'userTask', 'serviceTask', 'scriptTask', 'businessRuleTask', 'manualTask', 'receiveTask', 'sendTask'};
            for t = 1:length(taskTypes)
                taskType = taskTypes{t};
                taskNodes = obj.XMLDoc.getElementsByTagName(taskType);
                
                for i = 0:taskNodes.getLength()-1
                    taskNode = taskNodes.item(i);
                    taskId = char(taskNode.getAttribute('id'));
                    taskName = char(taskNode.getAttribute('name'));
                    if isempty(taskName)
                        taskName = [taskType, '_', taskId];
                    end
                    
                    % Get incoming and outgoing sequence flows
                    incomingFlows = obj.getIncomingFlows(taskId);
                    outgoingFlows = obj.getOutgoingFlows(taskId);
                    
                    % Create task structure
                    task = struct('id', taskId, 'name', taskName, 'type', taskType, ...
                        'incomingFlows', {incomingFlows}, 'outgoingFlows', {outgoingFlows});
                    obj.ProcessElements.tasks{end+1} = task;
                end
            end
            
            % Parse gateways
            gatewayTypes = {'exclusiveGateway', 'inclusiveGateway', 'parallelGateway', 'eventBasedGateway', 'complexGateway'};
            for t = 1:length(gatewayTypes)
                gatewayType = gatewayTypes{t};
                gatewayNodes = obj.XMLDoc.getElementsByTagName(gatewayType);
                
                for i = 0:gatewayNodes.getLength()-1
                    gatewayNode = gatewayNodes.item(i);
                    gatewayId = char(gatewayNode.getAttribute('id'));
                    gatewayName = char(gatewayNode.getAttribute('name'));
                    if isempty(gatewayName)
                        gatewayName = [gatewayType, '_', gatewayId];
                    end
                    
                    % Get incoming and outgoing sequence flows
                    incomingFlows = obj.getIncomingFlows(gatewayId);
                    outgoingFlows = obj.getOutgoingFlows(gatewayId);
                    
                    % Create gateway structure
                    gateway = struct('id', gatewayId, 'name', gatewayName, 'type', gatewayType, ...
                        'incomingFlows', {incomingFlows}, 'outgoingFlows', {outgoingFlows});
                    obj.ProcessElements.gateways{end+1} = gateway;
                end
            end
            
            % Parse sequence flows
            flowNodes = obj.XMLDoc.getElementsByTagName('sequenceFlow');
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                flowId = char(flowNode.getAttribute('id'));
                sourceRef = char(flowNode.getAttribute('sourceRef'));
                targetRef = char(flowNode.getAttribute('targetRef'));
                
                % Check for condition expression
                conditionNode = flowNode.getElementsByTagName('conditionExpression');
                condition = '';
                if conditionNode.getLength() > 0
                    condition = obj.getTextContent(conditionNode.item(0));
                end
                
                % Create sequence flow structure
                sequenceFlow = struct('id', flowId, 'sourceRef', sourceRef, ...
                    'targetRef', targetRef, 'condition', condition);
                obj.ProcessElements.sequenceFlows{end+1} = sequenceFlow;
            end
        end
        
        function model = convertToSimulink(obj)
            % Convert BPMN process to Simulink model
            % Returns the name of the created Simulink model
            
            % Check if process elements have been parsed
            if isempty(obj.ProcessElements.startEvents) && isempty(obj.ProcessElements.tasks) && ...
                    isempty(obj.ProcessElements.gateways) && isempty(obj.ProcessElements.sequenceFlows)
                obj.parseProcess();
            end
            
            % Close any open model with the same name
            if bdIsLoaded(obj.SimulinkModel)
                close_system(obj.SimulinkModel, 0);
            end
            
            % Create a new Simulink model
            model = new_system(obj.SimulinkModel);
            open_system(model);
            
            % Set model parameters
            set_param(model, 'SolverType', 'Fixed-step');
            set_param(model, 'FixedStep', '1.0');
            set_param(model, 'StopTime', '100');
            
            % Create blocks for BPMN elements
            obj.createStartEventBlocks(model);
            obj.createEndEventBlocks(model);
            obj.createTaskBlocks(model);
            obj.createGatewayBlocks(model);
            
            % Connect blocks with lines based on sequence flows
            obj.createConnectionLines(model);
            
            % Arrange blocks automatically
            obj.arrangeBlocks(model);
            
            % Save the model
            save_system(model);
        end
        
        function simulateModel(obj, stopTime)
            % Simulate the Simulink model
            % stopTime: Optional simulation stop time
            
            if nargin > 1
                set_param(obj.SimulinkModel, 'StopTime', num2str(stopTime));
            end
            
            % Check if model exists
            if ~bdIsLoaded(obj.SimulinkModel)
                error('Simulink model %s is not loaded. Call convertToSimulink first.', obj.SimulinkModel);
            end
            
            % Run simulation
            disp(['Simulating BPMN process in Simulink model: ', obj.SimulinkModel]);
            sim(obj.SimulinkModel);
            disp('Simulation complete');
        end
    end
    
    % Private helper methods
    methods (Access = private)
        function flows = getOutgoingFlows(obj, elementId)
            % Get outgoing sequence flows for an element
            flows = {};
            
            flowNodes = obj.XMLDoc.getElementsByTagName('sequenceFlow');
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                sourceRef = char(flowNode.getAttribute('sourceRef'));
                if strcmp(sourceRef, elementId)
                    flowId = char(flowNode.getAttribute('id'));
                    flows{end+1} = flowId;
                end
            end
        end
        
        function flows = getIncomingFlows(obj, elementId)
            % Get incoming sequence flows for an element
            flows = {};
            
            flowNodes = obj.XMLDoc.getElementsByTagName('sequenceFlow');
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                targetRef = char(flowNode.getAttribute('targetRef'));
                if strcmp(targetRef, elementId)
                    flowId = char(flowNode.getAttribute('id'));
                    flows{end+1} = flowId;
                end
            end
        end
        
        function textContent = getTextContent(obj, node)
            % Get text content of an XML node
            textContent = '';
            
            childNodes = node.getChildNodes();
            for i = 0:childNodes.getLength()-1
                child = childNodes.item(i);
                if child.getNodeType() == 3 % Text node
                    textContent = strcat(textContent, char(child.getNodeValue()));
                end
            end
            
            % Trim whitespace
            textContent = strtrim(textContent);
        end
        
        function createStartEventBlocks(obj, model)
            % Create Simulink blocks for start events
            
            for i = 1:length(obj.ProcessElements.startEvents)
                startEvent = obj.ProcessElements.startEvents{i};
                
                % Create a Simulink Stateflow chart for the start event
                chartPath = [model, '/Start_', startEvent.id];
                startBlock = add_block('built-in/Chart', chartPath);
                
                % Configure the block
                set_param(startBlock, 'Position', [100, 100+100*i, 150, 150+100*i]);
                set_param(startBlock, 'Name', startEvent.name);
                
                % Store the block path in the mapping
                obj.BlockMapping(startEvent.id) = chartPath;
                
                % Configure the Stateflow chart
                rt = sfroot;
                chart = rt.find('-isa', 'Stateflow.Chart', 'Path', chartPath);
                
                % Add an output data port for triggering the next element
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
                trans.LabelString = 'after(0.1, sec) {out1=1;}';
            end
        end
        
        function createEndEventBlocks(obj, model)
            % Create Simulink blocks for end events
            
            for i = 1:length(obj.ProcessElements.endEvents)
                endEvent = obj.ProcessElements.endEvents{i};
                
                % Create a Simulink Stateflow chart for the end event
                chartPath = [model, '/End_', endEvent.id];
                endBlock = add_block('built-in/Chart', chartPath);
                
                % Configure the block
                set_param(endBlock, 'Position', [800, 100+100*i, 850, 150+100*i]);
                set_param(endBlock, 'Name', endEvent.name);
                
                % Store the block path in the mapping
                obj.BlockMapping(endEvent.id) = chartPath;
                
                % Configure the Stateflow chart
                rt = sfroot;
                chart = rt.find('-isa', 'Stateflow.Chart', 'Path', chartPath);
                
                % Add an input data port for receiving triggers
                chart.Inputs = 'in1';
                
                % Add states for the end event
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
                trans.LabelString = 'in1 == 1';
            end
        end
        
        function createTaskBlocks(obj, model)
            % Create Simulink blocks for tasks
            
            for i = 1:length(obj.ProcessElements.tasks)
                task = obj.ProcessElements.tasks{i};
                
                % Create a Simulink Stateflow chart for the task
                chartPath = [model, '/Task_', task.id];
                taskBlock = add_block('built-in/Chart', chartPath);
                
                % Configure the block
                set_param(taskBlock, 'Position', [300, 100+100*i, 400, 150+100*i]);
                set_param(taskBlock, 'Name', task.name);
                
                % Store the block path in the mapping
                obj.BlockMapping(task.id) = chartPath;
                
                % Configure the Stateflow chart
                rt = sfroot;
                chart = rt.find('-isa', 'Stateflow.Chart', 'Path', chartPath);
                
                % Add input and output data ports
                chart.Inputs = 'in1';
                chart.Outputs = 'out1';
                
                % Add states for the task
                waiting = Stateflow.State(chart);
                waiting.Name = 'Waiting';
                waiting.Position = [50, 50, 70, 50];
                
                inProgress = Stateflow.State(chart);
                inProgress.Name = 'InProgress';
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
                trans1.LabelString = 'in1 == 1';
                
                trans2 = Stateflow.Transition(chart);
                trans2.Source = inProgress;
                trans2.Destination = completed;
                trans2.SourceOClock = 3;
                trans2.DestinationOClock = 9;
                
                % Different execution time based on task type
                executionTime = 1;
                if contains(task.type, 'user')
                    executionTime = 3;
                elseif contains(task.type, 'service')
                    executionTime = 0.5;
                elseif contains(task.type, 'script')
                    executionTime = 0.2;
                end
                
                trans2.LabelString = ['after(', num2str(executionTime), ', sec) {out1=1;}'];
            end
        end
        
        function createGatewayBlocks(obj, model)
            % Create Simulink blocks for gateways
            
            for i = 1:length(obj.ProcessElements.gateways)
                gateway = obj.ProcessElements.gateways{i};
                
                % Create a Simulink Stateflow chart for the gateway
                chartPath = [model, '/Gateway_', gateway.id];
                gatewayBlock = add_block('built-in/Chart', chartPath);
                
                % Configure the block
                set_param(gatewayBlock, 'Position', [500, 100+100*i, 550, 150+100*i]);
                set_param(gatewayBlock, 'Name', gateway.name);
                
                % Store the block path in the mapping
                obj.BlockMapping(gateway.id) = chartPath;
                
                % Configure the Stateflow chart
                rt = sfroot;
                chart = rt.find('-isa', 'Stateflow.Chart', 'Path', chartPath);
                
                % Set up inputs and outputs based on the number of flows
                numInputs = length(gateway.incomingFlows);
                numOutputs = length(gateway.outgoingFlows);
                
                inputStr = '';
                for j = 1:numInputs
                    if j > 1
                        inputStr = [inputStr, ','];
                    end
                    inputStr = [inputStr, 'in', num2str(j)];
                end
                chart.Inputs = inputStr;
                
                outputStr = '';
                for j = 1:numOutputs
                    if j > 1
                        outputStr = [outputStr, ','];
                    end
                    outputStr = [outputStr, 'out', num2str(j)];
                end
                chart.Outputs = outputStr;
                
                % Add states and transitions based on gateway type
                if strcmp(gateway.type, 'exclusiveGateway')
                    % Exclusive (XOR) gateway implementation
                    obj.configureExclusiveGateway(chart, numInputs, numOutputs);
                elseif strcmp(gateway.type, 'parallelGateway')
                    % Parallel (AND) gateway implementation
                    obj.configureParallelGateway(chart, numInputs, numOutputs);
                elseif strcmp(gateway.type, 'inclusiveGateway')
                    % Inclusive (OR) gateway implementation
                    obj.configureInclusiveGateway(chart, numInputs, numOutputs);
                else
                    % Default gateway implementation
                    obj.configureDefaultGateway(chart, numInputs, numOutputs);
                end
            end
        end
        
        function configureExclusiveGateway(obj, chart, numInputs, numOutputs)
            % Configure stateflow chart for an exclusive gateway
            
            % Create states
            waiting = Stateflow.State(chart);
            waiting.Name = 'Waiting';
            waiting.Position = [50, 50, 70, 50];
            
            deciding = Stateflow.State(chart);
            deciding.Name = 'Deciding';
            deciding.Position = [200, 50, 70, 50];
            
            % Add transition from waiting to deciding
            trans = Stateflow.Transition(chart);
            trans.Source = waiting;
            trans.Destination = deciding;
            
            % Build condition for transition
            condition = '';
            for i = 1:numInputs
                if i > 1
                    condition = [condition, ' | '];
                end
                condition = [condition, 'in', num2str(i), ' == 1'];
            end
            trans.LabelString = condition;
            
            % Add self-transition for deciding state that sets outputs
            for j = 1:numOutputs
                outTrans = Stateflow.Transition(chart);
                outTrans.Source = deciding;
                outTrans.Destination = deciding;
                outTrans.SourceOClock = 6 + j;
                outTrans.DestinationOClock = 6 + j + 2;
                
                % In a real implementation, this would use conditions from sequence flows
                % We're using probabilities for demonstration
                probability = 1.0 / numOutputs;
                condition = ['prob(', num2str(probability), ') {out', num2str(j), '=1;}'];
                outTrans.LabelString = condition;
            end
        end
        
        function configureParallelGateway(obj, chart, numInputs, numOutputs)
            % Configure stateflow chart for a parallel gateway
            
            % Create states
            waiting = Stateflow.State(chart);
            waiting.Name = 'Waiting';
            waiting.Position = [50, 50, 70, 50];
            
            allInputsReceived = Stateflow.State(chart);
            allInputsReceived.Name = 'AllInputsReceived';
            allInputsReceived.Position = [200, 50, 100, 50];
            
            activatedOutputs = Stateflow.State(chart);
            activatedOutputs.Name = 'ActivatedOutputs';
            activatedOutputs.Position = [350, 50, 100, 50];
            
            % Add transition from waiting to allInputsReceived
            trans = Stateflow.Transition(chart);
            trans.Source = waiting;
            trans.Destination = allInputsReceived;
            
            % Build condition - all inputs must be received
            condition = '';
            for i = 1:numInputs
                if i > 1
                    condition = [condition, ' & '];
                end
                condition = [condition, 'in', num2str(i), ' == 1'];
            end
            trans.LabelString = condition;
            
            % Add transition to activate all outputs
            trans2 = Stateflow.Transition(chart);
            trans2.Source = allInputsReceived;
            trans2.Destination = activatedOutputs;
            
            % Activate all outputs
            outputAction = '';
            for j = 1:numOutputs
                if j > 1
                    outputAction = [outputAction, ' '];
                end
                outputAction = [outputAction, 'out', num2str(j), '=1;'];
            end
            trans2.LabelString = outputAction;
        end
        
        function configureInclusiveGateway(obj, chart, numInputs, numOutputs)
            % Configure stateflow chart for an inclusive gateway
            
            % Create states
            waiting = Stateflow.State(chart);
            waiting.Name = 'Waiting';
            waiting.Position = [50, 50, 70, 50];
            
            deciding = Stateflow.State(chart);
            deciding.Name = 'Deciding';
            deciding.Position = [200, 50, 70, 50];
            
            % Add transition from waiting to deciding
            trans = Stateflow.Transition(chart);
            trans.Source = waiting;
            trans.Destination = deciding;
            
            % Build condition - at least one input must be received
            condition = '';
            for i = 1:numInputs
                if i > 1
                    condition = [condition, ' | '];
                end
                condition = [condition, 'in', num2str(i), ' == 1'];
            end
            trans.LabelString = condition;
            
            % Add self-transition for deciding state that sets outputs
            % In a real implementation, this would use conditions from sequence flows
            for j = 1:numOutputs
                outTrans = Stateflow.Transition(chart);
                outTrans.Source = deciding;
                outTrans.Destination = deciding;
                outTrans.SourceOClock = 6 + j;
                outTrans.DestinationOClock = 6 + j + 2;
                
                % For inclusive gateway, each output has a 50% chance of activation
                outTrans.LabelString = ['prob(0.5) {out', num2str(j), '=1;}'];
            end
        end
        
        function configureDefaultGateway(obj, chart, numInputs, numOutputs)
            % Configure stateflow chart for a default gateway
            
            % Create states
            waiting = Stateflow.State(chart);
            waiting.Name = 'Waiting';
            waiting.Position = [50, 50, 70, 50];
            
            active = Stateflow.State(chart);
            active.Name = 'Active';
            active.Position = [200, 50, 70, 50];
            
            % Add transition from waiting to active
            trans = Stateflow.Transition(chart);
            trans.Source = waiting;
            trans.Destination = active;
            
            % Build condition for transition - any input activates
            condition = '';
            for i = 1:numInputs
                if i > 1
                    condition = [condition, ' | '];
                end
                condition = [condition, 'in', num2str(i), ' == 1'];
            end
            trans.LabelString = condition;
            
            % Add action to activate first output
            if numOutputs > 0
                trans.LabelString = [trans.LabelString, ' {out1=1;}'];
            end
        end
        
        function createConnectionLines(obj, model)
            % Create connections between blocks based on sequence flows
            
            for i = 1:length(obj.ProcessElements.sequenceFlows)
                flow = obj.ProcessElements.sequenceFlows{i};
                sourceId = flow.sourceRef;
                targetId = flow.targetRef;
                
                % Check if source and target blocks exist in the mapping
                if isKey(obj.BlockMapping, sourceId) && isKey(obj.BlockMapping, targetId)
                    sourceBlock = obj.BlockMapping(sourceId);
                    targetBlock = obj.BlockMapping(targetId);
                    
                    % Determine port numbers for source and target
                    % This is simplified; a more complete implementation would track port usage
                    sourcePort = 1;
                    targetPort = 1;
                    
                    % For source, find outport number based on its outgoing flows
                    sourceElement = obj.findElementById(sourceId);
                    if ~isempty(sourceElement) && isfield(sourceElement, 'outgoingFlows')
                        for j = 1:length(sourceElement.outgoingFlows)
                            if strcmp(sourceElement.outgoingFlows{j}, flow.id)
                                sourcePort = j;
                                break;
                            end
                        end
                    end
                    
                    % For target, find inport number based on its incoming flows
                    targetElement = obj.findElementById(targetId);
                    if ~isempty(targetElement) && isfield(targetElement, 'incomingFlows')
                        for j = 1:length(targetElement.incomingFlows)
                            if strcmp(targetElement.incomingFlows{j}, flow.id)
                                targetPort = j;
                                break;
                            end
                        end
                    end
                    
                    % Create the connection line
                    try
                        line = add_line(model, [sourceBlock, '/out', num2str(sourcePort)], ...
                            [targetBlock, '/in', num2str(targetPort)], 'autorouting', 'on');
                    catch e
                        warning('Could not create connection for flow %s: %s', flow.id, e.message);
                    end
                end
            end
        end
        
        function element = findElementById(obj, elementId)
            % Find a BPMN element by its ID
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
            % Arrange blocks in the Simulink model automatically
            
            try
                % Use Simulink's automatic layout
                Simulink.BlockDiagram.arrangeSystem(model);
            catch e
                warning('Could not arrange blocks automatically: %s', e.message);
                
                % Fallback - basic arrangement based on BPMN flow
                obj.manualArrangeBlocks(model);
            end
        end
        
        function manualArrangeBlocks(obj, model)
            % Manual arrangement of blocks in a left-to-right process flow
            
            % Start with start events on the left
            x = 100;
            y = 100;
            spacing = 150;
            
            % Arrange start events
            for i = 1:length(obj.ProcessElements.startEvents)
                startEvent = obj.ProcessElements.startEvents{i};
                if isKey(obj.BlockMapping, startEvent.id)
                    blockPath = obj.BlockMapping(startEvent.id);
                    pos = get_param(blockPath, 'Position');
                    width = pos(3) - pos(1);
                    height = pos(4) - pos(2);
                    set_param(blockPath, 'Position', [x, y, x+width, y+height]);
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
                    pos = get_param(blockPath, 'Position');
                    width = pos(3) - pos(1);
                    height = pos(4) - pos(2);
                    set_param(blockPath, 'Position', [x, y, x+width, y+height]);
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
                    pos = get_param(blockPath, 'Position');
                    width = pos(3) - pos(1);
                    height = pos(4) - pos(2);
                    set_param(blockPath, 'Position', [x, y, x+width, y+height]);
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
                    pos = get_param(blockPath, 'Position');
                    width = pos(3) - pos(1);
                    height = pos(4) - pos(2);
                    set_param(blockPath, 'Position', [x, y, x+width, y+height]);
                    y = y + spacing;
                end
            end
        end
    end
end