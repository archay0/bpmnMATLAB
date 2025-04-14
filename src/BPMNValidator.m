classdef BPMNValidator < handle
    % BPMNValidator Class for validating BPMN 2.0 files
    %   This class provides functionality for validating BPMN 2.0 XML files
    %   against the specification, checking structural integrity and semantic rules
    
    properties
        XMLDoc          % XML document object
        ValidationLogs  % Structure with validation results
        BPMNVersion     % BPMN version to validate against
        SchemaPath      % Path to BPMN XML schema
        StrictMode      % Whether to enforce all rules or just critical ones
    end
    
    methods
        function obj = BPMNValidator(bpmnFilePath, schemaPath, strictMode)
            % Constructor for BPMNValidator
            % bpmnFilePath: Path to BPMN file to validate
            % schemaPath: Optional path to BPMN XML schema
            % strictMode: Optional flag for strict validation
            
            obj.ValidationLogs = struct('errors', {}, 'warnings', {}, 'info', {});
            obj.BPMNVersion = '2.0';
            
            % Set default schema path if not provided
            if nargin < 2 || isempty(schemaPath)
                currentDir = fileparts(mfilename('fullpath'));
                obj.SchemaPath = fullfile(currentDir, '..', 'schemas', 'BPMN20.xsd');
            else
                obj.SchemaPath = schemaPath;
            end
            
            % Set strict mode
            if nargin < 3
                obj.StrictMode = false;
            else
                obj.StrictMode = strictMode;
            end
            
            % Load BPMN file if provided
            if nargin > 0 && ~isempty(bpmnFilePath)
                obj.loadBPMNFile(bpmnFilePath);
            end
        end
        
        function loadBPMNFile(obj, filePath)
            % Load a BPMN file for validation
            % filePath: Path to the BPMN file
            
            try
                obj.XMLDoc = xmlread(filePath);
                obj.addInfo(['Successfully loaded BPMN file: ' filePath]);
            catch ex
                obj.addError(['Failed to load BPMN file: ' ex.message]);
            end
        end
        
        function valid = validate(obj)
            % Validate the BPMN file
            % Returns: Boolean indicating whether validation passed
            
            obj.ValidationLogs = struct('errors', {}, 'warnings', {}, 'info', {});
            obj.addInfo('Starting BPMN validation...');
            
            if isempty(obj.XMLDoc)
                obj.addError('No BPMN file loaded for validation');
                valid = false;
                return;
            end
            
            % Run all validation checks
            obj.validateBPMNSchema();
            obj.validateStructuralIntegrity();
            obj.validateSemanticRules();
            obj.validateExecutability();
            
            % Check if there are any errors
            valid = isempty(obj.ValidationLogs.errors);
            
            if valid
                obj.addInfo('BPMN validation completed successfully with no errors.');
            else
                obj.addInfo(['BPMN validation completed with ' num2str(length(obj.ValidationLogs.errors)) ' errors.']);
            end
            
            if ~isempty(obj.ValidationLogs.warnings)
                obj.addInfo(['Found ' num2str(length(obj.ValidationLogs.warnings)) ' warnings.']);
            end
        end
        
        function validateBPMNSchema(obj)
            % Validate against the BPMN XML schema
            
            if ~exist(obj.SchemaPath, 'file')
                obj.addWarning(['BPMN schema file not found: ' obj.SchemaPath]);
                obj.addWarning('Schema validation skipped.');
                return;
            end
            
            % MATLAB doesn't have built-in XSD validation
            % This is a placeholder - in production you would use Java libraries
            % or call external tools for XSD validation
            try
                % Example implementation - integrate with xmlvalidate or similar tools
                % xsdvalidator = org.apache.xerces.jaxp.validation.XMLSchemaFactory.newInstance(...);
                % schema = xsdvalidator.newSchema(javax.xml.transform.stream.StreamSource(obj.SchemaPath));
                % validator = schema.newValidator();
                % validator.validate(javax.xml.transform.dom.DOMSource(obj.XMLDoc));
                
                obj.addInfo('Schema validation is currently a placeholder and requires external tools.');
                obj.addWarning('Schema validation not performed - requires external XML validation tools.');
            catch ex
                obj.addError(['Schema validation failed: ' ex.message]);
            end
        end
        
        function validateStructuralIntegrity(obj)
            % Validate structural integrity of the BPMN diagram
            
            obj.addInfo('Checking structural integrity...');
            
            % Check for process definitions
            processes = obj.XMLDoc.getElementsByTagName('process');
            if processes.getLength() == 0
                obj.addError('No process definitions found.');
                return;
            else
                obj.addInfo(['Found ' num2str(processes.getLength()) ' process definitions.']);
            end
            
            % Check each process
            for i = 0:processes.getLength()-1
                process = processes.item(i);
                processId = char(process.getAttribute('id'));
                
                % Check for start events
                startEvents = process.getElementsByTagName('startEvent');
                if startEvents.getLength() == 0
                    obj.addWarning(['Process ' processId ' has no start events.']);
                else
                    obj.addInfo(['Process ' processId ' has ' num2str(startEvents.getLength()) ' start events.']);
                end
                
                % Check for end events
                endEvents = process.getElementsByTagName('endEvent');
                if endEvents.getLength() == 0
                    obj.addWarning(['Process ' processId ' has no end events.']);
                else
                    obj.addInfo(['Process ' processId ' has ' num2str(endEvents.getLength()) ' end events.']);
                end
                
                % Check for sequence flows
                obj.validateSequenceFlows(process);
            end
        end
        
        function validateSequenceFlows(obj, processNode)
            % Validate sequence flows in a process
            % processNode: DOM node representing a BPMN process
            
            processId = char(processNode.getAttribute('id'));
            
            % Get all flow nodes and sequence flows
            flowNodes = obj.getAllFlowNodes(processNode);
            sequenceFlows = processNode.getElementsByTagName('sequenceFlow');
            
            if sequenceFlows.getLength() == 0
                obj.addWarning(['Process ' processId ' has no sequence flows.']);
                return;
            end
            
            % Create maps for source and target references
            nodeIds = containers.Map();
            for i = 1:length(flowNodes)
                node = flowNodes{i};
                nodeId = char(node.getAttribute('id'));
                nodeIds(nodeId) = true;
            end
            
            % Check each sequence flow
            for i = 0:sequenceFlows.getLength()-1
                flow = sequenceFlows.item(i);
                flowId = char(flow.getAttribute('id'));
                sourceRef = char(flow.getAttribute('sourceRef'));
                targetRef = char(flow.getAttribute('targetRef'));
                
                % Verify source reference
                if isempty(sourceRef)
                    obj.addError(['Sequence flow ' flowId ' has no sourceRef attribute.']);
                elseif ~nodeIds.isKey(sourceRef)
                    obj.addError(['Sequence flow ' flowId ' references non-existent source: ' sourceRef]);
                end
                
                % Verify target reference
                if isempty(targetRef)
                    obj.addError(['Sequence flow ' flowId ' has no targetRef attribute.']);
                elseif !nodeIds.isKey(targetRef)
                    obj.addError(['Sequence flow ' flowId ' references non-existent target: ' targetRef]);
                end
            end
            
            % Check for disconnected nodes (no incoming or outgoing flows)
            obj.checkForDisconnectedNodes(processNode, flowNodes, sequenceFlows);
        end
        
        function checkForDisconnectedNodes(obj, processNode, flowNodes, sequenceFlows)
            % Check for disconnected nodes in the process
            % processNode: DOM node representing a BPMN process
            % flowNodes: Cell array of flow node DOM nodes
            % sequenceFlows: NodeList of sequence flow DOM nodes
            
            processId = char(processNode.getAttribute('id'));
            
            % Create maps for incoming and outgoing connections
            incoming = containers.Map();
            outgoing = containers.Map();
            
            % Initialize with empty arrays for all nodes
            for i = 1:length(flowNodes)
                node = flowNodes{i};
                nodeId = char(node.getAttribute('id'));
                incoming(nodeId) = {};
                outgoing(nodeId) = {};
            end
            
            % Map flows to nodes
            for i = 0:sequenceFlows.getLength()-1
                flow = sequenceFlows.item(i);
                sourceRef = char(flow.getAttribute('sourceRef'));
                targetRef = char(flow.getAttribute('targetRef'));
                
                if incoming.isKey(targetRef)
                    inflows = incoming(targetRef);
                    incoming(targetRef) = [inflows, {flow}];
                end
                
                if outgoing.isKey(sourceRef)
                    outflows = outgoing(sourceRef);
                    outgoing(sourceRef) = [outflows, {flow}];
                end
            end
            
            % Check each node for connections
            for i = 1:length(flowNodes)
                node = flowNodes{i};
                nodeId = char(node.getAttribute('id'));
                nodeType = node.getNodeName();
                
                % Start events should have no incoming flows
                if strcmp(nodeType, 'startEvent')
                    if !isempty(incoming(nodeId))
                        obj.addError(['Start event ' nodeId ' has incoming sequence flows, which is not allowed.']);
                    end
                    if isempty(outgoing(nodeId))
                        obj.addWarning(['Start event ' nodeId ' has no outgoing sequence flows.']);
                    end
                % End events should have no outgoing flows
                elseif strcmp(nodeType, 'endEvent')
                    if isempty(incoming(nodeId))
                        obj.addWarning(['End event ' nodeId ' has no incoming sequence flows.']);
                    end
                    if !isempty(outgoing(nodeId))
                        obj.addError(['End event ' nodeId ' has outgoing sequence flows, which is not allowed.']);
                    end
                % All other nodes should have both incoming and outgoing flows
                else
                    if isempty(incoming(nodeId)) && !strcmp(nodeType, 'boundaryEvent')
                        obj.addWarning(['Node ' nodeId ' (' char(nodeType) ') has no incoming sequence flows.']);
                    end
                    if isempty(outgoing(nodeId))
                        obj.addWarning(['Node ' nodeId ' (' char(nodeType) ') has no outgoing sequence flows.']);
                    end
                end
            end
        end
        
        function validateSemanticRules(obj)
            % Validate semantic rules of the BPMN diagram
            
            obj.addInfo('Checking semantic rules...');
            
            % Check for correct gateway usage
            obj.validateGateways();
            
            % Check for boundary events
            obj.validateBoundaryEvents();
            
            % Check for message flows
            obj.validateMessageFlows();
        end
        
        function validateGateways(obj)
            % Validate gateway rules
            
            % Get all gateways
            gateways = obj.XMLDoc.getElementsByTagName('exclusiveGateway');
            parallelGateways = obj.XMLDoc.getElementsByTagName('parallelGateway');
            inclusiveGateways = obj.XMLDoc.getElementsByTagName('inclusiveGateway');
            
            % Combine all gateway types
            allGateways = {};
            obj.addNodeListToArray(allGateways, gateways);
            obj.addNodeListToArray(allGateways, parallelGateways);
            obj.addNodeListToArray(allGateways, inclusiveGateways);
            
            obj.addInfo(['Found ' num2str(length(allGateways)) ' gateways in the model.']);
            
            % Get all sequence flows
            flowMap = obj.buildFlowMap();
            
            for i = 1:length(allGateways)
                gateway = allGateways{i};
                gatewayId = char(gateway.getAttribute('id'));
                gatewayType = gateway.getNodeName();
                
                % Get incoming and outgoing flows
                inFlows = flowMap.getIncoming(gatewayId);
                outFlows = flowMap.getOutgoing(gatewayId);
                
                % Check gateway direction
                if length(inFlows) > 1 && length(outFlows) > 1
                    obj.addWarning(['Gateway ' gatewayId ' has multiple incoming and outgoing flows. It should be split into two gateways.']);
                end
                
                % Check exclusive gateway conditions
                if strcmp(gatewayType, 'exclusiveGateway') && length(outFlows) > 1
                    obj.validateExclusiveGatewayConditions(gateway, outFlows);
                end
            end
        end
        
        function validateExclusiveGatewayConditions(obj, gateway, outFlows)
            % Check if exclusive gateway has proper conditions on outgoing flows
            
            gatewayId = char(gateway.getAttribute('id'));
            defaultFlow = char(gateway.getAttribute('default'));
            
            hasDefault = !isempty(defaultFlow);
            conditionCount = 0;
            
            for i = 1:length(outFlows)
                flow = outFlows{i};
                flowId = char(flow.getAttribute('id'));
                
                % Check if flow has condition expression
                conditions = flow.getElementsByTagName('conditionExpression');
                hasCondition = (conditions.getLength() > 0);
                
                if hasCondition
                    conditionCount = conditionCount + 1;
                elseif !hasDefault || !strcmp(flowId, defaultFlow)
                    obj.addError(['Flow ' flowId ' from exclusive gateway ' gatewayId ' has no condition and is not the default flow.']);
                end
            end
            
            if length(outFlows) > 1 && conditionCount == 0 && !hasDefault
                obj.addError(['Exclusive gateway ' gatewayId ' has multiple outgoing flows but no conditions or default flow.']);
            end
        end
        
        function validateBoundaryEvents(obj)
            % Validate boundary event rules
            
            % Get all boundary events
            boundaryEvents = obj.XMLDoc.getElementsByTagName('boundaryEvent');
            
            obj.addInfo(['Found ' num2str(boundaryEvents.getLength()) ' boundary events in the model.']);
            
            for i = 0:boundaryEvents.getLength()-1
                event = boundaryEvents.item(i);
                eventId = char(event.getAttribute('id'));
                attachedToRef = char(event.getAttribute('attachedToRef'));
                
                % Check if attached to reference is valid
                if isempty(attachedToRef)
                    obj.addError(['Boundary event ' eventId ' has no attachedToRef attribute.']);
                else
                    % Verify that referenced element exists
                    attachedNode = obj.findElementById(attachedToRef);
                    if isempty(attachedNode)
                        obj.addError(['Boundary event ' eventId ' references non-existent element: ' attachedToRef]);
                    else
                        % Check that it's attached to a valid element type
                        nodeName = attachedNode.getNodeName();
                        if !(strcmp(nodeName, 'task') || strcmp(nodeName, 'subProcess') || ...
                             strcmp(nodeName, 'callActivity') || endsWith(nodeName, 'Task'))
                            obj.addWarning(['Boundary event ' eventId ' is attached to ' nodeName ' which is not a recommended target.']);
                        end
                    end
                end
                
                % Check if the event has proper event definitions
                eventDefs = {'messageEventDefinition', 'timerEventDefinition', 'errorEventDefinition', ...
                           'signalEventDefinition', 'compensationEventDefinition', 'escalationEventDefinition'};
                
                hasValidDef = false;
                for j = 1:length(eventDefs)
                    defType = eventDefs{j};
                    defs = event.getElementsByTagName(defType);
                    if defs.getLength() > 0
                        hasValidDef = true;
                        break;
                    end
                end
                
                if !hasValidDef
                    obj.addError(['Boundary event ' eventId ' has no valid event definition.']);
                end
            end
        end
        
        function validateMessageFlows(obj)
            % Validate message flow rules
            
            % Check for collaboration element
            collaborations = obj.XMLDoc.getElementsByTagName('collaboration');
            if collaborations.getLength() == 0
                return; % No collaborations, so no message flows to check
            end
            
            % Get all message flows
            messageFlows = obj.XMLDoc.getElementsByTagName('messageFlow');
            
            obj.addInfo(['Found ' num2str(messageFlows.getLength()) ' message flows in the model.']);
            
            for i = 0:messageFlows.getLength()-1
                flow = messageFlows.item(i);
                flowId = char(flow.getAttribute('id'));
                sourceRef = char(flow.getAttribute('sourceRef'));
                targetRef = char(flow.getAttribute('targetRef'));
                
                % Check for source and target
                if isempty(sourceRef)
                    obj.addError(['Message flow ' flowId ' has no sourceRef attribute.']);
                end
                
                if isempty(targetRef)
                    obj.addError(['Message flow ' flowId ' has no targetRef attribute.']);
                end
                
                % Verify that source and target exist
                sourceNode = obj.findElementById(sourceRef);
                targetNode = obj.findElementById(targetRef);
                
                if isempty(sourceNode)
                    obj.addError(['Message flow ' flowId ' references non-existent source: ' sourceRef]);
                end
                
                if isempty(targetNode)
                    obj.addError(['Message flow ' flowId ' references non-existent target: ' targetRef]);
                end
                
                % Check that message flows are between different pools
                if !isempty(sourceNode) && !isempty(targetNode)
                    sourcePool = obj.getParentPool(sourceNode);
                    targetPool = obj.getParentPool(targetNode);
                    
                    if !isempty(sourcePool) && !isempty(targetPool) && strcmp(sourcePool, targetPool)
                        obj.addError(['Message flow ' flowId ' is between elements in the same pool (' sourcePool '), which is not allowed.']);
                    end
                end
            end
        end
        
        function validateExecutability(obj)
            % Validate that the process is executable if marked as such
            
            processes = obj.XMLDoc.getElementsByTagName('process');
            
            for i = 0:processes.getLength()-1
                process = processes.item(i);
                processId = char(process.getAttribute('id'));
                isExecutable = lower(char(process.getAttribute('isExecutable')));
                
                if strcmp(isExecutable, 'true')
                    obj.addInfo(['Checking executability of process ' processId '...']);
                    
                    % Check for service tasks having implementation
                    serviceTasks = process.getElementsByTagName('serviceTask');
                    for j = 0:serviceTasks.getLength()-1
                        task = serviceTasks.item(j);
                        taskId = char(task.getAttribute('id'));
                        implementation = char(task.getAttribute('implementation'));
                        
                        if isempty(implementation)
                            obj.addWarning(['Service task ' taskId ' in executable process has no implementation attribute.']);
                        end
                    end
                    
                    % Check for script tasks having script
                    scriptTasks = process.getElementsByTagName('scriptTask');
                    for j = 0:scriptTasks.getLength()-1
                        task = scriptTasks.item(j);
                        taskId = char(task.getAttribute('id'));
                        
                        scripts = task.getElementsByTagName('script');
                        if scripts.getLength() == 0
                            obj.addWarning(['Script task ' taskId ' in executable process has no script element.']);
                        end
                    end
                    
                    % Check that all gateways have proper conditions
                    obj.validateExecutableGateways(process);
                end
            end
        end
        
        function validateExecutableGateways(obj, processNode)
            % Validate gateways for executability
            
            gateways = processNode.getElementsByTagName('exclusiveGateway');
            
            for i = 0:gateways.getLength()-1
                gateway = gateways.item(i);
                gatewayId = char(gateway.getAttribute('id'));
                
                % Build flow map
                flowMap = obj.buildFlowMap();
                outFlows = flowMap.getOutgoing(gatewayId);
                
                if length(outFlows) <= 1
                    continue; % Skip gateways with 0 or 1 outgoing flows
                end
                
                defaultFlow = char(gateway.getAttribute('default'));
                hasDefault = !isempty(defaultFlow);
                
                % Check if all outgoing flows have conditions
                for j = 1:length(outFlows)
                    flow = outFlows{j};
                    flowId = char(flow.getAttribute('id'));
                    
                    if strcmp(flowId, defaultFlow)
                        continue; % Skip default flow
                    end
                    
                    conditions = flow.getElementsByTagName('conditionExpression');
                    if conditions.getLength() == 0
                        obj.addError(['Flow ' flowId ' from exclusive gateway ' gatewayId ' in executable process has no condition.']);
                    end
                end
                
                if !hasDefault
                    obj.addWarning(['Executable exclusive gateway ' gatewayId ' has no default flow.']);
                end
            end
        end
        
        function flowMap = buildFlowMap(obj)
            % Build a map of sequence flows for easier lookup
            % Returns a flow map object
            
            flowMap = BPMNFlowMap();
            
            % Get all sequence flows
            flows = obj.XMLDoc.getElementsByTagName('sequenceFlow');
            
            for i = 0:flows.getLength()-1
                flow = flows.item(i);
                sourceRef = char(flow.getAttribute('sourceRef'));
                targetRef = char(flow.getAttribute('targetRef'));
                
                flowMap.addFlow(flow, sourceRef, targetRef);
            end
        end
        
        function nodes = getAllFlowNodes(obj, processNode)
            % Get all flow nodes in a process
            % processNode: DOM node representing a BPMN process
            % Returns: Cell array of flow node DOM nodes
            
            nodes = {};
            
            % Get all types of flow nodes
            nodeTypes = {'task', 'userTask', 'serviceTask', 'sendTask', 'receiveTask', ...
                       'manualTask', 'businessRuleTask', 'scriptTask', 'callActivity', ...
                       'subProcess', 'startEvent', 'endEvent', 'intermediateThrowEvent', ...
                       'intermediateCatchEvent', 'boundaryEvent', 'exclusiveGateway', ...
                       'inclusiveGateway', 'parallelGateway', 'eventBasedGateway', 'complexGateway'};
                   
            for i = 1:length(nodeTypes)
                nodeList = processNode.getElementsByTagName(nodeTypes{i});
                obj.addNodeListToArray(nodes, nodeList);
            end
        end
        
        function addNodeListToArray(obj, array, nodeList)
            % Add nodes from a NodeList to a cell array
            % array: Cell array to add nodes to
            % nodeList: DOM NodeList of nodes to add
            
            for i = 0:nodeList.getLength()-1
                array{end+1} = nodeList.item(i);
            end
        end
        
        function node = findElementById(obj, id)
            % Find a BPMN element by ID
            % id: ID of the element to find
            % Returns: DOM node or empty if not found
            
            % Look in common element types
            elementTypes = {'process', 'task', 'userTask', 'serviceTask', 'sendTask', ...
                          'receiveTask', 'manualTask', 'businessRuleTask', 'scriptTask', ...
                          'callActivity', 'subProcess', 'startEvent', 'endEvent', ...
                          'intermediateThrowEvent', 'intermediateCatchEvent', 'boundaryEvent', ...
                          'exclusiveGateway', 'inclusiveGateway', 'parallelGateway', ...
                          'eventBasedGateway', 'complexGateway', 'participant', 'lane'};
                      
            for i = 1:length(elementTypes)
                elements = obj.XMLDoc.getElementsByTagName(elementTypes{i});
                
                for j = 0:elements.getLength()-1
                    element = elements.item(j);
                    elementId = char(element.getAttribute('id'));
                    
                    if strcmp(elementId, id)
                        node = element;
                        return;
                    end
                end
            end
            
            % Not found
            node = [];
        end
        
        function poolId = getParentPool(obj, node)
            % Get the ID of the pool containing this node
            % node: DOM node to find parent pool for
            % Returns: Pool ID or empty if not in a pool
            
            % Check if we can navigate upwards in the DOM
            % Note: This is a simplified approach and may not work in all cases
            % For robust implementation, we would need to use BPMN semantics to
            % determine the parent pool
            
            % First try to find a participant for this element through references
            participants = obj.XMLDoc.getElementsByTagName('participant');
            for i = 0:participants.getLength()-1
                participant = participants.item(i);
                processRef = char(participant.getAttribute('processRef'));
                
                % If this is a node in a process, check if the process is referenced by a participant
                process = obj.findAncestorByTagName(node, 'process');
                if !isempty(process)
                    processId = char(process.getAttribute('id'));
                    if strcmp(processId, processRef)
                        poolId = char(participant.getAttribute('id'));
                        return;
                    end
                end
            end
            
            % Not found
            poolId = [];
        end
        
        function ancestor = findAncestorByTagName(obj, node, tagName)
            % Find an ancestor of a node with a specific tag name
            % node: DOM node to find ancestor for
            % tagName: Tag name to look for
            % Returns: Ancestor node or empty if not found
            
            currentNode = node.getParentNode();
            while !isempty(currentNode)
                if strcmp(currentNode.getNodeName(), tagName)
                    ancestor = currentNode;
                    return;
                end
                currentNode = currentNode.getParentNode();
            end
            
            % Not found
            ancestor = [];
        end
        
        function addError(obj, message)
            % Add an error message to the validation logs
            obj.ValidationLogs.errors{end+1} = message;
        end
        
        function addWarning(obj, message)
            % Add a warning message to the validation logs
            obj.ValidationLogs.warnings{end+1} = message;
        end
        
        function addInfo(obj, message)
            % Add an info message to the validation logs
            obj.ValidationLogs.info{end+1} = message;
        end
        
        function displayValidationResults(obj)
            % Display validation results to command window
            
            fprintf('\n===== BPMN Validation Results =====\n\n');
            
            % Display errors
            if !isempty(obj.ValidationLogs.errors)
                fprintf('ERRORS (%d):\n', length(obj.ValidationLogs.errors));
                for i = 1:length(obj.ValidationLogs.errors)
                    fprintf('  - %s\n', obj.ValidationLogs.errors{i});
                end
                fprintf('\n');
            else
                fprintf('No errors found.\n\n');
            end
            
            % Display warnings
            if !isempty(obj.ValidationLogs.warnings)
                fprintf('WARNINGS (%d):\n', length(obj.ValidationLogs.warnings));
                for i = 1:length(obj.ValidationLogs.warnings)
                    fprintf('  - %s\n', obj.ValidationLogs.warnings{i});
                end
                fprintf('\n');
            else
                fprintf('No warnings found.\n\n');
            end
            
            % Display summary
            fprintf('SUMMARY:\n');
            fprintf('  - Errors: %d\n', length(obj.ValidationLogs.errors));
            fprintf('  - Warnings: %d\n', length(obj.ValidationLogs.warnings));
            fprintf('  - Info messages: %d\n', length(obj.ValidationLogs.info));
            
            if isempty(obj.ValidationLogs.errors)
                fprintf('\nValidation PASSED.\n');
            else
                fprintf('\nValidation FAILED.\n');
            end
            
            fprintf('\n===================================\n\n');
        end
        
        function results = getValidationResults(obj)
            % Get validation results as a structure
            % Returns: Structure with validation results
            
            results = obj.ValidationLogs;
            results.valid = isempty(obj.ValidationLogs.errors);
            results.errorCount = length(obj.ValidationLogs.errors);
            results.warningCount = length(obj.ValidationLogs.warnings);
            results.infoCount = length(obj.ValidationLogs.info);
        end
    end
