classdef BPMNElements
    % BPMNElements Static class with utility functions for creating BPMN elements
    % This class provides static methods to create various BPMN element types
    % and their attributes according to the BPMN 2.0 specification
    
    methods (Static)
        function taskNode = createTask(xmlDoc, id, name, taskType)
            % Create a task node with specified attributes
            % xmlDoc: XML document object
            % id: Unique identifier for the task
            % name: Name/label of the task
            % taskType: Type of task ('userTask', 'serviceTask', 'scriptTask', etc.)
            
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
            % xmlDoc: XML document object
            % id: Unique identifier for the gateway
            % name: Name/label of the gateway
            % gatewayType: Type of gateway ('exclusiveGateway', 'parallelGateway', etc.)
            
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
            % xmlDoc: XML document object
            % id: Unique identifier for the event
            % name: Name/label of the event
            % eventType: Type of event ('startEvent', 'endEvent', 'intermediateThrowEvent', etc.)
            % eventDefinition: Type of event definition ('messageEventDefinition', etc.)
            
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
            % xmlDoc: XML document object
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
            % xmlDoc: XML document object
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
        
        function poolNode = createCollaboration(xmlDoc, id, participants)
            % Create a collaboration with pools/participants
            % xmlDoc: XML document object
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
            
            return collabNode;
        end
    end
end