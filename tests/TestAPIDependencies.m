%% Testapidependencies.m
% Test script for checking whether all API dependencies are correctly set up
% This script checks whether all classes required for data generation are available
n% Clean up the area
nnnn% Add paths explicitly
fprintf('Add the necessary paths ... \n');
nif endsWith(currentDir, 'tests')
    % If we are already in the test directory
    addpath(fullfile(pwd, '..', 'SRC'));
    addpath(fullfile(pwd, '..', 'SRC', 'API'));
    addpath(fullfile(pwd, '..', 'SRC', 'util'));
    rootDir = fullfile(pwd, '..');
n    % When we are in the main directory
    addpath(fullfile(pwd, 'SRC'));
    addpath(fullfile(pwd, 'SRC', 'API'));
    addpath(fullfile(pwd, 'SRC', 'util'));
nnnfprintf('Search for necessary components ... \n');
fprintf('-----------------------------------------');
n% Test initialization of the API environment
fprintf('Initialize API environment:');
if exist('initapien vironment', 'file') == 2
    fprintf('✅ Found \n');
nn        fprintf('✅ Successful initialized \n');
n        fprintf('❌ Initialization errors: %s \n', ME.message);
nn    fprintf('❌ not found \n');
nn% Check whether all the required classes are available
n    'Apiconfig', 
    'Apical', 
    'Dating', 
    'Generator controller', 
    'Promptbuilder', 
    'Schemaloader', 
    'Validationlayer', 
    'BpmndatabaseConnector', 
    'Bpmndiagramexporter'
nnfprintf('\n over test of the required classes: \n');
nnn    fprintf('- Class %S:', className);
    if exist(className, 'class') == 8
        fprintf('✅ Found \n');
n        fprintf('❌ not found \n');
nn        % Search for the associated file to see if it exists
        fprintf('Search for %S.M file:', className);
n            fullfile(rootDir, 'SRC', [className '.']),
            fullfile(rootDir, 'SRC', 'API', [className '.']),
            fullfile(rootDir, 'SRC', 'util', [className '.'])
nnnn            if exist(classPaths{j}, 'file') == 2
                fprintf('✅ FILE Found at: %s \n', classPaths{j});
nnnnnn            fprintf('❌ file not found \n');
nnnn% Test API configuration
fprintf('Test \napiconfig settings:');
if exist('Apiconfig', 'class') == 8
nn        fprintf('✅ successful \n');
        fprintf('- Standard model: %s \n', apiOpts.model);
        fprintf('- Standard temperature: %.2f \n', apiOpts.temperature);
n        fprintf('❌ error: %s \n', ME.message);
nn    fprintf('❌ Apiconfig class not available \n');
nn% Test whether generator controller.
fprintf('Test \ngenerator controller access:');
if exist('Generator controller', 'class') == 8
n        % Create an empty option object (do not actually execute)
        testOpts = struct('fashion', 'iterative', 'order', {{'test'}}, 'batchsize', 1);
        methodInfo = methods('Generator controller');
        if any(strcmp(methodInfo, 'Generate conductor'))
            fprintf('✅ METHE REABERITY Found \n');
n            fprintf('❌ Method of generate conductor not found \n');
            fprintf('Available methods: %s \n', strjoin(methodInfo, ',,'));
nn        fprintf('❌ error: %s \n', ME.message);
nn    fprintf('❌ generator controller class not available \n');
nnfprintf('\n -------------------------------------------');
n    fprintf('All necessary components were found. \n');
    fprintf('Take them"generate_bpmn_data(\'Your product \', 4, \'output.xml \', struct(\'Debug \', true));"to test the data generation. \n');
n    fprintf('⚠️ Some components were not found.Please fix the problems before you execute the data generation. \n');
n