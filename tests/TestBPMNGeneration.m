%% Testbpmnggeneration.m
% A test script for the generation of BPMN data with the OpenRouter API
% This script uses the new API integration with the Microsoft/Mai-DS-R1: Free model
% and generates a temporary file with BPMN data
n% Clean up the area
nnnn% Add paths
addpath(fullfile(pwd, '..', 'SRC'));
addpath(fullfile(pwd, '..', 'SRC', 'API'));
addpath(fullfile(pwd, '..', 'SRC', 'util'));
nn    % Initialize API environment
    fprintf('Initialize API environment ... \n');
nn    % Configuration for data generation
n    opts.mode = 'iterative';
    opts.order = {'Process_definitions'};  % Nur Prozessdefinitionen für einen schnellen Test
n    opts.outputFile = 'test_bpmn_outPut.xml';
    opts.productDescription = 'A simple order system for an online bookstore';
nn    % Explicit determination of the OpenRouter model
    opts.model = 'Microsoft/Mai-DS-R1: Free';
n    fprintf('Start test generation with the following model: %s \n', opts.model);
n    % Generate the data with the generator controller
nn    fprintf('\ndes were successfully generated! \n');
    fprintf('Temporary file should be found under Doc/Temporary/Temp_Generated_Data.json \n');
    fprintf('BPMN output file should be found under Doc/Temporary/%S \n', opts.outputFile);
nn    fprintf('\n [error] generation failed: %s \n', ME.message);
n    % Spend detailed stack trace
n        fprintf('\nstack-trace: \n');
n            fprintf('In %s (line %d): %s \n', ...
nnnn