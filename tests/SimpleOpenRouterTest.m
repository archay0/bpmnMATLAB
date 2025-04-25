%% Simpleopenrouttertest.M
% A simple test for the OpenRouter API access
n% Clean up the area
nnnnfprintf('=== OpenRouter API test with Microsoft/Mai-Ds-R1: Free === \n \n');
n% Determine the project path
currentScript = mfilename('fullpath');
nnn% Add basic paths
addpath(fullfile(projectRoot, 'SRC'));
addpath(fullfile(projectRoot, 'SRC', 'API'));
addpath(fullfile(projectRoot, 'SRC', 'util'));
nn    % Initialize API environment
    fprintf('1. Initialist API environment ... \n');
    % Check whether initapienvironment is found
    if exist('initapien vironment', 'file')
nn        fprintf('Initapien vironment not found, make manual initialization ... \n');
        % Check whether Apicaller.M is present
        apiCallerPath = which('Apicaller.m');
n            error('Apicaller.M Not Found in the Matlab Path');
n            fprintf('Apicaller.M found: %s \n', apiCallerPath);
nn        % Environment variables shop
        fprintf('Charge ambient variables ... \n');
        env = loadEnvironment(fullfile(projectRoot, '.env'));
        if isfield(env, 'OpenRouter_api_Key')
            setenv('OpenRouter_api_Key', env.OPENROUTER_API_KEY);
            fprintf('OpenRouter_api_Key set \n');
n            error('OpenRouter_api_Key not found in .env');
nnn    fprintf('\n2.Configure API call ... \n');
    % Simple test options
nn    opt.model = 'Microsoft/Mai-DS-R1: Free';
n    opt.system_message = 'You are a BPMN expert.';
n    % Test message
    prompt = 'What is BPMN?Short answer please.';
    fprintf('Prompt:"%s"\n', prompt);
    fprintf('Model: %s \n', opt.model);
n    fprintf('\n3.Get API call through ... \n');
    % Call of the Sendprompt method
nn    % Success
    fprintf('\n4.Successful API call! \n');
    fprintf('Answer: \n%s \n', response.choices(1).message.content);
nn    % Provide error details
    fprintf('\n !!!Error !!! \n%s \n', ME.message);
n    % Stack trace for better diagnosis
n        fprintf('\nstack-trace: \n');
n            fprintf('In %s (line %d): %s \n', ...
nnnn    % Output of the Matlab path for troubleshooting
    fprintf('\ Matlab path: \n%s \n', path);
n