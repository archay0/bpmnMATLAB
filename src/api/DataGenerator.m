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
            
            % Format-Anweisungen hinzufügen, wenn nicht explizit deaktiviert
            if ~isfield(options, 'skipFormatting') || ~options.skipFormatting
                % Füge explizite Format-Anweisungen zum Prompt hinzu
                formatInstructions = [
                    '\n\nWICHTIG: Antworte ausschließlich mit einem gültigen JSON-Array oder -Objekt. ', ...
                    'Verwende keine Code-Blöcke mit ```json oder ```. ', ...
                    'Beginne deine Antwort direkt mit [ oder { und füge keinen zusätzlichen Text hinzu.'
                ];
                prompt = [prompt, formatInstructions];
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
                
                % Debugging für den extrahierten Text
                if isfield(options, 'debug') && options.debug
                    disp('Extrahierter Text aus der API-Antwort:');
                    disp(text);
                end
                
                % Entferne Code-Block-Markierungen, falls vorhanden (```json, ```, etc.)
                text = regexprep(text, '```json\s*', '');
                text = regexprep(text, '```\s*', '');
                
                % Entferne Markdown-Formatierungen und andere nicht-JSON-Zeichen
                text = regexprep(text, '^\s+', ''); % Whitespace am Anfang
                text = regexprep(text, '\s+$', ''); % Whitespace am Ende
                
                % Robuste JSON-Extraktion
                % Suche nach dem ersten { oder [ und dem letzten } oder ]
                jsonStart1 = regexp(text, '[\[{]', 'once');
                jsonEnd1 = regexp(text, '[\]}](?!.*[\]}])', 'once');
                
                % Alternative Methode mit strfind für bessere Kompatibilität
                jsonStart2 = min([strfind(text, '{'), strfind(text, '[')]);
                if isempty(jsonStart2)
                    jsonStart2 = inf;
                end
                
                jsonEnd2a = strfind(text, '}');
                jsonEnd2b = strfind(text, ']');
                if ~isempty(jsonEnd2a) || ~isempty(jsonEnd2b)
                    jsonEnd2 = max([jsonEnd2a, jsonEnd2b]);
                else
                    jsonEnd2 = 0;
                end
                
                % Nehme die bessere der beiden Extraktionsmethoden
                if !isempty(jsonStart1) && !isempty(jsonEnd1)
                    jsonStart = jsonStart1;
                    jsonEnd = jsonEnd1;
                elseif !isinf(jsonStart2) && jsonEnd2 > 0
                    jsonStart = jsonStart2;
                    jsonEnd = jsonEnd2;
                else
                    % Kein JSON gefunden - verwende den ganzen Text in der Hoffnung,
                    % dass es trotzdem funktioniert
                    jsonStart = 1;
                    jsonEnd = length(text);
                    warning('DataGenerator:NoJsonMarkers', 'Keine JSON-Marker gefunden, verwende den gesamten Text.');
                end
                
                % Extrahiere den JSON-Teil
                if jsonStart <= jsonEnd && jsonEnd <= length(text)
                    jsonText = text(jsonStart:jsonEnd);
                    
                    % Debugging für den extrahierten JSON-Text
                    if isfield(options, 'debug') && options.debug
                        disp('Extrahierter JSON-Text:');
                        disp(jsonText);
                    end
                else
                    % Fallback, wenn Marker inkonsistent sind
                    warning('DataGenerator:InvalidJsonMarkers', 'Ungültige JSON-Marker, verwende den gesamten Text.');
                    jsonText = text;
                end
                
                % Letzter Versuch, das JSON zu reparieren, wenn es immer noch ungültig ist
                % Überprüfe auf ungleiche Klammerzahl
                openBraces = sum(jsonText == '{');
                closeBraces = sum(jsonText == '}');
                openBrackets = sum(jsonText == '[');
                closeBrackets = sum(jsonText == ']');
                
                if openBraces > closeBraces
                    % Füge fehlende schließende Klammern hinzu
                    jsonText = [jsonText, repmat('}', 1, openBraces - closeBraces)];
                    warning('DataGenerator:AddedMissingBraces', 'Füge %d fehlende } hinzu', openBraces - closeBraces);
                end
                
                if openBrackets > closeBrackets
                    % Füge fehlende schließende Klammern hinzu
                    jsonText = [jsonText, repmat(']', 1, openBrackets - closeBrackets)];
                    warning('DataGenerator:AddedMissingBrackets', 'Füge %d fehlende ] hinzu', openBrackets - closeBrackets);
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