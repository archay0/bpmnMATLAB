%% TestAPIDependencies.m
% Test-Script zur Überprüfung, ob alle API-Abhängigkeiten korrekt eingerichtet sind
% Dieses Skript prüft, ob alle für die Datengenerierung erforderlichen Klassen verfügbar sind

% Bereinigen der Umgebung
clear all;
close all;
clc;

% Pfade explizit hinzufügen
fprintf('Füge erforderliche Pfade hinzu...\n');
currentDir = pwd;
if endsWith(currentDir, 'tests')
    % Wenn wir uns bereits im tests-Verzeichnis befinden
    addpath(fullfile(pwd, '..', 'src'));
    addpath(fullfile(pwd, '..', 'src', 'api'));
    addpath(fullfile(pwd, '..', 'src', 'util'));
    rootDir = fullfile(pwd, '..');
else
    % Wenn wir uns im Hauptverzeichnis befinden
    addpath(fullfile(pwd, 'src'));
    addpath(fullfile(pwd, 'src', 'api'));
    addpath(fullfile(pwd, 'src', 'util'));
    rootDir = pwd;
end

fprintf('Suche nach erforderlichen Komponenten...\n');
fprintf('----------------------------------------\n');

% Initialisierung der API-Umgebung testen
fprintf('API-Umgebung initialisieren: ');
if exist('initAPIEnvironment', 'file') == 2
    fprintf('✅ Gefunden\n');
    try
        initAPIEnvironment();
        fprintf('✅ Erfolgreich initialisiert\n');
    catch ME
        fprintf('❌ Fehler bei der Initialisierung: %s\n', ME.message);
    end
else
    fprintf('❌ Nicht gefunden\n');
end

% Überprüfen, ob alle erforderlichen Klassen verfügbar sind
requiredClasses = {
    'APIConfig', 
    'APICaller', 
    'DataGenerator', 
    'GeneratorController', 
    'PromptBuilder', 
    'SchemaLoader', 
    'ValidationLayer', 
    'BPMNDatabaseConnector', 
    'BPMNDiagramExporter'
};

fprintf('\nÜberprüfung der erforderlichen Klassen:\n');
allFound = true;
for i = 1:length(requiredClasses)
    className = requiredClasses{i};
    fprintf('- Klasse %s: ', className);
    if exist(className, 'class') == 8
        fprintf('✅ Gefunden\n');
    else
        fprintf('❌ Nicht gefunden\n');
        allFound = false;
        
        % Suche nach der zugehörigen Datei, um zu sehen, ob sie existiert
        fprintf('  Suche nach %s.m-Datei: ', className);
        classPaths = {
            fullfile(rootDir, 'src', [className '.m']),
            fullfile(rootDir, 'src', 'api', [className '.m']),
            fullfile(rootDir, 'src', 'util', [className '.m'])
        };
        
        fileFound = false;
        for j = 1:length(classPaths)
            if exist(classPaths{j}, 'file') == 2
                fprintf('✅ Datei gefunden unter: %s\n', classPaths{j});
                fileFound = true;
                break;
            end
        end
        
        if ~fileFound
            fprintf('❌ Datei nicht gefunden\n');
        end
    end
end

% API-Konfiguration testen
fprintf('\nAPIConfig-Einstellungen testen: ');
if exist('APIConfig', 'class') == 8
    try
        apiOpts = APIConfig.getDefaultOptions();
        fprintf('✅ Erfolgreich\n');
        fprintf('- Standard-Modell: %s\n', apiOpts.model);
        fprintf('- Standard-Temperatur: %.2f\n', apiOpts.temperature);
    catch ME
        fprintf('❌ Fehler: %s\n', ME.message);
    end
else
    fprintf('❌ APIConfig-Klasse nicht verfügbar\n');
end

% Testen, ob GeneratorController.generateIterative aufgerufen werden kann
fprintf('\nGeneratorController-Zugriff testen: ');
if exist('GeneratorController', 'class') == 8
    try
        % Ein leeres Optionen-Objekt erstellen (nicht tatsächlich ausführen)
        testOpts = struct('mode', 'iterative', 'order', {{'test'}}, 'batchSize', 1);
        methodInfo = methods('GeneratorController');
        if any(strcmp(methodInfo, 'generateIterative'))
            fprintf('✅ Methode generateIterative gefunden\n');
        else
            fprintf('❌ Methode generateIterative nicht gefunden\n');
            fprintf('Verfügbare Methoden: %s\n', strjoin(methodInfo, ', '));
        end
    catch ME
        fprintf('❌ Fehler: %s\n', ME.message);
    end
else
    fprintf('❌ GeneratorController-Klasse nicht verfügbar\n');
end

fprintf('\n----------------------------------------\n');
if allFound
    fprintf('Alle erforderlichen Komponenten wurden gefunden.\n');
    fprintf('Führen Sie "generate_bpmn_data(\'Ihr Produkt\', 4, \'output.xml\', struct(\'debug\', true));" aus, um die Datengenerierung zu testen.\n');
else
    fprintf('⚠️ Einige Komponenten wurden nicht gefunden. Bitte beheben Sie die Probleme, bevor Sie die Datengenerierung ausführen.\n');
end