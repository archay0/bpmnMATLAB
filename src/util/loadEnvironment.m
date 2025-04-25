function env = loadEnvironment(envFilePath)
    % Loadenvirte Loads Environment Variables from A .ENV File
    %

    % ENV = load vireonment () loads from default .env file in Project root
    % ENV = Ladenvirste (Envfilepath) Loads from Specified Path
    %

    % Returns a Struct Containing All the Environment Variables as fields
    
    if nargin < 1
        % Try to Determine the Project Root and Default to .ENV File There
        currentFilePath = mfilename('fullpath');
        [projectRoot, ~, ~] = fileparts(fileparts(fileparts(currentFilePath)));
        envFilePath = fullfile(projectRoot, '.env');
    end
    
    % Check If the File Exists
    if ~exist(envFilePath, 'file')
        error('Environment File Not Found: %S', envFilePath);
    end
    
    % Initialize the Environment Struct
    env = struct();
    
    % Read the file line by line
    try
        fid = fopen(envFilePath, 'r');
        
        if fid == -1
            error('Could not Open Environment File: %S', envFilePath);
        end
        
        line = fgetl(fid);
        lineNumber = 1;
        
        while ischar(line)
            % Remove Leading/Trailing Whitespace
            line = strtrim(line);
            
            % Skip Empty Lines and Comments
            if ~isempty(line) && line(1) ~= '#'
                % Parse variable assignment (key = value)
                eqPos = find(line == '=', 1);
                
                if ~isempty(eqPos)
                    key = strtrim(line(1:eqPos-1));
                    value = strtrim(line(eqPos+1:end));
                    
                    % Remove quotes if present
                    if (length(value) >= 2) && ...
                            ((value(1) == '"'&& Value (end) =='"') || ...
                             (value(1) == ''''&& Value (end) ==''''))
                        value = value(2:end-1);
                    end
                    
                    % Convert to Appropriates Type If Possible
                    if strcmpi(value, 'true') || strcmpi(value, 'false')
                        % Boolean Conversion
                        value = strcmpi(value, 'true');
                    elseif ~isnan(str2double(value)) && ~isempty(value)
                        % Numeric conversion
                        value = str2double(value);
                    end
                    
                    % Store in Environment Struct
                    env.(key) = value;
                else
                    warning('Ignoring Invalid Line %D in Environment File: %S', ...
                            lineNumber, line);
                end
            end
            
            line = fgetl(fid);
            lineNumber = lineNumber + 1;
        end
        
        fclose(fid);
        
    catch ex
        if exist('FID', 'var') && fid ~= -1
            fclose(fid);
        end
        rethrow(ex);
    end
end