end

% Helper class for tracking flow connections
classdef BPMNFlowMap < handle
    properties
        IncomingFlows  % Map of incoming flows for each node
        OutgoingFlows  % Map of outgoing flows for each node
    end
    
    methods
        function obj = BPMNFlowMap()
            % Constructor
            obj.IncomingFlows = containers.Map();
            obj.OutgoingFlows = containers.Map();
        end
        
        function addFlow(obj, flow, sourceRef, targetRef)
            % Add a flow to the maps
            % flow: DOM node representing the flow
            % sourceRef: ID of the source element
            % targetRef: ID of the target element
            
            % Add to outgoing flows map
            if !obj.OutgoingFlows.isKey(sourceRef)
                obj.OutgoingFlows(sourceRef) = {};
            end
            outFlows = obj.OutgoingFlows(sourceRef);
            obj.OutgoingFlows(sourceRef) = [outFlows, {flow}];
            
            % Add to incoming flows map
            if !obj.IncomingFlows.isKey(targetRef)
                obj.IncomingFlows(targetRef) = {};
            end
            inFlows = obj.IncomingFlows(targetRef);
            obj.IncomingFlows(targetRef) = [inFlows, {flow}];
        end
        
        function flows = getOutgoing(obj, nodeId)
            % Get outgoing flows for a node
            % nodeId: ID of the node
            % Returns: Cell array of flow DOM nodes
            
            if obj.OutgoingFlows.isKey(nodeId)
                flows = obj.OutgoingFlows(nodeId);
            else
                flows = {};
            end
        end
        
        function flows = getIncoming(obj, nodeId)
            % Get incoming flows for a node
            % nodeId: ID of the node
            % Returns: Cell array of flow DOM nodes
            
            if obj.IncomingFlows.isKey(nodeId)
                flows = obj.IncomingFlows(nodeId);
            else
                flows = {};
            end
        end
    end
end