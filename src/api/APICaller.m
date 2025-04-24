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
            request_data.max_tokens = 10000;
            
            % Send HTTP request via MATLAB webwrite instead of curl
            if options.debug
                fprintf('Sending HTTP request via webwrite to https://openrouter.ai/api/v1/chat/completions\n');
            end
            try
                opts_http = weboptions('MediaType','application/json', ...
                                       'HeaderFields',{'Authorization', ['Bearer ' api_key]}, ...
                                       'Timeout',60);
                raw = webwrite('https://openrouter.ai/api/v1/chat/completions', request_data, opts_http);
            catch ME
                error('APICaller:WebError', 'Fehler beim Senden der Anfrage: %s', ME.message);
            end
            % For backward compatibility: extract content field
            if isstruct(raw) && isfield(raw, 'choices') && !isempty(raw.choices)
                if isfield(raw.choices(1), 'message') && isfield(raw.choices(1).message, 'content')
                    raw.choices(1).text = raw.choices(1).message.content;
                end
            end
            if options.debug
                fprintf('API response received and parsed via webwrite.\n');
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