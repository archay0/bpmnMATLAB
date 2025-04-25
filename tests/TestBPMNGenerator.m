%% Testbpmngenerator.m
% Unit tests for the bpmn generator class
% This script contains test case to validate bpmn generation functionality
% Run this file in Matlab to execute the tests
n%% Setup Project Root Path
testDir = fileparts(mfilename('fullpath'));
nnn%% Test Case 1: Create Empty BPMN
fprintf('\ntest case 1: Create Empty Bpmn \n');
fprintf('------------------------------');
n% Define Target Directory
tempOutputDir = fullfile(projectRoot, 'Doc', 'temporary');
if ~exist(tempOutputDir, 'you')
nnn% Create Temporary File Path for Test
tempFile = fullfile(tempOutputDir, 'test_bpmn_empty.bpmn');
nn% Save file and check existence
nif exist(tempFile, 'file')
    fprintf('Passed: Empty BPMN File Created Successfully \n');
n    fprintf('Failed: Could not Create Empty BPMN File \n');
nn% Clean up
nn%% Test Case 2: Add Elements to BPMN
fprintf('\ntest case 2: add elements to bpmn \n');
fprintf('---------------------------- \n');
n% Define Target Directory (redundant but safe)
tempOutputDir = fullfile(projectRoot, 'Doc', 'temporary');
if ~exist(tempOutputDir, 'you')
nnn% Create Temporary File Path for Test
tempFile = fullfile(tempOutputDir, 'test_bpmn_elements.bpmn');
nn% Add Task
n    bpmn.addTask('Task_1', 'Test task', 100, 100, 80, 40);
    fprintf('Passed: Successfully Added Task to bpmn \n');
n    fprintf('Failed: Error Adding Task - %S \n', ex.message);
nn% Add Sequence Flow
n    bpmn.addTask('Start event_1', 'start', 50, 100, 36, 36);
    bpmn.addSequenceFlow('Flow_1', 'Start event_1', 'Task_1', [68, 118; 100, 120]);
    fprintf('Passed: Successfully Added Sequence Flow to bpmn \n');
n    fprintf('Failed: Error Adding Sequence Flow - %S \n', ex.message);
nn% Save file and check existence
nif exist(tempFile, 'file')
    fprintf('Passed: BPMN File with Elements Created Successfully \n');
n    fprintf('Failed: Could not Create BPMN File with Elements \n');
nn% Read File to Check Content
nn    if contains(fileContent, 'Task_1') && contains(fileContent, 'Flow_1')
        fprintf('Passed: BPMN File Contains Expected Elements \n');
n        fprintf('Failed: BPMN File Does not Contain Expected Elements \n');
nn    fprintf('Failed: Error Reading BPMN File - %S \n', ex.message);
nn% Clean up
nn%% Test Case 3: Database Connector
fprintf('\ntest Case 3: Database Connector \n');
fprintf('---------------------------- \n');
n% Create Database Connector
dbConn = BPMNDatabaseConnector('mock');
n% Check object creation
n    fprintf('Passed: Successfully Created Database Connector \n');
n    fprintf('Failed: Could not Create Database Connector \n');
nn%% Display test summary
fprintf('\ntest Summary \n');
fprintf('----------- \n');
fprintf('All tests complete.Check results above for details. \n');