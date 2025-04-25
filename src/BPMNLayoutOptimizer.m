classdef BPMNLayoutOptimizer < handle
    % BPMNLAYOUTOPTIMIZER - class to optimize the layout of BPMN diagrams
    %

    % This class implements various algorithms to optimize the layout
    % From BPMN diagrams, including intersection minimization, distance optimization
    % and alignment functions.
    
    properties
        diagram         % Referenz zum BPMN-Diagramm
        optimizeOptions % Optionen für die Optimierung
    end
    
    methods
        function obj = BPMNLayoutOptimizer(diagram, options)
            % Constructor for the BPMnlayoutoptimizer
            %

            % Input:
            % Diagram - BPMN diagram object
            % Options - Struct with optimization options (optional)
            
            obj.diagram = diagram;
            
            % Set standard options
            defaultOptions = struct(...
                'Minnodedistance', 50, ...
                'layerspacing', 100, ...
                'Optimizecrossings', true, ...
                'Aligngateways', true, ...
                'center', true, ...
                'Smartedgerouting', true, ...
                'avoid element overlap', true, ...  % Neue Option
                'OptimizeFlowpaths', true);       % Neue Option
            
            % If options have been provided, overwrite the standard values
            if nargin > 1 && ~isempty(options)
                optFields = fieldnames(options);
                for i = 1:length(optFields)
                    defaultOptions.(optFields{i}) = options.(optFields{i});
                end
            end
            
            obj.optimizeOptions = defaultOptions;
        end
        
        function optimizedDiagram = optimizeAll(obj)
            % Optimizes the entire diagram layout
            %

            % Return:
            % Optimized diagram - the optimized diagram
            
            % Create layers and assign elements
            layers = obj.assignElementsToLayers();
            
            % Minimize crossings between the layers
            if obj.optimizeOptions.optimizeCrossings
                layers = obj.minimizeCrossings(layers);
            end
            
            % Position elements based on the optimized layers
            obj.positionElements(layers);
            
            % Align gateways
            if obj.optimizeOptions.alignGateways
                obj.alignGateways();
            end
            
            % Center activities
            if obj.optimizeOptions.centerActivities
                obj.centerActivities();
            end
            
            % Avoid element overlaps - new function
            if obj.optimizeOptions.avoidElementOverlap
                obj.resolveElementOverlaps();
            end
            
            % Optimize Edge routing
            if obj.optimizeOptions.smartEdgeRouting
                obj.routeEdges();
            end
            
            % Optimize river paths - new function
            if obj.optimizeOptions.optimizeFlowPaths
                obj.optimizeFlowPaths();
            end
            
            optimizedDiagram = obj.diagram;
        end
        
        function layers = assignElementsToLayers(obj)
            % Points out elements based on the process flow direction
            %

            % Return:
            % Layers - Cell Array with element groups per shift
            
            % Implementation of a simple layering algorithm
            elements = obj.diagram.elements;
            flows = obj.diagram.flows;
            
            % Find start events as a starting point
            startElements = {};
            for i = 1:length(elements)
                if strcmpi(elements{i}.type, 'start event')
                    startElements{end+1} = elements{i}; %#ok<AGROW>
                end
            end
            
            % If no start events found, we take any elements without incoming flows
            if isempty(startElements)
                nodesWithoutIncoming = obj.findNodesWithoutIncomingFlows();
                startElements = nodesWithoutIncoming;
            end
            
            % Initialist Layers
            layers = {};
            currentLayer = 1;
            layers{currentLayer} = startElements;
            
            processedElements = {};
            
            % To lay iterative assignment of elements
            while ~isempty(layers{currentLayer})
                nextLayer = {};
                
                for i = 1:length(layers{currentLayer})
                    currentElement = layers{currentLayer}{i};
                    processedElements{end+1} = currentElement.id; %#ok<AGROW>
                    
                    % Find all outgoing flows and their goals
                    for j = 1:length(flows)
                        if strcmp(flows{j}.sourceRef, currentElement.id)
                            targetId = flows{j}.targetRef;
                            
                            % Find the target element
                            targetElement = obj.findElementById(targetId);
                            
                            % Check whether the target element has already been processed
                            if ~isempty(targetElement) && ~ismember(targetId, processedElements)
                                % Check whether all sources have already been processed
                                allSourcesProcessed = true;
                                
                                for k = 1:length(flows)
                                    if strcmp(flows{k}.targetRef, targetId) && ...
                                            ~strcmp(flows{k}.sourceRef, currentElement.id) && ...
                                            ~ismember(flows{k}.sourceRef, processedElements)
                                        allSourcesProcessed = false;
                                        break;
                                    end
                                end
                                
                                % Only add the element when all sources have been processed
                                if allSourcesProcessed && ~obj.isElementInAnyLayer(nextLayer, targetElement)
                                    nextLayer{end+1} = targetElement; %#ok<AGROW>
                                end
                            end
                        end
                    end
                end
                
                currentLayer = currentLayer + 1;
                if ~isempty(nextLayer)
                    layers{currentLayer} = nextLayer;
                else
                    break;
                end
            end
        end
        
        function nodesWithoutIncoming = findNodesWithoutIncomingFlows(obj)
            % Find elements without incoming flows
            elements = obj.diagram.elements;
            flows = obj.diagram.flows;
            
            nodesWithoutIncoming = {};
            
            for i = 1:length(elements)
                hasIncoming = false;
                
                for j = 1:length(flows)
                    if strcmp(flows{j}.targetRef, elements{i}.id)
                        hasIncoming = true;
                        break;
                    end
                end
                
                if ~hasIncoming
                    nodesWithoutIncoming{end+1} = elements{i}; %#ok<AGROW>
                end
            end
        end
        
        function element = findElementById(obj, id)
            % Finds an element through its ID
            elements = obj.diagram.elements;
            element = [];
            
            for i = 1:length(elements)
                if strcmp(elements{i}.id, id)
                    element = elements{i};
                    return;
                end
            end
        end
        
        function result = isElementInAnyLayer(~, layer, element)
            % Check whether an element is already included in a layer
            result = false;
            
            if isempty(layer)
                return;
            end
            
            for i = 1:length(layer)
                if strcmp(layer{i}.id, element.id)
                    result = true;
                    return;
                end
            end
        end
        
        function layers = minimizeCrossings(obj, layers)
            % Minimizes crossings between the layers
            %

            % Entry/return:
            % Layers - Cell Array with element groups per shift
            
            % Simple algorithm for crossing minimization
            % For each layer, elements are sorted based on connections
            
            for i = 2:length(layers)
                if length(layers{i}) > 1
                    % Determine the optimal order based on connections
                    % To the previous layer
                    
                    % A simple approach: arrange the elements according to the position of their
                    % Sources in the previous layer
                    
                    % Create a list of [element, weighted position]
                    elementPositions = cell(1, length(layers{i}));
                    flows = obj.diagram.flows;
                    
                    for j = 1:length(layers{i})
                        currentElement = layers{i}{j};
                        incomingPositionSum = 0;
                        incomingCount = 0;
                        
                        % Find all incoming rivers from the previous layer
                        for k = 1:length(flows)
                            if strcmp(flows{k}.targetRef, currentElement.id)
                                % Find the position of the source in the previous layer
                                sourceElement = obj.findElementById(flows{k}.sourceRef);
                                if ~isempty(sourceElement)
                                    for l = 1:length(layers{i-1})
                                        if strcmp(layers{i-1}{l}.id, sourceElement.id)
                                            incomingPositionSum = incomingPositionSum + l;
                                            incomingCount = incomingCount + 1;
                                            break;
                                        end
                                    end
                                end
                            end
                        end
                        
                        % Calculate the average position value
                        avgPosition = incomingCount > 0 ? incomingPositionSum / incomingCount : j;
                        elementPositions{j} = {currentElement, avgPosition};
                    end
                    
                    % Sort the elements according to their average position
                    positionValues = cellfun(@(x) x{2}, elementPositions);
                    [~, sortIdx] = sort(positionValues);
                    
                    % Sort the layer new
                    sortedLayer = cell(1, length(layers{i}));
                    for j = 1:length(sortIdx)
                        sortedLayer{j} = elementPositions{sortIdx(j)}{1};
                    end
                    
                    layers{i} = sortedLayer;
                end
            end
        end
        
        function positionElements(obj, layers)
            % Positioned elements based on the optimized layers
            
            % Basic configuration
            layerHeight = obj.optimizeOptions.layerSpacing;
            elementWidth = 100;  % Standard Elementbreite
            elementHeight = 80;  % Standard Elementhöhe
            marginX = obj.optimizeOptions.minNodeDistance;
            startX = 50;
            startY = 50;
            
            % Position every element based on its layer
            for i = 1:length(layers)
                currentY = startY + (i-1) * layerHeight;
                layerWidth = (length(layers{i}) - 1) * (elementWidth + marginX);
                currentX = startX;
                
                for j = 1:length(layers{i})
                    element = layers{i}{j};
                    
                    % Adjust the element size depending on the type
                    if strcmpi(element.type, 'task')
                        w = 100;
                        h = 80;
                    elseif strcmpi(element.type, 'gateway')
                        w = 50;
                        h = 50;
                    elseif any(strcmpi(element.type, {'start event', 'end event', 'intermediate event'}))
                        w = 40;
                        h = 40;
                    else
                        w = elementWidth;
                        h = elementHeight;
                    end
                    
                    % Position
                    element.x = currentX;
                    element.y = currentY;
                    element.width = w;
                    element.height = h;
                    
                    % Update the X position for the next element
                    currentX = currentX + w + marginX;
                end
            end
            
            % Post -processing: Center elements in every layer
            for i = 1:length(layers)
                if ~isempty(layers{i})
                    totalWidth = layers{i}{end}.x + layers{i}{end}.width - layers{i}{1}.x;
                    centerOffset = (layerWidth - totalWidth) / 2;
                    
                    if centerOffset > 0
                        for j = 1:length(layers{i})
                            layers{i}{j}.x = layers{i}{j}.x + centerOffset;
                        end
                    end
                end
            end
        end
        
        function alignGateways(obj)
            % Aligns gateways vertically
            
            elements = obj.diagram.elements;
            
            % Group gateways according to type
            gateways = {};
            for i = 1:length(elements)
                if strcmpi(elements{i}.type, 'Exclusivegateway') || ...
                   strcmpi(elements{i}.type, 'parallel gateway') || ...
                   strcmpi(elements{i}.type, 'Inclusiveegateway')
                    gateways{end+1} = elements{i}; %#ok<AGROW>
                end
            end
            
            % Find similar gateway groups (e.g. split/join pairs)
            if length(gateways) > 1
                for i = 1:length(gateways)-1
                    for j = i+1:length(gateways)
                        % When gateways are on different levels (different y-values)
                        % But of the same type, try to align them vertically
                        if abs(gateways{i}.y - gateways{j}.y) > gateways{i}.height && ...
                           strcmpi(gateways{i}.type, gateways{j}.type)
                            
                            % Calculate the middle X position
                            avgX = (gateways{i}.x + gateways{j}.x) / 2;
                            
                            % Alinate both to this position
                            gateways{i}.x = avgX;
                            gateways{j}.x = avgX;
                        end
                    end
                end
            end
        end
        
        function centerActivities(obj)
            % Centered activities within your connections
            
            elements = obj.diagram.elements;
            flows = obj.diagram.flows;
            
            for i = 1:length(elements)
                if strcmpi(elements{i}.type, 'task')
                    % Find all input and outgoing flows for this activity
                    incomingFlows = {};
                    outgoingFlows = {};
                    
                    for j = 1:length(flows)
                        if strcmp(flows{j}.targetRef, elements{i}.id)
                            incomingFlows{end+1} = flows{j}; %#ok<AGROW>
                        elseif strcmp(flows{j}.sourceRef, elements{i}.id)
                            outgoingFlows{end+1} = flows{j}; %#ok<AGROW>
                        end
                    end
                    
                    % Calculate average X position of the connected elements
                    sumX = 0;
                    count = 0;
                    
                    for j = 1:length(incomingFlows)
                        sourceElement = obj.findElementById(incomingFlows{j}.sourceRef);
                        if ~isempty(sourceElement)
                            sumX = sumX + sourceElement.x + sourceElement.width/2;
                            count = count + 1;
                        end
                    end
                    
                    for j = 1:length(outgoingFlows)
                        targetElement = obj.findElementById(outgoingFlows{j}.targetRef);
                        if ~isempty(targetElement)
                            sumX = sumX + targetElement.x + targetElement.width/2;
                            count = count + 1;
                        end
                    end
                    
                    % If there are connected elements, center the activity
                    if count > 0
                        avgX = sumX / count;
                        elements{i}.x = avgX - elements{i}.width/2;
                    end
                end
            end
        end
        
        function routeEdges(obj)
            % Implements intelligent edge routing for sequence flows
            
            flows = obj.diagram.flows;
            
            for i = 1:length(flows)
                sourceElement = obj.findElementById(flows{i}.sourceRef);
                targetElement = obj.findElementById(flows{i}.targetRef);
                
                if ~isempty(sourceElement) && ~isempty(targetElement)
                    % Calculate waypoints for the flow
                    waypoints = obj.calculateWaypoints(sourceElement, targetElement);
                    flows{i}.waypoints = waypoints;
                end
            end
        end
        
        function waypoints = calculateWaypoints(obj, source, target)
            % Calculates waypoints for a flow between two elements
            
            % Simple algorithm for straight lines with two points
            % The starting point (from the source element)
            sourceX = source.x + source.width/2;
            sourceY = source.y + source.height/2;
            
            % Target point (for the target element)
            targetX = target.x + target.width/2;
            targetY = target.y + target.height/2;
            
            % Additional waypoints could be inserted here for more complex routes
            
            % Simple case: direct connection (for more details)
            if abs(targetY - sourceY) < obj.optimizeOptions.layerSpacing * 1.5
                waypoints = [sourceX, sourceY; targetX, targetY];
                return;
            end
            
            % More complex case: 3-point connection (for further distant elements)
            % Center to avoid overlapping
            midY = (sourceY + targetY) / 2;
            waypoints = [sourceX, sourceY; sourceX, midY; targetX, midY; targetX, targetY];
        end
        
        function resolveElementOverlaps(obj)
            % Recognizes and solves overlapping elements in the diagram
            
            elements = obj.diagram.elements;
            modified = true;
            
            % Continue until no more overlaps are solved
            iterationCount = 0;
            maxIterations = 10; % Begrenzung der Iterationen zur Vermeidung von Endlosschleifen
            
            while modified && iterationCount < maxIterations
                modified = false;
                iterationCount = iterationCount + 1;
                
                % Check each element pair for overlap
                for i = 1:length(elements)
                    for j = i+1:length(elements)
                        % Calculate limitation framework
                        box1 = [elements{i}.x, elements{i}.y, ...
                               elements{i}.x + elements{i}.width, ...
                               elements{i}.y + elements{i}.height];
                           
                        box2 = [elements{j}.x, elements{j}.y, ...
                               elements{j}.x + elements{j}.width, ...
                               elements{j}.y + elements{j}.height];
                        
                        % Check for overlap
                        if obj.boxesOverlap(box1, box2)
                            % Calculate the amount of overlap
                            overlapX = min(box1(3), box2(3)) - max(box1(1), box2(1));
                            overlapY = min(box1(4), box2(4)) - max(box1(2), box2(2));
                            
                            % Determine the direction of push based on the smallest overlap
                            if overlapX < overlapY
                                % Horizontally
                                if box1(1) < box2(1)
                                    elements{j}.x = elements{j}.x + overlapX + obj.optimizeOptions.minNodeDistance/4;
                                else
                                    elements{i}.x = elements{i}.x + overlapX + obj.optimizeOptions.minNodeDistance/4;
                                end
                            else
                                % Push vertically, only when elements are not on the same layer
                                % To maintain the river structure
                                if abs(elements{i}.y - elements{j}.y) > obj.optimizeOptions.minNodeDistance
                                    if box1(2) < box2(2)
                                        elements{j}.y = elements{j}.y + overlapY + obj.optimizeOptions.minNodeDistance/4;
                                    else
                                        elements{i}.y = elements{i}.y + overlapY + obj.optimizeOptions.minNodeDistance/4;
                                    end
                                else
                                    % Push horizontally for elements on the same layer
                                    separation = obj.optimizeOptions.minNodeDistance + max(elements{i}.width, elements{j}.width)/2;
                                    if box1(1) < box2(1)
                                        elements{j}.x = elements{i}.x + separation;
                                    else
                                        elements{i}.x = elements{j}.x + separation;
                                    end
                                end
                            end
                            
                            modified = true;
                        end
                    end
                end
            end
            
            % After loosening overlaps, make sure that elements adhere to the minimum distance
            for i = 1:length(elements)
                for j = i+1:length(elements)
                    % Check only elements in the same approximate vertical position (same layer)
                    if abs(elements{i}.y - elements{j}.y) < obj.optimizeOptions.minNodeDistance
                        % Check the horizontal distance
                        if abs(elements{i}.x - elements{j}.x) < obj.optimizeOptions.minNodeDistance
                            % Adjust positions to adhere to the minimum distance
                            if elements{i}.x < elements{j}.x
                                elements{j}.x = elements{i}.x + elements{i}.width + obj.optimizeOptions.minNodeDistance;
                            else
                                elements{i}.x = elements{j}.x + elements{j}.width + obj.optimizeOptions.minNodeDistance;
                            end
                        end
                    end
                end
            end
        end
        
        function overlap = boxesOverlap(~, box1, box2)
            % Determined whether two boundary frames overlap
            % Box format: [X1, Y1, X2, Y2] (upper left and lower right corners)
            
            % Check whether a box is completely left/right/top/bottom of the other
            if box1(3) < box2(1) || box2(3) < box1(1) || ...
               box1(4) < box2(2) || box2(4) < box1(2)
                overlap = false;
            else
                overlap = true;
            end
        end
        
        function optimizeFlowPaths(obj)
            % Optimized river paths to improve diagram reading
            
            flows = obj.diagram.flows;
            
            for i = 1:length(flows)
                sourceElement = obj.findElementById(flows{i}.sourceRef);
                targetElement = obj.findElementById(flows{i}.targetRef);
                
                if ~isempty(sourceElement) && ~isempty(targetElement)
                    % Calculate the optimal path between the elements with A* or similar algorithm
                    flows{i}.waypoints = obj.calculateOptimalPath(sourceElement, targetElement);
                end
            end
            
            % Recognizing and loosening of river crossings where possible
            obj.reduceFlowCrossings();
        end
        
        function waypoints = calculateOptimalPath(obj, source, target)
            % Calculate an optimal path between two elements with improved waypoint calculation
            
            % Starting position (middle of the source element)
            sourceX = source.x + source.width/2;
            sourceY = source.y + source.height/2;
            
            % Target position (center of the target element)
            targetX = target.x + target.width/2;
            targetY = target.y + target.height/2;
            
            % Check whether the source and goal are close together
            if abs(sourceY - targetY) < obj.optimizeOptions.layerSpacing/2 && ...
               abs(sourceX - targetX) < obj.optimizeOptions.minNodeDistance*3
                % Direct connection for closely positioned elements
                waypoints = [sourceX, sourceY; targetX, targetY];
                return;
            end
            
            % Improved multi-point path for complex routing scenarios
            
            % Calculate whether there is a vertical or horizontal relationship
            isVerticalFlow = abs(sourceY - targetY) > abs(sourceX - targetX);
            
            if isVerticalFlow
                % Primarily vertical river path
                midY = (sourceY + targetY) / 2;
                
                % Check for potential routing interferences with other elements
                if obj.pathIntersectsElements(sourceX, sourceY, sourceX, midY) || ...
                   obj.pathIntersectsElements(sourceX, midY, targetX, midY) || ...
                   obj.pathIntersectsElements(targetX, midY, targetX, targetY)
                   
                    % Adjust the path to avoid interference
                    alternativeMidX = (sourceX + targetX) / 2;
                    waypoints = [sourceX, sourceY; 
                                alternativeMidX, sourceY;
                                alternativeMidX, targetY; 
                                targetX, targetY];
                else
                    % Standard vertical routing path
                    waypoints = [sourceX, sourceY; 
                                sourceX, midY; 
                                targetX, midY; 
                                targetX, targetY];
                end
            else
                % Primarily horizontal river path
                midX = (sourceX + targetX) / 2;
                
                % Check for potential routing interferences
                if obj.pathIntersectsElements(sourceX, sourceY, midX, sourceY) || ...
                   obj.pathIntersectsElements(midX, sourceY, midX, targetY) || ...
                   obj.pathIntersectsElements(midX, targetY, targetX, targetY)
                   
                    % Adjust the path to avoid interference
                    alternativeMidY = (sourceY + targetY) / 2;
                    waypoints = [sourceX, sourceY; 
                                sourceX, alternativeMidY;
                                targetX, alternativeMidY; 
                                targetX, targetY];
                else
                    % Standard horizontal routing path
                    waypoints = [sourceX, sourceY; 
                                midX, sourceY; 
                                midX, targetY; 
                                targetX, targetY];
                end
            end
        end
        
        function intersects = pathIntersectsElements(obj, x1, y1, x2, y2)
            % Checks whether a path segment collides with an element
            
            elements = obj.diagram.elements;
            intersects = false;
            
            % Path segment as a line
            linePath = [x1, y1, x2, y2];
            
            % Buffer distance to prevent too close to elements
            buffer = 5;
            
            for i = 1:length(elements)
                element = elements{i};
                
                % Skip of source and target elements or very small elements
                if (abs(element.x + element.width/2 - x1) < 1e-6 && 
                    abs(element.y + element.height/2 - y1) < 1e-6) || ...
                   (abs(element.x + element.width/2 - x2) < 1e-6 && 
                    abs(element.y + element.height/2 - y2) < 1e-6)
                    continue;
                end
                
                % Limitation framework of the element with buffer
                bbox = [element.x - buffer, element.y - buffer, 
                        element.x + element.width + buffer, element.y + element.height + buffer];
                
                % Check whether the line cuts the boundary framework of the element
                if obj.lineIntersectsBox(linePath, bbox)
                    intersects = true;
                    return;
                end
            end
        end
        
        function intersects = lineIntersectsBox(~, line, box)
            % Determined whether a line segment collides with a box
            % Line format: [X1, Y1, X2, Y2]
            % Box format: [X1, Y1, X2, Y2] (upper left and lower right corners)
            
            % Line segment parameter
            x1 = line(1); y1 = line(2);
            x2 = line(3); y2 = line(4);
            
            % Box boundaries
            left = box(1); top = box(2);
            right = box(3); bottom = box(4);
            
            % Cohen-Sutherland-Algorithm for line-right-hand collision
            INSIDE = 0; % 0000
            LEFT = 1;   % 0001
            RIGHT = 2;  % 0010
            BOTTOM = 4; % 0100
            TOP = 8;    % 1000
            
            % Calculate the outcodes
            function code = computeOutCode(x, y)
                code = INSIDE;
                if x < left
                    code = bitor(code, LEFT);
                elseif x > right
                    code = bitor(code, RIGHT);
                end
                if y < top
                    code = bitor(code, TOP);
                elseif y > bottom
                    code = bitor(code, BOTTOM);
                end
            end
            
            outcode1 = computeOutCode(x1, y1);
            outcode2 = computeOutCode(x2, y2);
            
            while true
                % Both end points are within the box - trivial acceptance
                if outcode1 == 0 && outcode2 == 0
                    intersects = true;
                    return;
                end
                
                % Line is completely outside the box - trivial rejection
                if bitand(outcode1, outcode2) ~= 0
                    intersects = false;
                    return;
                end
                
                % Part of the line could be within - Calculate intersection
                x = 0; y = 0;
                outcodeOut = max(outcode1, outcode2);
                
                % Find intersection
                if bitand(outcodeOut, TOP) ~= 0
                    x = x1 + (x2 - x1) * (top - y1) / (y2 - y1);
                    y = top;
                elseif bitand(outcodeOut, BOTTOM) ~= 0
                    x = x1 + (x2 - x1) * (bottom - y1) / (y2 - y1);
                    y = bottom;
                elseif bitand(outcodeOut, RIGHT) ~= 0
                    y = y1 + (y2 - y1) * (right - x1) / (x2 - x1);
                    x = right;
                elseif bitand(outcodeOut, LEFT) ~= 0
                    y = y1 + (y2 - y1) * (left - x1) / (x2 - x1);
                    x = left;
                end
                
                % Update endpoints
                if outcodeOut == outcode1
                    x1 = x; y1 = y;
                    outcode1 = computeOutCode(x1, y1);
                else
                    x2 = x; y2 = y;
                    outcode2 = computeOutCode(x2, y2);
                end
            end
        end
        
        function reduceFlowCrossings(obj)
            % Tries to reduce river crossings by adapting the waypoints
            
            flows = obj.diagram.flows;
            
            % Identify river crossings
            for i = 1:length(flows)-1
                for j = i+1:length(flows)
                    if isfield(flows{i}, 'Waypoints') && isfield(flows{j}, 'Waypoints')
                        % Check whether these rivers cross
                        crossingPoints = obj.findFlowCrossings(flows{i}, flows{j});
                        
                        if ~isempty(crossingPoints)
                            % Try to solve the intersection by adapting the waypoints
                            [flows{i}, flows{j}] = obj.resolveCrossing(flows{i}, flows{j}, crossingPoints);
                        end
                    end
                end
            end
        end
        
        function crossingPoints = findFlowCrossings(~, flow1, flow2)
            % Identified crossing points between two rivers
            
            crossingPoints = [];
            
            if ~isfield(flow1, 'Waypoints') || ~isfield(flow2, 'Waypoints') || ...
               size(flow1.waypoints, 1) < 2 || size(flow2.waypoints, 1) < 2
                return;
            end
            
            % Check each segment of Flow1 against each segment of Flow2
            for i = 1:size(flow1.waypoints, 1)-1
                seg1 = [flow1.waypoints(i,:), flow1.waypoints(i+1,:)];
                
                for j = 1:size(flow2.waypoints, 1)-1
                    seg2 = [flow2.waypoints(j,:), flow2.waypoints(j+1,:)];
                    
                    % Check whether segments are cutting
                    [intersect, x, y] = obj.lineSegmentIntersection(seg1, seg2);
                    
                    if intersect
                        crossingPoints(end+1,:) = [x, y, i, j]; %#ok<AGROW>
                    end
                end
            end
        end
        
        function [intersect, x, y] = lineSegmentIntersection(~, seg1, seg2)
            % Determined whether two line segments are cutting
            
            x1 = seg1(1); y1 = seg1(2);
            x2 = seg1(3); y2 = seg1(4);
            
            x3 = seg2(1); y3 = seg2(2);
            x4 = seg2(3); y4 = seg2(4);
            
            % Calculate the denominator
            den = (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1);
            
            % Check whether lines are parallel
            if abs(den) < 1e-10
                intersect = false;
                x = 0; y = 0;
                return;
            end
            
            % Calculate the counters
            numa = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3));
            numb = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3));
            
            % Calculate the parameters
            ua = numa / den;
            ub = numb / den;
            
            % When parameters are in [0.1], the segments cut themselves
            if ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1
                % Calculate the intersection point
                x = x1 + ua * (x2 - x1);
                y = y1 + ua * (y2 - y1);
                intersect = true;
            else
                intersect = false;
                x = 0; y = 0;
            end
        end
        
        function [flow1, flow2] = resolveCrossing(obj, flow1, flow2, crossingPoints)
            % Tries to solve the intersection between two rivers by changing the waypoints
            
            if isempty(crossingPoints)
                return;
            end
            
            % Get the crossing point and the segment indices
            crossingX = crossingPoints(1,1);
            crossingY = crossingPoints(1,2);
            seg1Idx = crossingPoints(1,3);
            seg2Idx = crossingPoints(1,4);
            
            % Calculate the offset distance
            offset = obj.optimizeOptions.minNodeDistance / 2;
            
            % Determine which river should be adapted based on their types and their importance
            source1 = obj.findElementById(flow1.sourceRef);
            source2 = obj.findElementById(flow2.sourceRef);
            
            if isempty(source1) || isempty(source2)
                return;
            end
            
            % Prioritize the adaptation of normal sequence flows compared to news flows or associations
            isFlow1SequenceFlow = strcmp(flow1.type, 'sequenceflow');
            isFlow2SequenceFlow = strcmp(flow2.type, 'sequenceflow');
            
            if isFlow1SequenceFlow && ~isFlow2SequenceFlow
                % Adjust river2
                flow2.waypoints = obj.insertWaypointOffset(flow2.waypoints, seg2Idx, offset);
            elseif ~isFlow1SequenceFlow && isFlow2SequenceFlow
                % Adjust river1
                flow1.waypoints = obj.insertWaypointOffset(flow1.waypoints, seg1Idx, offset);
            else
                % Both are of the same type, adapt the shorter one
                length1 = size(flow1.waypoints, 1);
                length2 = size(flow2.waypoints, 1);
                
                if length1 <= length2
                    flow1.waypoints = obj.insertWaypointOffset(flow1.waypoints, seg1Idx, offset);
                else
                    flow2.waypoints = obj.insertWaypointOffset(flow2.waypoints, seg2Idx, offset);
                end
            end
        end
        
        function waypoints = insertWaypointOffset(~, waypoints, segmentIdx, offset)
            % Insert a verse into a river path to avoid a crossroad
            
            if segmentIdx < 1 || segmentIdx >= size(waypoints, 1)
                return;
            end
            
            % Original segment points
            p1 = waypoints(segmentIdx, :);
            p2 = waypoints(segmentIdx+1, :);
            
            % Calculate the direction of segment
            dx = p2(1) - p1(1);
            dy = p2(2) - p1(2);
            
            % If the segment is more horizontal, create vertical offset
            if abs(dx) >= abs(dy)
                midX = (p1(1) + p2(1)) / 2;
                newPoints = [midX, p1(2)+offset; midX, p1(2)-offset];
            else
                % If the segment is more vertical, create horizontal offset
                midY = (p1(2) + p2(2)) / 2;
                newPoints = [p1(1)+offset, midY; p1(1)-offset, midY];
            end
            
            % Insert new points
            waypoints = [waypoints(1:segmentIdx,:); newPoints; waypoints(segmentIdx+1:end,:)];
        end
    end
end