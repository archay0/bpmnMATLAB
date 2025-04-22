%% TestBPMNGeneration.m
% Ein Testskript für die Generierung von BPMN-Daten mit der OpenRouter API
% Dieses Skript verwendet die neue API-Integration mit dem microsoft/mai-ds-r1:free-Modell
% und generiert eine temporäre Datei mit BPMN-Daten

% Bereinigen der Umgebung
clear all;
close all;
clc;

% Pfade hinzufügen
addpath(fullfile(pwd, '..', 'src'));
addpath(fullfile(pwd, '..', 'src', 'api'));
addpath(fullfile(pwd, '..', 'src', 'util'));

try
    % API-Umgebung initialisieren
    fprintf('Initialisiere API-Umgebung...\n');
    initAPIEnvironment();
    
    % Konfiguration für die Datengeneration
    opts = struct();
    opts.mode = 'iterative';
    opts.order = {'process_definitions'};  % Nur Prozessdefinitionen für einen schnellen Test
    opts.batchSize = 2;  % Eine kleine Anzahl für den Test
    opts.outputFile = 'test_bpmn_output.xml';
    opts.productDescription = 'Ein einfaches Bestellsystem für eine Online-Buchhandlung';
    opts.debug = true;  % Ausführliches Logging aktivieren
    
    % Explizite Festlegung des OpenRouter-Modells
    opts.model = 'microsoft/mai-ds-r1:free';
    
    fprintf('Starte Testgenerierung mit folgendem Modell: %s\n', opts.model);
    
    % Generiere die Daten mit dem GeneratorController
    GeneratorController.generateIterative(opts);
    
    fprintf('\nDaten wurden erfolgreich generiert!\n');
    fprintf('Temporäre Datei sollte unter doc/temporary/temp_generated_data.json zu finden sein\n');
    fprintf('BPMN-Ausgabedatei sollte unter doc/temporary/%s zu finden sein\n', opts.outputFile);
    
catch ME
    fprintf('\n[FEHLER] Generierung fehlgeschlagen: %s\n', ME.message);
    
    % Ausführlichen Stack-Trace ausgeben
    if ~isempty(ME.stack)
        fprintf('\nStack-Trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  In %s (Zeile %d): %s\n', ...
                ME.stack(i).name, ME.stack(i).line, ME.stack(i).file);
        end
    end
end