%% TestProductDataGeneration.m
% Test für die iterative Generierung von BPMN-Daten für ein spezifisches Produkt
% Dieses Skript verwendet den GeneratorController, um einen kompletten BPMN-Prozess
% für ein bestimmtes Produkt zu generieren, mit allen Modulen und Teilen

% Bereinigen der Umgebung
clear all;
close all;
clc;

% Pfade hinzufügen
addpath(fullfile(pwd, '..', 'src'));
addpath(fullfile(pwd, '..', 'src', 'api'));
addpath(fullfile(pwd, '..', 'src', 'util'));

% Produktname für die Generierung
productName = 'Industrieller Lidar-Sensor mit integrierter Kamera';

try
    % API-Umgebung initialisieren
    fprintf('Initialisiere API-Umgebung...\n');
    initAPIEnvironment();
    
    % Konfiguration für die vollständige Datengeneration
    opts = struct();
    opts.mode = 'iterative';
    % Vollständige Generierungsreihenfolge für ein komplexes Produkt
    opts.order = {'process_definitions', 'modules', 'parts', 'subparts'};
    opts.batchSize = 4;  % Mehr Elemente für ein realistisches Ergebnis
    opts.outputFile = 'product_bpmn_output.xml';
    opts.productDescription = productName;
    opts.debug = true;  % Ausführliches Logging aktivieren
    
    % OpenRouter-Modell verwenden
    opts.model = 'microsoft/mai-ds-r1:free';
    
    fprintf('Starte Datengenerierung für Produkt: %s\n', productName);
    fprintf('Verwende Modell: %s\n', opts.model);
    
    % Generiere die Daten mit dem GeneratorController
    fprintf('Beginne iterative Datengenerierung...\n');
    tic;  % Zeitmessung starten
    GeneratorController.generateIterative(opts);
    elapsed = toc;  % Zeitmessung beenden
    
    fprintf('\n✅ Datengenerierung erfolgreich abgeschlossen! (%.2f Sekunden)\n', elapsed);
    fprintf('Temporäre Datei mit generierten Daten: doc/temporary/temp_generated_data.json\n');
    fprintf('BPMN-Ausgabedatei: doc/temporary/%s\n', opts.outputFile);
    
    % Zusätzliche Informationen für Analyse
    fprintf('\nDie generierte BPMN-Datei enthält:\n');
    fprintf('- Prozessdefinition für das Produkt\n');
    fprintf('- Module und deren Abhängigkeiten\n');
    fprintf('- Teile und Unterteile für jedes Modul\n');
    fprintf('- Alle Sequenzflüsse zwischen den Elementen\n');
    fprintf('- Ressourcenzuweisungen für die Prozessschritte\n');
    
catch ME
    fprintf('\n❌ [FEHLER] Generierung fehlgeschlagen: %s\n', ME.message);
    
    % Ausführlichen Stack-Trace ausgeben
    if ~isempty(ME.stack)
        fprintf('\nStack-Trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  In %s (Zeile %d): %s\n', ...
                ME.stack(i).name, ME.stack(i).line, ME.stack(i).file);
        end
    end
end