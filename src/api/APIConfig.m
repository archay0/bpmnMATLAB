n    % Apiconfig contains central configuration settings for API integration
nn        % Standard API model configuration
        DEFAULT_MODEL = 'Microsoft/Mai-DS-R1: Free';
n        DEFAULT_SYSTEM_MESSAGE = 'You are an expert in Business Process Model and notation (BPMN).Generate precise, consistent and standard-compliant BPMN information.';
n        % Debug settings
nn        % Defines the formatting instructions for the API answers
        FORMAT_INSTRUCTIONS = ['Opt exclusively with a valid JSON array or object.', ...
                             'Pay attention to a correct and complete JSON syntax without additional text.'];
nnnn            % Returns the standard options for API calls
nnnnnnnn            % Adds format instructions for prompt
            prompt = sprintf('%s \n \n%s', prompt, APIConfig.FORMAT_INSTRUCTIONS);
nnn