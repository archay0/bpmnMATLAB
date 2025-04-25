function generate_bpmn_main(dbType, dbName, dbUser, dbPass, dbServer, dbPort, outputFile, processId)
    % Main Entry Point for Compiled BPMN Generation
    % Inputs are expected as strings.
    % Processid is optional.
    %

    % Parameters:
    % DBType - Database Type ('MySQL', 'Postgresql', etc.)
    % dbname - database name
    % DBuser - Database username
    % DB Pass - Database Password
    % DBServer - Database Server Address
    % DBPORT - DATABASE Port (as String or Number)
    % Outputfile - Full Path to Save the Generated BPMN File
    % Processid - (optional) ID of the Process to Import
    
    %#Function BPMNGENERATER BPMNDATABSECONNECTOR BPMNelements BPMndiagramexporter BPMnvalidator BPMNTOSIMULINK
    
    disp('Starting BPMN Generation ...');
    startTime = tic;

    try
        % --- Input validation and conversion ---
        if nargin < 7
            error('Usage: Generates_bpmn_Main (DBType, DBName, DBuser, DBPass, DBServer, DBPORT, OUTPUTFILE, [Processid])');
        end
        if nargin < 8
            processId = ''; % Default to importing the first process found
        end

        % Convert Port String to Number IF Necessary
        if ischar(dbPort) || isstring(dbPort)
            dbPortNum = str2double(dbPort);
            if isnan(dbPortNum)
                error('Invalid Port Number Provided: %S', dbPort);
            end
        else
            dbPortNum = dbPort; % Assume it's already numeric if not char/string
        end

        connectionParams = struct(...
            'dbname', dbName, ...
            'username', dbUser, ...
            'password', dbPass, ...
            'server', dbServer, ...
            'port', dbPortNum ...
        );

        % --- Database Connection ---
        disp(['Connecting to', dbType, 'Database ...']);
        dbConn = BPMNDatabaseConnector(dbType);
        success = dbConn.connect(connectionParams);
        if ~success
            % Error is thrown by Connect Method IF IT FAILS
            return;
        end

        % --- bpmn generation ---
        disp('Initializing BPMN generator ...');
        bpmnGen = BPMNGenerator(outputFile); % Pass output file directly

        disp('Importing from Database ...');
        if isempty(processId)
            bpmnGen.importFromDatabase(dbConn); % Import default process
        else
            bpmnGen.importFromDatabase(dbConn, processId); % Import specific process
        end

        % --- Save output ---
        disp(['Saving bpmn to file:', outputFile]);
        bpmnGen.saveToBPMNFile();

        % --- Cleanup ---
        dbConn.disconnect();

        elapsedTime = toc(startTime);
        fprintf('BPMN Generation Completed Successfully in %.2f Seconds. \ N', elapsedTime);
        
        % Success exit code when running as compiled
        if isdeployed
            exit(0);
        end

    catch ME
        disp('-----------------------------------');
        disp('Error During BPMN Generation:');
        disp(ME.identifier);
        disp(ME.message);
        for k=1:length(ME.stack)
           disp(['at', ME.stack(k).name, '(line', num2str(ME.stack(k).line), ')))']);
        end
        disp('-----------------------------------');

        % Attempt to Disconnect IF Connection Exists
        if exist('dbconn', 'var') && isvalid(dbConn) && dbConn.Connected
            try
                dbConn.disconnect();
            catch % Ignore errors during cleanup disconnect
            end
        end

        % Exit with a non-zero status code to indicate failure if running as compiled
        if isdeployed
            exit(1);
        else
            % Rethrow for Regular Matlab Execution
            rethrow(ME);
        end
    end
end