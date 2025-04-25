classdef BPMNDiagramExporter < handle
    % Bpmndiagramexporter class for exporting bpmn diagrams as visual files
    % This class provides functionality for exporting bpmn models as
    % SVG, PNG, Or PDF Files Directly from Matlab
    
    properties
        XMLDoc         % XML document object
        OutputFilePath % Path to save the output image file
        Width          % Output image width in pixels
        Height         % Output image height in pixels
        BackgroundColor % Background color RGB triplet [r,g,b]
    end
    
    methods
        function obj = BPMNDiagramExporter(bpmnFileOrObj)
            % Constructor for bpmndiagramexporter
            % bpmnfileorobj: Path to bpmn file or bpmngenerator instance
            
            obj.Width = 1200;  % Default width
            obj.Height = 800;  % Default height
            obj.BackgroundColor = [1 1 1];  % Default white background
            
            if ischar(bpmnFileOrObj) || isstring(bpmnFileOrObj)
                % Load from File
                obj.XMLDoc = xmlread(bpmnFileOrObj);
                [filepath, name, ~] = fileparts(bpmnFileOrObj);
                obj.OutputFilePath = fullfile(filepath, [name, '.SVG']);
            elseif isa(bpmnFileOrObj, 'BPMN generator')
                % Use xmldoc from bpmngenerator instance
                obj.XMLDoc = bpmnFileOrObj.XMLDoc;
                if ~isempty(bpmnFileOrObj.FilePath)
                    [filepath, name, ~] = fileparts(bpmnFileOrObj.FilePath);
                    obj.OutputFilePath = fullfile(filepath, [name, '.SVG']);
                else
                    obj.OutputFilePath = 'bpmn_diagram.svg';
                end
            else
                error('Input must be Either a file path or a bpmngenerator instance');
            end
        end
        
        function setOutputPath(obj, outputPath)
            % Sets the output file path
            % Outputpath: Full Path to the output file with extension
            obj.OutputFilePath = outputPath;
        end
        
        function setDimensions(obj, width, height)
            % Sets the dimensions of the output image
            % Width, Height: Dimensions in Pixels
            obj.Width = width;
            obj.Height = height;
        end
        
        function setBackgroundColor(obj, color)
            % Sets the background color
            % Color: RGB Triplet [R, G, B] with value between and 1
            obj.BackgroundColor = color;
        end
        
        function success = exportToSVG(obj, outputPath)
            % Export the BPMN Diagram to SVG format
            % Outputpath: Optional parameter to Override Output Filepath
            
            if nargin > 1
                obj.OutputFilePath = outputPath;
            end
            
            % Ensure the output path has .SVG extension
            [filepath, name, ext] = fileparts(obj.OutputFilePath);
            if ~strcmpi(ext, '.SVG')
                obj.OutputFilePath = fullfile(filepath, [name, '.SVG']);
            end
            
            success = obj.generateSVG();
        end
        
        function success = exportToPNG(obj, outputPath)
            % Export the bpmn diagram to png format
            % Outputpath: Optional parameter to Override Output Filepath
            
            if nargin > 1
                obj.OutputFilePath = outputPath;
            end
            
            % Ensure the output path has .png extension
            [filepath, name, ext] = fileparts(obj.OutputFilePath);
            if ~strcmpi(ext, '.png')
                obj.OutputFilePath = fullfile(filepath, [name, '.png']);
            end
            
            % First Generates SVG, then Convert to PNG
            tempSvgPath = fullfile(filepath, [name, '_Temp.svg']);
            obj.OutputFilePath = tempSvgPath;
            svgSuccess = obj.generateSVG();
            
            if ~svgSuccess
                success = false;
                return;
            end
            
            % Convert SVG to PNG Using Matlab's Built-in Capabilities
            success = obj.convertSVGToPNG(tempSvgPath, fullfile(filepath, [name, '.png']));
            
            % Clean up Temory File
            if exist(tempSvgPath, 'file')
                delete(tempSvgPath);
            end
        end
        
        function success = exportToPDF(obj, outputPath)
            % Export the bpmn diagram to pdf format
            % Outputpath: Optional parameter to Override Output Filepath
            
            if nargin > 1
                obj.OutputFilePath = outputPath;
            end
            
            % Ensure the output path has .pdf extension
            [filepath, name, ext] = fileparts(obj.OutputFilePath);
            if ~strcmpi(ext, '.pdf')
                obj.OutputFilePath = fullfile(filepath, [name, '.pdf']);
            end
            
            % First generates SVG, then convert to pdf
            tempSvgPath = fullfile(filepath, [name, '_Temp.svg']);
            obj.OutputFilePath = tempSvgPath;
            svgSuccess = obj.generateSVG();
            
            if ~svgSuccess
                success = false;
                return;
            end
            
            % Convert SVG to PDF Using Matlab's Built-in Capabilities
            success = obj.convertSVGToPDF(tempSvgPath, fullfile(filepath, [name, '.pdf']));
            
            % Clean up Temory File
            if exist(tempSvgPath, 'file')
                delete(tempSvgPath);
            end
        end
    end
    
    % Private methods for implementation
    methods (Access = private)
        function success = generateSVG(obj)
            % Generates the SVG File from BPMN XML
            try
                % Extract Diagram Information from BPMN XML
                diagramElements = obj.extractDiagramElements();
                
                % Create SVG Document
                svgDoc = obj.createSVGDocument(diagramElements);
                
                % Save SVG to File
                xmlwrite(obj.OutputFilePath, svgDoc);
                success = true;
                
            catch e
                warning('Error Generating SVG: %S', e.message);
                success = false;
            end
        end
        
        function elements = extractDiagramElements(obj)
            % Extract Diagram Elements from BPMN XML
            elements = struct('shapes', {{}}, 'Edges', {{}});
            
            % Extract bpmn shapes
            rootNode = obj.XMLDoc.getDocumentElement();
            bpmnDiNodes = rootNode.getElementsByTagName('bpmndi: bpmndiagram');
            
            if bpmnDiNodes.getLength() == 0
                warning('No bpmndiagram element found in bpmn file');
                return;
            end
            
            bpmnDiNode = bpmnDiNodes.item(0);
            planeNodes = bpmnDiNode.getElementsByTagName('bpmndi: bpmnplane');
            
            if planeNodes.getLength() == 0
                warning('No bpmnplane element found in bpmn file');
                return;
            end
            
            planeNode = planeNodes.item(0);
            
            % Extract shapes
            shapeNodes = planeNode.getElementsByTagName('bpmndi: bpmnshape');
            for i = 0:shapeNodes.getLength()-1
                shapeNode = shapeNodes.item(i);
                
                % Get element ID
                elementId = char(shapeNode.getAttribute('bpmnelement'));
                
                % Get bounds
                boundsNode = shapeNode.getElementsByTagName('DC: Bounds').item(0);
                x = str2double(char(boundsNode.getAttribute('X')));
                y = str2double(char(boundsNode.getAttribute('y')));
                width = str2double(char(boundsNode.getAttribute('Width')));
                height = str2double(char(boundsNode.getAttribute('Height')));
                
                % Get element type
                elementType = obj.getElementType(elementId);
                
                % Store Shape Data
                shape = struct('ID', elementId, 'type', elementType, 'X', x, 'y', y, 'Width', width, 'Height', height);
                elements.shapes{end+1} = shape;
            end
            
            % Extract Edges
            edgeNodes = planeNode.getElementsByTagName('bpmndi: bpmnedge');
            for i = 0:edgeNodes.getLength()-1
                edgeNode = edgeNodes.item(i);
                
                % Get element ID
                elementId = char(edgeNode.getAttribute('bpmnelement'));
                
                % Get waypoints
                waypointNodes = edgeNode.getElementsByTagName('Di: Waypoint');
                waypoints = [];
                
                for j = 0:waypointNodes.getLength()-1
                    waypointNode = waypointNodes.item(j);
                    x = str2double(char(waypointNode.getAttribute('X')));
                    y = str2double(char(waypointNode.getAttribute('y')));
                    waypoints(end+1, :) = [x, y];
                end
                
                % Get flow type
                flowType = obj.getFlowType(elementId);
                
                % Store Edge Data
                edge = struct('ID', elementId, 'type', flowType, 'Waypoints', waypoints);
                elements.edges{end+1} = edge;
            end
        end
        
        function elementType = getElementType(obj, elementId)
            % Get the element type from Its ID
            elements = obj.XMLDoc.getElementsByTagName('*');
            elementType = 'unknown';
            
            for i = 0:elements.getLength()-1
                element = elements.item(i);
                if element.getNodeType() == 1 && element.hasAttribute('ID')
                    id = char(element.getAttribute('ID'));
                    if strcmp(id, elementId)
                        elementType = char(element.getNodeName());
                        break;
                    end
                end
            end
        end
        
        function flowType = getFlowType(obj, flowId)
            % Get the Flow Type from Its ID
            flowNodes = obj.XMLDoc.getElementsByTagName('sequenceflow');
            flowType = 'sequenceflow';
            
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                id = char(flowNode.getAttribute('ID'));
                if strcmp(id, flowId)
                    flowType = 'sequenceflow';
                    return;
                end
            end
            
            % Check if it's a message flow
            flowNodes = obj.XMLDoc.getElementsByTagName('MessageFlow');
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                id = char(flowNode.getAttribute('ID'));
                if strcmp(id, flowId)
                    flowType = 'MessageFlow';
                    return;
                end
            end
            
            % Check if it's an association
            flowNodes = obj.XMLDoc.getElementsByTagName('association');
            for i = 0:flowNodes.getLength()-1
                flowNode = flowNodes.item(i);
                id = char(flowNode.getAttribute('ID'));
                if strcmp(id, flowId)
                    flowType = 'association';
                    return;
                end
            end
        end
        
        function svgDoc = createSVGDocument(obj, elements)
            % Create to SVG Document from Diagram Elements
            
            % Create Dom Document
            docNode = com.mathworks.xml.XMLUtils.createDocument('SVG');
            svgDoc = docNode.getDocumentElement();
            
            % Set SVG attributes
            svgDoc.setAttribute('XMLNS', 'http://www.w3.org/2000/svg');
            svgDoc.setAttribute('Width', num2str(obj.Width));
            svgDoc.setAttribute('Height', num2str(obj.Height));
            svgDoc.setAttribute('viewbox', ['0 0 0', num2str(obj.Width), ' ', num2str(obj.Height)]);
            
            % Add Background Rectangle
            bgRect = docNode.createElement('rect');
            bgRect.setAttribute('Width', '100%');
            bgRect.setAttribute('Height', '100%');
            bgRect.setAttribute('fill', obj.rgbToHex(obj.BackgroundColor));
            svgDoc.appendChild(bgRect);
            
            % Add Diagram Title
            title = docNode.createElement('title');
            title.appendChild(docNode.createTextNode('BPMN Diagram'));
            svgDoc.appendChild(title);
            
            % Add description
            desc = docNode.createElement('desc');
            desc.appendChild(docNode.createTextNode('Generated by BPMndiagramexporter for Matlab'));
            svgDoc.appendChild(desc);
            
            % Create A Group for All Elements
            mainGroup = docNode.createElement('G');
            svgDoc.appendChild(mainGroup);
            
            % Add Edges (Connections)
            edgesGroup = docNode.createElement('G');
            edgesGroup.setAttribute('ID', 'connections');
            for i = 1:length(elements.edges)
                edge = elements.edges{i};
                pathElem = obj.createPathElement(docNode, edge);
                edgesGroup.appendChild(pathElem);
            end
            mainGroup.appendChild(edgesGroup);
            
            % Add shapes (nodes)
            shapesGroup = docNode.createElement('G');
            shapesGroup.setAttribute('ID', 'nodes');
            for i = 1:length(elements.shapes)
                shape = elements.shapes{i};
                shapeElem = obj.createShapeElement(docNode, shape);
                shapesGroup.appendChild(shapeElem);
            end
            mainGroup.appendChild(shapesGroup);
            
            % Return the SVG Document
            svgDoc = docNode;
        end
        
        function pathElem = createPathElement(obj, docNode, edge)
            % Create to SVG Path Element for an edge
            pathElem = docNode.createElement('path');
            pathElem.setAttribute('ID', edge.id);
            
            % Create Path Data
            pathData = 'M';
            for i = 1:size(edge.waypoints, 1)
                x = edge.waypoints(i, 1);
                y = edge.waypoints(i, 2);
                if i == 1
                    pathData = [pathData, ' ', num2str(x), ',,', num2str(y)];
                else
                    pathData = [pathData, 'L', num2str(x), ',,', num2str(y)];
                end
            end
            
            pathElem.setAttribute('D', pathData);
            
            % Set Style Based on Flow Type
            if strcmp(edge.type, 'sequenceflow')
                pathElem.setAttribute('stroke', '#000000');
                pathElem.setAttribute('Stroke-Width', '1.5');
                pathElem.setAttribute('fill', 'none');
                pathElem.setAttribute('marker-end', 'URL (#squenceflawendmarker)');
            elseif strcmp(edge.type, 'MessageFlow')
                pathElem.setAttribute('stroke', '#000000');
                pathElem.setAttribute('Stroke-Width', '1.5');
                pathElem.setAttribute('Stroke-dasharray', '5.5');
                pathElem.setAttribute('fill', 'none');
                pathElem.setAttribute('marker-end', 'URL (#MessageFlowendmarker)');
            elseif strcmp(edge.type, 'association')
                pathElem.setAttribute('stroke', '#000000');
                pathElem.setAttribute('Stroke-Width', '1');
                pathElem.setAttribute('Stroke-dasharray', '3.3');
                pathElem.setAttribute('fill', 'none');
            end
            
            return;
        end
        
        function shapeElem = createShapeElement(obj, docNode, shape)
            % Create to SVG element for a shape
            group = docNode.createElement('G');
            group.setAttribute('ID', shape.id);
            
            % Create Shape element Based on Type
            if contains(shape.type, 'task') || contains(shape.type, 'Task')
                % Tasks are Rectangles with Rounded Corners
                rect = docNode.createElement('rect');
                rect.setAttribute('X', num2str(shape.x));
                rect.setAttribute('y', num2str(shape.y));
                rect.setAttribute('Width', num2str(shape.width));
                rect.setAttribute('Height', num2str(shape.height));
                rect.setAttribute('RX', '10');
                rect.setAttribute('ry', '10');
                rect.setAttribute('fill', '#FFFFFF');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('Stroke-Width', '2');
                group.appendChild(rect);
                
                % Add Task icon Based on Type If Needed
                % ...
                
            elseif contains(shape.type, 'gateway') || contains(shape.type, 'Gateway')
                % Gateways Are Diamonds
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
                    pointsStr = [pointsStr, num2str(points(i)), ',,', num2str(points(i+1)), ' '];
                end
                polygon.setAttribute('point', pointsStr);
                polygon.setAttribute('fill', '#FFFFFF');
                polygon.setAttribute('stroke', '#000000');
                polygon.setAttribute('Stroke-Width', '2');
                group.appendChild(polygon);
                
                % Add Gateway Icon Based on Type If Needed
                % ...
                
            elseif contains(shape.type, 'event') || contains(shape.type, 'Event')
                % Events are circles
                circle = docNode.createElement('circle');
                circle.setAttribute('CX', num2str(shape.x + shape.width/2));
                circle.setAttribute('cycling', num2str(shape.y + shape.height/2));
                circle.setAttribute('r', num2str(shape.width/2));
                circle.setAttribute('fill', '#FFFFFF');
                circle.setAttribute('stroke', '#000000');
                circle.setAttribute('Stroke-Width', '2');
                
                % Set Different Stroke Styles Based on Event Type
                if contains(shape.type, 'start')
                    circle.setAttribute('Stroke-Width', '1');
                elseif contains(shape.type, 'end')
                    circle.setAttribute('Stroke-Width', '3');
                elseif contains(shape.type, 'intermediate')
                    circle.setAttribute('Stroke-Width', '2');
                    
                    % Add Second Circle for Intermediate Events
                    innerCircle = docNode.createElement('circle');
                    innerCircle.setAttribute('CX', num2str(shape.x + shape.width/2));
                    innerCircle.setAttribute('cycling', num2str(shape.y + shape.height/2));
                    innerCircle.setAttribute('r', num2str(shape.width/2 - 4));
                    innerCircle.setAttribute('fill', 'none');
                    innerCircle.setAttribute('stroke', '#000000');
                    innerCircle.setAttribute('Stroke-Width', '1');
                    group.appendChild(innerCircle);
                end
                
                group.appendChild(circle);
                
                % Add Event Icon Based on Type If Needed
                % ...
                
            elseif contains(shape.type, 'pool') || contains(shape.type, 'participant')
                % Pools Are Rectangles
                rect = docNode.createElement('rect');
                rect.setAttribute('X', num2str(shape.x));
                rect.setAttribute('y', num2str(shape.y));
                rect.setAttribute('Width', num2str(shape.width));
                rect.setAttribute('Height', num2str(shape.height));
                rect.setAttribute('fill', '#FFFFFF');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('Stroke-Width', '2');
                group.appendChild(rect);
                
            elseif contains(shape.type, 'lane')
                % LANES ARE Rectangles
                rect = docNode.createElement('rect');
                rect.setAttribute('X', num2str(shape.x));
                rect.setAttribute('y', num2str(shape.y));
                rect.setAttribute('Width', num2str(shape.width));
                rect.setAttribute('Height', num2str(shape.height));
                rect.setAttribute('fill', '#FFFFFF');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('Stroke-Width', '1');
                rect.setAttribute('Stroke-dasharray', '3.3');
                group.appendChild(rect);
                
            elseif contains(shape.type, 'dataobject') || contains(shape.type, 'Dataobject reference')
                % Data objects are document symbols
                rect = docNode.createElement('path');
                x = shape.x;
                y = shape.y;
                w = shape.width;
                h = shape.height;
                foldWidth = w * 0.2;
                foldHeight = h * 0.2;
                
                pathData = [
                    'M', num2str(x), ',,', num2str(y), 
                    'L', num2str(x + w - foldWidth), ',,', num2str(y), 
                    'L', num2str(x + w), ',,', num2str(y + foldHeight), 
                    'L', num2str(x + w), ',,', num2str(y + h), 
                    'L', num2str(x), ',,', num2str(y + h), 
                    'Z', 
                    'M', num2str(x + w - foldWidth), ',,', num2str(y), 
                    'L', num2str(x + w - foldWidth), ',,', num2str(y + foldHeight), 
                    'L', num2str(x + w), ',,', num2str(y + foldHeight)
                ];
                
                rect.setAttribute('D', pathData);
                rect.setAttribute('fill', '#FFFFFF');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('Stroke-Width', '1');
                group.appendChild(rect);
                
            elseif contains(shape.type, 'datastore')
                % Data stores are database of Cylinder
                cylPath = docNode.createElement('path');
                x = shape.x;
                y = shape.y;
                w = shape.width;
                h = shape.height;
                ellipseHeight = h * 0.15;
                
                pathData = [
                    'M', num2str(x), ',,', num2str(y + ellipseHeight), 
                    'A', num2str(w/2), ',,', num2str(ellipseHeight), '0 1.0', num2str(w), ', 0', 
                    'A', num2str(w/2), ',,', num2str(ellipseHeight), '0 1.0', num2str(-w), ', 0', 
                    'M', num2str(x), ',,', num2str(y + ellipseHeight), 
                    'L', num2str(x), ',,', num2str(y + h - ellipseHeight), 
                    'A', num2str(w/2), ',,', num2str(ellipseHeight), '0 1.0', num2str(w), ', 0', 
                    'L', num2str(x + w), ',,', num2str(y + ellipseHeight), 
                    'M', num2str(x), ',,', num2str(y + h - ellipseHeight), 
                    'A', num2str(w/2), ',,', num2str(ellipseHeight), '0 1.0', num2str(w), ', 0'
                ];
                
                cylPath.setAttribute('D', pathData);
                cylPath.setAttribute('fill', '#FFFFFF');
                cylPath.setAttribute('stroke', '#000000');
                cylPath.setAttribute('Stroke-Width', '1');
                group.appendChild(cylPath);
                
            elseif contains(shape.type, 'text notation')
                % Text annotations are folded corner notes
                rect = docNode.createElement('path');
                x = shape.x;
                y = shape.y;
                w = shape.width;
                h = shape.height;
                foldWidth = w * 0.1;
                
                pathData = [
                    'M', num2str(x + foldWidth), ',,', num2str(y), 
                    'L', num2str(x), ',,', num2str(y), 
                    'L', num2str(x), ',,', num2str(y + h), 
                    'L', num2str(x + w), ',,', num2str(y + h), 
                    'L', num2str(x + w), ',,', num2str(y + foldWidth), 
                    'L', num2str(x + w - foldWidth), ',,', num2str(y), 
                    'Z', 
                    'M', num2str(x + w - foldWidth), ',,', num2str(y), 
                    'L', num2str(x + w - foldWidth), ',,', num2str(y + foldWidth), 
                    'L', num2str(x + w), ',,', num2str(y + foldWidth)
                ];
                
                rect.setAttribute('D', pathData);
                rect.setAttribute('fill', '#FFFCC');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('Stroke-Width', '1');
                group.appendChild(rect);
                
            else
                % Default Shape is a Rectangle
                rect = docNode.createElement('rect');
                rect.setAttribute('X', num2str(shape.x));
                rect.setAttribute('y', num2str(shape.y));
                rect.setAttribute('Width', num2str(shape.width));
                rect.setAttribute('Height', num2str(shape.height));
                rect.setAttribute('fill', '#FFFFFF');
                rect.setAttribute('stroke', '#000000');
                rect.setAttribute('Stroke-Width', '1');
                group.appendChild(rect);
            end
            
            shapeElem = group;
            return;
        end
        
        function hexColor = rgbToHex(obj, rgb)
            % Convert RGB Triplet to Hex Color String
            r = round(rgb(1) * 255);
            g = round(rgb(2) * 255);
            b = round(rgb(3) * 255);
            hexColor = sprintf('#%02x%02x%02x', r, g, b);
        end
        
        function success = convertSVGToPNG(obj, svgPath, pngPath)
            % Convert SVG to PNG Using Matlab's Saveas
            try
                % Check if we have the image processing toolbox
                if ~license('test', 'Image_toolbox')
                    warning('Image Processing Toolbox is request for png export.');
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
                    warning('Error Converting to PNG: %S', e.message);
                    % Fallback Method - Requires Image Processing Toolbox
                    try
                        img = imread(svgPath);
                        imwrite(img, pngPath);
                        success = true;
                    catch e2
                        warning('Fallback PNG Conversion Failed: %S', e2.message);
                        success = false;
                    end
                end
                close;
                
            catch e
                warning('Error Converting SVG to PNG: %S', e.message);
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
                warning('Error Converting SVG to PDF: %S', e.message);
                success = false;
            end
        end
    end
end