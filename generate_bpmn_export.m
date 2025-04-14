function generate_bpmn_export(inputFilePath, exportFormat, outputFilePath, width, height)
% Command line tool for exporting BPMN files to SVG/PNG
% 
% Parameters:
%   inputFilePath  - Path to input BPMN file
%   exportFormat   - Export format: 'svg' or 'png'
%   outputFilePath - Path to output SVG/PNG file
%   width          - Width of output image (optional, default is 1200)
%   height         - Height of output image (optional, default is 800)
%
% Example:
%   generate_bpmn_export('input.bpmn', 'png', 'output.png', 1200, 800)

%#function BPMNDiagramExporter

    try
        % Parameter validation
        if nargin < 3
            error('Usage: generate_bpmn_export(inputFilePath, exportFormat, outputFilePath, [width], [height])');
        end
        
        % Set defaults for width and height
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
            error('Input BPMN file not found: %s', inputFilePath);
        end
        
        % Validate export format
        exportFormat = lower(char(exportFormat));
        if ~ismember(exportFormat, {'svg', 'png'})
            error('Invalid export format: %s. Must be "svg" or "png"', exportFormat);
        end
        
        % Create output directory if it doesn't exist
        [outDir, ~, ~] = fileparts(outputFilePath);
        if ~isempty(outDir) && ~exist(outDir, 'dir')
            try
                mkdir(outDir);
                fprintf('Created output directory: %s\n', outDir);
            catch
                warning('Could not create output directory: %s', outDir);
            end
        end
        
        % Initialize exporter
        fprintf('Initializing diagram exporter for: %s\n', inputFilePath);
        exporter = BPMNDiagramExporter(inputFilePath);
        
        % Set dimensions
        exporter.Width = width;
        exporter.Height = height;
        
        % Export based on format
        switch exportFormat
            case 'svg'
                fprintf('Exporting to SVG: %s\n', outputFilePath);
                exporter.OutputFilePath = outputFilePath;
                exporter.generateSVG();
                
            case 'png'
                fprintf('Exporting to PNG: %s\n', outputFilePath);
                exporter.exportToPNG(outputFilePath);
        end
        
        fprintf('Export completed successfully.\n');
        
        % Success exit code when running as compiled
        if isdeployed
            exit(0);
        end
        
    catch ME
        % Error handling
        fprintf('ERROR during BPMN export: %s\n', ME.message);
        
        if isdeployed
            exit(1);
        else
            rethrow(ME);
        end
    end
end