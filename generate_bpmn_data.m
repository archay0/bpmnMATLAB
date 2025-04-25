n% Generates_bpmn_Data - Cli for iterative BPMN Data Generation
% Usage: Generates_bpmn_data (Productdescription, BatchSize, Outputfile, Options)
% Productdescription: letter text description of the product
% Batchsize: Number of Rows via table by iteration
% Outputfile: Path to Save the Generated BPMN XML
% Options: (optional) Struct with Additional Configuration:
% .Model: llm Model to use (default: 'Microsoft/Mai-Ds-R1: Free')
% . Temperature: LLM Temperature (default: 0.7)
% . Debug: Enable debug output (Default: False)
nn        error('Usage: Generates_bpmn_data (Productdescription, Batchsize, Outputfile)');
nnnnn    % Add paths explicitly to ensure that all modules are found
    fprintf('Add the necessary paths ... \n');
    currentDir = fileparts(mfilename('fullpath'));
n    addpath(fullfile(currentDir, 'SRC'));
    addpath(fullfile(currentDir, 'SRC', 'API'));
    addpath(fullfile(currentDir, 'SRC', 'util'));
n    % Spend debug information on available classes
    fprintf('Check whether generator controller is available:');
    if exist('Generator controller', 'class') == 8
        fprintf('✅ yes \n');
n        fprintf('❌ No \n');
        % Try to find the file manually
        controllerPath = fullfile(currentDir, 'SRC', 'API', 'GeneratorController.M');
        if exist(controllerPath, 'file') == 2
            fprintf('The GeneratorController.M file was found, but does not seem to be recognized as a class. \n');
n            fprintf('The GeneratorController.M file was not found. \n');
nnn    % Initialize API environment, if possible
    if exist('initapien vironment', 'file') == 2
nnn    % Define generation Order for Multi-Level Data
    order = {'Process_definitions', 'module', 'parts', 'subpars'};
n    % Build options Struct
n    opts.mode = 'iterative';
nnnnn    % Set standard values ​​for API options
    if exist('Apiconfig', 'class') == 8
nnnnn        % Fallback if Apiconfig is not found
        opts.model = 'Microsoft/Mai-DS-R1: Free';
nnnn    % Overwriting with custom options, if specified
nnnnnnnn    fprintf('Start BPMN generation with model: %s \n', opts.model);
n    % Attempts to dynamically load generator controllers if it is not found
    if exist('Generator controller', 'class') ~= 8
        fprintf('Attempts to load generator controllers dynamically ... \n');
nn        % Try to load the class manually
        controllerPath = fullfile(currentDir, 'SRC', 'API', 'GeneratorController.M');
        if exist(controllerPath, 'file') == 2
nn            fprintf('Class %s manually loaded. \n', className);
nnn    % Invoke generator controller
nnn        fprintf('Errors when executing generator controller.');
        fprintf('Error message: %s \n', ME.message);
        fprintf('Stack trace: \n');
n            fprintf('In %s (line %d) \n', ME.stack(i).name, ME.stack(i).line);
nn        % Alternatively, test over run
n            fprintf('\nucial alternative execution ... \n');
            controllerScript = fullfile(currentDir, 'SRC', 'API', 'GeneratorController.M');
            if exist(controllerScript, 'file') == 2
n                fprintf('Controller script executed. \n');
n                % Check again whether the class is now available
                if exist('Generator controller', 'class') == 8
                    fprintf('Generator controller now available, try again ... \n');
nn                    fprintf('Generator controller still not available as a class. \n');
nnn            fprintf('Alternative execution failed: %s \n', ME2.message);
nnn