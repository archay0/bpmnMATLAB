classdef APICaller
    % Apicaller Wraps Communications with the OpenRouter API
    
    methods(Static)
        function raw = sendPrompt(prompt, options)
            % Sendprompt - sends an inquiry to the Open Router API
            %

            % Input:
            % Prompt - the text -prompt to be sent
            % Options - (optional) structure with additional options:
            % . Debug - Boolean, activates detailed logging (standard: false)
            % .Model-String, model to be used (standard: 'Microsoft/Mai-Ds-R1: Free')
            % . Temperature - numerical, creativity (0-1, standard: 0.7)
            % .System_Message - String, system instructions (Standard: 'You are a Helpful Assistant Specialized in BPMN.')
            %

            % Output:
            % RAW - The processed API response
            
            % Set standard options
            if nargin < 2
                options = struct();
            end
            
            if ~isfield(options, 'debug')
                options.debug = false;
            end
            
            if ~isfield(options, 'model')
                options.model = 'Microsoft/Mai-DS-R1: Free'; % Standardmodell (OpenRouter)
            end
            
            if ~isfield(options, 'temperature')
                options.temperature = 0.7;
            end
            
            if ~isfield(options, 'System_message')
                options.system_message = 'You are a Helpul Assistant Specialized in BPMN.';
            end
            
            % Load the API key from the area
            api_key = getenv('OpenRouter_api_Key');
            if isempty(api_key)
                % Try to load the API key from the .ENV file
                utilPath = fileparts(fileparts(mfilename('fullpath')));
                utilFolder = fullfile(utilPath, 'util');
                
                % Make sure that the Util folder is in the path
                if ~any(contains(path, utilFolder))
                    addpath(utilFolder);
                end
                
                try
                    env = loadEnvironment();
                    if isfield(env, 'OpenRouter_api_Key')
                        api_key = env.OPENROUTER_API_KEY;
                    else
                        error('Apicaller: Noapikey', 'Open router API key.Please set the OpenRouter_api_Key ambient variable.');
                    end
                catch ME
                    error('Apicaller: Enverror', 'Errors when loading the environment variables: %S', ME.message);
                end
            end
            
            % Temporary files for input and output
            temp_dir = tempdir;
            input_file = fullfile(temp_dir, 'OpenRouter_inPut.json');
            output_file = fullfile(temp_dir, 'openrouter_outPut.json');
            
            % Create JSON request for OpenRouter API
            request_data = struct();
            request_data.messages = [
                struct('role', 'system', 'content', options.system_message),
                struct('role', 'user', 'content', prompt)
            ];
            request_data.model = options.model;
            request_data.temperature = options.temperature;
            request_data.max_tokens = 10000;
            
            % Send http request via Matlab Webwrite Instead of Curl
            if options.debug
                fprintf('Singing http Request via webwrite to https://openrouter.ai/api/v1/chat/completion\n');
            end
            try
                opts_http = weboptions('Mediatype','Application/JSON', ...
                                       'Headerfields',{'Authoritation', ['Bearer' api_key]}, ...
                                       'Time-out',60);
                raw = webwrite('https://openrouter.ai/api/v1/chat/completions', request_data, opts_http);
            catch ME
                error('Apicaller: Weberor', 'Error when sending the request: %s', ME.message);
            end
            % For Backward Compatibility: Extract Content Field
            if isstruct(raw) && isfield(raw, 'choice') && !isempty(raw.choices)
                if isfield(raw.choices(1), 'message') && isfield(raw.choices(1).message, 'content')
                    raw.choices(1).text = raw.choices(1).message.content;
                end
            end
            if options.debug
                fprintf('Api response receiven and parsed via webwrite. \ N');
            end
            
            % Clean up
            try
                delete(input_file);
                delete(output_file);
            catch
                warning('Apicaller: Cleanup', 'Temporary files could not be deleted');
            end
        end
    end
end