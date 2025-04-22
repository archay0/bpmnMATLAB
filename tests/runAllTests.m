function results = runAllTests()
    % runAllTests Run all tests in the bpmnMATLAB test suite
    %   This function runs all tests and outputs results to the console
    %   Returns a test results object
    
    import matlab.unittest.TestSuite;
    import matlab.unittest.TestRunner;
    import matlab.unittest.plugins.XMLPlugin; % Correct import for JUnit XML
    import matlab.unittest.plugins.CodeCoveragePlugin;
    import matlab.unittest.plugins.codecoverage.CoverageReport;
    
    % Get the root directory of the repository
    currentDir = fileparts(mfilename('fullpath'));
    rootDir = fullfile(currentDir, '..');
    
    % Add source directory to path if not already there
    srcDir = fullfile(rootDir, 'src');
    if ~contains(path, srcDir)
        addpath(srcDir);
    end
    
    % Create output directory for test results
    outputDir = fullfile(currentDir, 'output');
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end
    
    % Create test report directory
    reportDir = fullfile(outputDir, 'test-report');
    if ~exist(reportDir, 'dir')
        mkdir(reportDir);
    end
    
    % Create code coverage directory
    coverageDir = fullfile(outputDir, 'coverage');
    if ~exist(coverageDir, 'dir')
        mkdir(coverageDir);
    end
    
    % Discover and create test suite from all available tests
    suite = TestSuite.fromFolder(currentDir, 'IncludingSubfolders', true);
    
    % Create a test runner
    runner = TestRunner.withTextOutput('Verbosity', 3);
    
    % Add a plugin to write test results to JUnit-style XML file
    % Use XMLPlugin instead of TestReportPlugin for JUnit format
    runner.addPlugin(XMLPlugin.producingJUnitFormat(... 
        fullfile(reportDir, 'testResults.xml')));
    
    % Add code coverage plugin (if supported by MATLAB version)
    try
        % Create plugin to generate coverage report for src directory
        coveragePlugin = CodeCoveragePlugin.forFolder(srcDir, ...
            'IncludingSubfolders', true, ...
            'Producing', CoverageReport(coverageDir));
        
        % Add the plugin to the runner
        runner.addPlugin(coveragePlugin);
    catch e
        warning('Code coverage plugin not available in this MATLAB version: %s', e.message);
    end
    
    % Run the tests
    fprintf('\nRunning all bpmnMATLAB tests...\n\n');
    results = runner.run(suite);
    
    % Display summary of results
    fprintf('\n===== TEST SUMMARY =====\n');
    fprintf('Passed: %d\n', sum([results.Passed]));
    fprintf('Failed: %d\n', sum([results.Failed]));
    fprintf('Incomplete: %d\n', sum([results.Incomplete]));
    
    % Calculate total duration
    durations = [results.Duration];
    totalTime = sum(durations);
    fprintf('Total time: %.2f seconds\n', totalTime);
    
    % Point to detailed results
    fprintf('\nDetailed test results available at: %s\n', reportDir);
    
    % Check if we had code coverage
    if exist('coveragePlugin', 'var')
        fprintf('Code coverage report available at: %s\n', coverageDir);
    end
    
    fprintf('\n=========================\n');
end