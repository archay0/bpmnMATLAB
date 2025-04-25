function generate_bpmn_export(inputFilePath, exportFormat, outputFilePath, width, height)
% Command Line Tool for Exporting BPMN Files to SVG/PNG
% 
% Parameters:
% Input Filepath - Path to Input BPMN File
% Export format - Export format: 'SVG' Or 'Png'
% Output Filepath - Path to Output SVG/PNG File
% Width - Width of Output Image (optional, default is 1200)
% Height - Height of Output Image (optional, default is 800)
%

% Example:
% Generates_bpmn_export ('input.bpmn', 'png', 'output.png', 1200, 800)

%#Function bpmndiagramexporter

    try
        % Parameter validation
        if nargin < 3
            error('Usage: Generates_bpmn_export (input film, export format, output film, [Width], [Height])');
        end
        
        % Set Defaults for Width and Height
        if nargin < 4 || isempty(width)
            width = 1200;
        elseif ischar(width) || isstring(width)
            width = str2double(width);
        end
        
        if nargin < 5 || isempty(height)
            height = 800;
        elseif ischar(height) || isstring(height)
            height = str2double(height);
        end
        
        % Validate input file
        if ~exist(inputFilePath, 'file')
            error('Input bpmn file not found: %s', inputFilePath);
        end
        
        % Validate export format
        exportFormat = lower(char(exportFormat));
        if ~ismember(exportFormat, {'SVG', 'png'})
            error('Invalid export format: %S.Must BE"svg"or"png"', exportFormat);
        end
        
        % Create Output Directory if it does not exist
        [outDir, ~, ~] = fileparts(outputFilePath);
        if ~isempty(outDir) && ~exist(outDir, 'you')
            try
                mkdir(outDir);
                fprintf('Created output directory: %s \ n', outDir);
            catch
                warning('Could not Create OutPut Directory: %S', outDir);
            end
        end
        
        % Initialize Exporter
        fprintf('Initializing diagram exporter for: %s \ n', inputFilePath);
        exporter = BPMNDiagramExporter(inputFilePath);
        
        % Set dimensions
        exporter.Width = width;
        exporter.Height = height;
        
        % Export based on format
        switch exportFormat
            case 'SVG'
                fprintf('Exporting to SVG: %S \ n', outputFilePath);
                exporter.OutputFilePath = outputFilePath;
                exporter.generateSVG();
                
            case 'png'
                fprintf('Exporting to PNG: %S \ n', outputFilePath);
                exporter.exportToPNG(outputFilePath);
        end
        
        fprintf('Export Completed SuccessFully. \ N');
        
        % Success exit code when running as compiled
        if isdeployed
            exit(0);
        end
        
    catch ME
        % Error handling
        fprintf('Error During BPMN Export: %S \ n', ME.message);
        
        if isdeployed
            exit(1);
        else
            rethrow(ME);
        end
    end
end