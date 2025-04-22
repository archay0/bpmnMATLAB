classdef APICaller
    % APICaller wraps communications with the GitHub Models API using GitHub CLI
    
    methods(Static)
        function raw = sendPrompt(prompt, options)
            % sendPrompt - Sendet eine Anfrage an die GitHub Models API via GitHub CLI
            %
            % Input:
            %   prompt - Der zu sendende Text-Prompt
            %   options - (Optional) Struktur mit zusätzlichen Optionen:
            %       .debug - Boolean, aktiviert ausführliche Protokollierung (Standard: false)
            %       .model - String, zu verwendendes Modell (Standard: 'openai/gpt-4.1-mini')
            %       .temperature - Numerisch, Kreativität (0-1, Standard: 0.7)
            %       .system_message - String, Systemanweisung (Standard: 'You are a helpful assistant specialized in BPMN.')
            %
            % Output:
            %   raw - Die verarbeitete API-Antwort
            
            % Prüfen, ob GitHub CLI installiert ist
            [status, ~] = system('gh --version');
            if status ~= 0
                error('APICaller:NoCLI', 'GitHub CLI (gh) ist nicht installiert oder nicht im PATH. Bitte installieren Sie die GitHub CLI: https://cli.github.com/');
            end
            
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
            
            if ~isfield(options, 'temperature')
                options.temperature = 0.7;
            end
            
            if ~isfield(options, 'system_message')
                options.system_message = 'You are a helpful assistant specialized in BPMN.';
            end
            
            % Temporäre Dateien für Ein- und Ausgabe
            temp_dir = tempdir;
            input_file = fullfile(temp_dir, 'gh_models_input.json');
            output_file = fullfile(temp_dir, 'gh_models_output.json');
            
            % Erstelle JSON-Anfrage (in OpenAI-Format)
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
            
            % GitHub CLI Befehl erstellen
            gh_cmd = sprintf('gh api --method POST models.github.ai/inference --input "%s" -H "Content-Type: application/json" > "%s"', ...
                input_file, output_file);
            
            if options.debug
                fprintf('Führe GitHub CLI Befehl aus:\n%s\n', gh_cmd);
                tic;
            end
            
            % Befehl ausführen
            [status, cmdout] = system(gh_cmd);
            
            if options.debug
                elapsed = toc;
                fprintf('CLI-Aufruf abgeschlossen in %.2f Sekunden mit Status: %d\n', elapsed, status);
                
                if ~isempty(cmdout)
                    fprintf('CLI-Ausgabe: %s\n', cmdout);
                end
            end
            
            % Fehlerbehandlung
            if status ~= 0
                error('APICaller:CLIError', 'GitHub CLI-Fehler: %s', cmdout);
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