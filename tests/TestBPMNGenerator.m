%% TestBPMNGenerator.m
% Unit tests for the BPMN Generator class
% This script contains test cases to validate BPMN generation functionality
% Run this file in MATLAB to execute the tests

%% Add repository to path
currentDir = pwd;
repoPath = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(repoPath));

%% Test Case 1: Create Empty BPMN
fprintf('\nTest Case 1: Create Empty BPMN\n');
fprintf('---------------------------\n');

% Create temporary file for test
tempFile = fullfile(tempdir, 'test_bpmn_empty.bpmn');
bpmn = BPMNGenerator(tempFile);

% Save file and check existence
bpmn.saveToBPMNFile();
if exist(tempFile, 'file')
    fprintf('PASSED: Empty BPMN file created successfully\n');
else
    fprintf('FAILED: Could not create empty BPMN file\n');
end

% Clean up
delete(tempFile);

%% Test Case 2: Add Elements to BPMN
fprintf('\nTest Case 2: Add Elements to BPMN\n');
fprintf('----------------------------\n');

% Create temporary file for test
tempFile = fullfile(tempdir, 'test_bpmn_elements.bpmn');
bpmn = BPMNGenerator(tempFile);

% Add task
try
    bpmn.addTask('Task_1', 'Test Task', 100, 100, 80, 40);
    fprintf('PASSED: Successfully added task to BPMN\n');
catch ex
    fprintf('FAILED: Error adding task - %s\n', ex.message);
end

% Add sequence flow
try
    bpmn.addTask('StartEvent_1', 'Start', 50, 100, 36, 36);
    bpmn.addSequenceFlow('Flow_1', 'StartEvent_1', 'Task_1', [68, 118; 100, 120]);
    fprintf('PASSED: Successfully added sequence flow to BPMN\n');
catch ex
    fprintf('FAILED: Error adding sequence flow - %s\n', ex.message);
end

% Save file and check existence
bpmn.saveToBPMNFile();
if exist(tempFile, 'file')
    fprintf('PASSED: BPMN file with elements created successfully\n');
else
    fprintf('FAILED: Could not create BPMN file with elements\n');
end

% Read file to check content
try
    fileContent = fileread(tempFile);
    if contains(fileContent, 'Task_1') && contains(fileContent, 'Flow_1')
        fprintf('PASSED: BPMN file contains expected elements\n');
    else
        fprintf('FAILED: BPMN file does not contain expected elements\n');
    end
catch ex
    fprintf('FAILED: Error reading BPMN file - %s\n', ex.message);
end

% Clean up
delete(tempFile);

%% Test Case 3: Database Connector
fprintf('\nTest Case 3: Database Connector\n');
fprintf('----------------------------\n');

% Create database connector
dbConn = BPMNDatabaseConnector('mock');

% Check object creation
if ~isempty(dbConn)
    fprintf('PASSED: Successfully created database connector\n');
else
    fprintf('FAILED: Could not create database connector\n');
end

%% Display test summary
fprintf('\nTest Summary\n');
fprintf('-----------\n');
fprintf('All tests completed. Check results above for details.\n');