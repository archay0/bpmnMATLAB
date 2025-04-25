function initAPIEnvironment()
% Initapienvironment initializes the environment for API calls
%

% This auxiliary function ensures that all the necessary paths are set
% and the ambient variables for API calls were loaded correctly.
%

% Use:
% Initapienvironment ();
%


    fprintf('Initialize API environment ... \ n');
    
    % Determine the project path
    currentFile = mfilename('fullpath');
    [apiPath, ~, ~] = fileparts(currentFile);
    srcPath = fileparts(apiPath);
    projectRoot = fileparts(srcPath);
    
    % Add important paths
    if ~any(contains(path, apiPath))
        fprintf('Add api path: %s \ n', apiPath);
        addpath(apiPath);
    end
    
    if ~any(contains(path, fullfile(srcPath, 'util')))
        fprintf('Add util path: %s \ n', fullfile(srcPath, 'util'));
        addpath(fullfile(srcPath, 'util'));
    end

    % Add bridges folder for datatobpmnbridge
    bridgesPath = fullfile(srcPath, 'bridges');
    if ~any(contains(path, bridgesPath))
        fprintf('Add bridges path: %s \ n', bridgesPath);
        addpath(bridgesPath);
    end
    
    % Environment variables shop
    try
        % Check whether .ENV has already been loaded
        if isempty(getenv('OpenRouter_api_Key'))
            fprintf('Charge ambient variables from .ENV file ... \ n');
            env = loadEnvironment(fullfile(projectRoot, '.env'));
            
            % Set ambient variables if found
            if isfield(env, 'OpenRouter_api_Key')
                setenv('OpenRouter_api_Key', env.OPENROUTER_API_KEY);
                fprintf('OpenRouter_api_Key successfully set. \ N');
            end
        else
            fprintf('OpenRouter_api_Key is already set. \ N');
        end
    catch ME
        warning('Errors when loading the environment variables: %S', ME.message);
    end
    
    % Check whether apical is available
    apiCallerPath = which('Apical');
    if isempty(apiCallerPath)
        error('Apicaller not found.check the installation.');
    else
        fprintf('Apicaller found in: %s \ n', apiCallerPath);
    end
    
    fprintf('API environment successfully initiated. \ N');
end