classdef BPMNStyleManager < handle
    % BPMNStyleManager - Klasse für die Verwaltung von visuellen Stilen in BPMN-Diagrammen
    %
    % Diese Klasse ermöglicht die konsistente Anwendung von Stilen auf BPMN-Elemente und
    % unterstützt verschiedene voreingestellte Style-Themes sowie benutzerdefinierte Stile.
    
    properties
        diagram             % Referenz zum BPMN-Diagramm
        currentTheme        % Aktuelles Style-Theme
        customStyles        % Benutzerdefinierte Stile für bestimmte Elemente
        styleOptions        % Globale Stil-Konfigurationsoptionen
        defaultStyles       % Standard-Stile für Element-Typen
    end
    
    methods
        function obj = BPMNStyleManager(diagram, options)
            % Konstruktor für BPMNStyleManager
            %
            % Eingabe:
            %   diagram - BPMN-Diagramm Objekt
            %   options - Struct mit Stil-Optionen (optional)
            
            obj.diagram = diagram;
            
            % Standardoptionen festlegen
            defaultOptions = struct(...
                'theme', 'standard', ...          % standard, modern, minimal, highlight
                'lineStyle', 'orthogonal', ...    % orthogonal, curved, direct
                'colorScheme', 'default', ...     % default, monochrome, colorful, custom
                'fontFamily', 'Arial', ...
                'defaultFontSize', 12, ...
                'highlightCriticalPath', false, ...
                'useGradients', false, ...
                'useShadows', false, ...
                'roundCorners', true, ...
                'iconSet', 'standard');           % standard, minimal, detailed
            
            % Standard-Stile für jeden Element-Typ definieren
            obj.defaultStyles = obj.createDefaultStyles();
            
            % Wenn Optionen bereitgestellt wurden, überschreiben Sie die Standardwerte
            if nargin > 1 && ~isempty(options)
                optFields = fieldnames(options);
                for i = 1:length(optFields)
                    defaultOptions.(optFields{i}) = options.(optFields{i});
                end
            end
            
            obj.styleOptions = defaultOptions;
            obj.currentTheme = obj.styleOptions.theme;
            obj.customStyles = containers.Map();
            
            % Initial-Stile anwenden
            obj.applyTheme(obj.currentTheme);
        end
        
        function defaultStyles = createDefaultStyles(~)
            % Erstellt Standard-Stile für jeden BPMN-Element-Typ
            
            % Grundlegende Stil-Definitionen
            defaultStyles = struct();
            
            % Tasks
            defaultStyles.task = struct(...
                'fillColor', [255, 255, 255], ...
                'strokeColor', [0, 0, 0], ...
                'strokeWidth', 1.5, ...
                'textColor', [0, 0, 0], ...
                'cornerRadius', 5, ...
                'fontSize', 12);
            
            % Events
            defaultStyles.startEvent = struct(...
                'fillColor', [255, 255, 255], ...
                'strokeColor', [0, 128, 0], ...
                'strokeWidth', 1.5, ...
                'textColor', [0, 0, 0], ...
                'fontSize', 11);
            
            defaultStyles.endEvent = struct(...
                'fillColor', [255, 255, 255], ...
                'strokeColor', [128, 0, 0], ...
                'strokeWidth', 1.5, ...
                'textColor', [0, 0, 0], ...
                'fontSize', 11);
            
            defaultStyles.intermediateEvent = struct(...
                'fillColor', [255, 255, 255], ...
                'strokeColor', [0, 0, 128], ...
                'strokeWidth', 1.5, ...
                'textColor', [0, 0, 0], ...
                'fontSize', 11);
            
            % Gateways
            defaultStyles.exclusiveGateway = struct(...
                'fillColor', [255, 255, 255], ...
                'strokeColor', [0, 0, 0], ...
                'strokeWidth', 1.5, ...
                'textColor', [0, 0, 0], ...
                'fontSize', 11);
            
            defaultStyles.parallelGateway = struct(...
                'fillColor', [255, 255, 255], ...
                'strokeColor', [0, 0, 0], ...
                'strokeWidth', 1.5, ...
                'textColor', [0, 0, 0], ...
                'fontSize', 11);
            
            defaultStyles.inclusiveGateway = struct(...
                'fillColor', [255, 255, 255], ...
                'strokeColor', [0, 0, 0], ...
                'strokeWidth', 1.5, ...
                'textColor', [0, 0, 0], ...
                'fontSize', 11);
            
            % Flows
            defaultStyles.sequenceFlow = struct(...
                'lineColor', [0, 0, 0], ...
                'lineWidth', 1.2, ...
                'lineStyle', '-', ...
                'textColor', [0, 0, 0], ...
                'fontSize', 10);
            
            defaultStyles.messageFlow = struct(...
                'lineColor', [100, 100, 100], ...
                'lineWidth', 1.2, ...
                'lineStyle', '--', ...
                'textColor', [0, 0, 0], ...
                'fontSize', 10);
            
            defaultStyles.associationFlow = struct(...
                'lineColor', [150, 150, 150], ...
                'lineWidth', 1.0, ...
                'lineStyle', '-.', ...
                'textColor', [0, 0, 0], ...
                'fontSize', 10);
            
            % Container Elements
            defaultStyles.pool = struct(...
                'fillColor', [240, 240, 240], ...
                'strokeColor', [0, 0, 0], ...
                'strokeWidth', 1.5, ...
                'textColor', [0, 0, 0], ...
                'fontSize', 14);
            
            defaultStyles.lane = struct(...
                'fillColor', [250, 250, 250], ...
                'strokeColor', [180, 180, 180], ...
                'strokeWidth', 1.0, ...
                'textColor', [0, 0, 0], ...
                'fontSize', 12);
            
            % Data Objects
            defaultStyles.dataObject = struct(...
                'fillColor', [255, 255, 220], ...
                'strokeColor', [100, 100, 100], ...
                'strokeWidth', 1.0, ...
                'textColor', [0, 0, 0], ...
                'fontSize', 10);
            
            defaultStyles.dataStore = struct(...
                'fillColor', [255, 255, 220], ...
                'strokeColor', [100, 100, 100], ...
                'strokeWidth', 1.0, ...
                'textColor', [0, 0, 0], ...
                'fontSize', 10);
            
            % Annotations
            defaultStyles.textAnnotation = struct(...
                'fillColor', [255, 255, 255], ...
                'strokeColor', [120, 120, 120], ...
                'strokeWidth', 1.0, ...
                'textColor', [0, 0, 0], ...
                'fontSize', 10);
            
            % Groups
            defaultStyles.group = struct(...
                'fillColor', [0, 0, 0], ... % Transparent
                'strokeColor', [180, 180, 180], ...
                'strokeWidth', 1.0, ...
                'strokeStyle', '--', ...
                'textColor', [120, 120, 120], ...
                'fontSize', 11);
        end
        
        function applyTheme(obj, themeName)
            % Wendet ein vordefiniertes Theme auf das Diagramm an
            %
            % Eingabe:
            %   themeName - Name des Themes ('standard', 'modern', 'minimal', 'highlight')
            
            obj.currentTheme = themeName;
            
            % Basieren auf dem ausgewählten Theme modifizieren wir die Standardstile
            switch lower(themeName)
                case 'standard'
                    % Standard-Theme: Wir verwenden die Standard-Stile
                    % Keine Änderungen nötig
                    
                case 'modern'
                    % Modernes Theme mit lebendigen Farben und Abrundungen
                    obj.styleOptions.useGradients = true;
                    obj.styleOptions.useShadows = true;
                    obj.styleOptions.roundCorners = true;
                    
                    % Aktualisiere Farben für ein modernes Aussehen
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
                    % Minimalistisches Theme mit reduzierten visuellen Elementen
                    obj.styleOptions.useGradients = false;
                    obj.styleOptions.useShadows = false;
                    obj.styleOptions.roundCorners = false;
                    obj.styleOptions.lineStyle = 'direct';
                    obj.styleOptions.iconSet = 'minimal';
                    
                    % Monochrome Farben für ein minimalistisches Design
                    for field = fieldnames(obj.defaultStyles)'
                        fieldName = field{1};
                        if isfield(obj.defaultStyles.(fieldName), 'strokeWidth')
                            obj.defaultStyles.(fieldName).strokeWidth = 1.0;
                        end
                        if isfield(obj.defaultStyles.(fieldName), 'strokeColor')
                            obj.defaultStyles.(fieldName).strokeColor = [100, 100, 100];
                        end
                    end
                    
                case 'highlight'
                    % Theme zur Hervorhebung wichtiger Prozesselemente
                    obj.styleOptions.highlightCriticalPath = true;
                    obj.styleOptions.useGradients = true;
                    obj.styleOptions.useShadows = true;
                    obj.styleOptions.colorScheme = 'colorful';
                    
                    % Stärkere Farben für bessere Sichtbarkeit
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
                    warning('Unbekanntes Theme: %s. Verwende Standard-Theme.', themeName);
                    obj.currentTheme = 'standard';
            end
            
            % Wende die aktualisierten Stile auf das Diagramm an
            obj.applyStylesToElements();
        end
        
        function applyColorScheme(obj, schemeName)
            % Wendet ein Farbschema auf das Diagramm an
            %
            % Eingabe:
            %   schemeName - Name des Farbschemas ('default', 'monochrome', 'colorful', 'custom')
            
            obj.styleOptions.colorScheme = schemeName;
            
            switch lower(schemeName)
                case 'default'
                    % Wir verwenden die Standard-Farben des aktuellen Themes
                    % Keine Änderungen nötig
                    
                case 'monochrome'
                    % Monochrome Farbschema mit Grautönen
                    for field = fieldnames(obj.defaultStyles)'
                        fieldName = field{1};
                        
                        % Verschiedene Grautöne für verschiedene Element-Typen
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
                        
                        if isfield(obj.defaultStyles.(fieldName), 'fillColor')
                            obj.defaultStyles.(fieldName).fillColor = [grayLevel, grayLevel, grayLevel];
                        end
                        
                        if isfield(obj.defaultStyles.(fieldName), 'strokeColor')
                            obj.defaultStyles.(fieldName).strokeColor = [100, 100, 100];
                        end
                        
                        if isfield(obj.defaultStyles.(fieldName), 'lineColor')
                            obj.defaultStyles.(fieldName).lineColor = [100, 100, 100];
                        end
                    end
                    
                case 'colorful'
                    % Lebendiges Farbschema mit hohem Kontrast
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
                    % Bei benutzerdefiniertem Farbschema werden keine automatischen Änderungen vorgenommen
                    % Farben müssen manuell über setCustomStyle gesetzt werden
                    
                otherwise
                    warning('Unbekanntes Farbschema: %s. Verwende Standard-Farbschema.', schemeName);
                    obj.styleOptions.colorScheme = 'default';
            end
            
            % Wende die aktualisierten Stile auf das Diagramm an
            obj.applyStylesToElements();
        end
        
        function setLineStyle(obj, lineStyleName)
            % Setzt den Linienstil für Flows im Diagramm
            %
            % Eingabe:
            %   lineStyleName - Linienstil ('orthogonal', 'curved', 'direct')
            
            validStyles = {'orthogonal', 'curved', 'direct'};
            if ~ismember(lower(lineStyleName), validStyles)
                warning('Ungültiger Linienstil: %s. Gültige Werte: orthogonal, curved, direct', lineStyleName);
                return;
            end
            
            obj.styleOptions.lineStyle = lower(lineStyleName);
            
            % Wende den ausgewählten Linienstil auf das Diagramm an
            obj.applyLineStylesToFlows();
        end
        
        function setCustomStyle(obj, elementId, styleProperties)
            % Setzt benutzerdefinierte Stileigenschaften für ein bestimmtes Element
            %
            % Eingabe:
            %   elementId - ID des Elements, für das der Stil gesetzt werden soll
            %   styleProperties - Struct mit den zu setzenden Stilattributen
            
            % Finde das Element im Diagramm
            element = obj.findElementById(elementId);
            
            if isempty(element)
                warning('Element mit ID "%s" nicht gefunden.', elementId);
                return;
            end
            
            % Speichere den benutzerdefinierten Stil für das Element
            obj.customStyles(elementId) = styleProperties;
            
            % Aktualisiere das Element mit dem benutzerdefinierten Stil
            obj.applyStylesToElement(element);
        end
        
        function clearCustomStyle(obj, elementId)
            % Entfernt den benutzerdefinierten Stil für ein Element
            %
            % Eingabe:
            %   elementId - ID des Elements
            
            if obj.customStyles.isKey(elementId)
                obj.customStyles.remove(elementId);
                
                % Reset auf Standard-Stil
                element = obj.findElementById(elementId);
                if ~isempty(element)
                    obj.applyStylesToElement(element);
                end
            end
        end
        
        function highlightElements(obj, elementIds, highlightStyle)
            % Hebt ausgewählte Elemente hervor
            %
            % Eingabe:
            %   elementIds - Array von Element-IDs, die hervorgehoben werden sollen
            %   highlightStyle - Struct mit Stil für die Hervorhebung (optional)
            
            % Standardstil für Hervorhebung, falls nicht angegeben
            if nargin < 3 || isempty(highlightStyle)
                highlightStyle = struct(...
                    'strokeColor', [255, 0, 0], ...  % Rot
                    'strokeWidth', 2.5, ...
                    'fillColor', [255, 230, 230]);   % Hellrosa
            end
            
            % Wende den Hervorhebungsstil auf jedes Element an
            for i = 1:length(elementIds)
                obj.setCustomStyle(elementIds{i}, highlightStyle);
            end
        end
        
        function highlightPath(obj, elementIds)
            % Hebt einen Pfad von Elementen hervor, häufig für kritische Pfade verwendet
            %
            % Eingabe:
            %   elementIds - Geordnetes Array von Element-IDs entlang des Pfades
            
            % Spezielle Hervorhebung für Pfade
            pathStyle = struct(...
                'strokeColor', [220, 20, 60], ...     % Crimson
                'strokeWidth', 2.5, ...
                'fillColor', [255, 240, 245]);        % Hellrosa
            
            obj.highlightElements(elementIds, pathStyle);
            
            % Verbessere auch die Flows zwischen den Elementen im Pfad
            obj.highlightPathFlows(elementIds);
        end
        
        function highlightPathFlows(obj, elementIds)
            % Hebt Flows zwischen den Elementen des Pfads hervor
            %
            % Eingabe:
            %   elementIds - Geordnetes Array von Element-IDs entlang des Pfades
            
            flows = obj.diagram.flows;
            
            % Flow-Hervorhebungsstil
            flowStyle = struct(...
                'lineColor', [220, 20, 60], ...       % Crimson
                'lineWidth', 2.0);
            
            % Finde und aktualisiere alle Flows zwischen aufeinanderfolgenden Elementen im Pfad
            for i = 1:length(elementIds)-1
                sourceId = elementIds{i};
                targetId = elementIds{i+1};
                
                % Finde den Flow von source zu target
                for j = 1:length(flows)
                    if strcmp(flows{j}.sourceRef, sourceId) && strcmp(flows{j}.targetRef, targetId)
                        % Wende den Flow-Stil an
                        flowId = flows{j}.id;
                        obj.setCustomStyle(flowId, flowStyle);
                        break;
                    end
                end
            end
        end
        
        function applyStylesToElements(obj)
            % Wendet die Stile auf alle Elemente des Diagramms an
            
            elements = obj.diagram.elements;
            flows = obj.diagram.flows;
            
            % Stile auf Elemente anwenden
            for i = 1:length(elements)
                obj.applyStylesToElement(elements{i});
            end
            
            % Stile auf Flows anwenden
            for i = 1:length(flows)
                obj.applyStylesToFlow(flows{i});
            end
        end
        
        function applyStylesToElement(obj, element)
            % Wendet Stile auf ein einzelnes Element an
            
            % Bestimme den Elementtyp
            elementType = element.type;
            
            % Wähle den entsprechenden Stil basierend auf dem Elementtyp
            if isfield(obj.defaultStyles, elementType)
                style = obj.defaultStyles.(elementType);
            else
                % Wenn kein spezifischer Stil gefunden wurde, verwende den Standardstil für Tasks
                style = obj.defaultStyles.task;
            end
            
            % Prüfe, ob es einen benutzerdefinierten Stil für dieses Element gibt
            if obj.customStyles.isKey(element.id)
                customStyle = obj.customStyles(element.id);
                styleFields = fieldnames(customStyle);
                
                % Überschreibe die Standardstile mit benutzerdefinierten Werten
                for j = 1:length(styleFields)
                    style.(styleFields{j}) = customStyle.(styleFields{j});
                end
            end
            
            % Wende die Stileigenschaften auf das Element an
            if isfield(style, 'fillColor')
                element.fillColor = style.fillColor;
            end
            
            if isfield(style, 'strokeColor')
                element.strokeColor = style.strokeColor;
            end
            
            if isfield(style, 'strokeWidth')
                element.strokeWidth = style.strokeWidth;
            end
            
            if isfield(style, 'textColor')
                element.textColor = style.textColor;
            end
            
            if isfield(style, 'fontSize')
                element.fontSize = style.fontSize;
            end
            
            if isfield(style, 'cornerRadius') && obj.styleOptions.roundCorners
                element.cornerRadius = style.cornerRadius;
            elseif obj.styleOptions.roundCorners && (strcmp(elementType, 'task') || ...
                   strcmp(elementType, 'subProcess'))
                element.cornerRadius = 5;
            else
                element.cornerRadius = 0;
            end
            
            % Füge Gradient-Effekte hinzu, wenn aktiviert
            if obj.styleOptions.useGradients && ~strcmp(elementType, 'textAnnotation') && ...
               ~strcmp(elementType, 'group')
                if ~isfield(element, 'gradient')
                    element.gradient = struct();
                end
                
                % Erstelle einen helleren Farbton für den Gradienten
                if isfield(element, 'fillColor')
                    baseColor = element.fillColor;
                    lighterColor = min(255, baseColor + 40);  % Hellerer Farbton
                    element.gradient.startColor = lighterColor;
                    element.gradient.endColor = baseColor;
                    element.gradient.type = 'linear';
                    element.gradient.direction = 'vertical';
                end
            else
                % Entferne Gradient, wenn nicht aktiviert
                if isfield(element, 'gradient')
                    element = rmfield(element, 'gradient');
                end
            end
            
            % Füge Schatten-Effekte hinzu, wenn aktiviert
            if obj.styleOptions.useShadows && ~strcmp(elementType, 'textAnnotation') && ...
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
                % Entferne Schatten, wenn nicht aktiviert
                if isfield(element, 'shadow')
                    element = rmfield(element, 'shadow');
                end
            end
            
            % Setze die Schriftart, falls angegeben
            if ~isempty(obj.styleOptions.fontFamily)
                element.fontFamily = obj.styleOptions.fontFamily;
            end
        end
        
        function applyStylesToFlow(obj, flow)
            % Wendet Stile auf einen einzelnen Flow an
            
            % Bestimme den Flow-Typ
            if isfield(flow, 'type')
                flowType = flow.type;
            else
                % Standard: sequenceFlow
                flowType = 'sequenceFlow';
            end
            
            % Wähle den entsprechenden Stil basierend auf dem Flow-Typ
            if isfield(obj.defaultStyles, flowType)
                style = obj.defaultStyles.(flowType);
            else
                % Wenn kein spezifischer Stil gefunden wurde, verwende den Standardstil für SequenceFlows
                style = obj.defaultStyles.sequenceFlow;
            end
            
            % Prüfe, ob es einen benutzerdefinierten Stil für diesen Flow gibt
            if obj.customStyles.isKey(flow.id)
                customStyle = obj.customStyles(flow.id);
                styleFields = fieldnames(customStyle);
                
                % Überschreibe die Standardstile mit benutzerdefinierten Werten
                for j = 1:length(styleFields)
                    style.(styleFields{j}) = customStyle.(styleFields{j});
                end
            end
            
            % Wende die Stileigenschaften auf den Flow an
            if isfield(style, 'lineColor')
                flow.lineColor = style.lineColor;
            end
            
            if isfield(style, 'lineWidth')
                flow.lineWidth = style.lineWidth;
            end
            
            if isfield(style, 'lineStyle')
                flow.lineStyle = style.lineStyle;
            end
            
            if isfield(style, 'textColor')
                flow.textColor = style.textColor;
            end
            
            if isfield(style, 'fontSize')
                flow.fontSize = style.fontSize;
            end
            
            % Wende den ausgewählten Linienstil auf die Geometrie des Flows an
            obj.applyLineStyleToFlow(flow);
        end
        
        function applyLineStyleToFlow(obj, flow)
            % Wendet den ausgewählten Linienstil auf einen Flow an
            
            % Finde die Quell- und Zielelemente
            sourceElement = obj.findElementById(flow.sourceRef);
            targetElement = obj.findElementById(flow.targetRef);
            
            if isempty(sourceElement) || isempty(targetElement)
                return;
            end
            
            % Je nach gewähltem Linienstil die Wegpunkte berechnen
            switch obj.styleOptions.lineStyle
                case 'orthogonal'
                    % Rechtwinklige Verbindungen
                    waypoints = obj.calculateOrthogonalWaypoints(sourceElement, targetElement);
                    
                case 'curved'
                    % Gebogene Verbindungen
                    waypoints = obj.calculateCurvedWaypoints(sourceElement, targetElement);
                    flow.curved = true;
                    
                case 'direct'
                    % Direkte Verbindungen
                    waypoints = obj.calculateDirectWaypoints(sourceElement, targetElement);
                    
                otherwise
                    % Standard: orthogonal
                    waypoints = obj.calculateOrthogonalWaypoints(sourceElement, targetElement);
            end
            
            % Anwenden der berechneten Wegpunkte
            flow.waypoints = waypoints;
        end
        
        function applyLineStylesToFlows(obj)
            % Wendet den aktuellen Linienstil auf alle Flows im Diagramm an
            
            flows = obj.diagram.flows;
            
            for i = 1:length(flows)
                obj.applyLineStyleToFlow(flows{i});
            end
        end
        
        function waypoints = calculateOrthogonalWaypoints(obj, source, target)
            % Berechnet Wegpunkte für einen rechtwinkligen Pfad zwischen zwei Elementen
            
            % Mittelpunkte der Elemente
            sourceX = source.x + source.width/2;
            sourceY = source.y + source.height/2;
            targetX = target.x + target.width/2;
            targetY = target.y + target.height/2;
            
            % Einfacher Fall: gleiche Höhe
            if abs(sourceY - targetY) < obj.styleOptions.minNodeDistance
                waypoints = [sourceX, sourceY; targetX, targetY];
                return;
            end
            
            % Standard: 3-Punkt-Verbindung mit horizontalem Segment
            midY = (sourceY + targetY) / 2;
            waypoints = [sourceX, sourceY; sourceX, midY; targetX, midY; targetX, targetY];
        end
        
        function waypoints = calculateCurvedWaypoints(~, source, target)
            % Berechnet Wegpunkte für eine gebogene Verbindung
            % Bei einer gebogenen Linie benötigen wir normalerweise nur Start- und Endpunkt
            % plus Kontrollpunkte für die Kurve
            
            % Berechne die Mittelpunkte der Elemente als Start- und Endpunkte
            sourceX = source.x + source.width/2;
            sourceY = source.y + source.height/2;
            targetX = target.x + target.width/2;
            targetY = target.y + target.height/2;
            
            % Für eine einfache Bézier-Kurve brauchen wir auch Kontrollpunkte
            % bei einer kubischen Bézier-Kurve sind dies zwei zusätzliche Punkte
            controlPoint1X = sourceX + (targetX - sourceX) * 0.25;
            controlPoint1Y = sourceY;
            controlPoint2X = sourceX + (targetX - sourceX) * 0.75;
            controlPoint2Y = targetY;
            
            % Wegpunkte für eine Bézier-Kurve
            waypoints = [sourceX, sourceY; ...
                         controlPoint1X, controlPoint1Y; ...
                         controlPoint2X, controlPoint2Y; ...
                         targetX, targetY];
        end
        
        function waypoints = calculateDirectWaypoints(~, source, target)
            % Berechnet Wegpunkte für eine direkte Verbindung zwischen zwei Elementen
            
            % Bei einer direkten Verbindung verwenden wir einfach die Mittelpunkte der Elemente
            sourceX = source.x + source.width/2;
            sourceY = source.y + source.height/2;
            targetX = target.x + target.width/2;
            targetY = target.y + target.height/2;
            
            waypoints = [sourceX, sourceY; targetX, targetY];
        end
        
        function element = findElementById(obj, id)
            % Findet ein Element anhand seiner ID
            
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