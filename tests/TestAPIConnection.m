%% Test Script for GitHub Models API Connection
% This script tests the connection to the GitHub Models API with detailed error reporting

fprintf('Starting GitHub Models API Connection Test...\n');

% --- Setup ---
try
    % Add necessary paths
    if exist('../src', 'dir')
        addpath('../src');
        addpath('../src/api');
        addpath('../src/util');
    elseif exist('src', 'dir')
        addpath('src');
        addpath('src/api');
        addpath('src/util');
    else
        error('Could not find src directory. Run script from workspace root or tests directory.');
    end

    % Load environment variables
    if exist('../.env', 'file')
        loadEnvironment('../.env');
    elseif exist('.env', 'file')
        loadEnvironment('.env');
    else
        warning('No .env file found. Make sure GITHUB_API_TOKEN is set in your environment.');
    end

    % Check token
    token = getenv('GITHUB_API_TOKEN');
    if isempty(token)
        error('GITHUB_API_TOKEN is not set in the environment. This is required for API access.');
    else
        fprintf('✓ API token is set (length: %d characters)\n', length(token));
        % Display first few characters (safely)
        if length(token) > 7
            fprintf('  Token starts with: %s***\n', token(1:4));
        end
    end

    % --- Test direct API call with detailed debugging ---
    fprintf('\nTesting direct API call with weboptions...\n');
    
    % Define API endpoint - double check this is correct
    endpoint = 'https://models.github.ai/inference';
    fprintf('API Endpoint: %s\n', endpoint);
    
    % Prepare HTTP headers
    headers = { ...
        'Authorization', ['Bearer ' token];
        'Content-Type', 'application/json' ...
    };
    
    % Create options with extended debugging
    options = weboptions( ...
        'HeaderFields', headers, ...
        'MediaType', 'application/json', ...
        'Timeout', 60, ...
        'CertificateFilename', '', ... % Skip certificate verification if needed
        'Debug', true ... % Enable debugging output
    );
    
    % Simple test prompt
    testPrompt = 'Generate a brief description of what BPMN is used for.';
    
    % Create request body
    requestBody = struct( ...
        'prompt', testPrompt, ...
        'model', 'openai/o1' ...
    );
    
    % Convert to JSON
    jsonBody = jsonencode(requestBody);
    fprintf('Request body: %s\n', jsonBody);
    
    % Make the request
    try
        fprintf('Making API request...\n');
        startTime = tic;
        response = webwrite(endpoint, jsonBody, options);
        elapsed = toc(startTime);
        fprintf('✓ API request successful! Response received in %.2f seconds\n', elapsed);
        fprintf('Response type: %s\n', class(response));
        
        % Process and display response
        if isstruct(response)
            fprintf('Response is a struct with fields: %s\n', strjoin(fieldnames(response), ', '));
            
            % Check for choices field (for GitHub Models API)
            if isfield(response, 'choices') && ~isempty(response.choices)
                fprintf('Response text: %s\n', response.choices(1).text);
            elseif isfield(response, 'data')
                fprintf('Response data: %s\n', response.data);
            else
                fprintf('Response content: %s\n', jsonencode(response));
            end
        else
            fprintf('Response content: %s\n', jsonencode(response));
        end
        
    catch ME
        fprintf('\n❌ API REQUEST FAILED ❌\n');
        fprintf('Error Identifier: %s\n', ME.identifier);
        fprintf('Error Message: %s\n', ME.message);
        
        % Special handling for HTTP errors
        if strcmp(ME.identifier, 'MATLAB:webservices:HTTP404StatusCodeError')
            fprintf('\nDEBUGGING 404 ERROR:\n');
            fprintf('1. Verify the endpoint URL is correct: %s\n', endpoint);
            fprintf('2. Check if your API token has access to this endpoint\n');
            fprintf('3. Verify the API service is available (try another tool/browser)\n');
            fprintf('4. Check if the format of the request body is correct\n');
        elseif strcmp(ME.identifier, 'MATLAB:webservices:HTTP401StatusCodeError')
            fprintf('\nDEBUGGING 401 ERROR:\n');
            fprintf('Authentication failed. Your token appears to be invalid or has expired.\n');
        end
        
        % Display full error details
        fprintf('\nComplete error details:\n');
        disp(getReport(ME, 'extended'));
    end
    
catch ME
    fprintf('\n--- ERROR during API test ---\n');
    fprintf('Error Identifier: %s\n', ME.identifier);
    fprintf('Error Message: %s\n', ME.message);
    fprintf('Stack Trace:\n');
    disp(getReport(ME, 'extended'));
end

fprintf('\nAPI Connection Test Completed.\n');