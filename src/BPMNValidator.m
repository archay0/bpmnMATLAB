classdef BPMNValidator < handle
    % BPMNValidator Validates BPMN diagrams according to BPMN 2.0 specification
    %   This class provides comprehensive validation of BPMN diagrams to ensure
    %   they follow the BPMN 2.0 specification and are structurally sound
    
    properties
        FilePath            % Path to the BPMN file
        XMLDoc              % XML document object
        ValidationResults   % Results of validation
    end
    
    methods
        function obj = BPMNValidator(filePath)
            % Constructor for BPMNValidator
            %   filePath: Path to the BPMN file to validate
            
            obj.FilePath = filePath;
            obj.ValidationResults = struct('errors', {}, 'warnings', {});
            
            % Load XML document if file exists
            if exist(filePath, 'file')
                obj.XMLDoc = xmlread(filePath);
            else
                error('BPMN file not found: %s', filePath);
            end
        end
        
        function validate(obj)
            % Validate the BPMN file against BPMN 2.0 specification
            %   Performs multiple validation checks and stores results
            
            % Reset validation results
            obj.ValidationResults = struct('errors', {{}}, 'warnings', {{}});
            
            % Check BPMN namespace and structure
            obj.validateBPMNNamespace();
            
            % Validate process elements
            obj.validateProcessElements();
            
            % Validate sequence flows
            obj.validateSequenceFlows();
            
            % Validate gateway flows
            obj.validateGateways();
            
            % Validate event definitions
            obj.validateEventDefinitions();
            
            % Validate collaboration elements
            obj.validateCollaborationElements();
            
            % Validate data elements and associations
            obj.validateDataElements();
        end
        
        function results = getValidationResults(obj)
            % Get the validation results
            %   Returns a structure with errors and warnings
            
            results = obj.ValidationResults;
        end
        
        function printValidationResults(obj)
            % Print validation results to console
            
            fprintf('\nBPMN Validation Results for: %s\n', obj.FilePath);
            fprintf('----------------------------------------\n');
            
            % Print errors
            if ~isempty(obj.ValidationResults.errors)
                fprintf('\nErrors (%d):\n', length(obj.ValidationResults.errors));
                for i = 1:length(obj.ValidationResults.errors)
                    fprintf('  - %s\n', obj.ValidationResults.errors{i});
                end
            else
                fprintf('\nNo errors found.\n');
            end
            
            % Print warnings
            if ~isempty(obj.ValidationResults.warnings)
                fprintf('\nWarnings (%d):\n', length(obj.ValidationResults.warnings));
                for i = 1:length(obj.ValidationResults.warnings)
                    fprintf('  - %s\n', obj.ValidationResults.warnings{i});
                end
            else
                fprintf('\nNo warnings found.\n');
            end
            
            fprintf('\nValidation complete.\n');
        end
    end
    
    methods (Access = private)
        function validateBPMNNamespace(obj)
            % Validate BPMN namespace and root element
            
            % Get root element
            rootNode = obj.XMLDoc.getDocumentElement();
            
            % Check if root element is 'definitions'
            if ~strcmp(char(rootNode.getNodeName()), 'definitions') && ...
               ~strcmp(char(rootNode.getNodeName()), 'bpmn:definitions')
                obj.addError('Root element is not "definitions"');
            end
            
            % Check for BPMN namespace
            namespaceURI = char(rootNode.getAttribute('xmlns:bpmn'));
            if isempty(namespaceURI)
                namespaceURI = char(rootNode.getAttribute('xmlns'));
            end
            
            if isempty(namespaceURI) || ~contains(namespaceURI, 'bpmn')
                obj.addError('Missing BPMN namespace declaration');
            end
        end
        
        function validateProcessElements(obj)
            % Validate process elements (events, tasks, etc.)
            
            % Get all processes
            processes = obj.getAllElements('process');
            
            if processes.getLength() == 0
                obj.addWarning('No processes defined');
                return;
            end
            
            % Check each process
            for i = 0:processes.getLength()-1
                process = processes.item(i);
                processId = char(process.getAttribute('id'));
                
                % Check for start events
                startEvents = obj.getChildElements(process, 'startEvent');
                if startEvents.getLength() == 0
                    obj.addWarning(sprintf('Process "%s" has no start event', processId));
                end
                
                % Check for end events
                endEvents = obj.getChildElements(process, 'endEvent');
                if endEvents.getLength() == 0
                    obj.addWarning(sprintf('Process "%s" has no end event', processId));
                end
                
                % Check all flow nodes for required attributes
                obj.validateFlowNodeAttributes(process, processId);
            end
        end
        
        function validateFlowNodeAttributes(obj, process, processId)
            % Validate attributes of all flow nodes in a process
            
            % List of flow node types to check
            nodeTypes = {'task', 'userTask', 'serviceTask', 'scriptTask', 'sendTask', ...
                        'receiveTask', 'manualTask', 'businessRuleTask', ...
                        'exclusiveGateway', 'inclusiveGateway', 'parallelGateway', 'complexGateway', ...
                        'startEvent', 'endEvent', 'intermediateCatchEvent', 'intermediateThrowEvent'};
            
            % Check each type
            for t = 1:length(nodeTypes)
                nodes = obj.getChildElements(process, nodeTypes{t});
                
                for n = 0:nodes.getLength()-1
                    node = nodes.item(n);
                    nodeId = char(node.getAttribute('id'));
                    
                    % Check for required id attribute
                    if isempty(nodeId)
                        obj.addError(sprintf('%s in process "%s" is missing id attribute', nodeTypes{t}, processId));
                    end
                    
                    % Check node-specific requirements
                    if strcmp(nodeTypes{t}, 'exclusiveGateway') || strcmp(nodeTypes{t}, 'inclusiveGateway')
                        % Check if gateway has outgoing flows
                        if ~obj.hasOutgoingFlows(process, nodeId)
                            obj.addWarning(sprintf('Gateway "%s" in process "%s" has no outgoing sequence flows', nodeId, processId));
                        end
                        
                        % For exclusive gateway with multiple outgoing flows
                        if obj.countOutgoingFlows(process, nodeId) > 1
                            % Check for conditions
                            if ~obj.hasConditionsOnFlows(process, nodeId)
                                obj.addWarning(sprintf('Exclusive gateway "%s" has multiple outgoing flows without conditions', nodeId));
                            end
                        end
                    end
                    
                    % Check for disconnected nodes
                    if ~strcmp(nodeTypes{t}, 'startEvent') && ~obj.hasIncomingFlows(process, nodeId)
                        obj.addWarning(sprintf('%s "%s" has no incoming sequence flows', nodeTypes{t}, nodeId));
                    end
                    
                    if ~strcmp(nodeTypes{t}, 'endEvent') && ~obj.hasOutgoingFlows(process, nodeId)
                        obj.addWarning(sprintf('%s "%s" has no outgoing sequence flows', nodeTypes{t}, nodeId));
                    end
                end
            end
        end
        
        function validateSequenceFlows(obj)
            % Validate sequence flows
            
            % Get all sequence flows
            flows = obj.getAllElements('sequenceFlow');
            
            for i = 0:flows.getLength()-1
                flow = flows.item(i);
                flowId = char(flow.getAttribute('id'));
                sourceRef = char(flow.getAttribute('sourceRef'));
                targetRef = char(flow.getAttribute('targetRef'));
                
                % Check for required attributes
                if isempty(flowId)
                    obj.addError('Sequence flow is missing id attribute');
                    continue;
                end
                
                if isempty(sourceRef)
                    obj.addError(sprintf('Sequence flow "%s" is missing sourceRef attribute', flowId));
                end
                
                if isempty(targetRef)
                    obj.addError(sprintf('Sequence flow "%s" is missing targetRef attribute', flowId));
                end
                
                % Check that source and target elements exist
                if ~isempty(sourceRef) && ~obj.elementExists(sourceRef)
                    obj.addError(sprintf('Sequence flow "%s" references non-existent source element "%s"', flowId, sourceRef));
                end
                
                if ~isempty(targetRef) && ~obj.elementExists(targetRef)
                    obj.addError(sprintf('Sequence flow "%s" references non-existent target element "%s"', flowId, targetRef));
                end
                
                % Validate conditions
                conditions = flow.getElementsByTagName('conditionExpression');
                if conditions.getLength() > 0
                    % Check if source is a gateway
                    if ~obj.isGateway(sourceRef)
                        obj.addWarning(sprintf('Sequence flow "%s" has condition but source "%s" is not a gateway', flowId, sourceRef));
                    end
                end
            end
        end
        
        function validateGateways(obj)
            % Validate gateway configurations
            
            % Check exclusive gateways
            exclusiveGateways = obj.getAllElements('exclusiveGateway');
            for i = 0:exclusiveGateways.getLength()-1
                gateway = exclusiveGateways.item(i);
                gatewayId = char(gateway.getAttribute('id'));
                
                % Check for default flow
                defaultFlow = char(gateway.getAttribute('default'));
                if ~isempty(defaultFlow) && ~obj.flowExists(defaultFlow)
                    obj.addError(sprintf('Exclusive gateway "%s" references non-existent default flow "%s"', gatewayId, defaultFlow));
                end
                
                % Count outgoing flows
                outgoingCount = obj.countOutgoingFlows(gateway.getParentNode(), gatewayId);
                if outgoingCount > 1
                    % Should have conditions on flows
                    unconditionedFlows = obj.countUnconditionedOutgoingFlows(gateway.getParentNode(), gatewayId);
                    if unconditionedFlows > 0 && isempty(defaultFlow)
                        obj.addWarning(sprintf('Exclusive gateway "%s" has %d outgoing flows without conditions and no default flow', gatewayId, unconditionedFlows));
                    end
                end
            end
            
            % Check parallel gateways
            parallelGateways = obj.getAllElements('parallelGateway');
            for i = 0:parallelGateways.getLength()-1
                gateway = parallelGateways.item(i);
                gatewayId = char(gateway.getAttribute('id'));
                
                % Should have at least two outgoing or incoming flows
                outgoingCount = obj.countOutgoingFlows(gateway.getParentNode(), gatewayId);
                incomingCount = obj.countIncomingFlows(gateway.getParentNode(), gatewayId);
                
                if max(outgoingCount, incomingCount) < 2
                    obj.addWarning(sprintf('Parallel gateway "%s" should have at least 2 incoming or outgoing flows', gatewayId));
                end
                
                % Should not have conditions on parallel gateway flows
                if obj.hasConditionsOnFlows(gateway.getParentNode(), gatewayId)
                    obj.addWarning(sprintf('Parallel gateway "%s" should not have conditions on outgoing flows', gatewayId));
                end
            end
        end
        
        function validateEventDefinitions(obj)
            % Validate event definitions
            
            % Check boundary events
            boundaryEvents = obj.getAllElements('boundaryEvent');
            for i = 0:boundaryEvents.getLength()-1
                event = boundaryEvents.item(i);
                eventId = char(event.getAttribute('id'));
                attachedToRef = char(event.getAttribute('attachedToRef'));
                
                if isempty(attachedToRef)
                    obj.addError(sprintf('Boundary event "%s" is missing attachedToRef attribute', eventId));
                elseif ~obj.elementExists(attachedToRef)
                    obj.addError(sprintf('Boundary event "%s" references non-existent element "%s"', eventId, attachedToRef));
                end
                
                % Check for event definition
                if event.getElementsByTagName('errorEventDefinition').getLength() == 0 && ...
                   event.getElementsByTagName('timerEventDefinition').getLength() == 0 && ...
                   event.getElementsByTagName('messageEventDefinition').getLength() == 0 && ...
                   event.getElementsByTagName('signalEventDefinition').getLength() == 0 && ...
                   event.getElementsByTagName('escalationEventDefinition').getLength() == 0 && ...
                   event.getElementsByTagName('compensationEventDefinition').getLength() == 0 && ...
                   event.getElementsByTagName('conditionalEventDefinition').getLength() == 0
                    obj.addWarning(sprintf('Boundary event "%s" has no event definition', eventId));
                end
            end
            
            % Check start events
            startEvents = obj.getAllElements('startEvent');
            for i = 0:startEvents.getLength()-1
                event = startEvents.item(i);
                eventId = char(event.getAttribute('id'));
                
                % Start events with message/signal definitions should be in processes referenced by participants
                if event.getElementsByTagName('messageEventDefinition').getLength() > 0 || ...
                   event.getElementsByTagName('signalEventDefinition').getLength() > 0
                   
                   processId = char(event.getParentNode().getAttribute('id'));
                   if ~obj.isProcessReferencedByParticipant(processId)
                       obj.addWarning(sprintf('Start event "%s" with message/signal should be in a process referenced by a participant', eventId));
                   end
                end
            end
        end
        
        function validateCollaborationElements(obj)
            % Validate collaboration elements (pools, lanes, message flows)
            
            % Check for collaborations
            collaborations = obj.getAllElements('collaboration');
            if collaborations.getLength() == 0
                return;  % No collaborations to validate
            end
            
            % Validate participants
            participants = obj.getAllElements('participant');
            for i = 0:participants.getLength()-1
                participant = participants.item(i);
                participantId = char(participant.getAttribute('id'));
                processRef = char(participant.getAttribute('processRef'));
                
                if isempty(processRef)
                    obj.addWarning(sprintf('Participant "%s" has no processRef attribute', participantId));
                elseif ~obj.processExists(processRef)
                    obj.addError(sprintf('Participant "%s" references non-existent process "%s"', participantId, processRef));
                end
            end
            
            % Validate message flows
            messageFlows = obj.getAllElements('messageFlow');
            for i = 0:messageFlows.getLength()-1
                flow = messageFlows.item(i);
                flowId = char(flow.getAttribute('id'));
                sourceRef = char(flow.getAttribute('sourceRef'));
                targetRef = char(flow.getAttribute('targetRef'));
                
                % Check for required attributes
                if isempty(flowId)
                    obj.addError('Message flow is missing id attribute');
                    continue;
                end
                
                if isempty(sourceRef)
                    obj.addError(sprintf('Message flow "%s" is missing sourceRef attribute', flowId));
                end
                
                if isempty(targetRef)
                    obj.addError(sprintf('Message flow "%s" is missing targetRef attribute', flowId));
                end
                
                % Check that source and target elements exist
                if ~isempty(sourceRef) && !obj.elementExists(sourceRef)
                    obj.addError(sprintf('Message flow "%s" references non-existent source element "%s"', flowId, sourceRef));
                end
                
                if !isempty(targetRef) && !obj.elementExists(targetRef)
                    obj.addError(sprintf('Message flow "%s" references non-existent target element "%s"', flowId, targetRef));
                end
                
                % Message flows should be between elements in different pools
                if obj.elementExists(sourceRef) && obj.elementExists(targetRef)
                    sourceProcessId = obj.getProcessForElement(sourceRef);
                    targetProcessId = obj.getProcessForElement(targetRef);
                    
                    if !isempty(sourceProcessId) && !isempty(targetProcessId) && strcmp(sourceProcessId, targetProcessId)
                        obj.addWarning(sprintf('Message flow "%s" should connect elements in different pools', flowId));
                    end
                end
            end
            
            % Validate lanes
            lanes = obj.getAllElements('lane');
            for i = 0:lanes.getLength()-1
                lane = lanes.item(i);
                laneId = char(lane.getAttribute('id'));
                
                % Check flowNodeRefs
                nodeRefs = lane.getElementsByTagName('flowNodeRef');
                for n = 0:nodeRefs.getLength()-1
                    nodeRef = nodeRefs.item(n);
                    refId = char(nodeRef.getTextContent());
                    
                    if !obj.elementExists(refId)
                        obj.addError(sprintf('Lane "%s" references non-existent flow node "%s"', laneId, refId));
                    end
                end
            end
        end
        
        function validateDataElements(obj)
            % Validate data elements and associations
            
            % Validate data objects
            dataObjects = obj.getAllElements('dataObject');
            for i = 0:dataObjects.getLength()-1
                dataObject = dataObjects.item(i);
                dataId = char(dataObject.getAttribute('id'));
                
                % Typically should have associations
                if !obj.hasAssociation(dataId)
                    obj.addWarning(sprintf('Data object "%s" is not connected by associations', dataId));
                end
            end
            
            % Validate data stores
            dataStores = obj.getAllElements('dataStore');
            for i = 0:dataStores.getLength()-1
                dataStore = dataStores.item(i);
                dataId = char(dataStore.getAttribute('id'));
                
                % Typically should have associations
                if !obj.hasAssociation(dataId)
                    obj.addWarning(sprintf('Data store "%s" is not connected by associations', dataId));
                end
            end
            
            % Validate associations
            associations = obj.getAllElements('association');
            for i = 0:associations.getLength()-1
                association = associations.item(i);
                assocId = char(association.getAttribute('id'));
                sourceRef = char(association.getAttribute('sourceRef'));
                targetRef = char(association.getAttribute('targetRef'));
                
                % Check for required attributes
                if isempty(assocId)
                    obj.addError('Association is missing id attribute');
                    continue;
                end
                
                if isempty(sourceRef)
                    obj.addError(sprintf('Association "%s" is missing sourceRef attribute', assocId));
                end
                
                if isempty(targetRef)
                    obj.addError(sprintf('Association "%s" is missing targetRef attribute', assocId));
                end
                
                % Check that source and target elements exist
                if !isempty(sourceRef) && !obj.elementExists(sourceRef)
                    obj.addError(sprintf('Association "%s" references non-existent source element "%s"', assocId, sourceRef));
                end
                
                if !isempty(targetRef) && !obj.elementExists(targetRef)
                    obj.addError(sprintf('Association "%s" references non-existent target element "%s"', assocId, targetRef));
                end
            end
        end
        
        % Helper functions
        function elements = getAllElements(obj, tagName)
            % Get all elements with the specified tag name
            
            % Check if tag name contains namespace prefix
            if !contains(tagName, ':')
                % Try with various namespace prefixes
                elements = obj.XMLDoc.getElementsByTagName(tagName);
                if elements.getLength() == 0
                    elements = obj.XMLDoc.getElementsByTagName(['bpmn:', tagName]);
                end
            else
                elements = obj.XMLDoc.getElementsByTagName(tagName);
            end
        end
        
        function elements = getChildElements(obj, parentNode, tagName)
            % Get child elements of parentNode with the specified tag name
            
            % Check if tag name contains namespace prefix
            if !contains(tagName, ':')
                % Try with various namespace prefixes
                elements = parentNode.getElementsByTagName(tagName);
                if elements.getLength() == 0
                    elements = parentNode.getElementsByTagName(['bpmn:', tagName]);
                end
            else
                elements = parentNode.getElementsByTagName(tagName);
            end
        end
        
        function result = elementExists(obj, elementId)
            % Check if an element with the specified id exists
            
            result = false;
            if isempty(elementId)
                return;
            end
            
            % Get all elements with id attribute
            elements = obj.XMLDoc.getElementsByTagName('*');
            for i = 0:elements.getLength()-1
                element = elements.item(i);
                if element.hasAttribute('id') && strcmp(char(element.getAttribute('id')), elementId)
                    result = true;
                    return;
                end
            end
        end
        
        function result = flowExists(obj, flowId)
            % Check if a sequence flow with the specified id exists
            
            result = false;
            flows = obj.getAllElements('sequenceFlow');
            for i = 0:flows.getLength()-1
                flow = flows.item(i);
                if strcmp(char(flow.getAttribute('id')), flowId)
                    result = true;
                    return;
                end
            end
        end
        
        function result = processExists(obj, processId)
            % Check if a process with the specified id exists
            
            result = false;
            processes = obj.getAllElements('process');
            for i = 0:processes.getLength()-1
                process = processes.item(i);
                if strcmp(char(process.getAttribute('id')), processId)
                    result = true;
                    return;
                end
            end
        end
        
        function result = isProcessReferencedByParticipant(obj, processId)
            % Check if a process is referenced by a participant
            
            result = false;
            participants = obj.getAllElements('participant');
            for i = 0:participants.getLength()-1
                participant = participants.item(i);
                if strcmp(char(participant.getAttribute('processRef')), processId)
                    result = true;
                    return;
                end
            end
        end
        
        function result = isGateway(obj, elementId)
            % Check if an element is a gateway
            
            result = false;
            
            % Check gateway types
            gatewayTypes = {'exclusiveGateway', 'inclusiveGateway', 'parallelGateway', 'complexGateway', 'eventBasedGateway'};
            
            for t = 1:length(gatewayTypes)
                gateways = obj.getAllElements(gatewayTypes{t});
                for i = 0:gateways.getLength()-1
                    gateway = gateways.item(i);
                    if strcmp(char(gateway.getAttribute('id')), elementId)
                        result = true;
                        return;
                    end
                end
            end
        end
        
        function result = hasOutgoingFlows(obj, process, nodeId)
            % Check if a node has outgoing sequence flows
            
            result = false;
            flows = obj.getChildElements(process, 'sequenceFlow');
            
            for i = 0:flows.getLength()-1
                flow = flows.item(i);
                sourceRef = char(flow.getAttribute('sourceRef'));
                
                if strcmp(sourceRef, nodeId)
                    result = true;
                    return;
                end
            end
        end
        
        function result = hasIncomingFlows(obj, process, nodeId)
            % Check if a node has incoming sequence flows
            
            result = false;
            flows = obj.getChildElements(process, 'sequenceFlow');
            
            for i = 0:flows.getLength()-1
                flow = flows.item(i);
                targetRef = char(flow.getAttribute('targetRef'));
                
                if strcmp(targetRef, nodeId)
                    result = true;
                    return;
                end
            end
        end
        
        function result = hasConditionsOnFlows(obj, process, nodeId)
            % Check if a node's outgoing flows have conditions
            
            result = false;
            flows = obj.getChildElements(process, 'sequenceFlow');
            
            for i = 0:flows.getLength()-1
                flow = flows.item(i);
                sourceRef = char(flow.getAttribute('sourceRef'));
                
                if strcmp(sourceRef, nodeId)
                    % Check for condition
                    conditions = flow.getElementsByTagName('conditionExpression');
                    if conditions.getLength() > 0
                        result = true;
                        return;
                    end
                end
            end
        end
        
        function count = countOutgoingFlows(obj, process, nodeId)
            % Count outgoing flows from a node
            
            count = 0;
            flows = obj.getChildElements(process, 'sequenceFlow');
            
            for i = 0:flows.getLength()-1
                flow = flows.item(i);
                sourceRef = char(flow.getAttribute('sourceRef'));
                
                if strcmp(sourceRef, nodeId)
                    count = count + 1;
                end
            end
        end
        
        function count = countIncomingFlows(obj, process, nodeId)
            % Count incoming flows to a node
            
            count = 0;
            flows = obj.getChildElements(process, 'sequenceFlow');
            
            for i = 0:flows.getLength()-1
                flow = flows.item(i);
                targetRef = char(flow.getAttribute('targetRef'));
                
                if strcmp(targetRef, nodeId)
                    count = count + 1;
                end
            end
        end
        
        function count = countUnconditionedOutgoingFlows(obj, process, nodeId)
            % Count outgoing flows without conditions
            
            count = 0;
            flows = obj.getChildElements(process, 'sequenceFlow');
            
            for i = 0:flows.getLength()-1
                flow = flows.item(i);
                sourceRef = char(flow.getAttribute('sourceRef'));
                
                if strcmp(sourceRef, nodeId)
                    % Check for absence of condition
                    conditions = flow.getElementsByTagName('conditionExpression');
                    if conditions.getLength() == 0
                        count = count + 1;
                    end
                end
            end
        end
        
        function result = hasAssociation(obj, elementId)
            % Check if an element has associations
            
            result = false;
            associations = obj.getAllElements('association');
            
            for i = 0:associations.getLength()-1
                association = associations.item(i);
                sourceRef = char(association.getAttribute('sourceRef'));
                targetRef = char(association.getAttribute('targetRef'));
                
                if strcmp(sourceRef, elementId) || strcmp(targetRef, elementId)
                    result = true;
                    return;
                end
            end
        end
        
        function processId = getProcessForElement(obj, elementId)
            % Get the process ID containing an element
            
            processId = [];
            
            % Get all processes
            processes = obj.getAllElements('process');
            
            for p = 0:processes.getLength()-1
                process = processes.item(p);
                pId = char(process.getAttribute('id'));
                
                % Check child elements
                elements = process.getElementsByTagName('*');
                for e = 0:elements.getLength()-1
                    element = elements.item(e);
                    if element.hasAttribute('id') && strcmp(char(element.getAttribute('id')), elementId)
                        processId = pId;
                        return;
                    end
                end
            end
        end
        
        function addError(obj, message)
            % Add an error message to validation results
            obj.ValidationResults.errors{end+1} = message;
        end
        
        function addWarning(obj, message)
            % Add a warning message to validation results
            obj.ValidationResults.warnings{end+1} = message;
        end
    end
end