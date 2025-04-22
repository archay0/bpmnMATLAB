classdef APICaller
    % APICaller wraps HTTP communications with the GitHub Models API
    % Updated to work with GitHub Models API format (OpenAI compatible)
    
    methods(Static)
        function raw = sendPrompt(prompt, options)
            % sendPrompt - Sendet eine Anfrage an die GitHub Models API
            %
            % Input:
            %   prompt - Der zu sendende Text-Prompt
            %   options - (Optional) Struktur mit zusätzlichen Optionen:
            %       .debug - Boolean, aktiviert ausführliche Protokollierung (Standard: false)
            %       .model - String, zu verwendendes Modell (Standard: 'openai/gpt-4.1-mini')
            %       .timeout - Numerisch, Timeout in Sekunden (Standard: 60)
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
                options.model = 'openai/gpt-4.1-mini'; % Standardmodell (für allgemeine Anfragen)
            end
            
            if ~isfield(options, 'timeout')
                options.timeout = 60;
            end
            
            if ~isfield(options, 'temperature')
                options.temperature = 0.7;
            end
            
            if ~isfield(options, 'system_message')
                options.system_message = 'You are a helpful assistant specialized in BPMN.';
            end
            
            % API-Token abrufen (KORRIGIERTER NAME: GITHUB_TOKEN)
            token = getenv('GITHUB_TOKEN');
            
            % Fallback auf alten Namen für Abwärtskompatibilität
            if isempty(token)
                token = getenv('GITHUB_API_TOKEN');
                if ~isempty(token) && options.debug
                    fprintf('Warnung: GITHUB_API_TOKEN wird verwendet. Bitte auf GITHUB_TOKEN umstellen.\n');
                end
            end
            
            if isempty(token)
                error('APICaller:AuthError', 'Environment variable GITHUB_TOKEN is not set. Use setEnvironmentVariables() to set it.');
            end
            
            if options.debug
                fprintf('API-Token gefunden (Länge: %d Zeichen).\n', length(token));
                fprintf('Verwende Modell: %s\n', options.model);
            end
            
            % HTTP-Header und Optionen vorbereiten
            headers = { ...
                'Authorization', ['Bearer ' token];
                'Content-Type', 'application/json' ...
            };
            
            webOpts = weboptions( ...
                'HeaderFields', headers, ...
                'MediaType', 'application/json', ...
                'Timeout', options.timeout, ...
                'ContentType', 'json' ...
            );
            
            % Chat-Messages Format erstellen (OpenAI-kompatibel)
            messages = [
                struct('role', 'system', 'content', options.system_message),
                struct('role', 'user', 'content', prompt)
            ];
            
            % Anfrage-Body erstellen (Chat Completion Format)
            requestBody = struct();
            requestBody.messages = messages;
            requestBody.model = options.model;
            requestBody.temperature = options.temperature;
            requestBody.top_p = 1.0;
            requestBody.max_tokens = 1000; % Maximale Token-Anzahl für die Antwort
            
            % JSON-Body generieren
            jsonBody = jsonencode(requestBody);
            
            if options.debug
                fprintf('Anfrage-Body: %s\n', jsonBody);
            end
            
            % Endpunkt für GitHub Models API
            endpoint = 'https://models.github.ai/inference';
            
            % Anfrage senden
            if options.debug
                tic;
                fprintf('Sende Anfrage an %s...\n', endpoint);
            end
            
            try
                raw = webwrite(endpoint, jsonBody, webOpts);
                
                if options.debug
                    elapsed = toc;
                    fprintf('✓ Anfrage erfolgreich! Antwort in %.2f Sekunden erhalten.\n', elapsed);
                    
                    if isstruct(raw)
                        fprintf('Antwort-Struktur hat Felder: %s\n', strjoin(fieldnames(raw), ', '));
                    else
                        fprintf('Antworttyp: %s\n', class(raw));
                    end
                end
                
                % Extrahiere die Textnachricht aus der Antwort und wandle sie in ein Format um,
                % das mit der vorherigen Implementierung kompatibel ist
                if isfield(raw, 'choices') && ~isempty(raw.choices)
                    % Extrahiere den Text aus dem message.content der ersten Choice
                    messageContent = '';
                    if isfield(raw.choices(1), 'message') && isfield(raw.choices(1).message, 'content')
                        messageContent = raw.choices(1).message.content;
                    end
                    
                    % Für Abwärtskompatibilität: Füge text-Feld hinzu
                    raw.choices(1).text = messageContent;
                end
                
            catch ME
                errorMsg = sprintf('API-Anfrage fehlgeschlagen: %s\n', ME.message);
                
                if contains(ME.identifier, 'HTTP404')
                    errorMsg = [errorMsg 'Der Endpunkt wurde nicht gefunden. Überprüfen Sie die URL: ' endpoint '\n'];
                elseif contains(ME.identifier, 'HTTP401') || contains(ME.identifier, 'HTTP403')
                    errorMsg = [errorMsg 'Authentifizierungsfehler. Stellen Sie sicher, dass Ihr Token über "models:read" Berechtigungen verfügt.\n'];
                end
                
                error('APICaller:RequestFailed', errorMsg);
            end
        end
    end
end