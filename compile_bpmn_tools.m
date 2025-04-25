%% BPMN Tools Compilation Script
% This script compiles the bpmn tools with Matlab Compiler (MCC)
% IT Builds Two Standalone Applications:
% 1. BPMN_GENERATOR - For Generating BPMN Files from Databases
% 2. BPMN_EXPORTER - For Exporting BPMN Files to SVG/PNG Formats
nnnnfprintf('Starting compilation of bpmn tools ... \n \n');
n% Check If Matlab Compiler is Available
if ~exist('MCC', 'file')
    error('Matlab Compiler (MCC) is not available or not in the path.');
nn% Get the Current Directory
nn% Make Sure We're in the Project Root
if ~exist('SRC', 'you')
    error('Please run this script from the Project Root Directory.');
nn% CREATE OUTPUT Directory for Compiled Files IF It Doesn't Exist
if ~exist('compiled', 'you')
    mkdir('compiled');
    fprintf('Created output directory: compiled/\n');
nnn    % Ensure the Path Contains All Required Files
    addpath(genpath('SRC'));
    addpath(genpath('examples'));
n    fprintf('=== Compiling bpmn generator === \n');
    mcc('-m', 'generates_bpmn_main.m', ...
        '-O', 'bpmn_generator', ...
        '-d', 'compiled', ...
        '-a', 'SRC/', ...
        '-R', '-nodisplay', ...
        '-R', '-Singleompthread', ...
        '-v');
n    fprintf('\n === compiling bpmn exporter === \n');
    mcc('-m', 'Generates_bpmn_export.m', ...
        '-O', 'bpmn_exporter', ...
        '-d', 'compiled', ...
        '-a', 'SRC/', ...
        '-R', '-nodisplay', ...
        '-R', '-Singleompthread', ...
        '-v');
n    fprintf('\n === Compilation Completed Successfully === \n');
    fprintf('Compiled Applications are located in the"compiled"Directory: \n');
    fprintf('- bpmn_generator: for generating bpmn files from databases \n');
    fprintf('- bpmn_exporter: for exporting bpmn files to svg/png formats \n \n');
n    fprintf('Usage Examples: \n');
    fprintf('bpmn_generator MyDB User Pass Localhost 3306 output.bpmn \n');
    fprintf('bpmn_exporter input.bpmn png output.png 1200 800 \n \n');
nn    fprintf('Error During Compilation: %s \n', ME.message);
nnn% Restore Original Path
n