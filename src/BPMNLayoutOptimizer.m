classdef BPMNLayoutOptimizer < handle
    % BPMNLayoutOptimizer - Klasse zur Optimierung des Layouts von BPMN-Diagrammen
    %
    % Diese Klasse implementiert verschiedene Algorithmen zur Optimierung des Layouts
    % von BPMN-Diagrammen, einschließlich Kreuzungsminimierung, Abstandsoptimierung
    % und Ausrichtungsfunktionen.
    
    properties
        diagram         % Referenz zum BPMN-Diagramm
        optimizeOptions % Optionen für die Optimierung
    end
    
    methods
        function obj = BPMNLayoutOptimizer(diagram, options)
            % Konstruktor für den BPMNLayoutOptimizer
            %
            % Eingabe:
            %   diagram - BPMN-Diagramm Objekt
            %   options - Struct mit Optimierungsoptionen (optional)
            
            obj.diagram = diagram;
            
            % Standardoptionen setzen
            defaultOptions = struct(...
                'minNodeDistance', 50, ...
                'layerSpacing', 100, ...
                'optimizeCrossings', true, ...
                'alignGateways', true, ...
                'centerActivities', true, ...
                'smartEdgeRouting', true, ...
                'avoidElementOverlap', true, ...  % Neue Option
                'optimizeFlowPaths', true);       % Neue Option
            
            % Wenn Optionen bereitgestellt wurden, überschreiben Sie die Standardwerte
            if nargin > 1 && ~isempty(options)
                optFields = fieldnames(options);
                for i = 1:length(optFields)
                    defaultOptions.(optFields{i}) = options.(optFields{i});
                end
            end
            
            obj.optimizeOptions = defaultOptions;
        end
        
        function optimizedDiagram = optimizeAll(obj)
            % Optimiert das gesamte Diagramm-Layout
            %
            % Rückgabe:
            %   optimizedDiagram - Das optimierte Diagramm
            
            % Layers erstellen und Elemente zuweisen
            layers = obj.assignElementsToLayers();
            
            % Minimiere Kreuzungen zwischen den Schichten
            if obj.optimizeOptions.optimizeCrossings
                layers = obj.minimizeCrossings(layers);
            end
            
            % Positioniere Elemente basierend auf den optimierten Schichten
            obj.positionElements(layers);
            
            % Richte Gateways aus
            if obj.optimizeOptions.alignGateways
                obj.alignGateways();
            end
            
            % Zentriere Aktivitäten
            if obj.optimizeOptions.centerActivities
                obj.centerActivities();
            end
            
            % Vermeide Elementüberlappungen - neue Funktion
            if obj.optimizeOptions.avoidElementOverlap
                obj.resolveElementOverlaps();
            end
            
            % Optimiere Edge-Routing
            if obj.optimizeOptions.smartEdgeRouting
                obj.routeEdges();
            end
            
            % Optimiere Flusswege - neue Funktion
            if obj.optimizeOptions.optimizeFlowPaths
                obj.optimizeFlowPaths();
            end
            
            optimizedDiagram = obj.diagram;
        end
        
        function layers = assignElementsToLayers(obj)
            % Weist Elemente zu Schichten basierend auf der Prozessflussrichtung zu
            %
            % Rückgabe:
            %   layers - Cell-Array mit Elementgruppen pro Schicht
            
            % Implementierung eines einfachen Layering-Algorithmus
            elements = obj.diagram.elements;
            flows = obj.diagram.flows;
            
            % Finde Start-Events als Ausgangspunkt
            startElements = {};
            for i = 1:length(elements)
                if strcmpi(elements{i}.type, 'startEvent')
                    startElements{end+1} = elements{i}; %#ok<AGROW>
                end
            end
            
            % Wenn keine Start-Events gefunden, nehmen wir beliebige Elemente ohne eingehende Flows
            if isempty(startElements)
                nodesWithoutIncoming = obj.findNodesWithoutIncomingFlows();
                startElements = nodesWithoutIncoming;
            end
            
            % Initialisiere layers
            layers = {};
            currentLayer = 1;
            layers{currentLayer} = startElements;
            
            processedElements = {};
            
            % Iterative Zuweisung von Elementen zu Schichten
            while ~isempty(layers{currentLayer})
                nextLayer = {};
                
                for i = 1:length(layers{currentLayer})
                    currentElement = layers{currentLayer}{i};
                    processedElements{end+1} = currentElement.id; %#ok<AGROW>
                    
                    % Finde alle ausgehenden Flows und deren Ziele
                    for j = 1:length(flows)
                        if strcmp(flows{j}.sourceRef, currentElement.id)
                            targetId = flows{j}.targetRef;
                            
                            % Finde das Zielelement
                            targetElement = obj.findElementById(targetId);
                            
                            % Prüfe ob das Zielelement bereits verarbeitet wurde
                            if ~isempty(targetElement) && !ismember(targetId, processedElements)
                                % Prüfe ob alle Quellen bereits verarbeitet wurden
                                allSourcesProcessed = true;
                                
                                for k = 1:length(flows)
                                    if strcmp(flows{k}.targetRef, targetId) && ...
                                            ~strcmp(flows{k}.sourceRef, currentElement.id) && ...
                                            ~ismember(flows{k}.sourceRef, processedElements)
                                        allSourcesProcessed = false;
                                        break;
                                    end
                                end
                                
                                % Füge das Element nur hinzu, wenn alle Quellen verarbeitet wurden
                                if allSourcesProcessed && ~obj.isElementInAnyLayer(nextLayer, targetElement)
                                    nextLayer{end+1} = targetElement; %#ok<AGROW>
                                end
                            end
                        end
                    end
                end
                
                currentLayer = currentLayer + 1;
                if !isempty(nextLayer)
                    layers{currentLayer} = nextLayer;
                else
                    break;
                end
            end
        end
        
        function nodesWithoutIncoming = findNodesWithoutIncomingFlows(obj)
            % Findet Elemente ohne eingehende Flows
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
                
                if !hasIncoming
                    nodesWithoutIncoming{end+1} = elements{i}; %#ok<AGROW>
                end
            end
        end
        
        function element = findElementById(obj, id)
            % Findet ein Element durch seine ID
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
            % Prüft, ob ein Element bereits in einer Schicht enthalten ist
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
            % Minimiert Kreuzungen zwischen den Schichten
            %
            % Eingabe/Rückgabe:
            %   layers - Cell-Array mit Elementgruppen pro Schicht
            
            % Einfacher Algorithmus zur Kreuzungsminimierung
            % Für jede Schicht werden Elemente basierend auf Verbindungen umsortiert
            
            for i = 2:length(layers)
                if length(layers{i}) > 1
                    % Bestimme die optimale Reihenfolge basierend auf Verbindungen
                    % zur vorherigen Schicht
                    
                    % Ein einfacher Ansatz: Ordne die Elemente nach der Position ihrer
                    % Quellen in der vorherigen Schicht
                    
                    % Erstelle eine Liste von [Element, gewichtete Position]
                    elementPositions = cell(1, length(layers{i}));
                    flows = obj.diagram.flows;
                    
                    for j = 1:length(layers{i})
                        currentElement = layers{i}{j};
                        incomingPositionSum = 0;
                        incomingCount = 0;
                        
                        % Finde alle eingehenden Flüsse von der vorherigen Schicht
                        for k = 1:length(flows)
                            if strcmp(flows{k}.targetRef, currentElement.id)
                                % Finde die Position der Quelle in der vorherigen Schicht
                                sourceElement = obj.findElementById(flows{k}.sourceRef);
                                if !isempty(sourceElement)
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
                        
                        % Berechne den durchschnittlichen Positionswert
                        avgPosition = incomingCount > 0 ? incomingPositionSum / incomingCount : j;
                        elementPositions{j} = {currentElement, avgPosition};
                    end
                    
                    % Sortiere die Elemente nach ihrer durchschnittlichen Position
                    positionValues = cellfun(@(x) x{2}, elementPositions);
                    [~, sortIdx] = sort(positionValues);
                    
                    % Sortiere die Schicht neu
                    sortedLayer = cell(1, length(layers{i}));
                    for j = 1:length(sortIdx)
                        sortedLayer{j} = elementPositions{sortIdx(j)}{1};
                    end
                    
                    layers{i} = sortedLayer;
                end
            end
        end
        
        function positionElements(obj, layers)
            % Positioniert Elemente basierend auf den optimierten Schichten
            
            % Grundlegende Konfiguration
            layerHeight = obj.optimizeOptions.layerSpacing;
            elementWidth = 100;  % Standard Elementbreite
            elementHeight = 80;  % Standard Elementhöhe
            marginX = obj.optimizeOptions.minNodeDistance;
            startX = 50;
            startY = 50;
            
            % Positioniere jedes Element basierend auf seiner Schicht
            for i = 1:length(layers)
                currentY = startY + (i-1) * layerHeight;
                layerWidth = (length(layers{i}) - 1) * (elementWidth + marginX);
                currentX = startX;
                
                for j = 1:length(layers{i})
                    element = layers{i}{j};
                    
                    % Anpassen der Elementgröße je nach Typ
                    if strcmpi(element.type, 'task')
                        w = 100;
                        h = 80;
                    elseif strcmpi(element.type, 'gateway')
                        w = 50;
                        h = 50;
                    elseif any(strcmpi(element.type, {'startEvent', 'endEvent', 'intermediateEvent'}))
                        w = 40;
                        h = 40;
                    else
                        w = elementWidth;
                        h = elementHeight;
                    end
                    
                    % Element positionieren
                    element.x = currentX;
                    element.y = currentY;
                    element.width = w;
                    element.height = h;
                    
                    % Aktualisiere die X-Position für das nächste Element
                    currentX = currentX + w + marginX;
                end
            end
            
            % Nachbearbeitung: Zentriere Elemente in jeder Schicht
            for i = 1:length(layers)
                if !isempty(layers{i})
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
            % Richtet Gateways vertikal aus
            
            elements = obj.diagram.elements;
            
            % Gruppieren Sie Gateways nach Typ
            gateways = {};
            for i = 1:length(elements)
                if strcmpi(elements{i}.type, 'exclusiveGateway') || ...
                   strcmpi(elements{i}.type, 'parallelGateway') || ...
                   strcmpi(elements{i}.type, 'inclusiveGateway')
                    gateways{end+1} = elements{i}; %#ok<AGROW>
                end
            end
            
            % Finde ähnliche Gateway-Gruppen (z.B. Split/Join-Paare)
            if length(gateways) > 1
                for i = 1:length(gateways)-1
                    for j = i+1:length(gateways)
                        % Wenn Gateways auf unterschiedlichen Ebenen sind (unterschiedliche Y-Werte)
                        % aber vom gleichen Typ, versuchen Sie, sie vertikal auszurichten
                        if abs(gateways{i}.y - gateways{j}.y) > gateways{i}.height && ...
                           strcmpi(gateways{i}.type, gateways{j}.type)
                            
                            % Berechnen Sie die mittlere X-Position
                            avgX = (gateways{i}.x + gateways{j}.x) / 2;
                            
                            % Alinieren beide zu dieser Position
                            gateways{i}.x = avgX;
                            gateways{j}.x = avgX;
                        end
                    end
                end
            end
        end
        
        function centerActivities(obj)
            % Zentriert Aktivitäten innerhalb ihrer Verbindungen
            
            elements = obj.diagram.elements;
            flows = obj.diagram.flows;
            
            for i = 1:length(elements)
                if strcmpi(elements{i}.type, 'task')
                    % Finde alle ein- und ausgehenden Flows für diese Aktivität
                    incomingFlows = {};
                    outgoingFlows = {};
                    
                    for j = 1:length(flows)
                        if strcmp(flows{j}.targetRef, elements{i}.id)
                            incomingFlows{end+1} = flows{j}; %#ok<AGROW>
                        elseif strcmp(flows{j}.sourceRef, elements{i}.id)
                            outgoingFlows{end+1} = flows{j}; %#ok<AGROW>
                        end
                    end
                    
                    % Berechne durchschnittliche X-Position der verbundenen Elemente
                    sumX = 0;
                    count = 0;
                    
                    for j = 1:length(incomingFlows)
                        sourceElement = obj.findElementById(incomingFlows{j}.sourceRef);
                        if !isempty(sourceElement)
                            sumX = sumX + sourceElement.x + sourceElement.width/2;
                            count = count + 1;
                        end
                    end
                    
                    for j = 1:length(outgoingFlows)
                        targetElement = obj.findElementById(outgoingFlows{j}.targetRef);
                        if !isempty(targetElement)
                            sumX = sumX + targetElement.x + targetElement.width/2;
                            count = count + 1;
                        end
                    end
                    
                    % Wenn es verbundene Elemente gibt, zentriere die Aktivität
                    if count > 0
                        avgX = sumX / count;
                        elements{i}.x = avgX - elements{i}.width/2;
                    end
                end
            end
        end
        
        function routeEdges(obj)
            % Implementiert intelligentes Edge-Routing für Sequenzflüsse
            
            flows = obj.diagram.flows;
            
            for i = 1:length(flows)
                sourceElement = obj.findElementById(flows{i}.sourceRef);
                targetElement = obj.findElementById(flows{i}.targetRef);
                
                if !isempty(sourceElement) && !isempty(targetElement)
                    % Berechne Wegpunkte für den Flow
                    waypoints = obj.calculateWaypoints(sourceElement, targetElement);
                    flows{i}.waypoints = waypoints;
                end
            end
        end
        
        function waypoints = calculateWaypoints(obj, source, target)
            % Berechnet Wegpunkte für einen Flow zwischen zwei Elementen
            
            % Einfacher Algorithmus für gerade Linien mit zwei Punkten
            % Ausgangspunkt (vom Quell-Element)
            sourceX = source.x + source.width/2;
            sourceY = source.y + source.height/2;
            
            % Zielpunkt (zum Ziel-Element)
            targetX = target.x + target.width/2;
            targetY = target.y + target.height/2;
            
            % Für komplexere Routen könnten hier zusätzliche Wegpunkte eingefügt werden
            
            % Einfacher Fall: direkte Verbindung (für nähere Elemente)
            if abs(targetY - sourceY) < obj.optimizeOptions.layerSpacing * 1.5
                waypoints = [sourceX, sourceY; targetX, targetY];
                return;
            end
            
            % Komplexerer Fall: 3-Punkt-Verbindung (für weiter entfernte Elemente)
            % Mittelpunkt zur Vermeidung von Überschneidungen
            midY = (sourceY + targetY) / 2;
            waypoints = [sourceX, sourceY; sourceX, midY; targetX, midY; targetX, targetY];
        end
        
        function resolveElementOverlaps(obj)
            % Erkennt und löst überlappende Elemente im Diagramm
            
            elements = obj.diagram.elements;
            modified = true;
            
            % Iterationen fortsetzen, bis keine Überlappungen mehr gelöst werden
            iterationCount = 0;
            maxIterations = 10; % Begrenzung der Iterationen zur Vermeidung von Endlosschleifen
            
            while modified && iterationCount < maxIterations
                modified = false;
                iterationCount = iterationCount + 1;
                
                % Überprüfen Sie jedes Elementpaar auf Überlappung
                for i = 1:length(elements)
                    for j = i+1:length(elements)
                        % Berechne Begrenzungsrahmen
                        box1 = [elements{i}.x, elements{i}.y, ...
                               elements{i}.x + elements{i}.width, ...
                               elements{i}.y + elements{i}.height];
                           
                        box2 = [elements{j}.x, elements{j}.y, ...
                               elements{j}.x + elements{j}.width, ...
                               elements{j}.y + elements{j}.height];
                        
                        % Überprüfen Sie auf Überlappung
                        if obj.boxesOverlap(box1, box2)
                            % Berechne Überlappungsmenge
                            overlapX = min(box1(3), box2(3)) - max(box1(1), box2(1));
                            overlapY = min(box1(4), box2(4)) - max(box1(2), box2(2));
                            
                            % Bestimmen Sie die Schubrichtung basierend auf der kleinsten Überlappung
                            if overlapX < overlapY
                                % Horizontal schieben
                                if box1(1) < box2(1)
                                    elements{j}.x = elements{j}.x + overlapX + obj.optimizeOptions.minNodeDistance/4;
                                else
                                    elements{i}.x = elements{i}.x + overlapX + obj.optimizeOptions.minNodeDistance/4;
                                end
                            else
                                % Vertikal schieben, nur wenn Elemente nicht auf derselben Schicht sind
                                % um die Flussstruktur beizubehalten
                                if abs(elements{i}.y - elements{j}.y) > obj.optimizeOptions.minNodeDistance
                                    if box1(2) < box2(2)
                                        elements{j}.y = elements{j}.y + overlapY + obj.optimizeOptions.minNodeDistance/4;
                                    else
                                        elements{i}.y = elements{i}.y + overlapY + obj.optimizeOptions.minNodeDistance/4;
                                    end
                                else
                                    % Für Elemente auf derselben Schicht horizontal schieben
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
            
            % Nach dem Lösen von Überlappungen sicherstellen, dass Elemente den Mindestabstand einhalten
            for i = 1:length(elements)
                for j = i+1:length(elements)
                    % Überprüfen Sie nur Elemente in derselben ungefähren vertikalen Position (gleiche Schicht)
                    if abs(elements{i}.y - elements{j}.y) < obj.optimizeOptions.minNodeDistance
                        % Überprüfen Sie den horizontalen Abstand
                        if abs(elements{i}.x - elements{j}.x) < obj.optimizeOptions.minNodeDistance
                            % Positionen anpassen, um den Mindestabstand einzuhalten
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
            % Bestimmt, ob sich zwei Begrenzungsrahmen überlappen
            % Box-Format: [x1, y1, x2, y2] (obere linke und untere rechte Ecken)
            
            % Überprüfen Sie, ob eine Box vollständig links/rechts/oben/unten der anderen liegt
            if box1(3) < box2(1) || box2(3) < box1(1) || ...
               box1(4) < box2(2) || box2(4) < box1(2)
                overlap = false;
            else
                overlap = true;
            end
        end
        
        function optimizeFlowPaths(obj)
            % Optimiert Flusswege zur Verbesserung der Diagrammlesbarkeit
            
            flows = obj.diagram.flows;
            
            for i = 1:length(flows)
                sourceElement = obj.findElementById(flows{i}.sourceRef);
                targetElement = obj.findElementById(flows{i}.targetRef);
                
                if !isempty(sourceElement) && !isempty(targetElement)
                    % Berechne den optimalen Pfad zwischen den Elementen mit A* oder ähnlichem Algorithmus
                    flows{i}.waypoints = obj.calculateOptimalPath(sourceElement, targetElement);
                end
            end
            
            % Erkennen und Lösen von Flusskreuzungen, wo möglich
            obj.reduceFlowCrossings();
        end
        
        function waypoints = calculateOptimalPath(obj, source, target)
            % Berechnet einen optimalen Pfad zwischen zwei Elementen mit verbesserter Wegpunktberechnung
            
            % Ausgangsposition (Mitte des Quell-Elements)
            sourceX = source.x + source.width/2;
            sourceY = source.y + source.height/2;
            
            % Zielposition (Mitte des Ziel-Elements)
            targetX = target.x + target.width/2;
            targetY = target.y + target.height/2;
            
            % Überprüfen, ob Quelle und Ziel nahe beieinander liegen
            if abs(sourceY - targetY) < obj.optimizeOptions.layerSpacing/2 && ...
               abs(sourceX - targetX) < obj.optimizeOptions.minNodeDistance*3
                % Direkte Verbindung für eng positionierte Elemente
                waypoints = [sourceX, sourceY; targetX, targetY];
                return;
            end
            
            % Verbesserter Mehrpunktpfad für komplexe Routing-Szenarien
            
            % Berechnen, ob eine vertikale oder horizontale Beziehung besteht
            isVerticalFlow = abs(sourceY - targetY) > abs(sourceX - targetX);
            
            if isVerticalFlow
                % Primär vertikaler Flusspfad
                midY = (sourceY + targetY) / 2;
                
                % Überprüfen auf potenzielle Routing-Interferenzen mit anderen Elementen
                if obj.pathIntersectsElements(sourceX, sourceY, sourceX, midY) || ...
                   obj.pathIntersectsElements(sourceX, midY, targetX, midY) || ...
                   obj.pathIntersectsElements(targetX, midY, targetX, targetY)
                   
                    % Pfad anpassen zur Vermeidung von Interferenzen
                    alternativeMidX = (sourceX + targetX) / 2;
                    waypoints = [sourceX, sourceY; 
                                alternativeMidX, sourceY;
                                alternativeMidX, targetY; 
                                targetX, targetY];
                else
                    % Standard vertikaler Routing-Pfad
                    waypoints = [sourceX, sourceY; 
                                sourceX, midY; 
                                targetX, midY; 
                                targetX, targetY];
                end
            else
                % Primär horizontaler Flusspfad
                midX = (sourceX + targetX) / 2;
                
                % Überprüfen auf potenzielle Routing-Interferenzen
                if obj.pathIntersectsElements(sourceX, sourceY, midX, sourceY) || ...
                   obj.pathIntersectsElements(midX, sourceY, midX, targetY) || ...
                   obj.pathIntersectsElements(midX, targetY, targetX, targetY)
                   
                    % Pfad anpassen zur Vermeidung von Interferenzen
                    alternativeMidY = (sourceY + targetY) / 2;
                    waypoints = [sourceX, sourceY; 
                                sourceX, alternativeMidY;
                                targetX, alternativeMidY; 
                                targetX, targetY];
                else
                    % Standard horizontaler Routing-Pfad
                    waypoints = [sourceX, sourceY; 
                                midX, sourceY; 
                                midX, targetY; 
                                targetX, targetY];
                end
            end
        end
        
        function intersects = pathIntersectsElements(obj, x1, y1, x2, y2)
            % Überprüft, ob ein Pfadsegment mit einem Element kollidiert
            
            elements = obj.diagram.elements;
            intersects = false;
            
            % Pfadsegment als Linie
            linePath = [x1, y1, x2, y2];
            
            % Pufferabstand, um zu verhindern, dass zu nahe an Elementen geroutet wird
            buffer = 5;
            
            for i = 1:length(elements)
                element = elements{i};
                
                % Überspringen von Quell- und Zielelementen oder sehr kleinen Elementen
                if (abs(element.x + element.width/2 - x1) < 1e-6 && 
                    abs(element.y + element.height/2 - y1) < 1e-6) || ...
                   (abs(element.x + element.width/2 - x2) < 1e-6 && 
                    abs(element.y + element.height/2 - y2) < 1e-6)
                    continue;
                end
                
                % Begrenzungsrahmen des Elements mit Puffer
                bbox = [element.x - buffer, element.y - buffer, 
                        element.x + element.width + buffer, element.y + element.height + buffer];
                
                % Überprüfen, ob die Linie den Begrenzungsrahmen des Elements schneidet
                if obj.lineIntersectsBox(linePath, bbox)
                    intersects = true;
                    return;
                end
            end
        end
        
        function intersects = lineIntersectsBox(~, line, box)
            % Bestimmt, ob ein Liniensegment mit einer Box kollidiert
            % Linienformat: [x1, y1, x2, y2]
            % Box-Format: [x1, y1, x2, y2] (obere linke und untere rechte Ecken)
            
            % Liniensegmentparameter
            x1 = line(1); y1 = line(2);
            x2 = line(3); y2 = line(4);
            
            % Box-Grenzen
            left = box(1); top = box(2);
            right = box(3); bottom = box(4);
            
            % Cohen-Sutherland-Algorithmus zur Linien-Rechteck-Kollision
            INSIDE = 0; % 0000
            LEFT = 1;   % 0001
            RIGHT = 2;  % 0010
            BOTTOM = 4; % 0100
            TOP = 8;    % 1000
            
            % Berechnen der Outcodes
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
                % Beide Endpunkte sind innerhalb der Box - triviale Akzeptanz
                if outcode1 == 0 && outcode2 == 0
                    intersects = true;
                    return;
                end
                
                % Linie ist vollständig außerhalb der Box - triviale Ablehnung
                if bitand(outcode1, outcode2) != 0
                    intersects = false;
                    return;
                end
                
                % Ein Teil der Linie könnte innerhalb sein - Schnittpunkt berechnen
                x = 0; y = 0;
                outcodeOut = max(outcode1, outcode2);
                
                % Schnittpunkt finden
                if bitand(outcodeOut, TOP) != 0
                    x = x1 + (x2 - x1) * (top - y1) / (y2 - y1);
                    y = top;
                elseif bitand(outcodeOut, BOTTOM) != 0
                    x = x1 + (x2 - x1) * (bottom - y1) / (y2 - y1);
                    y = bottom;
                elseif bitand(outcodeOut, RIGHT) != 0
                    y = y1 + (y2 - y1) * (right - x1) / (x2 - x1);
                    x = right;
                elseif bitand(outcodeOut, LEFT) != 0
                    y = y1 + (y2 - y1) * (left - x1) / (x2 - x1);
                    x = left;
                end
                
                % Endpunkte aktualisieren
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
            % Versucht, Flusskreuzungen durch Anpassen der Wegpunkte zu reduzieren
            
            flows = obj.diagram.flows;
            
            % Flusskreuzungen identifizieren
            for i = 1:length(flows)-1
                for j = i+1:length(flows)
                    if isfield(flows{i}, 'waypoints') && isfield(flows{j}, 'waypoints')
                        % Überprüfen, ob diese Flüsse sich kreuzen
                        crossingPoints = obj.findFlowCrossings(flows{i}, flows{j});
                        
                        if !isempty(crossingPoints)
                            % Versuchen, die Kreuzung durch Anpassen der Wegpunkte zu lösen
                            [flows{i}, flows{j}] = obj.resolveCrossing(flows{i}, flows{j}, crossingPoints);
                        end
                    end
                end
            end
        end
        
        function crossingPoints = findFlowCrossings(~, flow1, flow2)
            % Identifiziert Kreuzungspunkte zwischen zwei Flüssen
            
            crossingPoints = [];
            
            if !isfield(flow1, 'waypoints') || !isfield(flow2, 'waypoints') || ...
               size(flow1.waypoints, 1) < 2 || size(flow2.waypoints, 1) < 2
                return;
            end
            
            % Überprüfen Sie jedes Segment von flow1 gegen jedes Segment von flow2
            for i = 1:size(flow1.waypoints, 1)-1
                seg1 = [flow1.waypoints(i,:), flow1.waypoints(i+1,:)];
                
                for j = 1:size(flow2.waypoints, 1)-1
                    seg2 = [flow2.waypoints(j,:), flow2.waypoints(j+1,:)];
                    
                    % Überprüfen, ob Segmente sich schneiden
                    [intersect, x, y] = obj.lineSegmentIntersection(seg1, seg2);
                    
                    if intersect
                        crossingPoints(end+1,:) = [x, y, i, j]; %#ok<AGROW>
                    end
                end
            end
        end
        
        function [intersect, x, y] = lineSegmentIntersection(~, seg1, seg2)
            % Bestimmt, ob sich zwei Liniensegmente schneiden
            
            x1 = seg1(1); y1 = seg1(2);
            x2 = seg1(3); y2 = seg1(4);
            
            x3 = seg2(1); y3 = seg2(2);
            x4 = seg2(3); y4 = seg2(4);
            
            % Berechnen des Nenners
            den = (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1);
            
            % Überprüfen, ob Linien parallel sind
            if abs(den) < 1e-10
                intersect = false;
                x = 0; y = 0;
                return;
            end
            
            % Berechnen der Zähler
            numa = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3));
            numb = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3));
            
            % Berechnen der Parameter
            ua = numa / den;
            ub = numb / den;
            
            % Wenn Parameter in [0,1] liegen, schneiden sich die Segmente
            if ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1
                % Berechnen des Schnittpunkts
                x = x1 + ua * (x2 - x1);
                y = y1 + ua * (y2 - y1);
                intersect = true;
            else
                intersect = false;
                x = 0; y = 0;
            end
        end
        
        function [flow1, flow2] = resolveCrossing(obj, flow1, flow2, crossingPoints)
            % Versucht, die Kreuzung zwischen zwei Flüssen durch Ändern der Wegpunkte zu lösen
            
            if isempty(crossingPoints)
                return;
            end
            
            % Erhalten Sie den Kreuzungspunkt und die Segmentindizes
            crossingX = crossingPoints(1,1);
            crossingY = crossingPoints(1,2);
            seg1Idx = crossingPoints(1,3);
            seg2Idx = crossingPoints(1,4);
            
            % Berechnen des Versatzabstands
            offset = obj.optimizeOptions.minNodeDistance / 2;
            
            % Bestimmen, welcher Fluss basierend auf ihren Typen und ihrer Wichtigkeit angepasst werden soll
            source1 = obj.findElementById(flow1.sourceRef);
            source2 = obj.findElementById(flow2.sourceRef);
            
            if isempty(source1) || isempty(source2)
                return;
            end
            
            % Priorisieren Sie die Anpassung normaler Sequenzflüsse gegenüber Nachrichtenflüssen oder Assoziationen
            isFlow1SequenceFlow = strcmp(flow1.type, 'sequenceFlow');
            isFlow2SequenceFlow = strcmp(flow2.type, 'sequenceFlow');
            
            if isFlow1SequenceFlow && !isFlow2SequenceFlow
                % Fluss2 anpassen
                flow2.waypoints = obj.insertWaypointOffset(flow2.waypoints, seg2Idx, offset);
            elseif !isFlow1SequenceFlow && isFlow2SequenceFlow
                % Fluss1 anpassen
                flow1.waypoints = obj.insertWaypointOffset(flow1.waypoints, seg1Idx, offset);
            else
                % Beide sind vom gleichen Typ, den kürzeren anpassen
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
            % Fügt einen Versatz in einen Flusspfad ein, um eine Kreuzung zu vermeiden
            
            if segmentIdx < 1 || segmentIdx >= size(waypoints, 1)
                return;
            end
            
            % Ursprüngliche Segmentpunkte
            p1 = waypoints(segmentIdx, :);
            p2 = waypoints(segmentIdx+1, :);
            
            % Berechnen der Segmentrichtung
            dx = p2(1) - p1(1);
            dy = p2(2) - p1(2);
            
            % Wenn das Segment mehr horizontal ist, vertikalen Versatz erstellen
            if abs(dx) >= abs(dy)
                midX = (p1(1) + p2(1)) / 2;
                newPoints = [midX, p1(2)+offset; midX, p1(2)-offset];
            else
                % Wenn das Segment mehr vertikal ist, horizontalen Versatz erstellen
                midY = (p1(2) + p2(2)) / 2;
                newPoints = [p1(1)+offset, midY; p1(1)-offset, midY];
            end
            
            % Neue Punkte einfügen
            waypoints = [waypoints(1:segmentIdx,:); newPoints; waypoints(segmentIdx+1:end,:)];
        end
    end
end