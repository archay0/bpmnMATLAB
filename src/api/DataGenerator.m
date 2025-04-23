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
            
            originalPrompt = prompt; % Store the initial prompt for potential retry
            maxRetries = 1; % Allow one retry attempt to fix the response
            retryCount = 0;
            rows = []; % Initialize output
            lastError = []; % Store the last error encountered
            text = ''; % Initialize text variable in outer scope

            while retryCount <= maxRetries
                try
                    % Add format instructions if not skipped (do this each attempt)
                    currentPrompt = prompt; % Use potentially updated prompt (original or fix-it)
                    if ~isfield(options, 'skipFormatting') || ~options.skipFormatting
                        formatInstructions = [
                            '\n\nWICHTIG: Antworte ausschließlich mit einem gültigen JSON-Array oder -Objekt. ', ...
                            'Verwende keine Code-Blöcke mit ```json oder ```. ', ...
                            'Beginne deine Antwort direkt mit [ oder { und füge keinen zusätzlichen Text hinzu.'
                        ];
                        currentPrompt = [currentPrompt, formatInstructions];
                    end
                    
                    % Make the API call
                    fprintf('--- Calling LLM (Attempt %d/%d) ---\n', retryCount + 1, maxRetries + 1);
                    raw = APICaller.sendPrompt(currentPrompt, options);
                    
                    % --- Start Response Processing --- 
                    text = ''; % Reset text for each attempt
                    % Determine response format and extract content
                    if isfield(raw, 'choices') && ~isempty(raw.choices) && isfield(raw.choices(1), 'message') && isfield(raw.choices(1).message, 'content')
                        text = raw.choices(1).message.content;
                    elseif isfield(raw, 'choices') && ~isempty(raw.choices) && isfield(raw.choices(1), 'text')
                        text = raw.choices(1).text;
                    elseif isfield(raw, 'data') && ischar(raw.data)
                        text = raw.data;
                    elseif ischar(raw)
                        text = raw;
                    else
                        warning('DataGenerator:UnknownFormat', 'Unknown response format. Attempting to encode.');
                        try text = jsonencode(raw); catch; text = ''; end
                    end
                    if ~ischar(text)
                        warning('DataGenerator:NonCharContent', 'Extracted content not char. Trying conversion.');
                        try text = char(text); catch; text = ''; end
                    end
                    
                    % Debugging extracted text
                    if isfield(options, 'debug') && options.debug
                        fprintf('--- Extracted Text (Attempt %d) ---\n', retryCount + 1);
                        disp(text);
                        fprintf('--- End Extracted Text ---\n');
                    end
                    
                    % Robust JSON Cleaning
                    text = strtrim(text);
                    text = regexprep(text, '^```json\s*', '');
                    text = regexprep(text, '\s*```$', '');
                    text = regexprep(text, '^```\s*', '');
                    text = regexprep(text, '\s*```$', '');
                    if startsWith(text, '`') && endsWith(text, '`')
                        text = text(2:end-1);
                    end
                    text = strtrim(text);
                    
                    % Check if text is empty after cleaning
                    if isempty(text)
                        error('DataGenerator:EmptyContent', 'API response content is empty after cleaning.');
                    end
                    
                    % Debugging before decode
                    if isfield(options, 'debug') && options.debug
                        fprintf('--- Text Before jsondecode (Attempt %d) ---\n', retryCount + 1);
                        disp(text);
                        fprintf('--- End Text Before jsondecode ---\n');
                    end
                    
                    % Attempt to decode the cleaned JSON text
                    rows = jsondecode(text);
                    
                    % Post-processing (e.g., cell array conversion)
                    if iscell(rows) && ~isempty(rows) && all(cellfun(@isstruct, rows))
                        try rows = vertcat(rows{:});
                        catch vertcatME
                            warning('DataGenerator:CellConversionFailed', 'Could not convert cell array: %s', vertcatME.message);
                        end
                    end
                    
                    % Success~ Exit the loop.
                    fprintf('--- LLM Call Successful (Attempt %d) ---\n', retryCount + 1);
                    lastError = []; % Clear last error on success
                    break; 

                catch ME
                    lastError = ME; % Store the error
                    fprintf('--- LLM Call Attempt %d FAILED: %s ---\n', retryCount + 1, ME.message);
                    
                    retryCount = retryCount + 1; % Increment retry counter
                    
                    if retryCount <= maxRetries
                        fprintf('--- Preparing Retry (%d/%d) ---\n', retryCount, maxRetries);
                        % Build the fix-it prompt
                        fixitPrompt = sprintf([...
                            'The previous response to the prompt below was problematic and could not be parsed as valid JSON.\n\n' ...
                            '===== ORIGINAL PROMPT =====\n%s\n\n' ...
                            '===== PROBLEMATIC RESPONSE TEXT =====\n%s\n\n' ...
                            '===== ERROR =====\n%s\n\n' ...
                            '===== INSTRUCTIONS =====\n' ...
                            'Please correct the response. Ensure it is VALID and COMPLETE JSON, starting directly with [ or {, containing NO explanatory text or markdown formatting (like ```json or ```), and fulfilling the original request. Respond ONLY with the corrected JSON data.'], ...
                            originalPrompt, text, ME.message); % Use 'text' which holds the problematic string from the failed attempt
                        
                        % Update the prompt for the next iteration
                        prompt = fixitPrompt; 
                        % Optionally clear 'rows' if needed before retry
                        rows = []; 
                        continue; % Go to the next iteration of the while loop
                    else
                        % Max retries exceeded, break the loop to throw error outside
                        fprintf('--- Max Retries Exceeded ---\n');
                        break; 
                    end
                end % end try-catch
            end % end while loop
            
            % After the loop, check if we ended due to an error
            if ~isempty(lastError)
                 % Throw a new error indicating retries failed, including the last error message
                 error('DataGenerator:RetryFailed', ...
                       'Failed to get valid JSON from LLM after %d retries. Last Error: %s\n\nLast Problematic Text:\n%s', ...
                       maxRetries, lastError.message, text);
            end
            
            % If loop finished successfully, 'rows' contains the valid data
            
        end % end callLLM method
    end % end static methods
end