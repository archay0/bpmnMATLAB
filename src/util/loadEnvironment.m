function env = loadEnvironment(envFilePath)
    % LOADENVIRONMENT Loads environment variables from a .env file
    %
    % env = loadEnvironment() loads from default .env file in project root
    % env = loadEnvironment(envFilePath) loads from specified path
    %
    % Returns a struct containing all the environment variables as fields
    
    if nargin < 1
        % Try to determine the project root and default to .env file there
        currentFilePath = mfilename('fullpath');
        [projectRoot, ~, ~] = fileparts(fileparts(fileparts(currentFilePath)));
        envFilePath = fullfile(projectRoot, '.env');
    end
    
    % Check if the file exists
    if ~exist(envFilePath, 'file')
        error('Environment file not found: %s', envFilePath);
    end
    
    % Initialize the environment struct
    env = struct();
    
    % Read the file line by line
    try
        fid = fopen(envFilePath, 'r');
        
        if fid == -1
            error('Could not open environment file: %s', envFilePath);
        end
        
        line = fgetl(fid);
        lineNumber = 1;
        
        while ischar(line)
            % Remove leading/trailing whitespace
            line = strtrim(line);
            
            % Skip empty lines and comments
            if ~isempty(line) && line(1) ~= '#'
                % Parse variable assignment (KEY=VALUE)
                eqPos = find(line == '=', 1);
                
                if ~isempty(eqPos)
                    key = strtrim(line(1:eqPos-1));
                    value = strtrim(line(eqPos+1:end));
                    
                    % Remove quotes if present
                    if (length(value) >= 2) && ...
                            ((value(1) == '"' && value(end) == '"') || ...
                             (value(1) == '''' && value(end) == ''''))
                        value = value(2:end-1);
                    end
                    
                    % Convert to appropriate type if possible
                    if strcmpi(value, 'true') || strcmpi(value, 'false')
                        % Boolean conversion
                        value = strcmpi(value, 'true');
                    elseif ~isnan(str2double(value)) && ~isempty(value)
                        % Numeric conversion
                        value = str2double(value);
                    end
                    
                    % Store in environment struct
                    env.(key) = value;
                else
                    warning('Ignoring invalid line %d in environment file: %s', ...
                            lineNumber, line);
                end
            end
            
            line = fgetl(fid);
            lineNumber = lineNumber + 1;
        end
        
        fclose(fid);
        
    catch ex
        if exist('fid', 'var') && fid ~= -1
            fclose(fid);
        end
        rethrow(ex);
    end
end