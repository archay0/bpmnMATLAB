classdef DataGenerator
    % Datagenerator Provides Methods to Call the LLM API and Return Matlab Data

    methods(Static)
        function rows = callLLM(prompt, options)
            % Sends the promptly via apical and decodes the json response
            %

            % Inputs:
            % Prompt - String prompt to send to the llm
            % Options - optional Structure with api options
            %

            % Output:
            % Rows - Decoded Json Response as Matlab Data Structure
            
            % Standard options, if not specified
            if nargin < 2
                options = struct();
            end
            
            % Set default options
            if ~isfield(options, 'baking')
                options.fallbackOnError = true; % Default to fallback mode - return data even if problematic
            end
            
            % Initialize the API environment if available
            if exist('initapien vironment', 'file') == 2
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
                    if ~isfield(options, 'ski piping') || ~options.skipFormatting
                        formatInstructions = [
                            '\ n \ n vecal: respond exclusively with a valid Json array or object.', ...
                            'Do not use code blocks with `` Json or `` `.', ...
                            'Start your answer directly with [or {and do not add any additional text.'
                        ];
                        currentPrompt = [currentPrompt, formatInstructions];
                    end
                    
                    % Make the api call
                    fprintf('--- Calling LLM (Attempt %D/ %D) --- \ n', retryCount + 1, maxRetries + 1);
                    raw = APICaller.sendPrompt(currentPrompt, options);
                    
                    % --- Start Response Processing ---
                    text = ''; % Reset text for each attempt
                    % Determine response format and extract content
                    if isfield(raw, 'choice') && ~isempty(raw.choices) && isfield(raw.choices(1), 'message') && isfield(raw.choices(1).message, 'content')
                        text = raw.choices(1).message.content;
                    elseif isfield(raw, 'choice') && ~isempty(raw.choices) && isfield(raw.choices(1), 'text')
                        text = raw.choices(1).text;
                    elseif isfield(raw, 'data') && ischar(raw.data)
                        text = raw.data;
                    elseif ischar(raw)
                        text = raw;
                    else
                        warning('Datagenerator: Unknown format', 'Unknown response format.Attempting to encode.');
                        try text = jsonencode(raw); catch; text = ''; end
                    end
                    if ~ischar(text)
                        warning('Datagenerator: noncharmet', 'Extracted content not char.Trying conversion.');
                        try text = char(text); catch; text = ''; end
                    end
                    
                    % Always Show A Sample of the Raw Response (Not Just in Debug Mode)
                    % Limited to 500 Chars to Avoid Flooding the Console
                    fprintf('--- raw llm response (truncated) --- \ n');
                    if length(text) > 500
                        fprintf('%s ... \ n [... truncated, total length: %d chars] \ n', text(1:500), length(text));
                    else
                        fprintf('%s \ n', text);
                    end
                    fprintf('--- end raw response --- \ n');
                    
                    % Robust Json Cleaning
                    originalText = text; % Save original before cleaning
                    text = strtrim(text);
                    text = regexprep(text, '^`` Json \ s*', '');
                    text = regexprep(text, '\ s*`` $', '');
                    text = regexprep(text, '^`` \ s*', '');
                    text = regexprep(text, '\ s*`` $', '');
                    if startsWith(text, '’') && endsWith(text, '’')
                        text = text(2:end-1);
                    end
                    text = strtrim(text);
                    
                    % Check if text is empty after cleaning
                    if isempty(text)
                        error('Datagenerator: EmptyContent', 'Api Response Content is Empty After Cleaning.');
                    end
                    
                    % Try to Extract JSON IF Text Contains it But has Extra Content
                    try
                        % Find potential Json Boundaries
                        jsonStart = regexp(text, '[\ [{]', 'once');
                        jsonEnd = regexp(text, '[\]}] [^\]}]*$', 'once');
                        
                        if ~isempty(jsonStart) && ~isempty(jsonEnd) && jsonEnd > jsonStart
                            potentialJson = text(jsonStart:jsonEnd);
                            % Try Parsing the potential JSON PORTION
                            try
                                testParse = jsondecode(potentialJson);
                                % If we get here, the extraction worked!
                                fprintf('Extracted JSON From Partial Text (Chars %D %D of %D) \ n', ...
                                       jsonStart, jsonEnd, length(text));
                                text = potentialJson;
                            catch
                                % If extraction failed, continue with full text
                            end
                        end
                    catch
                        % Ignore Errors in Json Extraction Attempt
                    end
                    
                    % Attempt to Decode the Cleaned Json Text
                    try
                        rows = jsondecode(text);
                        
                        % Post-Processing (e.G., Cell Array Conversion)
                        if iscell(rows) && ~isempty(rows) && all(cellfun(@isstruct, rows))
                            try 
                                rows = vertcat(rows{:});
                            catch vertcatME
                                warning('Datagenerator: Cellconversion failed', 'Could not Convert Cell Array: %S', vertcatME.message);
                            end
                        end
                        
                        % Success!Exit the Loop.
                        fprintf('--- llm Call Successful (Attempt %D) --- \ n', retryCount + 1);
                        lastError = []; % Clear last error on success
                        break;
                        
                    catch jsonME
                        % JSON DECODE Failed - Decide Whether To Retry or Use Fallback
                        lastError = jsonME;
                        fprintf('--- Json Decode failed: %s --- \ n', jsonME.message);
                        
                        % If Backonerror is Enabled and This is the Last Retry Attempt,
                        % Create a simple structure with the raw text to return
                        if options.fallbackOnError && retryCount >= maxRetries
                            fprintf('--- Using Fallback Mode-Returning Text AS-IS --- \ n');
                            rows = struct('raw text', originalText, ...
                                          'clean text', text, ...
                                          'Isvalide', false);
                            lastError = []; % Clear error since we're using fallback
                            break; % Exit the loop with the fallback data
                        else
                            % Re-Throw the error to trigger The Retry Mechanism
                            error('Datagenerator: Jsonparseeror', 'Failed to parse as json: %s', jsonME.message);
                        end
                    end

                catch ME
                    lastError = ME; % Store the error
                    fprintf('--- llm call attempt %d failed: %s --- \ n', retryCount + 1, ME.message);
                    
                    retryCount = retryCount + 1; % Increment retry counter
                    
                    if retryCount <= maxRetries
                        fprintf('--- Preparing Retry (%D/%D) --- \ n', retryCount, maxRetries);
                        % Build the fix-it prompt
                        fixitPrompt = sprintf([...
                            'The Previous Response to the Prompt Below was Problematic and Could not be parsed as valid Json. \ N \ n' ...
                            '==== original prompt ===== \ n%s \ n \ n' ...
                            '====== Problematic Response text ===== \ n%s \ n \ n' ...
                            '===== Error ===== \ n%s \ n \ n' ...
                            '=========== \ n' ...
                            'Please correct the response.Ensure it is valid and complete json, Starting Directly with [or {, containing no explaniky text or Markdown formatting (like `` Json or ``), and fulfilling the original Request.Respond only with the corrected jons data.'], ...
                            originalPrompt, text, ME.message); % Use 'text' which holds the problematic string from the failed attempt
                        
                        % Update the prompt for the next iteration
                        prompt = fixitPrompt; 
                        % Optionally Clear 'Rows' IF Needed Before Retry
                        rows = []; 
                        continue; % Go to the next iteration of the while loop
                    else
                        % Max Retries Expeded, Handle Fallback IF Enabled
                        if options.fallbackOnError && ~isempty(text)
                            fprintf('--- Using Fallback Mode After Max Retries --- \ n');
                            rows = struct('raw text', originalPrompt, ...
                                          'clean text', text, ...
                                          'Isvalide', false);
                            lastError = []; % Clear error since we're using fallback
                            break;
                        else
                            % OtherWise, Break The Loop to Throw Error Outside
                            fprintf('--- Max Retries Expeded --- \ n');
                            break;
                        end 
                    end
                end % end try-catch
            end % end while loop
            
            % After the loop, check if we ended due to an error
            if ~isempty(lastError)
                 % Throw a new error indicating retries failed, including the last error message
                 error('Datagenerator: Retryfailed', ...
                       'Failed to get valid json from llm after %d retries.Last error: %s \ nlast problematic text: \ n %s', ...
                       maxRetries, lastError.message, text);
            end
            
            % If loop finished successfully, 'rows' Contains the valid data or fallback
            
        end % end callLLM method
    end % end static methods
end