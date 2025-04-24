classdef DataGeneratorConnector < handle
    % DataGeneratorConnector integrates DataGenerator with DatabaseManager
    % This class provides methods to store LLM-generated data in the project database
    % and to retrieve data for incremental refinement of the BPMN model
    
    properties
        DatabaseManager   % Reference to the DatabaseManager instance
        CurrentContext    % Current generation context (from GeneratorController)
        ProjectName       % Name of the current project
        StorageMode       % Storage mode being used ('memory' or 'file')
    end
    
    methods
        function obj = DataGeneratorConnector(projectName, storageMode, options)
            % Constructor initializes the connector
            % projectName: Name of the project
            % storageMode: Storage mode ('memory' or 'file')
            % options: Optional configuration parameters
            
            if nargin < 1 || isempty(projectName)
                projectName = 'default_project';
            end
            
            if nargin < 2 || isempty(storageMode)
                storageMode = DatabaseConnectorFactory.MODE_FILE;
            end
            
            if nargin < 3
                options = struct();
            end
            
            % Initialize properties
            obj.ProjectName = projectName;
            obj.StorageMode = storageMode;
            obj.CurrentContext = struct();
            
            % Get database manager
            obj.DatabaseManager = DatabaseManager.getInstance(projectName, storageMode, options);
            
            fprintf('DataGeneratorConnector initialized for project "%s"\n', projectName);
        end
        
        function setContext(obj, context)
            % Set the current generation context
            % context: Structure with generation context from GeneratorController
            obj.CurrentContext = context;
        end
        
        function context = getContext(obj)
            % Get the current generation context
            % Returns: Structure with generation context
            context = obj.CurrentContext;
        end
        
        function projectData = initializeProject(obj, productDescription)
            % Initialize a new project for the given product description
            % productDescription: Text description of the product/process
            % Returns: Initial project data structure
            
            % Create new project in database
            projectData = obj.DatabaseManager.createNewProject(productDescription);
            
            % Add to context
            obj.CurrentContext.productDescription = productDescription;
            obj.CurrentContext.processId = projectData.processId;
            
            fprintf('Initialized project data for "%s"\n', productDescription);
        end
        
        function insertLLMData(obj, tableName, data, phase)
            % Insert LLM-generated data into the database
            % tableName: Name of the table to insert into
            % data: Structure array of data to insert
            % phase: Optional generation phase name (for context tracking)
            
            if nargin < 4
                phase = '';
            end
            
            % Store original data in context for validation purposes
            contextKey = [tableName 'Rows'];
            obj.CurrentContext.(contextKey) = data;
            
            % Perform validation if available
            try
                if exist('ValidationLayer', 'class')
                    schema = obj.DatabaseManager.DataStructure;
                    ValidationLayer.validate(tableName, data, schema, obj.CurrentContext);
                end
            catch ME
                warning('DataGeneratorConnector:ValidationWarning', ...
                        'Validation warning for %s: %s', tableName, ME.message);
            end
            
            % Ensure data has required fields
            validatedData = obj.DatabaseManager.validateAndPrepareData(tableName, data);
            
            % Insert into database
            insertedIds = obj.DatabaseManager.insertData(tableName, validatedData);
            
            % Store IDs in context
            if ~isempty(phase)
                obj.CurrentContext.([phase]) = insertedIds;
            else
                obj.CurrentContext.(tableName) = insertedIds;
            end
            
            fprintf('Inserted %d rows into %s for phase "%s"\n', ...
                    numel(insertedIds), tableName, phase);
        end
        
        function buildPromptContext(obj, options)
            % Build context for prompt generation based on stored data
            % options: Optional parameters to control context building
            %   - limit: Maximum number of items per table
            %   - tables: Cell array of tables to include
            
            if nargin < 2
                options = struct();
            end
            
            % Default limit
            limit = 25;
            if isfield(options, 'limit')
                limit = options.limit;
            end
            
            % Tables to include
            includeTables = {'process_definitions', 'bpmn_elements', 'sequence_flows'};
            if isfield(options, 'tables')
                includeTables = options.tables;
            end
            
            % Build context with collected data
            contextData = struct();
            
            % Fetch data from each table
            for i = 1:numel(includeTables)
                tableName = includeTables{i};
                
                % Fetch data from database
                tableData = obj.DatabaseManager.fetchData(tableName);
                
                if ~isempty(tableData)
                    % Limit number of items if needed
                    if numel(tableData) > limit
                        tableData = tableData(1:limit);
                    end
                    
                    % Add to context data
                    contextData.(tableName) = tableData;
                end
            end
            
            % Update current context with aggregated data
            obj.CurrentContext.contextData = contextData;
            
            % Build element and flow collections for semantic checks
            buildAggregatedCollections(obj);
            
            fprintf('Built prompt context from database with %d tables\n', ...
                    numel(fieldnames(contextData)));
        end
        
        function buildAggregatedCollections(obj)
            % Build aggregated collections of elements and flows for semantic validation
            
            % Initialize empty collections
            allElements = [];
            allFlows = [];
            
            % Check if we have context data
            if ~isfield(obj.CurrentContext, 'contextData')
                return;
            end
            
            % Aggregate elements
            if isfield(obj.CurrentContext.contextData, 'bpmn_elements')
                elements = obj.CurrentContext.contextData.bpmn_elements;
                % Keep only fields needed for semantic validation
                commonFields = {'element_id', 'element_type', 'element_subtype', 'process_id'};
                for i = 1:numel(elements)
                    % Get all available common fields
                    element = struct();
                    for j = 1:numel(commonFields)
                        field = commonFields{j};
                        if isfield(elements(i), field)
                            element.(field) = elements(i).(field);
                        end
                    end
                    % Build array only if we have elements
                    if ~isempty(fieldnames(element))
                        if isempty(allElements)
                            allElements = element;
                        else
                            allElements(end+1) = element;
                        end
                    end
                end
            end
            
            % Aggregate flows
            if isfield(obj.CurrentContext.contextData, 'sequence_flows')
                flows = obj.CurrentContext.contextData.sequence_flows;
                allFlows = flows;
            end
            
            % Add to context
            obj.CurrentContext.allElementRows = allElements;
            obj.CurrentContext.allFlowRows = allFlows;
        end
        
        function exportData(obj, outputPath)
            % Export all data to a consolidated file
            % outputPath: Path where to save the file
            
            obj.DatabaseManager.export(outputPath);
        end
    end
    
    methods(Static)
        function instance = getInstance(projectName, storageMode, options)
            % Get (or create) a singleton instance
            % This provides a singleton-like access pattern
            
            persistent connector;
            
            if isempty(connector) || ~isvalid(connector) || ...
                    (nargin > 0 && ~strcmp(connector.ProjectName, projectName))
                if nargin < 1
                    projectName = 'default_project';
                end
                if nargin < 2
                    storageMode = DatabaseConnectorFactory.MODE_FILE;
                end
                if nargin < 3
                    options = struct();
                end
                
                connector = DataGeneratorConnector(projectName, storageMode, options);
            end
            
            instance = connector;
        end
    end
end