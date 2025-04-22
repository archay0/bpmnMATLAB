classdef APICaller
    % APICaller wraps communications with the OpenRouter API
    
    methods(Static)
        function raw = sendPrompt(prompt, options)
            % sendPrompt - Sendet eine Anfrage an die OpenRouter API
            %
            % Input:
            %   prompt - Der zu sendende Text-Prompt
            %   options - (Optional) Struktur mit zusätzlichen Optionen:
            %       .debug - Boolean, aktiviert ausführliche Protokollierung (Standard: false)
            %       .model - String, zu verwendendes Modell (Standard: 'microsoft/mai-ds-r1:free')
            %       .temperature - Numerisch, Kreativität (0-1, Standard: 0.7)
            %       .system_message - String, Systemanweisung (Standard: 'You are a helpful assistant specialized in BPMN.')
            %
            % Output:
            %   raw - Die verarbeitete API-Antwort
            
            % Standardoptionen setzen
            if nargin < 2
                options = struct();
            end
            
            if ~isfield(options, 'debug')
                options.debug = false;
            end
            
            if ~isfield(options, 'model')
                options.model = 'microsoft/mai-ds-r1:free'; % Standardmodell (OpenRouter)
            end
            
            if ~isfield(options, 'temperature')
                options.temperature = 0.7;
            end
            
            if ~isfield(options, 'system_message')
                options.system_message = 'You are a helpful assistant specialized in BPMN.';
            end
            
            % Laden des API-Schlüssels aus der Umgebung
            api_key = getenv('OPENROUTER_API_KEY');
            if isempty(api_key)
                % Versuchen, die API-Schlüssel aus der .env-Datei zu laden
                utilPath = fileparts(fileparts(mfilename('fullpath')));
                utilFolder = fullfile(utilPath, 'util');
                
                % Stellen Sie sicher, dass der util-Ordner im Pfad ist
                if ~any(contains(path, utilFolder))
                    addpath(utilFolder);
                end
                
                try
                    env = loadEnvironment();
                    if isfield(env, 'OPENROUTER_API_KEY')
                        api_key = env.OPENROUTER_API_KEY;
                    else
                        error('APICaller:NoAPIKey', 'OpenRouter API-Schlüssel nicht gefunden. Bitte setzen Sie die OPENROUTER_API_KEY Umgebungsvariable.');
                    end
                catch ME
                    error('APICaller:EnvError', 'Fehler beim Laden der Umgebungsvariablen: %s', ME.message);
                end
            end
            
            % Temporäre Dateien für Ein- und Ausgabe
            temp_dir = tempdir;
            input_file = fullfile(temp_dir, 'openrouter_input.json');
            output_file = fullfile(temp_dir, 'openrouter_output.json');
            
            % Erstelle JSON-Anfrage für OpenRouter API
            request_data = struct();
            request_data.messages = [
                struct('role', 'system', 'content', options.system_message),
                struct('role', 'user', 'content', prompt)
            ];
            request_data.model = options.model;
            request_data.temperature = options.temperature;
            request_data.max_tokens = 1000;
            
            % Schreibe JSON in temporäre Datei
            input_fid = fopen(input_file, 'w');
            if input_fid == -1
                error('APICaller:FileError', 'Fehler beim Erstellen der temporären Eingabedatei');
            end
            fprintf(input_fid, '%s', jsonencode(request_data));
            fclose(input_fid);
            
            % Erstelle und führe den curl-Befehl aus
            curl_cmd = sprintf('curl -s -X POST https://openrouter.ai/api/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer %s" -H "HTTP-Referer: http://localhost:3000" -H "X-Title: BPMN MATLAB Generator" -d @"%s" > "%s"', ...
                api_key, input_file, output_file);
            
            if options.debug
                fprintf('Führe curl-Befehl aus:\n%s\n', curl_cmd);
                tic;
            end
            
            % Befehl ausführen
            [status, cmdout] = system(curl_cmd);
            
            if options.debug
                elapsed = toc;
                fprintf('curl-Aufruf abgeschlossen in %.2f Sekunden mit Status: %d\n', elapsed, status);
                
                if ~isempty(cmdout)
                    fprintf('curl-Ausgabe: %s\n', cmdout);
                end
            end
            
            % Fehlerbehandlung
            if status ~= 0
                error('APICaller:CurlError', 'curl-Fehler: %s', cmdout);
            end
            
            % Lese Ausgabe
            try
                output_fid = fopen(output_file, 'r');
                if output_fid == -1
                    error('APICaller:FileError', 'Fehler beim Öffnen der temporären Ausgabedatei');
                end
                response_text = fread(output_fid, '*char')';
                fclose(output_fid);
                
                % Parse JSON response
                raw = jsondecode(response_text);
                
                % Für Abwärtskompatibilität
                if isfield(raw, 'choices') && ~isempty(raw.choices)
                    if isfield(raw.choices(1), 'message') && isfield(raw.choices(1).message, 'content')
                        % Extrahiere den Text für die Abwärtskompatibilität
                        raw.choices(1).text = raw.choices(1).message.content;
                    end
                end
                
                if options.debug
                    fprintf('API-Antwort empfangen und erfolgreich geparst.\n');
                end
                
            catch ME
                error('APICaller:ResponseError', 'Fehler beim Verarbeiten der API-Antwort: %s', ME.message);
            end
            
            % Aufräumen
            try
                delete(input_file);
                delete(output_file);
            catch
                warning('APICaller:Cleanup', 'Temporäre Dateien konnten nicht gelöscht werden');
            end
        end
    end
end