classdef BPMNGenerator < handle
    % BPMNGENERATOR Class for generating BPMN 2.0 XML files
    %   This class provides functionality for creating, editing and saving
    %   BPMN 2.0 compliant XML files from MATLAB
    
    properties
        XMLDoc          % XML document object
        ProcessElements % Structure containing process elements
        FilePath        % Path to save the BPMN file
        DatabaseConn    % Database connection for data extraction
        BPMNVersion     % BPMN specification version
        Processes       % Cell array of process nodes
        Collaborations  % Cell array of collaboration nodes
        Participants    % Cell array of participant definitions
    end
    
    methods
        function obj = BPMNGenerator(filePath)
            % Constructor for BPMNGenerator
            % filePath: Optional path to save the BPMN file
            
            if nargin > 0
                obj.FilePath = filePath;
            end
            obj.BPMNVersion = '2.0';
            obj.ProcessElements = struct('tasks', {}, 'gateways', {}, 'events', {}, 'flows', {});
            obj.Processes = {};
            obj.Collaborations = {};
            obj.Participants = {};
            obj.initializeEmptyBPMN();
        end
        
        function initializeEmptyBPMN(obj)
            % Initialize an empty BPMN document with required namespaces
            
            % Create XML document
            obj.XMLDoc = com.mathworks.xml.XMLUtils.createDocument('definitions');
            
            % Get root element and add namespaces
            rootNode = obj.XMLDoc.getDocumentElement();
            rootNode.setAttribute('xmlns', 'http://www.omg.org/spec/BPMN/20100524/MODEL');
            rootNode.setAttribute('xmlns:bpmndi', 'http://www.omg.org/spec/BPMN/20100524/DI');
            rootNode.setAttribute('xmlns:dc', 'http://www.omg.org/spec/DD/20100524/DC');
            rootNode.setAttribute('xmlns:di', 'http://www.omg.org/spec/DD/20100524/DI');
            rootNode.setAttribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
            rootNode.setAttribute('xmlns:camunda', 'http://camunda.org/schema/1.0/bpmn');
            rootNode.setAttribute('id', 'Definitions_1');
            rootNode.setAttribute('targetNamespace', 'http://www.example.org/bpmn20');
            
            % Add empty process
            processNode = obj.XMLDoc.createElement('process');
            processId = 'Process_1';
            processNode.setAttribute('id', processId);
            processNode.setAttribute('isExecutable', 'false');
            rootNode.appendChild(processNode);
            obj.Processes{1} = processNode;
            
            % Add empty BPMNDiagram section for visualization
            bpmnDiNode = obj.XMLDoc.createElement('bpmndi:BPMNDiagram');
            bpmnDiNode.setAttribute('id', 'BPMNDiagram_1');
            bpmnPlane = obj.XMLDoc.createElement('bpmndi:BPMNPlane');
            bpmnPlane.setAttribute('id', 'BPMNPlane_1');
            bpmnPlane.setAttribute('bpmnElement', processId);
            bpmnDiNode.appendChild(bpmnPlane);
            rootNode.appendChild(bpmnDiNode);
        end

        % Convenience wrapper for start event
        function addStartEvent(obj, id, name, x, y, width, height)
            obj.addEvent(id, name, 'startEvent', '', x, y, width, height);
        end

        % Convenience wrapper for exclusive gateway
        function addExclusiveGateway(obj, id, name, x, y, width, height)
            obj.addGateway(id, name, 'exclusiveGateway', x, y, width, height);
        end

        % Convenience wrapper for participant/pool
        function addParticipant(obj, id, name, processRef, x, y, width, height)
            obj.addPool(id, name, processRef, x, y, width, height);
        end
        
        function addTask(obj, id, name, x, y, width, height)
            % Add a task to the BPMN diagram
            % id: Unique identifier for the task
            % name: Name/label of the task
            % x, y: Coordinates for the task in the diagram
            % width, height: Dimensions of the task box
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create task element
            taskNode = obj.XMLDoc.createElement('task');
            taskNode.setAttribute('id', id);
            taskNode.setAttribute('name', name);
            
            % Add to process
            processNode.appendChild(taskNode);
            
            % Add to diagram
            obj.addShapeToVisualization(id, x, y, width, height);
        end
        
        % Enhanced task creation with task types
        function addSpecificTask(obj, id, name, taskType, additionalAttributes, x, y, width, height)
            % Adds a specific task type (e.g., userTask, serviceTask) with additional attributes
            processNode = obj.getCurrentProcessNode();
            if isempty(processNode)
                error('BPMNGenerator:NoProcess', 'No process defined to add the task to.');
            end
            
            taskNode = obj.docNode.createElement(taskType);
            taskNode.setAttribute('id', id);
            taskNode.setAttribute('name', name);
            processNode.appendChild(taskNode);
            
            % Add additional attributes if provided
            if nargin >= 5 && ~isempty(additionalAttributes) && isstruct(additionalAttributes)
                fields = fieldnames(additionalAttributes);
                for i = 1:length(fields)
                    fieldName = fields{i};
                    fieldValue = additionalAttributes.(fieldName);
                    
                    % Convert simple types to string for attributes
                    if ischar(fieldValue) || isstring(fieldValue) || isnumeric(fieldValue) || islogical(fieldValue)
                        if islogical(fieldValue)
                            if fieldValue
                                attrValue = 'true';
                            else
                                attrValue = 'false';
                            end
                        else
                            attrValue = string(fieldValue); % Use string() for robust conversion
                        end
                        taskNode.setAttribute(fieldName, attrValue);
                    else
                        warning('BPMNGenerator:UnsupportedAttributeType', ...
                            'Skipping attribute "%s" for task "%s" due to unsupported type: %s', ...
                            fieldName, id, class(fieldValue));
                    end
                end
            end
            
            obj.addShape(id, x, y, width, height);
        end
        
        function addGateway(obj, id, name, gatewayType, x, y, width, height)
            % Add a gateway to the BPMN diagram
            % id: Unique identifier for the gateway
            % name: Name/label of the gateway
            % gatewayType: Type of gateway (exclusiveGateway, parallelGateway, etc.)
            % x, y: Coordinates for the gateway in the diagram
            % width, height: Dimensions of the gateway
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create gateway element
            gatewayNode = obj.XMLDoc.createElement(gatewayType);
            gatewayNode.setAttribute('id', id);
            
            if ~isempty(name)
                gatewayNode.setAttribute('name', name);
            end
            
            % Add to process
            processNode.appendChild(gatewayNode);
            
            % Add to diagram
            obj.addShapeToVisualization(id, x, y, width, height);
        end
        
        function addEvent(obj, id, name, eventType, eventDefinitionType, x, y, width, height)
            % Add an event to the BPMN diagram
            % id: Unique identifier for the event
            % name: Name/label of the event
            % eventType: Type of event (startEvent, endEvent, intermediateThrowEvent, etc.)
            % eventDefinitionType: Type of event definition (messageEventDefinition, etc.)
            % x, y: Coordinates for the event in the diagram
            % width, height: Dimensions of the event
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create event element
            eventNode = obj.XMLDoc.createElement(eventType);
            eventNode.setAttribute('id', id);
            
            if ~isempty(name)
                eventNode.setAttribute('name', name);
            end
            
            % Add event definition if specified
            if nargin >= 5 && ~isempty(eventDefinitionType)
                defNode = obj.XMLDoc.createElement(eventDefinitionType);
                defId = [eventDefinitionType, '_', id];
                defNode.setAttribute('id', defId);
                eventNode.appendChild(defNode);
            end
            
            % Add to process
            processNode.appendChild(eventNode);
            
            % Add to diagram
            obj.addShapeToVisualization(id, x, y, width, height);
        end
        
        function addBoundaryEvent(obj, id, name, attachedToRef, eventDefinitionType, isInterrupting, x, y, width, height)
            % Add a boundary event to the BPMN diagram
            % id: Unique identifier for the event
            % name: Name/label of the event
            % attachedToRef: ID of the element to attach the boundary event to
            % eventDefinitionType: Type of event definition (messageEventDefinition, etc.)
            % isInterrupting: Whether the event is interrupting
            % x, y: Coordinates for the event in the diagram
            % width, height: Dimensions of the event
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create boundary event element
            eventNode = obj.XMLDoc.createElement('boundaryEvent');
            eventNode.setAttribute('id', id);
            eventNode.setAttribute('attachedToRef', attachedToRef);
            
            if nargin >= 5 && ~isempty(isInterrupting)
                eventNode.setAttribute('cancelActivity', lower(isInterrupting));
            end
            
            if ~isempty(name)
                eventNode.setAttribute('name', name);
            end
            
            % Add event definition if specified
            if nargin >= 4 && ~isempty(eventDefinitionType)
                defNode = obj.XMLDoc.createElement(eventDefinitionType);
                defId = [eventDefinitionType, '_', id];
                defNode.setAttribute('id', defId);
                eventNode.appendChild(defNode);
            end
            
            % Add to process
            processNode.appendChild(eventNode);
            
            % Add to diagram
            obj.addShapeToVisualization(id, x, y, width, height);
        end
        
        function addSequenceFlow(obj, id, sourceRef, targetRef, waypoints, conditionExpression)
            % Add a sequence flow between elements
            % id: Unique identifier for the flow
            % sourceRef: ID of the source element
            % targetRef: ID of the target element
            % waypoints: Array of {x,y} coordinates for the flow path
            % conditionExpression: Optional condition expression for the flow
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create flow element
            flowNode = obj.XMLDoc.createElement('sequenceFlow');
            flowNode.setAttribute('id', id);
            flowNode.setAttribute('sourceRef', sourceRef);
            flowNode.setAttribute('targetRef', targetRef);
            
            % Add condition expression if provided
            if nargin >= 6 && ~isempty(conditionExpression)
                condNode = obj.XMLDoc.createElement('conditionExpression');
                condNode.setAttribute('xsi:type', 'tFormalExpression');
                textNode = obj.XMLDoc.createTextNode(conditionExpression);
                condNode.appendChild(textNode);
                flowNode.appendChild(condNode);
            end
            
            % Add to process
            processNode.appendChild(flowNode);
            
            % Add to diagram
            obj.addEdgeToVisualization(id, sourceRef, targetRef, waypoints);
        end
        
        function addMessageFlow(obj, id, sourceRef, targetRef, waypoints, messageName)
            % Add a message flow between pools/participants
            % id: Unique identifier for the flow
            % sourceRef: ID of the source element
            % targetRef: ID of the target element
            % waypoints: Array of {x,y} coordinates for the flow path
            % messageName: Optional name of the message
            
            % Get root element
            rootNode = obj.XMLDoc.getDocumentElement();
            
            % Check if collaboration node exists, create if not
            collabNodes = rootNode.getElementsByTagName('collaboration');
            if collabNodes.getLength() == 0
                collabNode = obj.XMLDoc.createElement('collaboration');
                collabNode.setAttribute('id', 'Collaboration_1');
                rootNode.insertBefore(collabNode, obj.getProcessNode());
                obj.Collaborations{1} = collabNode;
            else
                collabNode = collabNodes.item(0);
            end
            
            % Create message flow element
            flowNode = obj.XMLDoc.createElement('messageFlow');
            flowNode.setAttribute('id', id);
            flowNode.setAttribute('sourceRef', sourceRef);
            flowNode.setAttribute('targetRef', targetRef);
            
            if nargin >= 6 && ~isempty(messageName)
                flowNode.setAttribute('name', messageName);
            end
            
            % Add to collaboration
            collabNode.appendChild(flowNode);
            
            % Add to diagram
            obj.addEdgeToVisualization(id, sourceRef, targetRef, waypoints);
        end
        
        function addDataObject(obj, id, name, isCollection, x, y, width, height)
            % Add a data object to the BPMN diagram
            % id: Unique identifier for the data object
            % name: Name/label of the data object
            % isCollection: Whether the data object is a collection
            % x, y: Coordinates for the data object in the diagram
            % width, height: Dimensions of the data object
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create data object element
            dataObjRef = obj.XMLDoc.createElement('dataObjectReference');
            dataObjRef.setAttribute('id', [id, '_ref']);
            if ~isempty(name)
                dataObjRef.setAttribute('name', name);
            end
            
            dataObj = obj.XMLDoc.createElement('dataObject');
            dataObj.setAttribute('id', id);
            
            if nargin >= 4 && isCollection
                dataObj.setAttribute('isCollection', 'true');
            end
            
            % Add to process
            processNode.appendChild(dataObj);
            processNode.appendChild(dataObjRef);
            
            % Add to diagram
            obj.addShapeToVisualization([id, '_ref'], x, y, width, height);
        end
        
        function addDataStore(obj, id, name, capacity, x, y, width, height)
            % Add a data store to the BPMN diagram
            % id: Unique identifier for the data store
            % name: Name/label of the data store
            % capacity: Optional capacity of the data store
            % x, y: Coordinates for the data store in the diagram
            % width, height: Dimensions of the data store
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create data store element
            dataStoreRef = obj.XMLDoc.createElement('dataStoreReference');
            dataStoreRef.setAttribute('id', [id, '_ref']);
            if ~isempty(name)
                dataStoreRef.setAttribute('name', name);
            end
            
            dataStore = obj.XMLDoc.createElement('dataStore');
            dataStore.setAttribute('id', id);
            
            if nargin >= 4 && ~isempty(capacity)
                dataStore.setAttribute('capacity', num2str(capacity));
            end
            
            % Add to process
            processNode.appendChild(dataStore);
            processNode.appendChild(dataStoreRef);
            
            % Add to diagram
            obj.addShapeToVisualization([id, '_ref'], x, y, width, height);
        end
        
        function addDataAssociation(obj, id, sourceRef, targetRef, waypoints)
            % Add a data association between elements and data objects
            % id: Unique identifier for the association
            % sourceRef: ID of the source element
            % targetRef: ID of the target element
            % waypoints: Array of {x,y} coordinates for the association path
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create association element
            assocNode = obj.XMLDoc.createElement('dataAssociation');
            assocNode.setAttribute('id', id);
            
            % Add source reference
            sourceNode = obj.XMLDoc.createElement('sourceRef');
            sourceText = obj.XMLDoc.createTextNode(sourceRef);
            sourceNode.appendChild(sourceText);
            assocNode.appendChild(sourceNode);
            
            % Add target reference
            targetNode = obj.XMLDoc.createElement('targetRef');
            targetText = obj.XMLDoc.createTextNode(targetRef);
            targetNode.appendChild(targetText);
            assocNode.appendChild(targetNode);
            
            % Add to process
            processNode.appendChild(assocNode);
            
            % Add to diagram
            obj.addEdgeToVisualization(id, sourceRef, targetRef, waypoints);
        end
        
        function addSubProcess(obj, id, name, x, y, width, height, isExpanded)
            % Add a subprocess to the BPMN diagram
            % id: Unique identifier for the subprocess
            % name: Name/label of the subprocess
            % x, y: Coordinates for the subprocess in the diagram
            % width, height: Dimensions of the subprocess
            % isExpanded: Whether the subprocess is expanded in the diagram
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create subprocess element
            subProcessNode = obj.XMLDoc.createElement('subProcess');
            subProcessNode.setAttribute('id', id);
            
            if ~isempty(name)
                subProcessNode.setAttribute('name', name);
            end
            
            if nargin >= 8
                if isExpanded
                    subProcessNode.setAttribute('triggeredByEvent', 'false');
                else
                    subProcessNode.setAttribute('triggeredByEvent', 'true');
                end
            end
            
            % Add to process
            processNode.appendChild(subProcessNode);
            
            % Add to diagram
            obj.addShapeToVisualization(id, x, y, width, height, isExpanded);
        end
        
        function addPool(obj, id, name, processRef, x, y, width, height)
            % Add a pool (participant) to the BPMN diagram
            % id: Unique identifier for the pool
            % name: Name/label of the pool
            % processRef: ID of the process for this pool
            % x, y: Coordinates for the pool in the diagram
            % width, height: Dimensions of the pool
            
            % Get root element
            rootNode = obj.XMLDoc.getDocumentElement();
            
            % Check if collaboration node exists, create if not
            collabNodes = rootNode.getElementsByTagName('collaboration');
            if collabNodes.getLength() == 0
                collabNode = obj.XMLDoc.createElement('collaboration');
                collabNode.setAttribute('id', 'Collaboration_1');
                rootNode.insertBefore(collabNode, obj.getProcessNode());
                obj.Collaborations{1} = collabNode;
            else
                collabNode = collabNodes.item(0);
            end
            
            % Create participant (pool) element
            poolNode = obj.XMLDoc.createElement('participant');
            poolNode.setAttribute('id', id);
            
            if ~isempty(name)
                poolNode.setAttribute('name', name);
            end
            
            if ~isempty(processRef)
                poolNode.setAttribute('processRef', processRef);
            end
            
            % Add to collaboration
            collabNode.appendChild(poolNode);
            obj.Participants{end+1} = struct('id', id, 'processRef', processRef);
            
            % Add to diagram
            obj.addShapeToVisualization(id, x, y, width, height);
        end
        
        function addLane(obj, id, name, parentId, x, y, width, height)
            % Add a lane to the BPMN diagram
            % id: Unique identifier for the lane
            % name: Name/label of the lane
            % parentId: ID of the parent pool or lane
            % x, y: Coordinates for the lane in the diagram
            % width, height: Dimensions of the lane
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Check if laneSet exists, create if not
            laneSets = processNode.getElementsByTagName('laneSet');
            if laneSets.getLength() == 0
                laneSetNode = obj.XMLDoc.createElement('laneSet');
                laneSetNode.setAttribute('id', 'LaneSet_1');
                processNode.appendChild(laneSetNode);
            else
                laneSetNode = laneSets.item(0);
            end
            
            % Create lane element
            laneNode = obj.XMLDoc.createElement('lane');
            laneNode.setAttribute('id', id);
            
            if ~isempty(name)
                laneNode.setAttribute('name', name);
            end
            
            % Check if this is a nested lane
            if nargin >= 4 && ~isempty(parentId)
                % Find parent lane node
                lanes = laneSetNode.getElementsByTagName('lane');
                for i = 0:lanes.getLength()-1
                    lane = lanes.item(i);
                    if strcmp(lane.getAttribute('id'), parentId)
                        % Add as nested lane
                        childLaneSetNode = lane.getElementsByTagName('childLaneSet');
                        if childLaneSetNode.getLength() == 0
                            childLaneSetNode = obj.XMLDoc.createElement('childLaneSet');
                            childLaneSetNode.setAttribute('id', ['LaneSet_', parentId]);
                            lane.appendChild(childLaneSetNode);
                        else
                            childLaneSetNode = childLaneSetNode.item(0);
                        end
                        childLaneSetNode.appendChild(laneNode);
                        break;
                    end
                end
            else
                % Add to top-level laneSet
                laneSetNode.appendChild(laneNode);
            end
            
            % Add to diagram
            obj.addShapeToVisualization(id, x, y, width, height);
        end
        
        function addTextAnnotation(obj, id, text, x, y, width, height)
            % Add a text annotation to the BPMN diagram
            % id: Unique identifier for the annotation
            % text: Text content of the annotation
            % x, y: Coordinates for the annotation in the diagram
            % width, height: Dimensions of the annotation
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create text annotation element
            annotNode = obj.XMLDoc.createElement('textAnnotation');
            annotNode.setAttribute('id', id);
            
            textNode = obj.XMLDoc.createElement('text');
            textContent = obj.XMLDoc.createTextNode(text);
            textNode.appendChild(textContent);
            annotNode.appendChild(textNode);
            
            % Add to process
            processNode.appendChild(annotNode);
            
            % Add to diagram
            obj.addShapeToVisualization(id, x, y, width, height);
        end
        
        function addAssociation(obj, id, sourceRef, targetRef, waypoints, direction)
            % Add an association between elements
            % id: Unique identifier for the association
            % sourceRef: ID of the source element
            % targetRef: ID of the target element
            % waypoints: Array of {x,y} coordinates for the association path
            % direction: Association direction (None, One, Both)
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create association element
            assocNode = obj.XMLDoc.createElement('association');
            assocNode.setAttribute('id', id);
            assocNode.setAttribute('sourceRef', sourceRef);
            assocNode.setAttribute('targetRef', targetRef);
            
            if nargin >= 6 && ~isempty(direction)
                assocNode.setAttribute('associationDirection', direction);
            end
            
            % Add to process
            processNode.appendChild(assocNode);
            
            % Add to diagram
            obj.addEdgeToVisualization(id, sourceRef, targetRef, waypoints);
        end
        
        function importFromDatabase(obj, dbConnector, processId, mappingConfig)
            % Import process information from database
            % dbConnector: BPMNDatabaseConnector instance
            % processId: ID of the process to import
            % mappingConfig: Structure defining how to map DB fields to BPMN elements
            
            if ~isa(dbConnector, 'BPMNDatabaseConnector')
                error('Database connector must be a BPMNDatabaseConnector instance');
            end
            
            if !dbConnector.Connected
                error('Database connection not established. Call connect first.');
            end
            
            % Get process definitions
            if nargin < 3 || isempty(processId)
                processData = dbConnector.queryProcessDefinitions();
                if isempty(processData)
                    error('No process definitions found in database');
                end
                processId = processData.process_id{1};
            end
            
            % Get process elements
            elements = dbConnector.queryProcessElements(processId);
            if isempty(elements)
                warning('No elements found for process %s', processId);
                return;
            end
            
            % Get sequence flows
            flows = dbConnector.querySequenceFlows(processId);
            
            % Process the elements
            for i = 1:height(elements)
                element = elements(i, :);
                elementId = element.element_id{1};
                elementType = element.element_type{1};
                elementName = element.element_name{1};
                
                % Get position information - would need to query from position table
                x = 100 + i * 150; % Default positioning if not available
                y = 200;
                width = 100;
                height = 80;
                
                % Create the element based on type
                switch lower(elementType)
                    case 'task'
                        obj.addTask(elementId, elementName, x, y, width, height);
                    case 'gateway'
                        gatewayType = 'exclusiveGateway'; % Default
                        % Would need logic to determine gateway type from properties
                        obj.addGateway(elementId, elementName, gatewayType, x, y, 50, 50);
                    case 'startevent'
                        obj.addEvent(elementId, elementName, 'startEvent', '', x, y, 36, 36);
                    case 'endevent'
                        obj.addEvent(elementId, elementName, 'endEvent', '', x, y, 36, 36);
                    case 'subprocess'
                        obj.addSubProcess(elementId, elementName, x, y, 200, 150, true);
                    % Additional element types would be handled here
                end
            end
            
            % Process the flows
            for i = 1:height(flows)
                flow = flows(i, :);
                flowId = flow.flow_id{1};
                sourceRef = flow.source_ref{1};
                targetRef = flow.target_ref{1};
                
                % Default waypoints - would need to query from waypoints table
                sourceX = 0; sourceY = 0; targetX = 0; targetY = 0;
                % Logic to determine waypoints would go here
                waypoints = [sourceX, sourceY; targetX, targetY];
                
                % Add condition expression if available
                condExpr = '';
                if isfield(flow, 'condition_expr') && !isempty(flow.condition_expr{1})
                    condExpr = flow.condition_expr{1};
                end
                
                obj.addSequenceFlow(flowId, sourceRef, targetRef, waypoints, condExpr);
            end
            
            fprintf('Imported %d elements and %d flows from process %s\n', ...
                   height(elements), height(flows), processId);
        end
        
        function connectToDatabase(obj, dbType, connectionParams)
            % Connect to database for process data extraction
            % dbType: Type of database ('mysql', 'postgresql', etc.)
            % connectionParams: Structure with connection parameters
            
            try
                % Use MATLAB Database Toolbox to establish connection
                switch lower(dbType)
                    case 'mysql'
                        obj.DatabaseConn = database(connectionParams.dbName, ...
                                                  connectionParams.username, ...
                                                  connectionParams.password, ...
                                                  'Vendor', 'MySQL', ...
                                                  'Server', connectionParams.server, ...
                                                  'PortNumber', connectionParams.port);
                    case 'postgresql'
                        obj.DatabaseConn = database(connectionParams.dbName, ...
                                                  connectionParams.username, ...
                                                  connectionParams.password, ...
                                                  'Vendor', 'PostgreSQL', ...
                                                  'Server', connectionParams.server, ...
                                                  'PortNumber', connectionParams.port);
                    otherwise
                        error('Unsupported database type: %s', dbType);
                end
                
                if !isempty(obj.DatabaseConn.Message)
                    error('Database connection failed: %s', obj.DatabaseConn.Message);
                end
                
                fprintf('Successfully connected to %s database\n', dbType);
            catch ex
                error('Error connecting to database: %s', ex.message);
            end
        end
        
        function saveToBPMNFile(obj, filePath)
            % Save the BPMN model to XML file
            % filePath: Path where to save the file (optional)
            
            if nargin > 1
                obj.FilePath = filePath;
            end
            
            if isempty(obj.FilePath)
                error('File path not specified. Provide a path to save the BPMN file.');
            end
            
            % Ensure output directory exists
            [fileDir, ~, ~] = fileparts(obj.FilePath);
            if !isempty(fileDir) && !exist(fileDir, 'dir')
                mkdir(fileDir);
            end
                for i = 0:processNodes.getLength()-1
                    node = processNodes.item(i);
                    if strcmp(node.getAttribute('id'), processId)
                        processNode = node;
                        return;
                    end
                end
                error('Process with ID %s not found', processId);
            else
                if processNodes.getLength() > 0
                    processNode = processNodes.item(0);
                else
                    error('No process nodes found in BPMN document');
                end
            end
        end
        
        function addShapeToVisualization(obj, elementId, x, y, width, height, isExpanded)
            % Add shape to BPMNDiagram for visualization
            % elementId: ID of the element to visualize
            % x, y: Coordinates for the element
            % width, height: Dimensions of the element
            % isExpanded: Optional parameter for subprocesses
            
            rootNode = obj.XMLDoc.getDocumentElement();
            bpmnDiNodes = rootNode.getElementsByTagName('bpmndi:BPMNDiagram');
            
            if bpmnDiNodes.getLength() > 0
                bpmnDiNode = bpmnDiNodes.item(0);
                planeNodes = bpmnDiNode.getElementsByTagName('bpmndi:BPMNPlane');
                
                if planeNodes.getLength() > 0
                    planeNode = planeNodes.item(0);
                    
                    % Create shape element
                    shapeNode = obj.XMLDoc.createElement('bpmndi:BPMNShape');
                    shapeNode.setAttribute('id', ['Shape_', elementId]);
                    shapeNode.setAttribute('bpmnElement', elementId);
                    
                    boundsNode = obj.XMLDoc.createElement('dc:Bounds');
                    boundsNode.setAttribute('x', num2str(x));
                    boundsNode.setAttribute('y', num2str(y));
                    boundsNode.setAttribute('width', num2str(width));
                    boundsNode.setAttribute('height', num2str(height));
                    
                    shapeNode.appendChild(boundsNode);
                    
                    % Add isExpanded attribute for subprocesses
                    if nargin >= 7 && ~isempty(isExpanded)
                        shapeNode.setAttribute('isExpanded', lower(toString(isExpanded)));
                    end
                    
                    planeNode.appendChild(shapeNode);
                end
            end
        end
        
        function addEdgeToVisualization(obj, flowId, sourceRef, targetRef, waypoints)
            % Add edge to BPMNDiagram for visualization
            % flowId: ID of the flow (sequence flow, message flow, etc.)
            % sourceRef: ID of the source element
            % targetRef: ID of the target element
            % waypoints: Array of {x,y} coordinates for the flow path
            
            rootNode = obj.XMLDoc.getDocumentElement();
            bpmnDiNodes = rootNode.getElementsByTagName('bpmndi:BPMNDiagram');
            
            if bpmnDiNodes.getLength() > 0
                bpmnDiNode = bpmnDiNodes.item(0);
                planeNodes = bpmnDiNode.getElementsByTagName('bpmndi:BPMNPlane');
                
                if planeNodes.getLength() > 0
                    planeNode = planeNodes.item(0);
                    
                    % Create edge element
                    edgeNode = obj.XMLDoc.createElement('bpmndi:BPMNEdge');
                    edgeNode.setAttribute('id', ['Edge_', flowId]);
                    edgeNode.setAttribute('bpmnElement', flowId);
                    
                    % Add waypoints
                    for i = 1:size(waypoints, 1)
                        wpNode = obj.XMLDoc.createElement('di:waypoint');
                        wpNode.setAttribute('x', num2str(waypoints(i, 1)));
                        wpNode.setAttribute('y', num2str(waypoints(i, 2)));
                        edgeNode.appendChild(wpNode);
                    end
                    
                    planeNode.appendChild(edgeNode);
                end
            end
        end
        
        function exportToSVG(obj, filePath)
            % Export BPMN diagram to SVG
            % This is a placeholder - actual implementation would require rendering code
            error('SVG export not yet implemented');
        end
    end
    
    % Helper functions
    methods (Static)
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