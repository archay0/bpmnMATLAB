%% BPMN Tools Compilation Script
% This script compiles the BPMN tools with MATLAB Compiler (MCC)
% It builds two standalone applications:
% 1. bpmn_generator - For generating BPMN files from databases
% 2. bpmn_exporter - For exporting BPMN files to SVG/PNG formats

close all;
clear all;

fprintf('Starting compilation of BPMN tools...\n\n');

% Check if MATLAB Compiler is available
if ~exist('mcc', 'file')
    error('MATLAB Compiler (MCC) is not available or not in the path.');
end

% Get the current directory
currentDir = pwd;

% Make sure we're in the project root
if ~exist('src', 'dir')
    error('Please run this script from the project root directory.');
end

% Create output directory for compiled files if it doesn't exist
if ~exist('compiled', 'dir')
    mkdir('compiled');
    fprintf('Created output directory: compiled/\n');
end

try
    % Ensure the path contains all required files
    addpath(genpath('src'));
    addpath(genpath('examples'));
    
    fprintf('=== Compiling BPMN Generator ===\n');
    mcc('-m', 'generate_bpmn_main.m', ...
        '-o', 'bpmn_generator', ...
        '-d', 'compiled', ...
        '-a', 'src/', ...
        '-R', '-nodisplay', ...
        '-R', '-singleCompThread', ...
        '-v');
    
    fprintf('\n=== Compiling BPMN Exporter ===\n');
    mcc('-m', 'generate_bpmn_export.m', ...
        '-o', 'bpmn_exporter', ...
        '-d', 'compiled', ...
        '-a', 'src/', ...
        '-R', '-nodisplay', ...
        '-R', '-singleCompThread', ...
        '-v');
    
    fprintf('\n=== Compilation Completed Successfully ===\n');
    fprintf('Compiled applications are located in the "compiled" directory:\n');
    fprintf('  - bpmn_generator: For generating BPMN files from databases\n');
    fprintf('  - bpmn_exporter: For exporting BPMN files to SVG/PNG formats\n\n');
    
    fprintf('Usage examples:\n');
    fprintf('  bpmn_generator mysql mydb user pass localhost 3306 output.bpmn\n');
    fprintf('  bpmn_exporter input.bpmn png output.png 1200 800\n\n');
    
catch ME
    fprintf('ERROR during compilation: %s\n', ME.message);
    rethrow(ME);
end

% Restore original path
path(pathdef);