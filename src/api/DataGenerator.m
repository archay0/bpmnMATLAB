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
                fprintf('--- Raw API Response ---\n');
                disp(raw);
                fprintf('--- End Raw API Response ---\n');
            end
            
            % Verarbeite die Antwort basierend auf der API-Struktur
            text = ''; % Initialize text
            try
                % Bestimme, von welchem API-Anbieter die Antwort stammt
                if isfield(raw, 'choices') && ~isempty(raw.choices) && isfield(raw.choices(1), 'message') && isfield(raw.choices(1).message, 'content')
                    % OpenRouter/OpenAI-Format
                    text = raw.choices(1).message.content;
                elseif isfield(raw, 'choices') && ~isempty(raw.choices) && isfield(raw.choices(1), 'text')
                    % GitHub Models API v1 Format
                    text = raw.choices(1).text;
                elseif isfield(raw, 'data') && ischar(raw.data) % Ensure data is char/string
                    % Alternatives Format
                    text = raw.data;
                elseif ischar(raw) % Handle case where raw itself is the string
                    text = raw;
                else
                    % Fallback: Try to encode the whole structure if text extraction fails
                    warning('DataGenerator:UnknownFormat', 'Unknown response format or content structure. Attempting to encode the entire response.');
                    try
                        text = jsonencode(raw); % This might fail if raw is complex
                    catch encodeME
                         warning('DataGenerator:EncodingFallbackFailed', 'Failed to encode the entire raw response: %s', encodeME.message);
                         text = ''; % Set text to empty if encoding fails
                    end
                end

                % Ensure text is a character vector
                if ~ischar(text)
                    warning('DataGenerator:NonCharContent', 'Extracted content is not a character vector. Trying to convert.');
                    try
                        text = char(text); % Attempt conversion
                    catch convertME
                        warning('DataGenerator:ConversionFailed', 'Failed to convert content to character vector: %s', convertME.message);
                        text = ''; % Set text to empty if conversion fails
                    end
                end

                % Debugging für den extrahierten Text
                if isfield(options, 'debug') && options.debug
                    fprintf('--- Extracted Text ---\n');
                    disp(text);
                    fprintf('--- End Extracted Text ---\n');
                end

                % --- Robust JSON Cleaning ---
                % 1. Trim whitespace
                text = strtrim(text);

                % 2. Remove potential markdown code block fences (```json ... ``` or ``` ... ```)
                text = regexprep(text, '^```json\s*', '');
                text = regexprep(text, '\s*```$', '');
                text = regexprep(text, '^```\s*', '');
                text = regexprep(text, '\s*```$', '');
                
                % 3. Remove potential single backticks if they enclose the whole string
                if startsWith(text, '`') && endsWith(text, '`')
                    text = text(2:end-1);
                end

                % 4. Trim whitespace again after cleaning
                text = strtrim(text);

                % Check if text is empty after cleaning
                if isempty(text)
                    warning('DataGenerator:EmptyContent', 'API response content is empty after cleaning.');
                    rows = []; % Return empty
                    return;
                end

                % Debugging before decoding
                if isfield(options, 'debug') && options.debug
                    fprintf('--- Text Before jsondecode ---\n');
                    disp(text);
                    fprintf('--- End Text Before jsondecode ---\n');
                end

                % 5. Attempt to decode the cleaned JSON text
                try
                    rows = jsondecode(text);
                catch decodeME
                    % If decoding fails, throw a specific error with the problematic text
                    error('DataGenerator:ParseError', 'Failed to parse LLM JSON response: %s\n\nProblematic Text:\n%s', decodeME.message, text);
                end
                
                % If the result is a cell array, try converting to struct array if appropriate
                % This might need adjustment based on expected output structure
                if iscell(rows) && ~isempty(rows) && all(cellfun(@isstruct, rows))
                    try
                        rows = vertcat(rows{:}); % More robust conversion for cell array of structs
                    catch vertcatME
                        warning('DataGenerator:CellConversionFailed', 'Could not automatically convert cell array to struct array: %s', vertcatME.message);
                        % Keep rows as cell array if conversion fails
                    end
                end

            catch ME % Catch errors during the extraction/parsing process
                 % Provide more context in the error message
                 baseME = MException('DataGenerator:ProcessingError', ...
                     sprintf('Error processing API response: %s\nAttempted Text: %s', ME.message, text));
                 baseME = addCause(baseME, ME);
                 throw(baseME);
            end
        end
    end
end