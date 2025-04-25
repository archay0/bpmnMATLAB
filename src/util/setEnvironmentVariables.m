function setEnvironmentVariables()
    % setEnvironmentVariables - direct setting of environment variables in Matlab
    %
    % This function sets the necessary environmental variables directly,
    % instead of loading them from a file. This script should not be
    % included in Git commits because it contains sensitive information.
    %
    % Usage:
    % setEnvironmentVariables();
    %
    % API configuration:
    % - Github Models API: Need github_token with "Models: Read" permissions
    % - OpenRouter API: Needs OpenRouter_api_Key
    %
    % See also: loadEnvironment, getenv

    fprintf('Setting environment variables for API access...\n');
    
    % Insert your actual API key and other environmental variables here
    % ====================================================================================================
    
    % OpenRouter API token - real name is OpenRouter_api_Key
    % Replace 'your_openrouter_api_key_here' with your actual OpenRouter token
    setenv('OpenRouter_api_Key', 'SK-OR-OR-V1-7BF303C0C0B2B6EDB1FE953B2E859B4E339D03E896CC8B95205D');
    
    % Github Models API token (if required) - Ensure this line is correctly commented or valid
    % setenv('github_token', 'your_github_pat_here'); % Example placeholder
    % setenv('github_api_token', getenv('github_token'));
    
    % OpenAI API token (if needed)
    % setenv('openai_api_key', 'your_openai_api_key_here');
    
    % ====================================================================================================
    
    % Confirm successful setting (without revealing the actual values)
    if ~isempty(getenv('OpenRouter_api_Key'))
        fprintf('✓ OpenRouter_api_Key set\n');
    else
        fprintf('✗ OpenRouter_api_Key not set\n');
    end
    
    if ~isempty(getenv('github_token'))
        fprintf('✓ github_token set\n');
    else
        fprintf('✗ github_token not set\n');
    end
    
    fprintf('Environment variables were successfully set.\n');
    
    % Example of OpenRouter API usage
    fprintf('\n----------------------------------------------------------\n');
    fprintf('Example of OpenRouter API use (Python):\n\n');
    fprintf('import requests\n\n');
    fprintf('openrouter_url = "https://openrouter.ai/api/v1/chat/completions"\n');
    fprintf('api_key = "%s" # Your OpenRouter API key\n', 'your_openrouter_api_key');
    fprintf('model = "microsoft/mai-ds-r1:free"\n\n');
    fprintf('headers = {\n');
    fprintf('    "Content-Type": "application/json",\n');
    fprintf('    "Authorization": f"Bearer {api_key}",\n');
    fprintf('    "HTTP-Referer": "http://localhost:3000",\n');
    fprintf('    "X-Title": "BPMN MATLAB Generator"\n');
    fprintf('}\n\n');
    fprintf('data = {\n');
    fprintf('    "messages": [\n');
    fprintf('        {"role": "system", "content": "You are a helpful assistant."},\n');
    fprintf('        {"role": "user", "content": "What is the capital of France?"}\n');
    fprintf('    ],\n');
    fprintf('    "temperature": 0.7,\n');
    fprintf('    "model": model\n');
    fprintf('}\n\n');
    fprintf('response = requests.post(openrouter_url, headers=headers, json=data)\n');
    fprintf('print(response.json()["choices"][0]["message"]["content"])\n');
    fprintf('----------------------------------------------------------\n');
end