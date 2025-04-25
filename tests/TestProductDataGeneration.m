%% Test Productdageneration.M
% Test for the iterative generation of BPMN data for a specific product
% This script uses the generator controller to a complete BPMN process
% to generate for a specific product, with all modules and parts
n% Clean up the area
nnnn% Add paths
addpath(fullfile(pwd, '..', 'SRC'));
addpath(fullfile(pwd, '..', 'SRC', 'API'));
addpath(fullfile(pwd, '..', 'SRC', 'util'));
n% Product name for generation
productName = 'Industrial lidar sensor with integrated camera';
nn    % Initialize API environment
    fprintf('Initialize API environment ... \n');
nn    % Configuration for complete data generation
n    opts.mode = 'iterative';
    % Full generation order for a complex product
    opts.order = {'Process_definitions', 'module', 'parts', 'subpars'};
n    opts.outputFile = 'product_bpmn_outPut.xml';
nnn    % Use OpenRouter model
    opts.model = 'Microsoft/Mai-DS-R1: Free';
n    fprintf('Start data generation for product: %s \n', productName);
    fprintf('Use model: %s \n', opts.model);
n    % Generate the data with the generator controller
    fprintf('Start iterative data generation ... \n');
nnnn    fprintf('\nann data generation successfully completed!(%.2f seconds) \n', elapsed);
    fprintf('Temporary file with generated data: Doc/Temporary/Temp_generated_Data.json \n');
    fprintf('BPMN output file: Doc/Temporary/%S \n', opts.outputFile);
n    % Additional information for analysis
    fprintf('\nthe generated BPMN file contains: \n');
    fprintf('- Process definition for the product \n');
    fprintf('- Modules and their dependencies \n');
    fprintf('- Parts and sub -parts for each module \n');
    fprintf('- All sequence flows between the elements \n');
    fprintf('- Resource assignments for the process steps \n');
nn    fprintf('\n❌ [error] generation failed: %s \n', ME.message);
n    % Spend detailed stack trace
n        fprintf('\nstack-trace: \n');
n            fprintf('In %s (line %d): %s \n', ...
nnnn