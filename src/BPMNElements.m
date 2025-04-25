classdef BPMNElements
    % BPMNElements Static Class with Utility Functions for Creating BPMN Elements
    % This Class provides static methods to create various BPMN element types
    % and their attributes according to the BPMN 2.0 specification
    
    methods (Static)
        function taskNode = createTask(xmlDoc, id, name, taskType)
            % Create a task node with specified attributes
            % xmlDoc: XML Document Object
            % id: Unique identifier for the task
            % name: Name/label of the task
            % taskType: Type of Task ('userTask', 'serviceTask', 'scriptTask', etc.)
            
            if nargin < 4
                taskType = 'task'; % Default task type
            end
            
            taskNode = xmlDoc.createElement(taskType);
            taskNode.setAttribute('id', id);
            taskNode.setAttribute('name', name);
            
            % Add specific attributes based on task type
            switch taskType
                case 'userTask'
                    taskNode.setAttribute('implementation', 'unspecified');
                case 'serviceTask'
                    taskNode.setAttribute('implementation', 'unspecified');
                case 'scriptTask'
                    taskNode.setAttribute('scriptFormat', 'text/javascript');
                case 'businessRuleTask'
                    taskNode.setAttribute('implementation', 'unspecified');
            end
        end
        
        function gatewayNode = createGateway(xmlDoc, id, name, gatewayType)
            % Create a gateway node with specified attributes
            % xmlDoc: XML Document Object
            % id: Unique identifier for the gateway
            % name: Name/label of the gateway
            % gatewayType: Type of Gateway ('exclusiveGateway', 'parallelGateway', etc.)
            
            gatewayNode = xmlDoc.createElement(gatewayType);
            gatewayNode.setAttribute('id', id);
            
            if ~isempty(name)
                gatewayNode.setAttribute('name', name);
            end
            
            % Add specific attributes based on gateway type
            switch gatewayType
                case 'exclusiveGateway'
                    gatewayNode.setAttribute('gatewayDirection', 'Diverging');
                case 'inclusiveGateway'
                    gatewayNode.setAttribute('gatewayDirection', 'Diverging');
                case 'parallelGateway'
                    gatewayNode.setAttribute('gatewayDirection', 'Diverging');
            end
        end
        
        function eventNode = createEvent(xmlDoc, id, name, eventType, eventDefinition)
            % Create an event node with specified attributes
            % xmlDoc: XML Document Object
            % id: Unique identifier for the event
            % name: Name/label of the event
            % eventType: Type of Event ('startEvent', 'endEvent', 'intermediateThrowEvent', etc.)
            % eventDefinition: Type of Event Definition ('messageEventDefinition', etc.)
            
            eventNode = xmlDoc.createElement(eventType);
            eventNode.setAttribute('id', id);
            
            if ~isempty(name)
                eventNode.setAttribute('name', name);
            end
            
            % Add event definition if specified
            if nargin > 4 && ~isempty(eventDefinition)
                defNode = xmlDoc.createElement(eventDefinition);
                defNode.setAttribute('id', [eventDefinition, '_', id]);
                eventNode.appendChild(defNode);
            end
        end
        
        function flowNode = createSequenceFlow(xmlDoc, id, sourceRef, targetRef, condition)
            % Create a sequence flow element
            % xmlDoc: XML Document Object
            % id: Unique identifier for the flow
            % sourceRef: ID of the source element
            % targetRef: ID of the target element
            % condition: Optional condition expression for the flow
            
            flowNode = xmlDoc.createElement('sequenceFlow');
            flowNode.setAttribute('id', id);
            flowNode.setAttribute('sourceRef', sourceRef);
            flowNode.setAttribute('targetRef', targetRef);
            
            % Add condition if specified
            if nargin > 4 && ~isempty(condition)
                condNode = xmlDoc.createElement('conditionExpression');
                condNode.setAttribute('xsi:type', 'tFormalExpression');
                textNode = xmlDoc.createTextNode(condition);
                condNode.appendChild(textNode);
                flowNode.appendChild(condNode);
            end
        end
        
        function laneSetNode = createLaneSet(xmlDoc, id, lanes)
            % Create a lane set with specified lanes
            % xmlDoc: XML Document Object
            % id: Unique identifier for the lane set
            % lanes: Cell array of structures with lane information
            
            laneSetNode = xmlDoc.createElement('laneSet');
            laneSetNode.setAttribute('id', id);
            
            for i = 1:length(lanes)
                laneNode = xmlDoc.createElement('lane');
                laneNode.setAttribute('id', lanes{i}.id);
                laneNode.setAttribute('name', lanes{i}.name);
                
                % Add flow node references if specified
                if isfield(lanes{i}, 'flowNodeRefs') && ~isempty(lanes{i}.flowNodeRefs)
                    for j = 1:length(lanes{i}.flowNodeRefs)
                        refNode = xmlDoc.createElement('flowNodeRef');
                        textNode = xmlDoc.createTextNode(lanes{i}.flowNodeRefs{j});
                        refNode.appendChild(textNode);
                        laneNode.appendChild(refNode);
                    end
                end
                
                laneSetNode.appendChild(laneNode);
            end
        end
        
        function collabNode = createCollaboration(xmlDoc, id, participants)
            % Create a collaboration with pools/participants
            % xmlDoc: XML Document Object
            % id: Unique identifier for the collaboration
            % participants: Cell array of structures with participant information
            
            collabNode = xmlDoc.createElement('collaboration');
            collabNode.setAttribute('id', id);
            
            for i = 1:length(participants)
                partNode = xmlDoc.createElement('participant');
                partNode.setAttribute('id', participants{i}.id);
                partNode.setAttribute('name', participants{i}.name);
                partNode.setAttribute('processRef', participants{i}.processRef);
                collabNode.appendChild(partNode);
            end
        end
        
        function transactionNode = createTransaction(xmlDoc, id, name, method)
            % Create a transaction subprocess element with specified attributes
            % xmlDoc: XML Document Object
            % id: Unique identifier for the transaction
            % name: Name/label of the transaction
            % method: Transaction method ('Compensate', 'Image', 'Store')
            
            transactionNode = xmlDoc.createElement('transaction');
            transactionNode.setAttribute('id', id);
            
            if ~isempty(name)
                transactionNode.setAttribute('name', name);
            end
            
            % Set transaction method with default to 'Compensate'
            if nargin < 4 || isempty(method)
                method = 'Compensate';
            end
            
            transactionNode.setAttribute('method', method);
            
            % Add standard transaction attributes
            transactionNode.setAttribute('startQuantity', '1');
            transactionNode.setAttribute('completionQuantity', '1');
            transactionNode.setAttribute('isForCompensation', 'false');
        end
        
        function boundaryEventNode = createBoundaryEvent(xmlDoc, id, name, attachedToRef, eventDefinition, cancelActivity)
            % Create a boundary event with specified attributes
            % xmlDoc: XML Document Object
            % id: Unique identifier for the event
            % name: Name/label of the event
            % attachedToRef: ID of the activity this event is attached to
            % eventDefinition: Type of Event Definition
            % cancelActivity: Whether the event interrupts/cancels the activity (true/false)
            
            boundaryEventNode = xmlDoc.createElement('boundaryEvent');
            boundaryEventNode.setAttribute('id', id);
            boundaryEventNode.setAttribute('attachedToRef', attachedToRef);
            
            if nargin < 6
                cancelActivity = true; % Default to interrupting
            end
            
            boundaryEventNode.setAttribute('cancelActivity', BPMNElements.toString(cancelActivity));
            
            if ~isempty(name)
                boundaryEventNode.setAttribute('name', name);
            end
            
            % Add event definition if specified
            if nargin > 4 && ~isempty(eventDefinition)
                defNode = xmlDoc.createElement(eventDefinition);
                defNode.setAttribute('id', [eventDefinition, '_', id]);
                boundaryEventNode.appendChild(defNode);
            end
        end
        
        function compensateEventDefinitionNode = createCompensateEventDefinition(xmlDoc, id, activityRef, waitForCompletion)
            % Create a compensate event definition
            % xmlDoc: XML Document Object
            % id: Unique identifier for the event definition
            % activityRef: Optional reference to the activity to compensate
            % waitForCompletion: Whether to wait for completion before continuing
            
            compensateEventDefinitionNode = xmlDoc.createElement('compensateEventDefinition');
            compensateEventDefinitionNode.setAttribute('id', id);
            
            if nargin >= 3 && ~isempty(activityRef)
                compensateEventDefinitionNode.setAttribute('activityRef', activityRef);
            end
            
            if nargin >= 4 && ~isempty(waitForCompletion)
                compensateEventDefinitionNode.setAttribute('waitForCompletion', BPMNElements.toString(waitForCompletion));
            end
        end
        
        function groupNode = createGroup(xmlDoc, id, categoryValue)
            % Create a group artifact
            % xmlDoc: XML Document Object
            % id: Unique identifier for the group
            % categoryValue: Optional category value reference
            
            groupNode = xmlDoc.createElement('group');
            groupNode.setAttribute('id', id);
            
            if nargin >= 3 && ~isempty(categoryValue)
                groupNode.setAttribute('categoryValueRef', categoryValue);
            end
        end
        
        function categoryNode = createCategory(xmlDoc, id, name)
            % Create a category element
            % xmlDoc: XML Document Object
            % id: Unique identifier for the category
            % name: Name of the category
            
            categoryNode = xmlDoc.createElement('category');
            categoryNode.setAttribute('id', id);
            
            if ~isempty(name)
                categoryNode.setAttribute('name', name);
            end
        end
        
        function gatewayNode = createParallelEventBasedGateway(xmlDoc, id, name)
            % Create a parallel event-based gateway with specified attributes
            % xmlDoc: XML Document Object
            % id: Unique identifier for the gateway
            % name: Name/label of the gateway
            
            gatewayNode = xmlDoc.createElement('eventBasedGateway');
            gatewayNode.setAttribute('id', id);
            
            if ~isempty(name)
                gatewayNode.setAttribute('name', name);
            end
            
            % Set special attributes for parallel event-based gateway
            gatewayNode.setAttribute('instantiate', 'false');
            gatewayNode.setAttribute('eventGatewayType', 'Parallel');
        end
        
        function str = toString(value)
            % Convert any value to string representation
            if islogical(value)
                if value
                    str = 'true';
                else
                    str = 'false';
                end
            elseif isnumeric(value)
                str = num2str(value);
            else
                str = char(value);
            end
        end
    end
end