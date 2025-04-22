% Test-Script für OpenRouter API mit microsoft/mai-ds-r1:free Modell
% Dieses Skript testet, ob die Integration mit OpenRouter funktioniert

% Sicherstellen, dass der Pfad korrekt gesetzt ist
addpath(fullfile(pwd, 'src'));
addpath(fullfile(pwd, 'src', 'api'));
addpath(fullfile(pwd, 'src', 'util'));

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
        disp(ME.stack(1));
    end
end