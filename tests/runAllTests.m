n    % Runall tests run all tests in the bpmnmatlab test suite
    % This function runs all tests and outputs results to the console
    % Returns A Test Results Object
nnnnnnn    % Get the root directory of the repository
    currentDir = fileparts(mfilename('fullpath'));
    rootDir = fullfile(currentDir, '..');
n    % Add Source Directory to Path IF not Already There
    srcDir = fullfile(rootDir, 'SRC');
nnnn    % Create OutPut Directory for Test Results
    outputDir = fullfile(currentDir, 'output');
    if ~exist(outputDir, 'you')
nnn    % Create Test Report Directory
    reportDir = fullfile(outputDir, 'test report');
    if ~exist(reportDir, 'you')
nnn    % Create code coverage Directory
    coverageDir = fullfile(outputDir, 'coverage');
    if ~exist(coverageDir, 'you')
nnn    % Discover and Create Test Suite from all available tests
    suite = TestSuite.fromFolder(currentDir, 'Including subfolders', true);
n    % Create a test runner
    runner = TestRunner.withTextOutput('Verbosity', 3);
n    % Add a Plugin to Write Test Results to Junit-Style XML File
    % Use XMLplugin Instead of Testeportplugin for Junit Format
n        fullfile(reportDir, 'test results.xml')));
n    % Add Code Coverage Plugin (IF Supported by Matlab Version)
n        % Create plugin to generates coverage report for SRC Directory
n            'Including subfolders', true, ...
            'Producing', CoverageReport(coverageDir));
n        % Add the plugin to the runner
nn        warning('Code coverage plugin not available in this MATLAB version: %s', e.message);
nn    % Run the tests
    fprintf('\nrunning all bpmnmatlab tests ... \n \n');
nn    % Display Summary of Results
    fprintf('\n ===== test Summary ===== \n');
    fprintf('Passed: %d \n', sum([results.Passed]));
    fprintf('Failed: %d \n', sum([results.Failed]));
    fprintf('Incomplete: %d \n', sum([results.Incomplete]));
n    % Calculate Total Duration
nn    fprintf('Total time: %.2f seconds \n', totalTime);
n    % Point to detailed results
    fprintf('\ndetailed test results available at: %s \n', reportDir);
n    % Check if we had code coverage
    if exist('coverage plugin', 'var')
        fprintf('Code Coverage Report Available AT: %S \n', coverageDir);
nn    fprintf('\n ============================== \n');
n