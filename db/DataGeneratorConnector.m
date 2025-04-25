n    % DatageneratorConnector Integrates Datagenerator with Databasemanager
    % This Class Provides Methods to Store LLM-Generated Data in the Project Database
    % and to retrieve Data for Incremental Refinement of the BPMN Model
nnnnn        StorageMode       % Storage mode being used ('memory' or 'file')
nnnn            % Constructor Initializes The Connector
            % Project name: Name of the Project
            % Storagemode: Storage Mode ('memory' or 'file')
            % Options: Optional Configuration Parameters
nn                projectName = 'default_project';
nnnnnnnnnn            % Initialize Properties
nnnn            % Get database manager
nn            fprintf('DatageneratorConnector Initialized for Project"%s"\n', projectName);
nnn            % Set the Current Generation Context
            % Context: Structure with Generation Context from GeneratorController
nnnn            % Get the Current Generation Context
            % Returns: Structure with Generation Context
nnnn            % Initialize a new project for the given product description
            % Productdescription: Text Description of the Product/Process
            % Returns: Initial Project Data Structure
n            % Create New Project in Database
nn            % Add to context
nnn            fprintf('Initialized Project Data for"%s"\n', productDescription);
nnn            % Insert llm-generated data into the database
            % Tablename: Name of the table to insert into
            % Data: Structure Array of Data to Insert
            % Phase: Optional generation phase name (for context tracking)
nnnnn            % Store Original Data in Context for Validation Purposes
            contextKey = [tableName 'Rows'];
nn            % Perform Validation If Available
n                if exist('Validationlayer', 'class')
nnnn                warning('DatageneratorConnector: validation warning', ...
                        'Validation Warning for %S: %S', tableName, ME.message);
nn            % Ensure Data Has Required Fields
nn            % Insert into database
nn            % Store IDS in Context
nnnnnn            fprintf('Inserted %d rows ino %s for phase"%s"\n', ...
nnnn            % Build context for prompt generation Based on Stored Data
            % Options: Optional parameters to control context building
            % - Limit: Maximum Number of items per table
            % - Tables: Cell Array of Tables to Include
nnnnn            % Default limit
n            if isfield(options, 'limit')
nnn            % Tables to Include
            includeTables = {'Process_definitions', 'bpmn_elements', 'sequence_flows'};
            if isfield(options, 'tablet')
nnn            % Build context with collected data
nn            % Fetch data from each table
nnn                % Fetch data from database
nnn                    % Limit Number of items if Needed
nnnn                    % Add to context data
nnnn            % Update Current Context with Aggregated Data
nn            % Build element and Flow Collections for Semantic Checks
nn            fprintf('Built promptly context from database with %d tables \n', ...
nnnn            % Build aggregated collections of elements and flows for semantic validation
n            % Initialize Empty Collections
nnn            % Check if we have context data
            if ~isfield(obj.CurrentContext, 'Contextdata')
nnn            % Agregate Elements
            if isfield(obj.CurrentContext.contextData, 'bpmn_elements')
n                % Keep only field for semantic validation
                commonFields = {'element_id', 'element_type', 'element_subype', 'Process_id'};
n                    % Get All Available Common Fields
nnnnnnn                    % Build array only if we have elements
nnnnnnnnnn            % Agregate Flows
            if isfield(obj.CurrentContext.contextData, 'sequence_flows')
nnnn            % Add to context
nnnnn            % Export all data to a consolidated file
            % Outputpath: Path Where to Save the File
nnnnnnn            % Get (or create) a singleton instance
            % This provides a singleton-like access patterns
nnnnnn                    projectName = 'default_project';
nnnnnnnnnnnnnnn