function generate_bpmn_data(productDescription, batchSize, outputFile, options)
% generate_bpmn_data - CLI for iterative BPMN data generation
% Usage: generate_bpmn_data(productDescription, batchSize, outputFile, options)
%  productDescription: brief text description of the product
%  batchSize: number of rows per table per iteration
%  outputFile: path to save the generated BPMN XML
%  options: (optional) struct with additional configuration:
%    .model: LLM model to use (default: 'microsoft/mai-ds-r1:free')
%    .temperature: LLM temperature (default: 0.7)
%    .debug: enable debug output (default: false)

    if nargin < 3
        error('Usage: generate_bpmn_data(productDescription, batchSize, outputFile)');
    end
    if ischar(batchSize) || isstring(batchSize)
        batchSize = str2double(batchSize);
    end
    
    % Initialisiere API-Umgebung, falls möglich
    if exist('initAPIEnvironment', 'file') == 2
        initAPIEnvironment();
    end

    % Define generation order for multi-level data
    order = {'process_definitions', 'modules', 'parts', 'subparts'};

    % Build options struct
    opts = struct();
    opts.mode = 'iterative';
    opts.productDescription = productDescription;
    opts.order = order;
    opts.batchSize = batchSize;
    opts.outputFile = outputFile;
    
    % Standardwerte für API-Optionen setzen
    if exist('APIConfig', 'class') == 8
        apiDefaults = APIConfig.getDefaultOptions();
        opts.model = apiDefaults.model;
        opts.temperature = apiDefaults.temperature;
        opts.debug = apiDefaults.debug;
    else
        % Fallback, falls APIConfig nicht gefunden wird
        opts.model = 'microsoft/mai-ds-r1:free';
        opts.temperature = 0.7;
        opts.debug = false;
    end
    
    % Überschreibe mit benutzerdefinierten Optionen, falls angegeben
    if nargin > 3 && isstruct(options)
        fields = fieldnames(options);
        for i = 1:length(fields)
            field = fields{i};
            opts.(field) = options.(field);
        end
    end
    
    fprintf('Starte BPMN-Generierung mit Modell: %s\n', opts.model);

    % Invoke GeneratorController
    GeneratorController.generateIterative(opts);
end