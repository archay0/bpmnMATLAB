% Test script for OpenRouter API with Microsoft/Mai-DS-R1: Free Model
% This script tests whether the integration with OpenRouter works
n% Recognize the current path and use absolute paths
nnif ~contains(projectRoot, 'bpmnmatlab')
    % Try to switch to the main directory if we are in subfolders
    cd('..');
nnn% Add path correctly with absolute paths
addpath(fullfile(projectRoot, 'SRC'));
addpath(fullfile(projectRoot, 'SRC', 'API'));
addpath(fullfile(projectRoot, 'SRC', 'util'));
n% Provide the path to troubleshooting
disp('Paths in the Matlab search path:');
nn% Check whether the Apicaller class is found
apiCallerPath = which('Apical');
n    error('Apicaller Class Could not be found.check the paths.');
n    disp(['Apicaller found in:' apiCallerPath]);
nn% Activate debug mode
debug_options = struct('debug', true);
nn    % Testing a simple API call
    disp('Start test of the OpenRouter API with Microsoft/May DS-R1: Free Model ...');
    disp('Send a simple prompt ...');
n    % Inquiries
nn    options.model = 'Microsoft/Mai-DS-R1: Free';
n    options.system_message = 'You are an expert for BPMN (Business Process Model and Notation).';
n    % Send a simple test prompt
    prompt = 'What are the most important elements in a BPMN diagram?Give a short answer.';
n    % Direct call with full class and method
nn    % Show the answer
    disp('Receive API response:');
    if isfield(response, 'choice') && ~isempty(response.choices)
        if isfield(response.choices(1), 'message') && isfield(response.choices(1).message, 'content')
nn            disp('Error: response format not as expected');
nnn        disp('Error: unexpected answer format');
nnn    disp('Open router API test completed!');
nn    disp('Error testing the API OpenRouter:');
n    if isfield(ME, 'stack')
n            disp(['File:' ME.stack(i).file '|Line:' num2str(ME.stack(i).line) '|Function:' ME.stack(i).name]);
nnn