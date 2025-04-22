%% Test Script for Generating BPMN Data for a Lidar Camera Production Process

fprintf('Starting Enhanced Lidar Camera Data Generation Test...\n');

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

    % --- Enhanced Configuration ---
    opts = struct();
    
    % More detailed product description with manufacturing process information
    opts.productDescription = ['A high-precision lidar camera system for autonomous vehicle applications, ' ...
                             'including optical sensors, laser emitters, calibration components, and connection cables. ' ...
                             'Manufactured by EDFCams at their Argentina facility. ' ...
                             'The manufacturing process involves component assembly, calibration, testing, ' ...
                             'quality control, and packaging stages. Multiple departments are involved: ' ...
                             'parts receiving, component preparation, assembly line, testing department, ' ...
                             'quality assurance, and packaging division.'];
    
    % Optimized generation order to ensure proper relationship establishment
    % First define processes and pools, then core elements, then connections
    opts.order = {
        'process_definitions',    % Define top-level processes first
        'pools_and_lanes',        % Define organizational structure
        'bpmn_elements',          % Create basic elements 
        'tasks',                  % Define specific tasks
        'gateways',               % Define decision points
        'events',                 % Define events
        'data_objects',           % Define data objects
        'data_stores'             % Define data stores
    };
    
    % Increase batch size for more coherent generation
    opts.batchSize = 8;  
    
    % Keep the file in doc/temporary directory
    opts.outputFile = 'lidar_camera_production_process.bpmn';
    
    % Additional parameters to guide the generation
    opts.additionalParams = struct();
    opts.additionalParams.targetGranularity = 'detailed';    % Generate a detailed BPMN
    opts.additionalParams.companyDepartments = {'Manufacturing', 'Quality Control', 'Engineering', 'Packaging'};
    opts.additionalParams.requireParallelProcessing = true;  % Ensure the use of parallel gateways
    opts.additionalParams.includeProbabilisticPaths = true;  % Include exclusive gateways with conditions

    fprintf('Enhanced Configuration:\n');
    disp(opts);

    % --- Pre-Generation Checks ---
    fprintf('Performing pre-generation validation checks...\n');
    
    % Verify token exists
    if isempty(getenv('GITHUB_API_TOKEN'))
        error('GITHUB_API_TOKEN is not set in the environment. Required for API calls.');
    end
    
    % Ensure output directory exists
    outputDir = 'doc/temporary';
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
        fprintf('Created output directory: %s\n', outputDir);
    end

    % --- Run Generation ---
    fprintf('Calling GeneratorController.generateIterative...\n');
    tic; % Start timing the generation
    GeneratorController.generateIterative(opts);
    generationTime = toc; % End timing
    fprintf('Generation completed in %.2f seconds.\n', generationTime);

    % --- Post-Generation Validation ---
    fprintf('\nPerforming post-generation validation checks...\n');
    
    % Check if the temporary data file exists
    tempDataPath = fullfile('doc/temporary', 'temp_generated_data.json');
    if ~exist(tempDataPath, 'file')
        warning('Temporary data file not generated at %s', tempDataPath);
    else
        % Read the temporary JSON data to check its structure
        try
            fid = fopen(tempDataPath, 'r');
            if fid == -1
                warning('Could not open temporary data file for reading');
            else
                tempData = fread(fid, '*char')';
                fclose(fid);
                
                % Parse the JSON to check structure (just validation, no need to store)
                tempJson = jsondecode(tempData);
                
                % Check presence of key components
                if isfield(tempJson, 'allElements')
                    fprintf('✓ Generated elements: %d\n', numel(tempJson.allElements));
                else
                    warning('No elements found in generated data');
                end
                
                if isfield(tempJson, 'allFlows')
                    fprintf('✓ Generated flows: %d\n', numel(tempJson.allFlows));
                else
                    warning('No flows found in generated data');
                end
            end
        catch ME
            warning('Error validating temporary data: %s', ME.message);
        end
    end
    
    % Check if final BPMN file exists
    finalBpmnPath = fullfile('doc/temporary', opts.outputFile);
    if ~exist(finalBpmnPath, 'file')
        warning('Final BPMN file was not generated at %s', finalBpmnPath);
    else
        % Check file size
        fileInfo = dir(finalBpmnPath);
        fprintf('✓ Final BPMN file size: %.2f KB\n', fileInfo.bytes/1024);
        
        % Optional: Use BPMNValidator to validate the generated file
        try
            validator = BPMNValidator(finalBpmnPath);
            validator.validate();
            results = validator.getValidationResults();
            
            fprintf('BPMN Validation Results:\n');
            fprintf('  Errors: %d\n', numel(results.errors));
            fprintf('  Warnings: %d\n', numel(results.warnings));
            
            if numel(results.errors) > 0
                fprintf('Top errors found:\n');
                maxDisplay = min(3, numel(results.errors));
                for i = 1:maxDisplay
                    fprintf('  - %s\n', results.errors{i});
                end
            end
        catch ME
            warning('BPMNValidator error: %s', ME.message);
        end
    end

    fprintf('\nData generation process completed.\n');
    fprintf('✓ Temporary data: %s\n', tempDataPath);
    fprintf('✓ Final BPMN: %s\n', finalBpmnPath);

catch ME
    fprintf('\n❌ ERROR during data generation test ❌\n');
    fprintf('Error Identifier: %s\n', ME.identifier);
    fprintf('Error Message: %s\n', ME.message);
    fprintf('Stack Trace:\n');
    for k = 1:length(ME.stack)
        fprintf('  File: %s, Name: %s, Line: %d\n', ME.stack(k).file, ME.stack(k).name, ME.stack(k).line);
    end
    fprintf('-----------------------------------------\n');
end

fprintf('Lidar Camera Production Process Generation Test Finished.\n');
