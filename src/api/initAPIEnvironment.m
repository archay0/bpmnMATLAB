function initAPIEnvironment()
% INITAPIENVIRONMENT Initialisiert die Umgebung für API-Aufrufe
%
% Diese Hilfsfunktion stellt sicher, dass alle notwendigen Pfade gesetzt sind
% und Umgebungsvariablen für API-Aufrufe korrekt geladen wurden.
%
% Verwendung:
%   initAPIEnvironment();
%

    fprintf('Initialisiere API-Umgebung...\n');
    
    % Projektpfade ermitteln
    currentFile = mfilename('fullpath');
    [apiPath, ~, ~] = fileparts(currentFile);
    srcPath = fileparts(apiPath);
    projectRoot = fileparts(srcPath);
    
    % Wichtige Pfade hinzufügen
    if ~any(contains(path, apiPath))
        fprintf('Füge API-Pfad hinzu: %s\n', apiPath);
        addpath(apiPath);
    end
    
    if ~any(contains(path, fullfile(srcPath, 'util')))
        fprintf('Füge Util-Pfad hinzu: %s\n', fullfile(srcPath, 'util'));
        addpath(fullfile(srcPath, 'util'));
    end
    
    % Umgebungsvariablen laden
    try
        % Prüfen, ob .env bereits geladen wurde
        if isempty(getenv('OPENROUTER_API_KEY'))
            fprintf('Lade Umgebungsvariablen aus .env-Datei...\n');
            env = loadEnvironment(fullfile(projectRoot, '.env'));
            
            % Umgebungsvariablen setzen, falls gefunden
            if isfield(env, 'OPENROUTER_API_KEY')
                setenv('OPENROUTER_API_KEY', env.OPENROUTER_API_KEY);
                fprintf('OPENROUTER_API_KEY erfolgreich gesetzt.\n');
            end
        else
            fprintf('OPENROUTER_API_KEY ist bereits gesetzt.\n');
        end
    catch ME
        warning('Fehler beim Laden der Umgebungsvariablen: %s', ME.message);
    end
    
    % Prüfen, ob APICaller verfügbar ist
    apiCallerPath = which('APICaller');
    if isempty(apiCallerPath)
        error('APICaller nicht gefunden. Überprüfen Sie die Installation.');
    else
        fprintf('APICaller gefunden in: %s\n', apiCallerPath);
    end
    
    fprintf('API-Umgebung erfolgreich initialisiert.\n');
end