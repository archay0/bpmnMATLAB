% Test-Script für OpenRouter API mit microsoft/mai-ds-r1:free Modell
% Dieses Skript testet, ob die Integration mit OpenRouter funktioniert

% Aktuellen Pfad erkennen und absolute Pfade verwenden
currentFolder = pwd;
projectRoot = currentFolder;
if ~contains(projectRoot, 'bpmnMATLAB')
    % Versuchen, ins Hauptverzeichnis zu wechseln, falls wir in Unterordner sind
    cd('..');
    projectRoot = pwd;
end

% Pfade korrekt hinzufügen mit absoluten Pfaden
addpath(fullfile(projectRoot, 'src'));
addpath(fullfile(projectRoot, 'src', 'api'));
addpath(fullfile(projectRoot, 'src', 'util'));

% Pfade ausgeben zur Fehlersuche
disp('Pfade im MATLAB-Suchpfad:');
disp(path);

% Prüfen, ob die APICaller-Klasse gefunden wird
apiCallerPath = which('APICaller');
if isempty(apiCallerPath)
    error('APICaller-Klasse konnte nicht gefunden werden. Überprüfen Sie die Pfade.');
else
    disp(['APICaller gefunden in: ' apiCallerPath]);
end

% Debug-Modus aktivieren
debug_options = struct('debug', true);

try
    % Testen eines einfachen API-Aufrufs
    disp('Starte Test der OpenRouter API mit microsoft/mai-ds-r1:free Modell...');
    disp('Sende einen einfachen Prompt...');
    
    % Anfrage-Optionen
    options = struct();
    options.debug = true;
    options.model = 'microsoft/mai-ds-r1:free';
    options.temperature = 0.7;
    options.system_message = 'Du bist ein Experte für BPMN (Business Process Model and Notation).';
    
    % Senden eines einfachen Test-Prompts
    prompt = 'Was sind die wichtigsten Elemente in einem BPMN-Diagramm? Gib eine kurze Antwort.';
    
    % Direkter Aufruf mit voller Klasse und Methode
    response = APICaller.sendPrompt(prompt, options);
    
    % Anzeigen der Antwort
    disp('API-Antwort erhalten:');
    if isfield(response, 'choices') && ~isempty(response.choices)
        if isfield(response.choices(1), 'message') && isfield(response.choices(1).message, 'content')
            disp(response.choices(1).message.content);
        else
            disp('Fehler: Antwortformat nicht wie erwartet');
            disp(jsonencode(response));
        end
    else
        disp('Fehler: Unerwartetes Antwortformat');
        disp(jsonencode(response));
    end
    
    disp('OpenRouter API-Test abgeschlossen!');
    
catch ME
    disp('Fehler beim Testen der OpenRouter API:');
    disp(ME.message);
    if isfield(ME, 'stack')
        for i = 1:length(ME.stack)
            disp(['Datei: ' ME.stack(i).file ' | Zeile: ' num2str(ME.stack(i).line) ' | Funktion: ' ME.stack(i).name]);
        end
    end
end