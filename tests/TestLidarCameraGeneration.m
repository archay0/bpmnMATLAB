%% Test Script for Generating BPMN Data for a Lidar Camera Production Process
nfprintf('Starting Enhanced Lidar Camera Data Generation Test ... \n');
n% --- Set up ---
n    % Add Necessary Paths (Assuming Script is Run from Workspace Root or Tests Dir)
    if exist('../src', 'you')
        addpath('../src');
        addpath('../src/api');
        addpath('../src/util');
    elseif exist('SRC', 'you')
        addpath('SRC');
        addpath('SRC/API');
        addpath('SRC/Util');
n        error('Could not find SRC Directory.Run script from Workspace root or tests Directory.');
nn    % Initialize the API environment (contains load vireonment)
    if exist('initapien vironment', 'file') == 2
        fprintf('Initializing Api Environment ... \n');
nn        % Fallback on the old method
        if exist('../.env', 'file')
            loadEnvironment('../.env');
        elseif exist('.env', 'file')
            loadEnvironment('.env');
n            warning('Test lidar cameragenization: NoenV', '.ENV file not found.Api Calls Might Fail IF Api Key is not set.');
nnn    % --- Enhanced configuration ---
nn    % More Detailed Product Description with Manufacturing Process Information
    opts.productDescription = ['A high-precision LIDAR CAMERA SYSTEM for Autonomous Vehicle Applications,' ...
                             'Including optical sensors, laser emitters, Calibration Components, and Connection Cables.' ...
                             'Manufactured by Edfcams at their Argentina Facility.' ...
                             'The Manufacturing Process Involves Component Assembly, Calibration, Testing,' ...
                             'Quality Control, and Packaging Stages.Multiple departments are involved:' ...
                             'Parts Receiving, Component Preparation, Assembly Line, Testing Department,' ...
                             'Quality Assurance, and Packaging Division.'];
n    % Optimized generation Order to Ensure Proper Relationship establishment
    % First Define Processes and Pools, Then Core Elements, Then Connections
n        'Process_definitions',    % Define top-level processes first
        'Pools_and_lanes',        % Define organizational structure
        'bpmn_elements',          % Create basic elements 
        'tasks',                  % Define specific tasks
        'gateways',               % Define decision points
        'events',                 % Define events
        'data_objects',           % Define data objects
        'data_stores'             % Define data stores
nn    % Increase Batch Size for more coherent generation
nn    % Keep the File in Doc/Temporary Directory
    opts.outputFile = 'lidar_camera_production_process.bpmn';
n    % Additional parameters to guide the generation
n    opts.additionalParams.targetGranularity = 'detailed';    % Generate a detailed BPMN
    opts.additionalParams.companyDepartments = {'Manufacturing', 'Quality Control', 'Engineering', 'Packaging'};
nnn    % API-specific configuration for open routers
    if exist('Apiconfig', 'class') == 8
        % Load Default API options from Apiconfig
nnnnn        % Manual Defaults IF Apiconfig is not Available
        opts.model = 'Microsoft/Mai-DS-R1: Free';
nnnn    % Override System Message for Better BPMN Generation
    opts.system_message = ['You are a bpmn (Business Process Model and Notation) Expert.', ...
                          'Generates Detailed, Consistent BPMN Processes with Proper Semantics.', ...
                          'FOCUS on Creating Structured JSON OUTPUT that follows database scheme requirements.'];
n    fprintf('Enhanced configuration: \n');
nn    % --- pre-generation checks ---
    fprintf('Performing pre-generation validation checks ... \n');
n    % Verify Api Key Exist (OpenRouter Instead of Github)
    if isempty(getenv('OpenRouter_api_Key'))
        error('OpenRouter_api_Key is not set in the environment.required for api calls.');
nn    % Ensure Output Directory Exists
    outputDir = 'Doc/Temporary';
    if ~exist(outputDir, 'you')
n        fprintf('Created output directory: %s \n', outputDir);
nn    % --- Run generation ---
    fprintf('Calling GeneratorController.', opts.model);
nnn    fprintf('Generation Completed in %.2f Seconds. \n', generationTime);
n    % --- Post generation validation ---
    fprintf('\nperforming post-generation validation checks ... \n');
n    % Check If the Temporary Data File Exists
    tempDataPath = fullfile('Doc/Temporary', 'temp_generated_data.json');
    if ~exist(tempDataPath, 'file')
        warning('Temporary Data File Not Generated At %S', tempDataPath);
n        % Read the Temporary Json Data to Check Its Structure
n            fid = fopen(tempDataPath, 'r');
n                warning('Could not Open Temporary Data File for Reading');
n                tempData = fread(fid, '*Char')';
nn                % Parse The Json to Check Structure (Just Validation, No Need To Store)
nn                % Check Presence of Key Components
                if isfield(tempJson, 'all -elements')
                    fprintf('✓ Generated Elements: %d \n', numel(tempJson.allElements));
n                    warning('No Elements Found in Generated Data');
nn                if isfield(tempJson, 'allflows')
                    fprintf('✓ Generated flows: %d \n', numel(tempJson.allFlows));
n                    warning('No Flows Found in Generated Data');
nnn            warning('Error validating temporary data: %s', ME.message);
nnn    % Check If Final BPMN File Exists
    finalBpmnPath = fullfile('Doc/Temporary', opts.outputFile);
    if ~exist(finalBpmnPath, 'file')
        warning('Final BPMN File was not generated at %s', finalBpmnPath);
n        % Check file size
n        fprintf('✓ Final BPMN File Size: %.2F KB \n', fileInfo.bytes/1024);
n        % Optional: Use BPMNValidator to validate the generated file
nnnnn            fprintf('Bpmn validation results: \n');
            fprintf('Errors: %d \n', numel(results.errors));
            fprintf('Warning: %d \n', numel(results.warnings));
nn                fprintf('Top Errors Found: \n');
nn                    fprintf('- %S \n', results.errors{i});
nnn            warning('Bpmnvalidator error: %s', ME.message);
nnn    fprintf('\ndata generation Process Completed. \n');
    fprintf('✓ Temporary data: %s \n', tempDataPath);
    fprintf('✓ Final BPMN: %S \n', finalBpmnPath);
nn    fprintf('\n❌ Error during data generation test ❌ \n');
    fprintf('Error identifier: %s \n', ME.identifier);
    fprintf('Error message: %s \n', ME.message);
    fprintf('Stack trace: \n');
n        fprintf('File: %S, name: %S, Line: %d \n', ME.stack(k).file, ME.stack(k).name, ME.stack(k).line);
n    fprintf('-------------------------------------------');
nnfprintf('Lidar Camera Production Process Generation Test Finished. \n');
