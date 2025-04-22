classdef APICaller
    % APICaller wraps HTTP communications with the GitHub Models API

    methods(Static)
        function raw = sendPrompt(prompt)
            % Read API token
            token = getenv('GITHUB_API_TOKEN');
            if isempty(token)
                error('APICaller:AuthError', 'Environment variable GITHUB_API_TOKEN is not set');
            end

            % Prepare HTTP headers and options
            headers = { ...
                'Authorization', ['Bearer ' token];
                'Content-Type', 'application/json' ...
            };
            options = weboptions( ...
                'HeaderFields', headers, ...
                'MediaType', 'application/json', ...
                'Timeout', 60 ...
            );

            % Build request body
            body = struct('prompt', prompt);

            % Send POST to GitHub Models API endpoint
            endpoint = 'https://api.github.com/models/your-model-id/generate';
            try
                raw = webwrite(endpoint, jsonencode(body), options);
            catch ME
                error('APICaller:RequestFailed', 'LLM API request failed: %s', ME.message);
            end
        end
    end
end