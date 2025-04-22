classdef DataGenerator
    % DataGenerator provides methods to call the LLM API and return MATLAB data

    methods(Static)
        function rows = callLLM(prompt, options)
            % Sends the prompt via APICaller and decodes the JSON response
            %
            % Inputs:
            %   prompt  - String prompt to send to the LLM
            %   options - Optional structure with API options
            %
            % Output:
            %   rows    - Decoded JSON response as MATLAB data structure
            
            % Standardoptionen, falls nicht angegeben
            if nargin < 2
                options = struct();
            end
            
            % Initialisiere die API-Umgebung, wenn verfügbar
            if exist('initAPIEnvironment', 'file') == 2
                initAPIEnvironment();
            end
            
            % API aufrufen mit den gegebenen Optionen
            raw = APICaller.sendPrompt(prompt, options);
            
            % Optionales Debugging
            if isfield(options, 'debug') && options.debug
                disp('Rohe API-Antwort:');
                disp(raw);
            end
            
            % Verarbeite die Antwort basierend auf der API-Struktur
            try
                % Bestimme, von welchem API-Anbieter die Antwort stammt
                if isfield(raw, 'choices') && ~isempty(raw.choices) && isfield(raw.choices(1), 'message') && isfield(raw.choices(1).message, 'content')
                    % OpenRouter/OpenAI-Format
                    text = raw.choices(1).message.content;
                elseif isfield(raw, 'choices') && ~isempty(raw.choices) && isfield(raw.choices(1), 'text')
                    % GitHub Models API v1 Format
                    text = raw.choices(1).text;
                elseif isfield(raw, 'data')
                    % Alternatives Format
                    text = raw.data;
                else
                    % Fallback
                    warning('DataGenerator:UnknownFormat', 'Unbekanntes Antwortformat. Versuche die gesamte Antwort zu verwenden.');
                    text = jsonencode(raw);
                end
                
                % Extrahiere JSON aus dem Text
                jsonStart = strfind(text, '[');
                jsonEnd = strfind(text, ']');
                
                if isempty(jsonStart) || isempty(jsonEnd)
                    jsonStart = strfind(text, '{');
                    jsonEnd = strfind(text, '}');
                end
                
                if ~isempty(jsonStart) && ~isempty(jsonEnd)
                    % Wir haben wahrscheinlich JSON in einer längeren Textantwort
                    jsonText = text(jsonStart(1):jsonEnd(end));
                else
                    % Verwende den gesamten Text
                    jsonText = text;
                end
                
                % Konvertiere zu MATLAB-Struktur
                rows = jsondecode(jsonText);
                
                % Wenn das Ergebnis ein Zellarray ist, konvertieren zu struct array
                if iscell(rows)
                    rows = cell2mat(rows);
                end
                
            catch ME
                error('DataGenerator:ParseError', 'Fehler beim Parsen der LLM-Antwort: %s\n\nAntworttext: %s', ME.message, text);
            end
        end
    end
end