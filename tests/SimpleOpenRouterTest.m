%% SimpleOpenRouterTest.m
% Ein einfacher Test für den OpenRouter API-Zugriff

% Bereinigen der Umgebung
clear all;
close all;
clc;

fprintf('=== OpenRouter API Test mit microsoft/mai-ds-r1:free ===\n\n');

% Projektpfad bestimmen
currentScript = mfilename('fullpath');
[testDir, ~, ~] = fileparts(currentScript);
projectRoot = fileparts(testDir);

% Füge Basispfade hinzu
addpath(fullfile(projectRoot, 'src'));
addpath(fullfile(projectRoot, 'src', 'api'));
addpath(fullfile(projectRoot, 'src', 'util'));

try
    % API-Umgebung initialisieren
    fprintf('1. Initialisiere API-Umgebung...\n');
    % Prüfen, ob initAPIEnvironment gefunden wird
    if exist('initAPIEnvironment', 'file')
        initAPIEnvironment();
    else
        fprintf('  initAPIEnvironment nicht gefunden, stelle manuelle Initialisierung sicher...\n');
        % Prüfen, ob APICaller.m vorhanden ist
        apiCallerPath = which('APICaller.m');
        if isempty(apiCallerPath)
            error('APICaller.m nicht im MATLAB-Pfad gefunden');
        else
            fprintf('  APICaller.m gefunden: %s\n', apiCallerPath);
        end
        
        % Umgebungsvariablen laden
        fprintf('  Lade Umgebungsvariablen...\n');
        env = loadEnvironment(fullfile(projectRoot, '.env'));
        if isfield(env, 'OPENROUTER_API_KEY')
            setenv('OPENROUTER_API_KEY', env.OPENROUTER_API_KEY);
            fprintf('  OPENROUTER_API_KEY gesetzt\n');
        else
            error('OPENROUTER_API_KEY nicht in .env gefunden');
        end
    end
    
    fprintf('\n2. Konfiguriere API-Aufruf...\n');
    % Einfache Testoptionen
    opt = struct();
    opt.debug = true;
    opt.model = 'microsoft/mai-ds-r1:free';
    opt.temperature = 0.7;
    opt.system_message = 'Du bist ein BPMN-Experte.';
    
    % Testnachricht
    prompt = 'Was ist BPMN? Kurze Antwort bitte.';
    fprintf('  Prompt: "%s"\n', prompt);
    fprintf('  Modell: %s\n', opt.model);
    
    fprintf('\n3. Führe API-Aufruf durch...\n');
    % Aufruf der sendPrompt-Methode
    response = APICaller.sendPrompt(prompt, opt);
    
    % Erfolg
    fprintf('\n4. API-Aufruf erfolgreich!\n');
    fprintf('  Antwort:\n%s\n', response.choices(1).message.content);
    
catch ME
    % Fehlerdetails ausgeben
    fprintf('\n!!! FEHLER !!!\n%s\n', ME.message);
    
    % Stack-Trace für bessere Diagnose
    if ~isempty(ME.stack)
        fprintf('\nStack-Trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  In %s (Zeile %d): %s\n', ...
                ME.stack(i).name, ME.stack(i).line, ME.stack(i).file);
        end
    end
    
    % Ausgabe des MATLAB-Pfads zur Fehlersuche
    fprintf('\nMATLAB-Pfad:\n%s\n', path);
end