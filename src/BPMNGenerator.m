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
        function addSpecificTask(obj, id, name, taskType, properties, x, y, width, height)
            % Add a specific task type to the BPMN diagram
            % id: Unique identifier for the task
            % name: Name/label of the task
            % taskType: Type of task (userTask, serviceTask, etc.)
            % properties: Structure with task-specific properties
            % x, y: Coordinates for the task in the diagram
            % width, height: Dimensions of the task box
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create task element with specific type
            taskNode = obj.XMLDoc.createElement(taskType);
            taskNode.setAttribute('id', id);
            
            if ~isempty(name)
                taskNode.setAttribute('name', name);
            end
            
            % Add all properties as attributes
            if nargin >= 4 && ~isempty(properties)
                propFields = fieldnames(properties);
                for i = 1:length(propFields)
                    fieldName = propFields{i};
                    fieldValue = properties.(fieldName);
                    
                    % Handle special properties like implementation attributes
                    if strcmp(fieldName, 'script') && strcmp(taskType, 'scriptTask')
                        % Add script as a child element
                        scriptNode = obj.XMLDoc.createElement('script');
                        scriptText = obj.XMLDoc.createTextNode(fieldValue);
                        scriptNode.appendChild(scriptText);
                        taskNode.appendChild(scriptNode);
                    elseif strcmp(fieldName, 'multiInstanceLoopCharacteristics')
                        if ischar(fieldValue) && any(strcmpi(fieldValue, {'sequential', 'parallel'}))
                            miNode = obj.XMLDoc.createElement('multiInstanceLoopCharacteristics');
                            miNode.setAttribute('isSequential', lower(strcmpi(fieldValue, 'sequential')));
                            taskNode.appendChild(miNode);
                        end
                    else
                        % Regular attribute
                        taskNode.setAttribute(fieldName, toString(fieldValue));
                    end
                end
            end
            
            % Add to process
            processNode.appendChild(taskNode);
            
            % Add to diagram
            obj.addShapeToVisualization(id, x, y, width, height);
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
            
            % Add specific attributes for certain gateway types
            if strcmp(gatewayType, 'eventBasedGateway')
                % Default to exclusive event-based gateway
                gatewayNode.setAttribute('instantiate', 'false');
            elseif strcmp(gatewayType, 'parallelEventBasedGateway')
                % Parallel event-based gateway specific attributes
                gatewayNode.setAttribute('instantiate', 'false');
                gatewayNode.setAttribute('eventGatewayType', 'parallel');
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
        
        function addTransaction(obj, id, name, x, y, width, height, isExpanded)
            % Add a transaction subprocess to the BPMN diagram
            % id: Unique identifier for the transaction
            % name: Name/label of the transaction
            % x, y: Coordinates for the transaction in the diagram
            % width, height: Dimensions of the transaction
            % isExpanded: Whether the transaction is expanded in the diagram
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create transaction element
            transactionNode = obj.XMLDoc.createElement('transaction');
            transactionNode.setAttribute('id', id);
            
            if ~isempty(name)
                transactionNode.setAttribute('name', name);
            end
            
            % Add method attribute (compensate, store, image) - default to 'compensate'
            transactionNode.setAttribute('method', 'compensate');
            
            % Add to process
            processNode.appendChild(transactionNode);
            
            % Add to diagram with special transaction visualization
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
        
        function addGroup(obj, id, name, categoryValue, x, y, width, height)
            % Add a group artifact to the BPMN diagram
            % id: Unique identifier for the group
            % name: Optional name/label of the group
            % categoryValue: Optional category value for classification
            % x, y: Coordinates for the group in the diagram
            % width, height: Dimensions of the group
            
            % Get process node
            processNode = obj.getProcessNode();
            
            % Create group element
            groupNode = obj.XMLDoc.createElement('group');
            groupNode.setAttribute('id', id);
            
            if ~isempty(name)
                groupNode.setAttribute('name', name);
            end
            
            if nargin >= 4 && ~isempty(categoryValue)
                groupNode.setAttribute('categoryValue', categoryValue);
            end
            
            % Add to process
            processNode.appendChild(groupNode);
            
            % Add to diagram
            obj.addShapeToVisualization(id, x, y, width, height);
        end
        
        function importFromDatabase(obj, dbConnector, processId)
            % Import BPMN definition from a database connection.
            % Requires a connected BPMNDatabaseConnector object.
            % dbConnector: BPMNDatabaseConnector instance
            % processId: Optional ID of the process to import (if not provided, first process will be used)
            
            if ~isa(dbConnector, 'BPMNDatabaseConnector')
                error('BPMNGenerator:ImportError', 'Database connector must be a BPMNDatabaseConnector instance');
            end
            
            if !dbConnector.Connected
                error('BPMNGenerator:ConnectionError', 'Database connection not established. Call connect first.');
            end
            
            obj.DatabaseConn = dbConnector; % Store connector for later use
            
            % Get process definitions if processId not provided
            if nargin < 3 || isempty(processId)
                processData = dbConnector.queryProcessDefinitions();
                if isempty(processData)
                    error('BPMNGenerator:NoProcessError', 'No process definitions found in database');
                end
                processId = processData.process_id{1};
                
                % Set process attributes if available
                if ismember('is_executable', processData.Properties.VariableNames)
                    processNode = obj.getProcessNode();
                    processNode.setAttribute('isExecutable', lower(processData.is_executable{1}));
                end
                if ismember('process_name', processData.Properties.VariableNames)
                    processNode = obj.getProcessNode();
                    processNode.setAttribute('name', processData.process_name{1});
                end
            end
            
            fprintf('Importing process %s from database...\n', processId);
            
            try
                % --- 1. Import BPMN Elements ---
                fprintf('Importing elements...\n');
                elementsData = dbConnector.fetchElements(processId);
                
                if !isempty(elementsData)
                    fprintf('Found %d elements in database\n', height(elementsData));
                    
                    % Process each element based on type
                    for i = 1:height(elementsData)
                        element = elementsData(i, :);
                        
                        % Extract common fields
                        elementId = element.element_id{1};
                        elementType = element.element_type{1};
                        elementName = '';
                        
                        % Get name - handle different field names
                        if ismember('element_name', element.Properties.VariableNames)
                            elementName = element.element_name{1};
                        elseif ismember('name', element.Properties.VariableNames)
                            elementName = element.name{1};
                        end
                        
                        % Get position and size if available
                        x = 100 + i * 150; % Default positioning if not available
                        y = 200;
                        width = 100;
                        height = 80;
                        
                        if ismember('x', element.Properties.VariableNames) && !isnan(element.x)
                            x = element.x;
                        end
                        if ismember('y', element.Properties.VariableNames) && !isnan(element.y)
                            y = element.y;
                        end
                        if ismember('width', element.Properties.VariableNames) && !isnan(element.width)
                            width = element.width;
                        end
                        if ismember('height', element.Properties.VariableNames) && !isnan(element.height)
                            height = element.height;
                        end
                        
                        % Handle element based on its type
                        fprintf('Processing %s: %s\n', elementType, elementId);
                        
                        switch lower(elementType)
                            % Tasks
                            case 'task'
                                obj.addTask(elementId, elementName, x, y, width, height);
                            case 'usertask'
                                obj.addSpecificTask(elementId, elementName, 'userTask', struct(), x, y, width, height);
                            case 'servicetask'
                                properties = struct();
                                if ismember('implementation', element.Properties.VariableNames) && !isempty(element.implementation{1})
                                    properties.implementation = element.implementation{1};
                                end
                                obj.addSpecificTask(elementId, elementName, 'serviceTask', properties, x, y, width, height);
                            case 'scripttask'
                                properties = struct();
                                if ismember('script', element.Properties.VariableNames) && !isempty(element.script{1})
                                    properties.script = element.script{1};
                                end
                                if ismember('script_format', element.Properties.VariableNames) && !isempty(element.script_format{1})
                                    properties.scriptFormat = element.script_format{1};
                                end
                                obj.addSpecificTask(elementId, elementName, 'scriptTask', properties, x, y, width, height);
                                
                            % Gateways
                            case {'exclusivegateway', 'gateway'}
                                obj.addGateway(elementId, elementName, 'exclusiveGateway', x, y, 50, 50);
                            case 'parallelgateway'
                                obj.addGateway(elementId, elementName, 'parallelGateway', x, y, 50, 50);
                                
                            % Events
                            case 'startevent'
                                eventDefType = '';
                                if ismember('event_definition_type', element.Properties.VariableNames) && !isempty(element.event_definition_type{1})
                                    eventDefType = element.event_definition_type{1};
                                end
                                obj.addEvent(elementId, elementName, 'startEvent', eventDefType, x, y, 36, 36);
                            case 'endevent'
                                eventDefType = '';
                                if ismember('event_definition_type', element.Properties.VariableNames) && !isempty(element.event_definition_type{1})
                                    eventDefType = element.event_definition_type{1};
                                end
                                obj.addEvent(elementId, elementName, 'endEvent', eventDefType, x, y, 36, 36);
                            case 'boundaryevent'
                                eventDefType = '';
                                isInterrupting = true;
                                attachedToRef = '';
                                
                                if ismember('event_definition_type', element.Properties.VariableNames) && !isempty(element.event_definition_type{1})
                                    eventDefType = element.event_definition_type{1};
                                end
                                if ismember('is_interrupting', element.Properties.VariableNames)
                                    isInterrupting = element.is_interrupting;
                                end
                                if ismember('attached_to_ref', element.Properties.VariableNames) && !isempty(element.attached_to_ref{1})
                                    attachedToRef = element.attached_to_ref{1};
                                end
                                
                                obj.addBoundaryEvent(elementId, elementName, attachedToRef, eventDefType, isInterrupting, x, y, 36, 36);
                                
                            % Container elements    
                            case 'subprocess'
                                isExpanded = true;
                                if ismember('is_expanded', element.Properties.VariableNames)
                                    isExpanded = element.is_expanded;
                                end
                                obj.addSubProcess(elementId, elementName, x, y, 200, 150, isExpanded);
                            case 'pool'
                                processRef = '';
                                if ismember('process_ref', element.Properties.VariableNames) && !isempty(element.process_ref{1})
                                    processRef = element.process_ref{1};
                                end
                                obj.addPool(elementId, elementName, processRef, x, y, 600, 200);
                            case 'lane'
                                parentId = '';
                                if ismember('parent_id', element.Properties.VariableNames) && !isempty(element.parent_id{1})
                                    parentId = element.parent_id{1};
                                end
                                obj.addLane(elementId, elementName, parentId, x, y, 570, 200);
                                
                            % Data elements    
                            case 'dataobject'
                                isCollection = false;
                                if ismember('is_collection', element.Properties.VariableNames)
                                    isCollection = element.is_collection;
                                end
                                obj.addDataObject(elementId, elementName, isCollection, x, y, 36, 50);
                                
                            % Annotations
                            case 'textannotation'
                                text = elementName; % Use name as the text content
                                obj.addTextAnnotation(elementId, text, x, y, 100, 50);
                                
                            % Handle other types
                            otherwise
                                warning('BPMNGenerator:UnknownElement', 'Unknown element type: %s (ID: %s)', elementType, elementId);
                        end
                    end
                else
                    warning('BPMNGenerator:NoElements', 'No elements found for process %s', processId);
                end
                
                % --- 2. Import Sequence Flows ---
                fprintf('Importing sequence flows...\n');
                flowsData = dbConnector.fetchSequenceFlows(processId);
                
                if !isempty(flowsData)
                    fprintf('Found %d sequence flows in database\n', height(flowsData));
                    
                    for i = 1:height(flowsData)
                        flow = flowsData(i, :);
                        
                        % Extract flow fields
                        flowId = flow.flow_id{1};
                        sourceRef = flow.source_ref{1};
                        targetRef = flow.target_ref{1};
                        
                        % Extract condition if available
                        condExpr = '';
                        if ismember('condition_expr', flow.Properties.VariableNames) && !isempty(flow.condition_expr{1})
                            condExpr = flow.condition_expr{1};
                        end
                        
                        % Check for waypoints
                        waypoints = [];
                        if ismember('waypoints_data', flow.Properties.VariableNames) && !isempty(flow.waypoints_data{1})
                            % Parse the waypoints data string
                            wpData = flow.waypoints_data{1};
                            waypoints = parseWaypointsData(wpData);
                        end
                        
                        % If no waypoints, create default straight line
                        if isempty(waypoints)
                            % Create default waypoints between elements
                            % This is simplified - would need element positions for better defaults
                            waypoints = [100, 100; 200, 200];
                        end
                        
                        fprintf('Processing sequence flow: %s (%s -> %s)\n', flowId, sourceRef, targetRef);
                        obj.addSequenceFlow(flowId, sourceRef, targetRef, waypoints, condExpr);
                    end
                else
                    warning('BPMNGenerator:NoFlows', 'No sequence flows found for process %s', processId);
                end
                
                % --- 3. Import Message Flows ---
                fprintf('Importing message flows...\n');
                messageFlowsData = dbConnector.fetchMessageFlows();
                
                if !isempty(messageFlowsData)
                    fprintf('Found %d message flows in database\n', height(messageFlowsData));
                    
                    for i = 1:height(messageFlowsData)
                        flow = messageFlowsData(i, :);
                        
                        % Extract flow fields
                        flowId = flow.flow_id{1};
                        sourceRef = flow.source_ref{1};
                        targetRef = flow.target_ref{1};
                        
                        % Extract message name if available
                        messageName = '';
                        if ismember('message_id', flow.Properties.VariableNames) && !isempty(flow.message_id{1})
                            messageName = flow.message_id{1};
                        end
                        
                        % Check for waypoints
                        waypoints = [];
                        if ismember('waypoints_data', flow.Properties.VariableNames) && !isempty(flow.waypoints_data{1})
                            % Parse the waypoints data string
                            wpData = flow.waypoints_data{1};
                            waypoints = parseWaypointsData(wpData);
                        end
                        
                        % If no waypoints, create default straight line
                        if isempty(waypoints)
                            waypoints = [100, 100; 200, 200];
                        end
                        
                        fprintf('Processing message flow: %s (%s -> %s)\n', flowId, sourceRef, targetRef);
                        obj.addMessageFlow(flowId, sourceRef, targetRef, waypoints, messageName);
                    end
                else
                    fprintf('No message flows found\n');
                end
                
                % --- 4. Import Data Objects and Associations ---
                fprintf('Importing data objects...\n');
                dataObjectsData = dbConnector.fetchDataObjects(processId);
                
                if !isempty(dataObjectsData)
                    fprintf('Found %d data objects in database\n', height(dataObjectsData));
                    
                    for i = 1:height(dataObjectsData)
                        dataObj = dataObjectsData(i, :);
                        
                        % Extract data object fields
                        dataObjId = dataObj.data_object_id{1};
                        
                        % Get name
                        dataObjName = '';
                        if ismember('name', dataObj.Properties.VariableNames) && !isempty(dataObj.name{1})
                            dataObjName = dataObj.name{1};
                        end
                        
                        % Check if collection
                        isCollection = false;
                        if ismember('is_collection', dataObj.Properties.VariableNames)
                            isCollection = dataObj.is_collection;
                        end
                        
                        % Get position
                        x = 300 + i * 100;
                        y = 100;
                        width = 36;
                        height = 50;
                        
                        if ismember('x', dataObj.Properties.VariableNames) && !isnan(dataObj.x)
                            x = dataObj.x;
                        end
                        if ismember('y', dataObj.Properties.VariableNames) && !isnan(dataObj.y)
                            y = dataObj.y;
                        end
                        if ismember('width', dataObj.Properties.VariableNames) && !isnan(dataObj.width)
                            width = dataObj.width;
                        end
                        if ismember('height', dataObj.Properties.VariableNames) && !isnan(dataObj.height)
                            height = dataObj.height;
                        end
                        
                        fprintf('Processing data object: %s\n', dataObjId);
                        obj.addDataObject(dataObjId, dataObjName, isCollection, x, y, width, height);
                    end
                else
                    fprintf('No data objects found\n');
                end
                
                % Get data associations
                fprintf('Importing data associations...\n');
                dataAssocData = dbConnector.fetchDataAssociations();
                
                if !isempty(dataAssocData)
                    fprintf('Found %d data associations in database\n', height(dataAssocData));
                    
                    for i = 1:height(dataAssocData)
                        assoc = dataAssocData(i, :);
                        
                        % Extract data association fields
                        assocId = assoc.association_id{1};
                        sourceRef = assoc.source_ref{1};
                        targetRef = assoc.target_ref{1};
                        
                        % Check for waypoints
                        waypoints = [];
                        if ismember('waypoints_data', assoc.Properties.VariableNames) && !isempty(assoc.waypoints_data{1})
                            % Parse the waypoints data string
                            wpData = assoc.waypoints_data{1};
                            waypoints = parseWaypointsData(wpData);
                        end
                        
                        % If no waypoints, create default straight line
                        if isempty(waypoints)
                            waypoints = [100, 100; 200, 200];
                        end
                        
                        fprintf('Processing data association: %s (%s -> %s)\n', assocId, sourceRef, targetRef);
                        obj.addDataAssociation(assocId, sourceRef, targetRef, waypoints);
                    end
                else
                    fprintf('No data associations found\n');
                end
                
                % --- 5. Import Text Annotations and Associations ---
                fprintf('Importing text annotations and associations...\n');
                
                % Text annotations are handled in the main elements loop
                
                % Get regular associations (not data associations)
                associationData = dbConnector.fetchAssociations(processId);
                
                if !isempty(associationData)
                    fprintf('Found %d associations in database\n', height(associationData));
                    
                    for i = 1:height(associationData)
                        assoc = associationData(i, :);
                        
                        % Extract association fields
                        assocId = assoc.flow_id{1};
                        sourceRef = assoc.source_ref{1};
                        targetRef = assoc.target_ref{1};
                        
                        % Get direction if available
                        direction = 'None';
                        if ismember('association_direction', assoc.Properties.VariableNames) && !isempty(assoc.association_direction{1})
                            direction = assoc.association_direction{1};
                        end
                        
                        % Check for waypoints
                        waypoints = [];
                        if ismember('waypoints_data', assoc.Properties.VariableNames) && !isempty(assoc.waypoints_data{1})
                            % Parse the waypoints data string
                            wpData = assoc.waypoints_data{1};
                            waypoints = parseWaypointsData(wpData);
                        end
                        
                        % If no waypoints, create default straight line
                        if isempty(waypoints)
                            waypoints = [100, 100; 200, 200];
                        end
                        
                        fprintf('Processing association: %s (%s -> %s)\n', assocId, sourceRef, targetRef);
                        obj.addAssociation(assocId, sourceRef, targetRef, waypoints, direction);
                    end
                else
                    fprintf('No associations found\n');
                end
                
                fprintf('Database import completed successfully!\n');
                
            catch ME
                % Add context to the error and rethrow
                newME = MException('BPMNGenerator:DatabaseImportError', ...
                    'Error importing BPMN from database: %s', ME.message);
                newME.addCause(ME);
                throw(newME);
            end
        end
        
        function importFromFile(obj, filePath)
            % Import BPMN definition from an existing BPMN XML file
            % filePath: Path to the BPMN XML file
            
            if ~exist(filePath, 'file')
                error('BPMNGenerator:ImportError', 'BPMN file does not exist: %s', filePath);
            end
            
            try
                % Load the BPMN XML file
                fprintf('Loading BPMN file: %s\n', filePath);
                
                % Preserve the original file path if needed
                originalFilePath = obj.FilePath;
                obj.FilePath = filePath;
                
                % Load the XML document
                bpmnDoc = xmlread(filePath);
                obj.XMLDoc = bpmnDoc;
                
                % Update the internal collections of processes and collaborations
                obj.updateInternalCollections();
                
                fprintf('BPMN file imported successfully!\n');
                
            catch ME
                % Add context to the error and rethrow
                newME = MException('BPMNGenerator:FileImportError', ...
                    'Error importing BPMN from file: %s', ME.message);
                newME.addCause(ME);
                throw(newME);
            end
        end
        
        function updateInternalCollections(obj)
            % Update internal collections of processes, collaborations, etc.
            % after loading a BPMN file
            
            % Clear existing collections
            obj.Processes = {};
            obj.Collaborations = {};
            obj.Participants = {};
            
            rootNode = obj.XMLDoc.getDocumentElement();
            
            % Get all processes
            processNodes = rootNode.getElementsByTagName('process');
            for i = 0:processNodes.getLength()-1
                processNode = processNodes.item(i);
                obj.Processes{end+1} = processNode;
            end
            
            % Get all collaborations
            collabNodes = rootNode.getElementsByTagName('collaboration');
            for i = 0:collabNodes.getLength()-1
                collabNode = collabNodes.item(i);
                obj.Collaborations{end+1} = collabNode;
                
                % Process participants in each collaboration
                participantNodes = collabNode.getElementsByTagName('participant');
                for j = 0:participantNodes.getLength()-1
                    participantNode = participantNodes.item(j);
                    id = char(participantNode.getAttribute('id'));
                    processRef = '';
                    if participantNode.hasAttribute('processRef')
                        processRef = char(participantNode.getAttribute('processRef'));
                    end
                    obj.Participants{end+1} = struct('id', id, 'processRef', processRef);
                end
            end
            
            % Update ProcessElements structure (optional)
            obj.extractProcessElements();
        end
        
        function extractProcessElements(obj)
            % Extract process elements from the BPMN document into internal structure
            % This makes them easier to access and manipulate
            
            obj.ProcessElements = struct('tasks', {}, 'gateways', {}, 'events', {}, 'flows', {});
            
            % Get the process node
            try
                processNode = obj.getProcessNode();
            catch
                warning('No process node found in BPMN document.');
                return;
            end
            
            % Extract tasks
            taskNodes = processNode.getElementsByTagName('task');
            for i = 0:taskNodes.getLength()-1
                taskNode = taskNodes.item(i);
                id = char(taskNode.getAttribute('id'));
                name = '';
                if taskNode.hasAttribute('name')
                    name = char(taskNode.getAttribute('name'));
                end
                
                % Add to tasks collection
                taskElement = struct('id', id, 'name', name, 'type', 'task', 'node', taskNode);
                obj.ProcessElements.tasks{end+1} = taskElement;
            end
            
            % Extract user tasks
            userTaskNodes = processNode.getElementsByTagName('userTask');
            for i = 0:userTaskNodes.getLength()-1
                taskNode = userTaskNodes.item(i);
                id = char(taskNode.getAttribute('id'));
                name = '';
                if taskNode.hasAttribute('name')
                    name = char(taskNode.getAttribute('name'));
                end
                
                % Add to tasks collection
                taskElement = struct('id', id, 'name', name, 'type', 'userTask', 'node', taskNode);
                obj.ProcessElements.tasks{end+1} = taskElement;
            end
            
            % Extract service tasks
            serviceTaskNodes = processNode.getElementsByTagName('serviceTask');
            for i = 0:serviceTaskNodes.getLength()-1
                taskNode = serviceTaskNodes.item(i);
                id = char(taskNode.getAttribute('id'));
                name = '';
                if taskNode.hasAttribute('name')
                    name = char(taskNode.getAttribute('name'));
                end
                
                % Add to tasks collection
                taskElement = struct('id', id, 'name', name, 'type', 'serviceTask', 'node', taskNode);
                obj.ProcessElements.tasks{end+1} = taskElement;
            end
            
            % Extract gateways
            gatewayTypes = {'exclusiveGateway', 'parallelGateway', 'inclusiveGateway', 'complexGateway', 'eventBasedGateway'};
            
            for t = 1:length(gatewayTypes)
                gatewayType = gatewayTypes{t};
                gatewayNodes = processNode.getElementsByTagName(gatewayType);
                
                for i = 0:gatewayNodes.getLength()-1
                    gatewayNode = gatewayNodes.item(i);
                    id = char(gatewayNode.getAttribute('id'));
                    name = '';
                    if gatewayNode.hasAttribute('name')
                        name = char(gatewayNode.getAttribute('name'));
                    end
                    
                    % Add to gateways collection
                    gatewayElement = struct('id', id, 'name', name, 'type', gatewayType, 'node', gatewayNode);
                    obj.ProcessElements.gateways{end+1} = gatewayElement;
                end
            end
            
            % Extract events
            eventTypes = {'startEvent', 'endEvent', 'intermediateThrowEvent', 'intermediateCatchEvent', 'boundaryEvent'};
            
            for t = 1:length(eventTypes)
                eventType = eventTypes{t};
                eventNodes = processNode.getElementsByTagName(eventType);
                
                for i = 0:eventNodes.getLength()-1
                    eventNode = eventNodes.item(i);
                    id = char(eventNode.getAttribute('id'));
                    name = '';
                    if eventNode.hasAttribute('name')
                        name = char(eventNode.getAttribute('name'));
                    end
                    
                    % Determine event definition type
                    eventDefinition = 'none';
                    childNodes = eventNode.getChildNodes();
                    for j = 0:childNodes.getLength()-1
                        childNode = childNodes.item(j);
                        if childNode.getNodeType() == 1  % Element node
                            nodeName = char(childNode.getNodeName());
                            if contains(nodeName, 'EventDefinition')
                                eventDefinition = nodeName;
                                break;
                            end
                        end
                    end
                    
                    % Add to events collection
                    eventElement = struct('id', id, 'name', name, 'type', eventType, ...
                        'definitionType', eventDefinition, 'node', eventNode);
                    obj.ProcessElements.events{end+1} = eventElement;
                end
            end
            
            % Extract sequence flows
            flowNodes = processNode.getElementsByTagName('sequenceFlow');
            
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                id = char(flowNode.getAttribute('id'));
                sourceRef = char(flowNode.getAttribute('sourceRef'));
                targetRef = char(flowNode.getAttribute('targetRef'));
                name = '';
                if flowNode.hasAttribute('name')
                    name = char(flowNode.getAttribute('name'));
                end
                
                % Check for condition expression
                conditionExpr = '';
                conditionNodes = flowNode.getElementsByTagName('conditionExpression');
                if conditionNodes.getLength() > 0
                    conditionNode = conditionNodes.item(0);
                    if conditionNode.hasChildNodes()
                        conditionExpr = char(conditionNode.getFirstChild().getNodeValue());
                    end
                end
                
                % Add to flows collection
                flowElement = struct('id', id, 'name', name, 'type', 'sequenceFlow', ...
                    'sourceRef', sourceRef, 'targetRef', targetRef, ...
                    'conditionExpression', conditionExpr, 'node', flowNode);
                obj.ProcessElements.flows{end+1} = flowElement;
            end
        end
        
        function modifyElement(obj, elementId, properties)
            % Modify an existing BPMN element's properties
            % elementId: ID of the element to modify
            % properties: Structure with properties to update
            
            if isempty(elementId)
                error('BPMNGenerator:ModifyError', 'Element ID cannot be empty');
            end
            
            if ~isstruct(properties)
                error('BPMNGenerator:ModifyError', 'Properties must be provided as a structure');
            end
            
            % Find the element in the document
            rootNode = obj.XMLDoc.getDocumentElement();
            allNodes = rootNode.getElementsByTagName('*');
            
            elementNode = [];
            for i = 0:allNodes.getLength()-1
                node = allNodes.item(i);
                if node.getNodeType() == 1 && node.hasAttribute('id') % Element node with id attribute
                    if strcmp(char(node.getAttribute('id')), elementId)
                        elementNode = node;
                        break;
                    end
                end
            end
            
            if isempty(elementNode)
                error('BPMNGenerator:ModifyError', 'Element with ID %s not found', elementId);
            end
            
            % Update the element's properties
            propFields = fieldnames(properties);
            for i = 1:length(propFields)
                fieldName = propFields{i};
                fieldValue = properties.(fieldName);
                
                if strcmpi(fieldName, 'name')
                    elementNode.setAttribute('name', char(fieldValue));
                elseif strcmpi(fieldName, 'x') || strcmpi(fieldName, 'y') || ...
                       strcmpi(fieldName, 'width') || strcmpi(fieldName, 'height')
                    % Update element position/size in the visualization
                    obj.updateElementVisualization(elementId, properties);
                    break; % Only need to do this once for all position/size properties
                else
                    % For other properties, just set the attribute directly
                    elementNode.setAttribute(fieldName, obj.toString(fieldValue));
                end
            end
            
            fprintf('Element %s updated successfully\n', elementId);
        end
        
        function updateElementVisualization(obj, elementId, properties)
            % Update the visualization properties of a BPMN element
            % elementId: ID of the element to update
            % properties: Structure with x, y, width, height properties
            
            rootNode = obj.XMLDoc.getDocumentElement();
            bpmnDiNodes = rootNode.getElementsByTagName('bpmndi:BPMNDiagram');
            
            if bpmnDiNodes.getLength() == 0
                warning('No BPMNDiagram element found in BPMN document');
                return;
            end
            
            bpmnDiNode = bpmnDiNodes.item(0);
            planeNodes = bpmnDiNode.getElementsByTagName('bpmndi:BPMNPlane');
            
            if planeNodes.getLength() == 0
                warning('No BPMNPlane element found in BPMN document');
                return;
            end
            
            planeNode = planeNodes.item(0);
            
            % Find the shape element for the element being modified
            shapeNodes = planeNode.getElementsByTagName('bpmndi:BPMNShape');
            shapeNode = [];
            
            for i = 0:shapeNodes.getLength()-1
                shape = shapeNodes.item(i);
                if strcmp(char(shape.getAttribute('bpmnElement')), elementId)
                    shapeNode = shape;
                    break;
                end
            end
            
            if isempty(shapeNode)
                warning('No shape element found for element %s', elementId);
                return;
            end
            
            % Update the bounds
            boundsNodes = shapeNode.getElementsByTagName('dc:Bounds');
            if boundsNodes.getLength() > 0
                boundsNode = boundsNodes.item(0);
                
                if isfield(properties, 'x')
                    boundsNode.setAttribute('x', num2str(properties.x));
                end
                
                if isfield(properties, 'y')
                    boundsNode.setAttribute('y', num2str(properties.y));
                end
                
                if isfield(properties, 'width')
                    boundsNode.setAttribute('width', num2str(properties.width));
                end
                
                if isfield(properties, 'height')
                    boundsNode.setAttribute('height', num2str(properties.height));
                end
            end
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
                % Use try-catch because mkdir can fail in compiled applications with
                % certain permissions
                try
                    mkdir(fileDir);
                catch ME
                    warning('Cannot create directory: %s. Will attempt to save file anyway.', fileDir);
                end
            end
            
            % Write XML to file with error handling for compiled context
            try
                xmlwrite(obj.FilePath, obj.XMLDoc);
                fprintf('BPMN file saved to: %s\n', obj.FilePath);
            catch ME
                error('Failed to save BPMN file: %s', ME.message);
            end
        end
        
        function processNode = getProcessNode(obj, processId)
            % Helper method to get a process node
            % processId: Optional ID of specific process to get
            
            rootNode = obj.XMLDoc.getDocumentElement();
            processNodes = rootNode.getElementsByTagName('process');
            
            % Return specific process if ID provided, otherwise first process
            if nargin >= 2 && !isempty(processId)
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
                    if nargin >= 7 && !isempty(isExpanded)
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