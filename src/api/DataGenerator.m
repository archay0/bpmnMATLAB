classdef DataGenerator
    % DataGenerator provides methods to call the LLM API and return MATLAB data

    methods(Static)
        function rows = callLLM(prompt)
            % Sends the prompt via APICaller and decodes the JSON response
            raw = APICaller.sendPrompt(prompt);
            % Assume API returns JSON text in raw.choices(1).text or raw.data
            try
                if isfield(raw, 'choices')
                    % GitHub Models API v1 convention
                    text = raw.choices(1).text;
                elseif isfield(raw, 'data')
                    text = raw.data;
                else
                    text = jsonencode(raw);
                end
                rows = jsondecode(text);
            catch ME
                error('DataGenerator:ParseError', 'Failed to parse LLM JSON response: %s', ME.message);
            end
        end
    end
end