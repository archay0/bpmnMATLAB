%% Test Script for Generating BPMN Data for a Lidar Camera

fprintf('Starting Lidar Camera Data Generation Test...\n');

% --- Setup ---
try
    % Add necessary paths (assuming script is run from workspace root or tests dir)
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

    % Load environment variables (like GITHUB_API_TOKEN)
    if exist('../.env', 'file')
        loadEnvironment('../.env');
    elseif exist('.env', 'file')
        loadEnvironment('.env');
    else
        warning('TestLidarCameraGeneration:NoEnv', '.env file not found. API calls might fail if GITHUB_API_TOKEN is not set.');
    end

    % --- Configuration ---
    opts = struct();
    opts.productDescription = 'A lidar camera product, including necessary cables and assembly steps. Manufactured by edfcams based in Argentina.';
    % Define the order of generation - start with process, then elements, flows, etc.
    % Adjust based on actual schema dependencies and desired generation flow
    opts.order = {'process_definitions', 'bpmn_elements', 'tasks', 'events', 'gateways', 'pools_and_lanes', 'data_objects', 'data_stores'}; % Example order, adjust as needed
    opts.batchSize = 5; % Generate a small number of items per step for testing
    opts.outputFile = 'lidar_camera_process.bpmn'; % Keep only the base filename here

    fprintf('Configuration:\n');
    disp(opts);

    % --- Run Generation ---
    fprintf('Calling GeneratorController.generateIterative...\n');
    % The controller will now handle placing the file in doc/temporary
    GeneratorController.generateIterative(opts);

    fprintf('Data generation process completed.\n');
    fprintf('Check temporary file: doc/temporary/temp_generated_data.json\n'); % Updated path
    fprintf('Check final output file: doc/temporary/%s\n', opts.outputFile); % Updated path

catch ME
    fprintf('\n--- ERROR during data generation test ---\n');
    fprintf('Error Identifier: %s\n', ME.identifier);
    fprintf('Error Message: %s\n', ME.message);
    fprintf('Stack Trace:\n');
    for k = 1:length(ME.stack)
        fprintf('  File: %s, Name: %s, Line: %d\n', ME.stack(k).file, ME.stack(k).name, ME.stack(k).line);
    end
    fprintf('-----------------------------------------\n');
end

fprintf('Lidar Camera Data Generation Test Finished.\n');
