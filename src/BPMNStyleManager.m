classdef BPMNStyleManager < handle
    % BPMnstylemanager - class for the management of visual styles in BPMN diagrams
    %

    % This class enables the consistent use of styles to BPMN elements and
    % Supports various preset style themes and custom styles.
    
    properties
        diagram             % Referenz zum BPMN-Diagramm
        currentTheme        % Aktuelles Style-Theme
        customStyles        % Benutzerdefinierte Stile für bestimmte Elemente
        styleOptions        % Globale Stil-Konfigurationsoptionen
        defaultStyles       % Standard-Stile für Element-Typen
    end
    
    methods
        function obj = BPMNStyleManager(diagram, options)
            % Constructor for BPMnstylemanager
            %

            % Input:
            % Diagram - BPMN diagram object
            % Options - Struct with style options (optional)
            
            obj.diagram = diagram;
            
            % Set standard options
            defaultOptions = struct(...
                'theme', 'standard', ...          % standard, modern, minimal, highlight
                'linestyle', 'orthogonal', ...    % orthogonal, curved, direct
                'color scheme', 'default', ...     % default, monochrome, colorful, custom
                'font family', 'Arial', ...
                'default fontsize', 12, ...
                'highlight clit', false, ...
                'Usegradient', false, ...
                'useshadows', false, ...
                'Roundcorner', true, ...
                'iconset', 'standard');           % standard, minimal, detailed
            
            % Define standard styles for each element type
            obj.defaultStyles = obj.createDefaultStyles();
            
            % If options have been provided, overwrite the standard values
            if nargin > 1 && ~isempty(options)
                optFields = fieldnames(options);
                for i = 1:length(optFields)
                    defaultOptions.(optFields{i}) = options.(optFields{i});
                end
            end
            
            obj.styleOptions = defaultOptions;
            obj.currentTheme = obj.styleOptions.theme;
            obj.customStyles = containers.Map();
            
            % Use initial styles
            obj.applyTheme(obj.currentTheme);
        end
        
        function defaultStyles = createDefaultStyles(~)
            % Creates standard styles for every BPMN element type
            
            % Basic style definitions
            defaultStyles = struct();
            
            % Tasks
            defaultStyles.task = struct(...
                'fillcolor', [255, 255, 255], ...
                'strokecolor', [0, 0, 0], ...
                'Strokewidth', 1.5, ...
                'text color', [0, 0, 0], ...
                'Corner radius', 5, ...
                'fontsize', 12);
            
            % Events
            defaultStyles.startEvent = struct(...
                'fillcolor', [255, 255, 255], ...
                'strokecolor', [0, 128, 0], ...
                'Strokewidth', 1.5, ...
                'text color', [0, 0, 0], ...
                'fontsize', 11);
            
            defaultStyles.endEvent = struct(...
                'fillcolor', [255, 255, 255], ...
                'strokecolor', [128, 0, 0], ...
                'Strokewidth', 1.5, ...
                'text color', [0, 0, 0], ...
                'fontsize', 11);
            
            defaultStyles.intermediateEvent = struct(...
                'fillcolor', [255, 255, 255], ...
                'strokecolor', [0, 0, 128], ...
                'Strokewidth', 1.5, ...
                'text color', [0, 0, 0], ...
                'fontsize', 11);
            
            % Gateways
            defaultStyles.exclusiveGateway = struct(...
                'fillcolor', [255, 255, 255], ...
                'strokecolor', [0, 0, 0], ...
                'Strokewidth', 1.5, ...
                'text color', [0, 0, 0], ...
                'fontsize', 11);
            
            defaultStyles.parallelGateway = struct(...
                'fillcolor', [255, 255, 255], ...
                'strokecolor', [0, 0, 0], ...
                'Strokewidth', 1.5, ...
                'text color', [0, 0, 0], ...
                'fontsize', 11);
            
            defaultStyles.inclusiveGateway = struct(...
                'fillcolor', [255, 255, 255], ...
                'strokecolor', [0, 0, 0], ...
                'Strokewidth', 1.5, ...
                'text color', [0, 0, 0], ...
                'fontsize', 11);
            
            % Flows
            defaultStyles.sequenceFlow = struct(...
                'linecolor', [0, 0, 0], ...
                'Linewidth', 1.2, ...
                'linestyle', '-', ...
                'text color', [0, 0, 0], ...
                'fontsize', 10);
            
            defaultStyles.messageFlow = struct(...
                'linecolor', [100, 100, 100], ...
                'Linewidth', 1.2, ...
                'linestyle', '--', ...
                'text color', [0, 0, 0], ...
                'fontsize', 10);
            
            defaultStyles.associationFlow = struct(...
                'linecolor', [150, 150, 150], ...
                'Linewidth', 1.0, ...
                'linestyle', '-.', ...
                'text color', [0, 0, 0], ...
                'fontsize', 10);
            
            % Container Elements
            defaultStyles.pool = struct(...
                'fillcolor', [240, 240, 240], ...
                'strokecolor', [0, 0, 0], ...
                'Strokewidth', 1.5, ...
                'text color', [0, 0, 0], ...
                'fontsize', 14);
            
            defaultStyles.lane = struct(...
                'fillcolor', [250, 250, 250], ...
                'strokecolor', [180, 180, 180], ...
                'Strokewidth', 1.0, ...
                'text color', [0, 0, 0], ...
                'fontsize', 12);
            
            % Data objects
            defaultStyles.dataObject = struct(...
                'fillcolor', [255, 255, 220], ...
                'strokecolor', [100, 100, 100], ...
                'Strokewidth', 1.0, ...
                'text color', [0, 0, 0], ...
                'fontsize', 10);
            
            defaultStyles.dataStore = struct(...
                'fillcolor', [255, 255, 220], ...
                'strokecolor', [100, 100, 100], ...
                'Strokewidth', 1.0, ...
                'text color', [0, 0, 0], ...
                'fontsize', 10);
            
            % Annotations
            defaultStyles.textAnnotation = struct(...
                'fillcolor', [255, 255, 255], ...
                'strokecolor', [120, 120, 120], ...
                'Strokewidth', 1.0, ...
                'text color', [0, 0, 0], ...
                'fontsize', 10);
            
            % Groups
            defaultStyles.group = struct(...
                'fillcolor', [0, 0, 0], ... % Transparent
                'strokecolor', [180, 180, 180], ...
                'Strokewidth', 1.0, ...
                'strokestyle', '--', ...
                'text color', [120, 120, 120], ...
                'fontsize', 11);
        end
        
        function applyTheme(obj, themeName)
            % Apply a predefined theme to the diagram
            %

            % Input:
            % Topic name - name of the theme ('Standard', 'Modern', 'Minimal', 'Highlight')
            
            obj.currentTheme = themeName;
            
            % Based on the selected theme, we modify the standard styles
            switch lower(themeName)
                case 'standard'
                    % Standard theme: We use the standard styles
                    % No changes necessary
                    
                case 'modern'
                    % Modern theme with lively colors and rounds
                    obj.styleOptions.useGradients = true;
                    obj.styleOptions.useShadows = true;
                    obj.styleOptions.roundCorners = true;
                    
                    % Update colors for a modern look
                    obj.defaultStyles.task.fillColor = [240, 248, 255];
                    obj.defaultStyles.task.strokeColor = [70, 130, 180];
                    
                    obj.defaultStyles.startEvent.fillColor = [240, 255, 240];
                    obj.defaultStyles.startEvent.strokeColor = [46, 139, 87];
                    
                    obj.defaultStyles.endEvent.fillColor = [255, 240, 240];
                    obj.defaultStyles.endEvent.strokeColor = [178, 34, 34];
                    
                    obj.defaultStyles.exclusiveGateway.fillColor = [255, 250, 240];
                    obj.defaultStyles.exclusiveGateway.strokeColor = [218, 165, 32];
                    
                    obj.defaultStyles.parallelGateway.fillColor = [240, 248, 255];
                    obj.defaultStyles.parallelGateway.strokeColor = [70, 130, 180];
                    
                    obj.defaultStyles.pool.fillColor = [248, 248, 255];
                    obj.defaultStyles.lane.fillColor = [250, 250, 255];
                    
                case 'minimal'
                    % Minimalist theme with reduced visual elements
                    obj.styleOptions.useGradients = false;
                    obj.styleOptions.useShadows = false;
                    obj.styleOptions.roundCorners = false;
                    obj.styleOptions.lineStyle = 'direct';
                    obj.styleOptions.iconSet = 'minimal';
                    
                    % Monochrome colors for a minimalist design
                    for field = fieldnames(obj.defaultStyles)'
                        fieldName = field{1};
                        if isfield(obj.defaultStyles.(fieldName), 'Strokewidth')
                            obj.defaultStyles.(fieldName).strokeWidth = 1.0;
                        end
                        if isfield(obj.defaultStyles.(fieldName), 'strokecolor')
                            obj.defaultStyles.(fieldName).strokeColor = [100, 100, 100];
                        end
                    end
                    
                case 'highlight'
                    % Thema for the highlighting of important process elements
                    obj.styleOptions.highlightCriticalPath = true;
                    obj.styleOptions.useGradients = true;
                    obj.styleOptions.useShadows = true;
                    obj.styleOptions.colorScheme = 'Colorful';
                    
                    % Stronger colors for better visibility
                    obj.defaultStyles.task.fillColor = [255, 255, 224];
                    obj.defaultStyles.task.strokeColor = [0, 0, 0];
                    obj.defaultStyles.task.strokeWidth = 2.0;
                    
                    obj.defaultStyles.startEvent.fillColor = [144, 238, 144];
                    obj.defaultStyles.startEvent.strokeColor = [0, 100, 0];
                    obj.defaultStyles.startEvent.strokeWidth = 2.0;
                    
                    obj.defaultStyles.endEvent.fillColor = [255, 182, 193];
                    obj.defaultStyles.endEvent.strokeColor = [139, 0, 0];
                    obj.defaultStyles.endEvent.strokeWidth = 2.0;
                    
                    obj.defaultStyles.exclusiveGateway.fillColor = [255, 218, 185];
                    obj.defaultStyles.exclusiveGateway.strokeColor = [160, 82, 45];
                    obj.defaultStyles.exclusiveGateway.strokeWidth = 2.0;
                    
                otherwise
                    warning('Unknown theme: %s.Use standard theme.', themeName);
                    obj.currentTheme = 'standard';
            end
            
            % Apply the updated styles to the diagram
            obj.applyStylesToElements();
        end
        
        function applyColorScheme(obj, schemeName)
            % Use a color scheme to the diagram
            %

            % Input:
            % Schemame - name of the color scheme ('default', 'monochrome', 'Colorful', 'Custom')
            
            obj.styleOptions.colorScheme = schemeName;
            
            switch lower(schemeName)
                case 'default'
                    % We use the standard colors of the current theme
                    % No changes necessary
                    
                case 'monochrome'
                    % Monochrome color scheme with shades of gray
                    for field = fieldnames(obj.defaultStyles)'
                        fieldName = field{1};
                        
                        % Different shades of gray for different element types
                        if contains(fieldName, 'task')
                            grayLevel = 240;
                        elseif contains(fieldName, 'event')
                            grayLevel = 225;
                        elseif contains(fieldName, 'gateway')
                            grayLevel = 210;
                        elseif contains(fieldName, 'pool') || contains(fieldName, 'lane')
                            grayLevel = 245;
                        else
                            grayLevel = 230;
                        end
                        
                        if isfield(obj.defaultStyles.(fieldName), 'fillcolor')
                            obj.defaultStyles.(fieldName).fillColor = [grayLevel, grayLevel, grayLevel];
                        end
                        
                        if isfield(obj.defaultStyles.(fieldName), 'strokecolor')
                            obj.defaultStyles.(fieldName).strokeColor = [100, 100, 100];
                        end
                        
                        if isfield(obj.defaultStyles.(fieldName), 'linecolor')
                            obj.defaultStyles.(fieldName).lineColor = [100, 100, 100];
                        end
                    end
                    
                case 'Colorful'
                    % Lively color scheme with high contrast
                    obj.defaultStyles.task.fillColor = [255, 255, 200]; % Hellgelb
                    obj.defaultStyles.task.strokeColor = [0, 0, 150];   % Dunkelblau
                    
                    obj.defaultStyles.startEvent.fillColor = [200, 255, 200]; % Hellgrün
                    obj.defaultStyles.startEvent.strokeColor = [0, 150, 0];   % Grün
                    
                    obj.defaultStyles.endEvent.fillColor = [255, 200, 200];   % Hellrot
                    obj.defaultStyles.endEvent.strokeColor = [150, 0, 0];     % Dunkelrot
                    
                    obj.defaultStyles.intermediateEvent.fillColor = [200, 200, 255]; % Hellblau
                    obj.defaultStyles.intermediateEvent.strokeColor = [0, 0, 150];   % Dunkelblau
                    
                    obj.defaultStyles.exclusiveGateway.fillColor = [255, 223, 186]; % Hellorange
                    obj.defaultStyles.exclusiveGateway.strokeColor = [210, 105, 30]; % Braun
                    
                    obj.defaultStyles.parallelGateway.fillColor = [200, 200, 255]; % Hellblau
                    obj.defaultStyles.parallelGateway.strokeColor = [0, 0, 150];   % Dunkelblau
                    
                    obj.defaultStyles.inclusiveGateway.fillColor = [233, 200, 255]; % Helllila
                    obj.defaultStyles.inclusiveGateway.strokeColor = [128, 0, 128]; % Lila
                    
                    obj.defaultStyles.pool.fillColor = [240, 240, 240]; % Hellgrau
                    obj.defaultStyles.lane.fillColor = [250, 250, 250]; % Sehr hellgrau
                    
                    obj.defaultStyles.dataObject.fillColor = [255, 255, 180]; % Hellgelb
                    obj.defaultStyles.dataStore.fillColor = [255, 255, 180];  % Hellgelb
                    
                case 'custom'
                    % If the color scheme is customary, no automatic changes are made
                    % Colors must be set manually via setc tuslum style
                    
                otherwise
                    warning('Unknown color scheme: %s.Use standard color scheme.', schemeName);
                    obj.styleOptions.colorScheme = 'default';
            end
            
            % Apply the updated styles to the diagram
            obj.applyStylesToElements();
        end
        
        function setLineStyle(obj, lineStyleName)
            % Sets the line style for flows in the diagram
            %

            % Input:
            % Linestyle name - Line style ('Orthogonal', 'Curved', 'Direct')
            
            validStyles = {'orthogonal', 'curved', 'direct'};
            if ~ismember(lower(lineStyleName), validStyles)
                warning('Invalid line style: %s.Valid values: Orthogonal, Curved, Direct', lineStyleName);
                return;
            end
            
            obj.styleOptions.lineStyle = lower(lineStyleName);
            
            % Apply the selected line style to the diagram
            obj.applyLineStylesToFlows();
        end
        
        function setCustomStyle(obj, elementId, styleProperties)
            % Sets custom style properties for a certain element
            %

            % Input:
            % Elementid - ID of the element for which the style is to be set
            % Styleproperties - Struct with the style attributes to be set
            
            % Find the element in the diagram
            element = obj.findElementById(elementId);
            
            if isempty(element)
                warning('Element with ID"%s"not found.', elementId);
                return;
            end
            
            % Save the custom style for the element
            obj.customStyles(elementId) = styleProperties;
            
            % Update the element with the custom style
            obj.applyStylesToElement(element);
        end
        
        function clearCustomStyle(obj, elementId)
            % Removes the custom style for an element
            %

            % Input:
            % Elementid - ID of the Element
            
            if obj.customStyles.isKey(elementId)
                obj.customStyles.remove(elementId);
                
                % Reset on standard style
                element = obj.findElementById(elementId);
                if ~isempty(element)
                    obj.applyStylesToElement(element);
                end
            end
        end
        
        function highlightElements(obj, elementIds, highlightStyle)
            % Removes selected elements
            %

            % Input:
            % Elementids - Array by element IDS that are to be emphasized
            % Highlight style - Struct with style for the emphasis (optional)
            
            % Standard style for highlighting, if not specified
            if nargin < 3 || isempty(highlightStyle)
                highlightStyle = struct(...
                    'strokecolor', [255, 0, 0], ...  % Rot
                    'Strokewidth', 2.5, ...
                    'fillcolor', [255, 230, 230]);   % Hellrosa
            end
            
            % Apply the highlighting style to each element
            for i = 1:length(elementIds)
                obj.setCustomStyle(elementIds{i}, highlightStyle);
            end
        end
        
        function highlightPath(obj, elementIds)
            % Emphasizes a path of elements, often used for critical paths
            %

            % Input:
            % Elementids - Ordered array by element IDS along the path
            
            % Special highlighting for paths
            pathStyle = struct(...
                'strokecolor', [220, 20, 60], ...     % Crimson
                'Strokewidth', 2.5, ...
                'fillcolor', [255, 240, 245]);        % Hellrosa
            
            obj.highlightElements(elementIds, pathStyle);
            
            % Also improve the flows between the elements in the path
            obj.highlightPathFlows(elementIds);
        end
        
        function highlightPathFlows(obj, elementIds)
            % Lifts flows between the elements of the path
            %

            % Input:
            % Elementids - Ordered array by element IDS along the path
            
            flows = obj.diagram.flows;
            
            % Flow removal style
            flowStyle = struct(...
                'linecolor', [220, 20, 60], ...       % Crimson
                'Linewidth', 2.0);
            
            % Find and update all flows between consecutive elements in the path
            for i = 1:length(elementIds)-1
                sourceId = elementIds{i};
                targetId = elementIds{i+1};
                
                % Find the flow from Source to Target
                for j = 1:length(flows)
                    if strcmp(flows{j}.sourceRef, sourceId) && strcmp(flows{j}.targetRef, targetId)
                        % Apply the flow style
                        flowId = flows{j}.id;
                        obj.setCustomStyle(flowId, flowStyle);
                        break;
                    end
                end
            end
        end
        
        function applyStylesToElements(obj)
            % Use the styles to all elements of the diagram
            
            elements = obj.diagram.elements;
            flows = obj.diagram.flows;
            
            % Apply styles to elements
            for i = 1:length(elements)
                obj.applyStylesToElement(elements{i});
            end
            
            % Apply styles to flows
            for i = 1:length(flows)
                obj.applyStylesToFlow(flows{i});
            end
        end
        
        function applyStylesToElement(obj, element)
            % Use styles to a single element
            
            % Determine the element type
            elementType = element.type;
            
            % Choose the corresponding style based on the element type
            if isfield(obj.defaultStyles, elementType)
                style = obj.defaultStyles.(elementType);
            else
                % If no specific style has been found, use the standard style for tasks
                style = obj.defaultStyles.task;
            end
            
            % Check whether there is a custom style for this element
            if obj.customStyles.isKey(element.id)
                customStyle = obj.customStyles(element.id);
                styleFields = fieldnames(customStyle);
                
                % Overwrite the standard styles with custom values
                for j = 1:length(styleFields)
                    style.(styleFields{j}) = customStyle.(styleFields{j});
                end
            end
            
            % Apply the style properties to the element
            if isfield(style, 'fillcolor')
                element.fillColor = style.fillColor;
            end
            
            if isfield(style, 'strokecolor')
                element.strokeColor = style.strokeColor;
            end
            
            if isfield(style, 'Strokewidth')
                element.strokeWidth = style.strokeWidth;
            end
            
            if isfield(style, 'text color')
                element.textColor = style.textColor;
            end
            
            if isfield(style, 'fontsize')
                element.fontSize = style.fontSize;
            end
            
            if isfield(style, 'Corner radius') && obj.styleOptions.roundCorners
                element.cornerRadius = style.cornerRadius;
            elseif obj.styleOptions.roundCorners && (strcmp(elementType, 'task') || ...
                   strcmp(elementType, 'subprocess'))
                element.cornerRadius = 5;
            else
                element.cornerRadius = 0;
            end
            
            % Add gradient effects when activated
            if obj.styleOptions.useGradients && ~strcmp(elementType, 'text notation') && ...
               ~strcmp(elementType, 'group')
                if ~isfield(element, 'gradient')
                    element.gradient = struct();
                end
                
                % Create a lighter color for the gradient
                if isfield(element, 'fillcolor')
                    baseColor = element.fillColor;
                    lighterColor = min(255, baseColor + 40);  % Hellerer Farbton
                    element.gradient.startColor = lighterColor;
                    element.gradient.endColor = baseColor;
                    element.gradient.type = 'linear';
                    element.gradient.direction = 'vertical';
                end
            else
                % Remove gradient, if not activated
                if isfield(element, 'gradient')
                    element = rmfield(element, 'gradient');
                end
            end
            
            % Add shadow effects when activated
            if obj.styleOptions.useShadows && ~strcmp(elementType, 'text notation') && ...
               ~strcmp(elementType, 'group') && ~contains(elementType, 'Flow')
                if ~isfield(element, 'shadow')
                    element.shadow = struct();
                end
                
                element.shadow.visible = true;
                element.shadow.color = [180, 180, 180];
                element.shadow.offsetX = 3;
                element.shadow.offsetY = 3;
                element.shadow.blur = 5;
            else
                % Remove shadows if not activated
                if isfield(element, 'shadow')
                    element = rmfield(element, 'shadow');
                end
            end
            
            % Set the font if specified
            if ~isempty(obj.styleOptions.fontFamily)
                element.fontFamily = obj.styleOptions.fontFamily;
            end
        end
        
        function applyStylesToFlow(obj, flow)
            % Turn styles to a single flow
            
            % Determine the flow type
            if isfield(flow, 'type')
                flowType = flow.type;
            else
                % Standard: Sequenceflow
                flowType = 'sequenceflow';
            end
            
            % Wähle den entsprechenden Stil basierend auf dem Flow-Typ
            if isfield(obj.defaultStyles, flowType)
                style = obj.defaultStyles.(flowType);
            else
                % Wenn kein spezifischer Stil gefunden wurde, verwende den Standardstil für SequenceFlows
                style = obj.defaultStyles.sequenceFlow;
            end
            
            % Check whether there is a custom style for this flow
            if obj.customStyles.isKey(flow.id)
                customStyle = obj.customStyles(flow.id);
                styleFields = fieldnames(customStyle);
                
                % Overwrite the standard styles with custom values
                for j = 1:length(styleFields)
                    style.(styleFields{j}) = customStyle.(styleFields{j});
                end
            end
            
            % Apply the style properties to the flow
            if isfield(style, 'linecolor')
                flow.lineColor = style.lineColor;
            end
            
            if isfield(style, 'Linewidth')
                flow.lineWidth = style.lineWidth;
            end
            
            if isfield(style, 'linestyle')
                flow.lineStyle = style.lineStyle;
            end
            
            if isfield(style, 'text color')
                flow.textColor = style.textColor;
            end
            
            if isfield(style, 'fontsize')
                flow.fontSize = style.fontSize;
            end
            
            % Apply the selected line style to the geometry of the flows
            obj.applyLineStyleToFlow(flow);
        end
        
        function applyLineStyleToFlow(obj, flow)
            % Apply the selected line style to a flow
            
            % Find the source and target elements
            sourceElement = obj.findElementById(flow.sourceRef);
            targetElement = obj.findElementById(flow.targetRef);
            
            if isempty(sourceElement) || isempty(targetElement)
                return;
            end
            
            % Depending on the selected line style, calculate the waypoints
            switch obj.styleOptions.lineStyle
                case 'orthogonal'
                    % Right -angled connections
                    waypoints = obj.calculateOrthogonalWaypoints(sourceElement, targetElement);
                    
                case 'curved'
                    % Curved connections
                    waypoints = obj.calculateCurvedWaypoints(sourceElement, targetElement);
                    flow.curved = true;
                    
                case 'direct'
                    % Direct connections
                    waypoints = obj.calculateDirectWaypoints(sourceElement, targetElement);
                    
                otherwise
                    % Standard: Orthogonal
                    waypoints = obj.calculateOrthogonalWaypoints(sourceElement, targetElement);
            end
            
            % Apply the calculated waypoints
            flow.waypoints = waypoints;
        end
        
        function applyLineStylesToFlows(obj)
            % Apply the current line style to all flows in the diagram
            
            flows = obj.diagram.flows;
            
            for i = 1:length(flows)
                obj.applyLineStyleToFlow(flows{i});
            end
        end
        
        function waypoints = calculateOrthogonalWaypoints(obj, source, target)
            % Calculates waypoints for a right -angled path between two elements
            
            % Center of the elements
            sourceX = source.x + source.width/2;
            sourceY = source.y + source.height/2;
            targetX = target.x + target.width/2;
            targetY = target.y + target.height/2;
            
            % Simple case: same height
            if abs(sourceY - targetY) < obj.styleOptions.minNodeDistance
                waypoints = [sourceX, sourceY; targetX, targetY];
                return;
            end
            
            % Standard: 3-point connection with a horizontal segment
            midY = (sourceY + targetY) / 2;
            waypoints = [sourceX, sourceY; sourceX, midY; targetX, midY; targetX, targetY];
        end
        
        function waypoints = calculateCurvedWaypoints(~, source, target)
            % Calculates waypoints for a curved connection
            % With a curved line we usually only need the start and end point
            % Plus control points for the curve
            
            % Calculate the centerpoints of the elements as start and end points
            sourceX = source.x + source.width/2;
            sourceY = source.y + source.height/2;
            targetX = target.x + target.width/2;
            targetY = target.y + target.height/2;
            
            % For a simple Bézier curve we also need control points
            % With a Cubic Bézier curve, these are two additional points
            controlPoint1X = sourceX + (targetX - sourceX) * 0.25;
            controlPoint1Y = sourceY;
            controlPoint2X = sourceX + (targetX - sourceX) * 0.75;
            controlPoint2Y = targetY;
            
            % Ways for a Bézier curve
            waypoints = [sourceX, sourceY; ...
                         controlPoint1X, controlPoint1Y; ...
                         controlPoint2X, controlPoint2Y; ...
                         targetX, targetY];
        end
        
        function waypoints = calculateDirectWaypoints(~, source, target)
            % Calculates waypoints for a direct connection between two elements
            
            % With a direct connection we simply use the centerpoints of the elements
            sourceX = source.x + source.width/2;
            sourceY = source.y + source.height/2;
            targetX = target.x + target.width/2;
            targetY = target.y + target.height/2;
            
            waypoints = [sourceX, sourceY; targetX, targetY];
        end
        
        function element = findElementById(obj, id)
            % Finds an element based on its ID
            
            elements = obj.diagram.elements;
            
            for i = 1:length(elements)
                if strcmp(elements{i}.id, id)
                    element = elements{i};
                    return;
                end
            end
            
            element = [];
        end
    end
end