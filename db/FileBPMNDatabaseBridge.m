n    % Filebpmndatabasebridge bridges BpmndatabaseConnector and Filebasedbpmndatabase
    % This class provides methods that match bpmndatabaseConnector's static methods
    % While forwarding calls to a filebasedbpmndatabase instance
nnnnnnnnn            % Constructor Initializes the Bridge and Underlying Filebasedbpmndatabase
            % ProjectName: Name of the Project (Used for Directory Naming)
            % Options: Optional Configuration Parameters
nn                projectName = 'default_project';
nnnnnnnnnn                % Initialize The File-Based Database
nnn                fprintf('Filebpmndatabasebridge initialized for project: %s \n', obj.ProjectName);
n                error('Filebpmndatabasebridge: Initerror', ...
                      'Failed to initialize database bridge: %s', ME.message);
nnnn            % Insert rows Into a table, matching bpmndatabaseeconnector.inszrows interface
            % Tablename: Name of the Table (Collection)
            % Rows: Structure Array of Data to Insert
            % Returns: Array of inserted IDS
nn                error('Filebpmndatabasebridge: Notinitialized', 'Bridge not initialized');
nnn                % Forward the Call to the File-Based Database
nn                error('Filebpmndatabasebridge: Advertisement', ...
                      'Failed to insert rows: %s', ME.message);
nnnn            % Fetch Data from Specified Tables, Matching BPMndatabaseConnector.fetchall Interface
            % Tablename: Cell Array of Table Names to fetch from
            % Returns: Structure Where Each Field Corresponds to a Table
nn                error('Filebpmndatabasebridge: Notinitialized', 'Bridge not initialized');
nnn                % Ensure Tablenames is a Cell Array
nnnn                % Initialize Result Structure
nn                % Fetch data for each table
nnnn                    % Store in Result Structure
nnn                error('Filebpmndatabasebridge: Fetcheror', ...
                      'Failed to fetch data: %s', ME.message);
nnnn            % Export All Data to a Single Consolidated Json File
            % Outputpath: Path Where to Save the File
nn                error('Filebpmndatabasebridge: Notinitialized', 'Bridge not initialized');
nnnnn                error('Filebpmndatabasebridge: Exporterror', ...
                      'Failed to export data: %s', ME.message);
nnnn            % Get a Summary of the Database Contents
nn                error('Filebpmndatabasebridge: Notinitialized', 'Bridge not initialized');
nnnnn                error('Filebpmndatabasebridge: Summaryerror', ...
                      'Failed to get Summary: %S', ME.message);
nnnnn        % Static Methods that Mirror Those in BPMndatabaseConnector
nn            % Get or Create to Instance of the Bridge
            % This provides A Singleton-Like Access Pattern similar to bpmndatabaseConnector
nnnnnn                    projectName = 'default_project';
nnnnnnnnnnnn            % Static version of insertrows that uses the singleton instance
            % Tablename: Name of the Table (Collection)
            % Rows: Structure Array of Data to Insert
            % Returns: Array of inserted IDS
nnnnnn            % Static version of fetchAll that uses the singleton instance
            % Tablename: Cell Array of Table Names to fetch from
            % Returns: Structure Where Each Field Corresponds to a Table
nnnnnn            % Static version of Exporttofile that uses the singleton instance
            % Outputpath: Path Where to Save the File
nnnnnn            % Static version of Getsummary That uses the singleton instance
nnnnnn