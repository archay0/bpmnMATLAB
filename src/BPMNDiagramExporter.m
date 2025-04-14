classdef BPMNDiagramExporter < handle
    % BPMNDiagramExporter Class for exporting BPMN diagrams as visual files
    %   This class provides functionality for exporting BPMN models as
    %   SVG, PNG, or PDF files directly from MATLAB
    
    properties
        XMLDoc         % XML document object
        OutputFilePath % Path to save the output image file
        Width          % Output image width in pixels
        Height         % Output image height in pixels
        BackgroundColor % Background color RGB triplet [r,g,b]
    end
    
    methods
        function obj = BPMNDiagramExporter(bpmnFileOrObj)
            % Constructor for BPMNDiagramExporter
            % bpmnFileOrObj: Path to BPMN file or BPMNGenerator instance
            
            obj.Width = 1200;  % Default width
            obj.Height = 800;  % Default height
            obj.BackgroundColor = [1 1 1];  % Default white background
            
            if ischar(bpmnFileOrObj) || isstring(bpmnFileOrObj)
                % Load from file
                obj.XMLDoc = xmlread(bpmnFileOrObj);
                [filepath, name, ~] = fileparts(bpmnFileOrObj);
                obj.OutputFilePath = fullfile(filepath, [name, '.svg']);
            elseif isa(bpmnFileOrObj, 'BPMNGenerator')
                % Use XMLDoc from BPMNGenerator instance
                obj.XMLDoc = bpmnFileOrObj.XMLDoc;
                if ~isempty(bpmnFileOrObj.FilePath)
                    [filepath, name, ~] = fileparts(bpmnFileOrObj.FilePath);
                    obj.OutputFilePath = fullfile(filepath, [name, '.svg']);
                else
                    obj.OutputFilePath = 'bpmn_diagram.svg';
                end
            else
                error('Input must be either a file path or a BPMNGenerator instance');
            end
        end
        
        function setOutputPath(obj, outputPath)
            % Sets the output file path
            % outputPath: Full path to the output file with extension
            obj.OutputFilePath = outputPath;
        end
        
        function setDimensions(obj, width, height)
            % Sets the dimensions of the output image
            % width, height: Dimensions in pixels
            obj.Width = width;
            obj.Height = height;
        end
        
        function setBackgroundColor(obj, color)
            % Sets the background color
            % color: RGB triplet [r,g,b] with values between 0 and 1
            obj.BackgroundColor = color;
        end
        
        function success = exportToSVG(obj, outputPath)
            % Export the BPMN diagram to SVG format
            % outputPath: Optional parameter to override OutputFilePath
            
            if nargin > 1
                obj.OutputFilePath = outputPath;
            end
            
            % Ensure the output path has .svg extension
            [filepath, name, ext] = fileparts(obj.OutputFilePath);
            if ~strcmpi(ext, '.svg')
                obj.OutputFilePath = fullfile(filepath, [name, '.svg']);
            end
            
            success = obj.generateSVG();
        end
        
        function success = exportToPNG(obj, outputPath)
            % Export the BPMN diagram to PNG format
            % outputPath: Optional parameter to override OutputFilePath
            
            if nargin > 1
                obj.OutputFilePath = outputPath;
            end
            
            % Ensure the output path has .png extension
            [filepath, name, ext] = fileparts(obj.OutputFilePath);
            if ~strcmpi(ext, '.png')
                obj.OutputFilePath = fullfile(filepath, [name, '.png']);
            end
            
            % First generate SVG, then convert to PNG
            tempSvgPath = fullfile(filepath, [name, '_temp.svg']);
            obj.OutputFilePath = tempSvgPath;
            svgSuccess = obj.generateSVG();
            
            if ~svgSuccess
                success = false;
                return;
            end
            
            % Convert SVG to PNG using MATLAB's built-in capabilities
            success = obj.convertSVGToPNG(tempSvgPath, fullfile(filepath, [name, '.png']));
            
            % Clean up temporary file
            if exist(tempSvgPath, 'file')
                delete(tempSvgPath);
            end
        end
        
        function success = exportToPDF(obj, outputPath)
            % Export the BPMN diagram to PDF format
            % outputPath: Optional parameter to override OutputFilePath
            
            if nargin > 1
                obj.OutputFilePath = outputPath;
            end
            
            % Ensure the output path has .pdf extension
            [filepath, name, ext] = fileparts(obj.OutputFilePath);
            if ~strcmpi(ext, '.pdf')
                obj.OutputFilePath = fullfile(filepath, [name, '.pdf']);
            end
            
            % First generate SVG, then convert to PDF
            tempSvgPath = fullfile(filepath, [name, '_temp.svg']);
            obj.OutputFilePath = tempSvgPath;
            svgSuccess = obj.generateSVG();
            
            if ~svgSuccess
                success = false;
                return;
            end
            
            % Convert SVG to PDF using MATLAB's built-in capabilities
            success = obj.convertSVGToPDF(tempSvgPath, fullfile(filepath, [name, '.pdf']));
            
            % Clean up temporary file
            if exist(tempSvgPath, 'file')
                delete(tempSvgPath);
            end
        end
    end
    
    % Private methods for implementation
    methods (Access = private)
        function success = generateSVG(obj)
            % Generate the SVG file from BPMN XML
            try
                % Extract diagram information from BPMN XML
                diagramElements = obj.extractDiagramElements();
                
                % Create SVG document
                svgDoc = obj.createSVGDocument(diagramElements);
                
                % Save SVG to file
                xmlwrite(obj.OutputFilePath, svgDoc);
                success = true;
                
            catch e
                warning('Error generating SVG: %s', e.message);
                success = false;
            end
        end
        
        function elements = extractDiagramElements(obj)
            % Extract diagram elements from BPMN XML
            elements = struct('shapes', {{}}, 'edges', {{}});
            
            % Extract BPMN shapes
            rootNode = obj.XMLDoc.getDocumentElement();
            bpmnDiNodes = rootNode.getElementsByTagName('bpmndi:BPMNDiagram');
            
            if bpmnDiNodes.getLength() == 0
                warning('No BPMNDiagram element found in BPMN file');
                return;
            end
            
            bpmnDiNode = bpmnDiNodes.item(0);
            planeNodes = bpmnDiNode.getElementsByTagName('bpmndi:BPMNPlane');
            
            if planeNodes.getLength() == 0
                warning('No BPMNPlane element found in BPMN file');
                return;
            end
            
            planeNode = planeNodes.item(0);
            
            % Extract shapes
            shapeNodes = planeNode.getElementsByTagName('bpmndi:BPMNShape');
            for i = 0:shapeNodes.getLength()-1
                shapeNode = shapeNodes.item(i);
                
                % Get element ID
                elementId = char(shapeNode.getAttribute('bpmnElement'));
                
                % Get bounds
                boundsNode = shapeNode.getElementsByTagName('dc:Bounds').item(0);
                x = str2double(char(boundsNode.getAttribute('x')));
                y = str2double(char(boundsNode.getAttribute('y')));
                width = str2double(char(boundsNode.getAttribute('width')));
                height = str2double(char(boundsNode.getAttribute('height')));
                
                % Get element type
                elementType = obj.getElementType(elementId);
                
                % Store shape data
                shape = struct('id', elementId, 'type', elementType, 'x', x, 'y', y, 'width', width, 'height', height);
                elements.shapes{end+1} = shape;
            end
            
            % Extract edges
            edgeNodes = planeNode.getElementsByTagName('bpmndi:BPMNEdge');
            for i = 0:edgeNodes.getLength()-1
                edgeNode = edgeNodes.item(i);
                
                % Get element ID
                elementId = char(edgeNode.getAttribute('bpmnElement'));
                
                % Get waypoints
                waypointNodes = edgeNode.getElementsByTagName('di:waypoint');
                waypoints = [];
                
                for j = 0:waypointNodes.getLength()-1
                    waypointNode = waypointNodes.item(j);
                    x = str2double(char(waypointNode.getAttribute('x')));
                    y = str2double(char(waypointNode.getAttribute('y')));
                    waypoints(end+1, :) = [x, y];
                end
                
                % Get flow type
                flowType = obj.getFlowType(elementId);
                
                % Store edge data
                edge = struct('id', elementId, 'type', flowType, 'waypoints', waypoints);
                elements.edges{end+1} = edge;
            end
        end
        
        function elementType = getElementType(obj, elementId)
            % Get the element type from its ID
            elements = obj.XMLDoc.getElementsByTagName('*');
            elementType = 'unknown';
            
            for i = 0:elements.getLength()-1
                element = elements.item(i);
                if element.getNodeType() == 1 && element.hasAttribute('id')
                    id = char(element.getAttribute('id'));
                    if strcmp(id, elementId)
                        elementType = char(element.getNodeName());
                        break;
                    end
                end
            end
        end
        
        function flowType = getFlowType(obj, flowId)
            % Get the flow type from its ID
            flowNodes = obj.XMLDoc.getElementsByTagName('sequenceFlow');
            flowType = 'sequenceFlow';
            
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                id = char(flowNode.getAttribute('id'));
                if strcmp(id, flowId)
                    flowType = 'sequenceFlow';
                    return;
                end
            end
            
            % Check if it's a message flow
            flowNodes = obj.XMLDoc.getElementsByTagName('messageFlow');
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                id = char(flowNode.getAttribute('id'));
                if strcmp(id, flowId)
                    flowType = 'messageFlow';
                    return;
                end
            end
            
            % Check if it's an association
            flowNodes = obj.XMLDoc.getElementsByTagName('association');
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                id = char(flowNode.getAttribute('id'));
                if strcmp(id, flowId)
                    flowType = 'association';
                    return;
                end
            end
        end
        
        function svgDoc = createSVGDocument(obj, elements)
            % Create an SVG document from diagram elements
            
            % Create DOM document
            docNode = com.mathworks.xml.XMLUtils.createDocument('svg');
            svgDoc = docNode.getDocumentElement();
            
            % Set SVG attributes
            svgDoc.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
            svgDoc.setAttribute('width', num2str(obj.Width));
            svgDoc.setAttribute('height', num2str(obj.Height));
            svgDoc.setAttribute('viewBox', ['0 0 ', num2str(obj.Width), ' ', num2str(obj.Height)]);
            
            % Add background rectangle
            bgRect = docNode.createElement('rect');
            bgRect.setAttribute('width', '100%');
            bgRect.setAttribute('height', '100%');
            bgRect.setAttribute('fill', obj.rgbToHex(obj.BackgroundColor));
            svgDoc.appendChild(bgRect);
            
            % Add diagram title
            title = docNode.createElement('title');
            title.appendChild(docNode.createTextNode('BPMN Diagram'));
            svgDoc.appendChild(title);
            
            % Add description
            desc = docNode.createElement('desc');
            desc.appendChild(docNode.createTextNode('Generated by BPMNDiagramExporter for MATLAB'));
            svgDoc.appendChild(desc);
            
            % Create a group for all elements
            mainGroup = docNode.createElement('g');
            svgDoc.appendChild(mainGroup);
            
            % Add edges (connections)
            edgesGroup = docNode.createElement('g');
            edgesGroup.setAttribute('id', 'connections');
            for i = 1:length(elements.edges)
                edge = elements.edges{i};
                pathElem = obj.createPathElement(docNode, edge);
                edgesGroup.appendChild(pathElem);
            end
            mainGroup.appendChild(edgesGroup);
            
            % Add shapes (nodes)
            shapesGroup = docNode.createElement('g');
            shapesGroup.setAttribute('id', 'nodes');
            for i = 1:length(elements.shapes)
                shape = elements.shapes{i};
                shapeElem = obj.createShapeElement(docNode, shape);
                shapesGroup.appendChild(shapeElem);
            end
            mainGroup.appendChild(shapesGroup);
            
            % Return the SVG document
            svgDoc = docNode;
        end
        
        function pathElem = createPathElement(obj, docNode, edge)
            % Create an SVG path element for an edge
            pathElem = docNode.createElement('path');
            pathElem.setAttribute('id', edge.id);
            
            % Create path data
            pathData = 'M';
            for i = 1:size(edge.waypoints, 1)
                x = edge.waypoints(i, 1);
                y = edge.waypoints(i, 2);
                if i == 1
                    pathData = [pathData, ' ', num2str(x), ',', num2str(y)];
                else
                    pathData = [pathData, ' L', num2str(x), ',', num2str(y)];
                end
            end
            
            pathElem.setAttribute('d', pathData);
            
            % Set style based on flow type
            if strcmp(edge.type, 'sequenceFlow')
                pathElem.setAttribute('stroke', '#000000');
                pathElem.setAttribute('stroke-width', '1.5');
                pathElem.setAttribute('fill', 'none');
                pathElem.setAttribute('marker-end', 'url(#sequenceFlowEndMarker)');
            elseif strcmp(edge.type, 'messageFlow')
                pathElem.setAttribute('stroke', '#000000');
                pathElem.setAttribute('stroke-width', '1.5');
                pathElem.setAttribute('stroke-dasharray', '5,5');
                pathElem.setAttribute('fill', 'none');
                pathElem.setAttribute('marker-end', 'url(#messageFlowEndMarker)');
            elseif strcmp(edge.type, 'association')
                pathElem.setAttribute('stroke', '#000000');
                pathElem.setAttribute('stroke-width', '1');
                pathElem.setAttribute('stroke-dasharray', '3,3');
                pathElem.setAttribute('fill', 'none');
            end
            
            return;
        end
        
        function shapeElem = createShapeElement(obj, docNode, shape)
            % Create an SVG element for a shape
            group = docNode.createElement('g');
            group.setAttribute('id', shape.id);
            
            % Create shape element based on type
            if contains(shape.type, 'task') || contains(shape.type, 'Task')
                % Tasks are rectangles with rounded corners
                rect = docNode.createElement('rect');
                rect.setAttribute('x', num2str(shape.x));
                rect.setAttribute('y', num2str(shape.y));
                rect.setAttribute('width', num2str(shape.width));
                rect.setAttribute('height', num2str(shape.height));
                rect.setAttribute('rx', '10');
                rect.setAttribute('ry', '10');
                rect.setAttribute('fill', '#FFFFFF');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('stroke-width', '2');
                group.appendChild(rect);
                
                % Add task icon based on type if needed
                % ...
                
            elseif contains(shape.type, 'gateway') || contains(shape.type, 'Gateway')
                % Gateways are diamonds
                centerX = shape.x + shape.width/2;
                centerY = shape.y + shape.height/2;
                halfWidth = shape.width/2;
                halfHeight = shape.height/2;
                
                points = [
                    centerX, shape.y, 
                    shape.x + shape.width, centerY, 
                    centerX, shape.y + shape.height, 
                    shape.x, centerY
                ];
                
                polygon = docNode.createElement('polygon');
                pointsStr = '';
                for i = 1:2:length(points)
                    pointsStr = [pointsStr, num2str(points(i)), ',', num2str(points(i+1)), ' '];
                end
                polygon.setAttribute('points', pointsStr);
                polygon.setAttribute('fill', '#FFFFFF');
                polygon.setAttribute('stroke', '#000000');
                polygon.setAttribute('stroke-width', '2');
                group.appendChild(polygon);
                
                % Add gateway icon based on type if needed
                % ...
                
            elseif contains(shape.type, 'event') || contains(shape.type, 'Event')
                % Events are circles
                circle = docNode.createElement('circle');
                circle.setAttribute('cx', num2str(shape.x + shape.width/2));
                circle.setAttribute('cy', num2str(shape.y + shape.height/2));
                circle.setAttribute('r', num2str(shape.width/2));
                circle.setAttribute('fill', '#FFFFFF');
                circle.setAttribute('stroke', '#000000');
                circle.setAttribute('stroke-width', '2');
                
                % Set different stroke styles based on event type
                if contains(shape.type, 'start')
                    circle.setAttribute('stroke-width', '1');
                elseif contains(shape.type, 'end')
                    circle.setAttribute('stroke-width', '3');
                elseif contains(shape.type, 'intermediate')
                    circle.setAttribute('stroke-width', '2');
                    
                    % Add second circle for intermediate events
                    innerCircle = docNode.createElement('circle');
                    innerCircle.setAttribute('cx', num2str(shape.x + shape.width/2));
                    innerCircle.setAttribute('cy', num2str(shape.y + shape.height/2));
                    innerCircle.setAttribute('r', num2str(shape.width/2 - 4));
                    innerCircle.setAttribute('fill', 'none');
                    innerCircle.setAttribute('stroke', '#000000');
                    innerCircle.setAttribute('stroke-width', '1');
                    group.appendChild(innerCircle);
                end
                
                group.appendChild(circle);
                
                % Add event icon based on type if needed
                % ...
                
            elseif contains(shape.type, 'pool') || contains(shape.type, 'participant')
                % Pools are rectangles
                rect = docNode.createElement('rect');
                rect.setAttribute('x', num2str(shape.x));
                rect.setAttribute('y', num2str(shape.y));
                rect.setAttribute('width', num2str(shape.width));
                rect.setAttribute('height', num2str(shape.height));
                rect.setAttribute('fill', '#FFFFFF');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('stroke-width', '2');
                group.appendChild(rect);
                
            elseif contains(shape.type, 'lane')
                % Lanes are rectangles
                rect = docNode.createElement('rect');
                rect.setAttribute('x', num2str(shape.x));
                rect.setAttribute('y', num2str(shape.y));
                rect.setAttribute('width', num2str(shape.width));
                rect.setAttribute('height', num2str(shape.height));
                rect.setAttribute('fill', '#FFFFFF');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('stroke-width', '1');
                rect.setAttribute('stroke-dasharray', '3,3');
                group.appendChild(rect);
                
            elseif contains(shape.type, 'dataObject') || contains(shape.type, 'dataObjectReference')
                % Data objects are document symbols
                rect = docNode.createElement('path');
                x = shape.x;
                y = shape.y;
                w = shape.width;
                h = shape.height;
                foldWidth = w * 0.2;
                foldHeight = h * 0.2;
                
                pathData = [
                    'M', num2str(x), ',', num2str(y), 
                    ' L', num2str(x + w - foldWidth), ',', num2str(y), 
                    ' L', num2str(x + w), ',', num2str(y + foldHeight), 
                    ' L', num2str(x + w), ',', num2str(y + h), 
                    ' L', num2str(x), ',', num2str(y + h), 
                    ' Z', 
                    ' M', num2str(x + w - foldWidth), ',', num2str(y), 
                    ' L', num2str(x + w - foldWidth), ',', num2str(y + foldHeight), 
                    ' L', num2str(x + w), ',', num2str(y + foldHeight)
                ];
                
                rect.setAttribute('d', pathData);
                rect.setAttribute('fill', '#FFFFFF');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('stroke-width', '1');
                group.appendChild(rect);
                
            elseif contains(shape.type, 'dataStore')
                % Data stores are database cylinders
                cylPath = docNode.createElement('path');
                x = shape.x;
                y = shape.y;
                w = shape.width;
                h = shape.height;
                ellipseHeight = h * 0.15;
                
                pathData = [
                    'M', num2str(x), ',', num2str(y + ellipseHeight), 
                    ' a', num2str(w/2), ',', num2str(ellipseHeight), ' 0 1,0 ', num2str(w), ',0', 
                    ' a', num2str(w/2), ',', num2str(ellipseHeight), ' 0 1,0 ', num2str(-w), ',0', 
                    ' M', num2str(x), ',', num2str(y + ellipseHeight), 
                    ' L', num2str(x), ',', num2str(y + h - ellipseHeight), 
                    ' a', num2str(w/2), ',', num2str(ellipseHeight), ' 0 1,0 ', num2str(w), ',0', 
                    ' L', num2str(x + w), ',', num2str(y + ellipseHeight), 
                    ' M', num2str(x), ',', num2str(y + h - ellipseHeight), 
                    ' a', num2str(w/2), ',', num2str(ellipseHeight), ' 0 1,0 ', num2str(w), ',0'
                ];
                
                cylPath.setAttribute('d', pathData);
                cylPath.setAttribute('fill', '#FFFFFF');
                cylPath.setAttribute('stroke', '#000000');
                cylPath.setAttribute('stroke-width', '1');
                group.appendChild(cylPath);
                
            elseif contains(shape.type, 'textAnnotation')
                % Text annotations are folded corner notes
                rect = docNode.createElement('path');
                x = shape.x;
                y = shape.y;
                w = shape.width;
                h = shape.height;
                foldWidth = w * 0.1;
                
                pathData = [
                    'M', num2str(x + foldWidth), ',', num2str(y), 
                    ' L', num2str(x), ',', num2str(y), 
                    ' L', num2str(x), ',', num2str(y + h), 
                    ' L', num2str(x + w), ',', num2str(y + h), 
                    ' L', num2str(x + w), ',', num2str(y + foldWidth), 
                    ' L', num2str(x + w - foldWidth), ',', num2str(y), 
                    ' Z', 
                    ' M', num2str(x + w - foldWidth), ',', num2str(y), 
                    ' L', num2str(x + w - foldWidth), ',', num2str(y + foldWidth), 
                    ' L', num2str(x + w), ',', num2str(y + foldWidth)
                ];
                
                rect.setAttribute('d', pathData);
                rect.setAttribute('fill', '#FFFFCC');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('stroke-width', '1');
                group.appendChild(rect);
                
            else
                % Default shape is a rectangle
                rect = docNode.createElement('rect');
                rect.setAttribute('x', num2str(shape.x));
                rect.setAttribute('y', num2str(shape.y));
                rect.setAttribute('width', num2str(shape.width));
                rect.setAttribute('height', num2str(shape.height));
                rect.setAttribute('fill', '#FFFFFF');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('stroke-width', '1');
                group.appendChild(rect);
            end
            
            shapeElem = group;
            return;
        end
        
        function hexColor = rgbToHex(obj, rgb)
            % Convert RGB triplet to hex color string
            r = round(rgb(1) * 255);
            g = round(rgb(2) * 255);
            b = round(rgb(3) * 255);
            hexColor = sprintf('#%02X%02X%02X', r, g, b);
        end
        
        function success = convertSVGToPNG(obj, svgPath, pngPath)
            % Convert SVG to PNG using MATLAB's saveas
            try
                % Check if we have the Image Processing Toolbox
                if ~license('test', 'Image_Toolbox')
                    warning('Image Processing Toolbox is required for PNG export.');
                    success = false;
                    return;
                end
                
                figure('visible', 'off');
                try
                    plot(0, 0, 'visible', 'off');
                    axis off;
                    
                    % Use webread to load the SVG
                    svg_str = fileread(svgPath);
                    
                    % Display the SVG in the figure
                    img = matlab.io.internal.renderSVG(svg_str);
                    imshow(img);
                    
                    % Save as PNG
                    export_fig(pngPath, '-png', '-r300', '-transparent');
                    success = true;
                catch e
                    warning('Error converting to PNG: %s', e.message);
                    % Fallback method - requires Image Processing Toolbox
                    try
                        img = imread(svgPath);
                        imwrite(img, pngPath);
                        success = true;
                    catch e2
                        warning('Fallback PNG conversion failed: %s', e2.message);
                        success = false;
                    end
                end
                close;
                
            catch e
                warning('Error converting SVG to PNG: %s', e.message);
                success = false;
            end
        end
        
        function success = convertSVGToPDF(obj, svgPath, pdfPath)
            % Convert SVG to PDF
            try
                figure('visible', 'off');
                plot(0, 0, 'visible', 'off');
                axis off;
                
                % Use webread to load the SVG
                svg_str = fileread(svgPath);
                
                % Display the SVG in the figure
                img = matlab.io.internal.renderSVG(svg_str);
                imshow(img);
                
                % Save as PDF
                print(pdfPath, '-dpdf', '-r300');
                success = true;
                
                close;
                
            catch e
                warning('Error converting SVG to PDF: %s', e.message);
                success = false;
            end
        end
    end
end