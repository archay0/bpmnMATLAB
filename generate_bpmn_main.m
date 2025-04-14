function generate_bpmn_main(dbType, dbName, dbUser, dbPass, dbServer, dbPort, outputFile, processId)
    % Main entry point for compiled BPMN generation
    % Inputs are expected as strings.
    % processId is optional.
    %
    % Parameters:
    %   dbType - Database type ('mysql', 'postgresql', etc.)
    %   dbName - Database name
    %   dbUser - Database username
    %   dbPass - Database password
    %   dbServer - Database server address
    %   dbPort - Database port (as string or number)
    %   outputFile - Full path to save the generated BPMN file
    %   processId - (Optional) ID of the process to import
    
    %#function BPMNGenerator BPMNDatabaseConnector BPMNElements BPMNDiagramExporter BPMNValidator BPMNToSimulink
    
    disp('Starting BPMN generation...');
    startTime = tic;

    try
        % --- Input Validation and Conversion ---
        if nargin < 7
            error('Usage: generate_bpmn_main(dbType, dbName, dbUser, dbPass, dbServer, dbPort, outputFile, [processId])');
        end
        if nargin < 8
            processId = ''; % Default to importing the first process found
        end

        % Convert port string to number if necessary
        if ischar(dbPort) || isstring(dbPort)
            dbPortNum = str2double(dbPort);
            if isnan(dbPortNum)
                error('Invalid port number provided: %s', dbPort);
            end
        else
            dbPortNum = dbPort; % Assume it's already numeric if not char/string
        end

        connectionParams = struct(...
            'dbName', dbName, ...
            'username', dbUser, ...
            'password', dbPass, ...
            'server', dbServer, ...
            'port', dbPortNum ...
        );

        % --- Database Connection ---
        disp(['Connecting to ', dbType, ' database...']);
        dbConn = BPMNDatabaseConnector(dbType);
        success = dbConn.connect(connectionParams);
        if ~success
            % Error is thrown by connect method if it fails
            return;
        end

        % --- BPMN Generation ---
        disp('Initializing BPMN Generator...');
        bpmnGen = BPMNGenerator(outputFile); % Pass output file directly

        disp('Importing from database...');
        if isempty(processId)
            bpmnGen.importFromDatabase(dbConn); % Import default process
        else
            bpmnGen.importFromDatabase(dbConn, processId); % Import specific process
        end

        % --- Save Output ---
        disp(['Saving BPMN to file: ', outputFile]);
        bpmnGen.saveToBPMNFile();

        % --- Cleanup ---
        dbConn.disconnect();

        elapsedTime = toc(startTime);
        fprintf('BPMN generation completed successfully in %.2f seconds.\n', elapsedTime);
        
        % Success exit code when running as compiled
        if isdeployed
            exit(0);
        end

    catch ME
        disp('-----------------------------------------');
        disp('ERROR during BPMN generation:');
        disp(ME.identifier);
        disp(ME.message);
        for k=1:length(ME.stack)
           disp(['  at ', ME.stack(k).name, ' (line ', num2str(ME.stack(k).line), ')']);
        end
        disp('-----------------------------------------');

        % Attempt to disconnect if connection exists
        if exist('dbConn', 'var') && isvalid(dbConn) && dbConn.Connected
            try
                dbConn.disconnect();
            catch % Ignore errors during cleanup disconnect
            end
        end

        % Exit with a non-zero status code to indicate failure if running as compiled
        if isdeployed
            exit(1);
        else
            % Rethrow for regular MATLAB execution
            rethrow(ME);
        end
    end
end