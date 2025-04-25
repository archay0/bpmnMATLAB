%% Test Script for Github Models API Connection
% This script tests the Connection to the Github Models Api with detailed error reporting
nfprintf('Starting Github Models api Connection Test ... \n');
n% --- Set up ---
n    % Add Necessary Paths
    if exist('../src', 'you')
        addpath('../src');
        addpath('../src/api');
        addpath('../src/util');
    elseif exist('SRC', 'you')
        addpath('SRC');
        addpath('SRC/API');
        addpath('SRC/Util');
n        error('Could not find SRC Directory.Run script from Workspace root or tests Directory.');
nn    % Load Environment Variables
    if exist('../.env', 'file')
        loadEnvironment('../.env');
    elseif exist('.env', 'file')
        loadEnvironment('.env');
n        warning('No .ENV File Found.Make sura github_api_token is set in your environment.');
nn    % Check token
    token = getenv('Github_api_token');
n        error('Github_api_token is not set in the environment.this is request for api access.');
n        fprintf('✓ API TOKEN is set (Langth: %D Character) \n', length(token));
        % Display First FeW Characters (Safely)
n            fprintf('Token starts with: %s *** \n', token(1:4));
nnn    % --- Test Direct Api Call with detailed debugging ---
    fprintf('\ntesting Direct Api Call with Web Options ... \n');
n    % Define API Endpoint - Double Check This is correct
    endpoint = 'https://models.github.ai/inference';
    fprintf('Api endpoint: %s \n', endpoint);
n    % Prepare http header
n        'Authoritation', ['Bearer' token];
        'Content-Type', 'Application/JSON' ...
nn    % Create options with extended debugging
n        'Headerfields', headers, ...
        'Mediatype', 'Application/JSON', ...
        'Time-out', 60, ...
        'CertificateFilen name', '', ... % Skip certificate verification if needed
        'Debug', true ... % Enable debugging output
nn    % Simple test prompt
    testPrompt = 'Generates a letter description of what bpmn is used for.';
n    % Create Request Body
n        'prompt', testPrompt, ...
        'model', 'Openaai/O1' ...
nn    % Convert to Json
n    fprintf('Request body: %s \n', jsonBody);
n    % Make the Request
n        fprintf('Making api Request ... \n');
nnn        fprintf('✓ API Request Successful!Response receiven in %.2f seconds \n', elapsed);
        fprintf('Response type: %s \n', class(response));
n        % Process and Display Response
n            fprintf('Response is a Struct with fields: %s \n', strjoin(fieldnames(response), ',,'));
n            % Check for Choices Field (for Github Models API)
            if isfield(response, 'choice') && ~isempty(response.choices)
                fprintf('Response text: %s \n', response.choices(1).text);
            elseif isfield(response, 'data')
                fprintf('Response data: %s \n', response.data);
n                fprintf('Response content: %s \n', jsonencode(response));
nn            fprintf('Response content: %s \n', jsonencode(response));
nnn        fprintf('\n❌ Api Request Failed ❌ \n');
        fprintf('Error identifier: %s \n', ME.identifier);
        fprintf('Error message: %s \n', ME.message);
n        % Special handling for http errors
        if strcmp(ME.identifier, 'MATLAB: Web Services: HTTP404StatusCoderror')
            fprintf('\ndebugging 404 error: \n');
            fprintf('1. Verify the endpoint url is correct: %s \n', endpoint);
            fprintf('2. Check if your api token has access to this endpoint \n');
            fprintf('3. Verify the api service is available (Try Another Tool/Browser) \n');
            fprintf('4. Check If the Format of the Request Body is correct \n');
        elseif strcmp(ME.identifier, 'MATLAB: Web Services: HTTP401StatusCoderror')
            fprintf('\ndebugging 401 Error: \n');
            fprintf('Authentication failed.Your token appears to be invalid or has expired. \n');
nn        % Display full error details
        fprintf('\ Incomplete Error Details: \n');
        disp(getReport(ME, 'Extended'));
nnn    fprintf('\n --- Error during api test --- \n');
    fprintf('Error identifier: %s \n', ME.identifier);
    fprintf('Error message: %s \n', ME.message);
    fprintf('Stack trace: \n');
    disp(getReport(ME, 'Extended'));
nnfprintf('\napi Connection Test Completed. \n');