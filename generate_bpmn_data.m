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
    
    % Pfade explizit hinzufügen, um sicherzustellen, dass alle Module gefunden werden
    fprintf('Füge erforderliche Pfade hinzu...\n');
    currentDir = fileparts(mfilename('fullpath'));
    addpath(currentDir); % Hauptverzeichnis
    addpath(fullfile(currentDir, 'src'));
    addpath(fullfile(currentDir, 'src', 'api'));
    addpath(fullfile(currentDir, 'src', 'util'));
    
    % Debug-Information zu verfügbaren Klassen ausgeben
    fprintf('Überprüfe, ob GeneratorController verfügbar ist: ');
    if exist('GeneratorController', 'class') == 8
        fprintf('✅ Ja\n');
    else
        fprintf('❌ Nein\n');
        % Versuche die Datei manuell zu finden
        controllerPath = fullfile(currentDir, 'src', 'api', 'GeneratorController.m');
        if exist(controllerPath, 'file') == 2
            fprintf('Die Datei GeneratorController.m wurde gefunden, scheint aber nicht als Klasse erkannt zu werden.\n');
        else
            fprintf('Die Datei GeneratorController.m wurde nicht gefunden.\n');
        end
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

    % Versuche, GeneratorController dynamisch zu laden, wenn er nicht gefunden wird
    if exist('GeneratorController', 'class') ~= 8
        fprintf('Versuche GeneratorController dynamisch zu laden...\n');
        rehash path;  % Aktualisiere den MATLAB-Pfadcache
        
        % Versuche, die Klasse manuell zu laden
        controllerPath = fullfile(currentDir, 'src', 'api', 'GeneratorController.m');
        if exist(controllerPath, 'file') == 2
            [~, className, ~] = fileparts(controllerPath);
            run(controllerPath);
            fprintf('Klasse %s manuell geladen.\n', className);
        end
    end

    % Invoke GeneratorController
    try
        GeneratorController.generateIterative(opts);
    catch ME
        fprintf('Fehler beim Ausführen von GeneratorController.generateIterative:\n');
        fprintf('Fehlermeldung: %s\n', ME.message);
        fprintf('Stack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  In %s (Zeile %d)\n', ME.stack(i).name, ME.stack(i).line);
        end
        
        % Versuche alternativ über run
        try
            fprintf('\nVersuche alternative Ausführung...\n');
            controllerScript = fullfile(currentDir, 'src', 'api', 'GeneratorController.m');
            if exist(controllerScript, 'file') == 2
                run(controllerScript);
                fprintf('Controller-Skript ausgeführt.\n');
                
                % Prüfe noch einmal, ob die Klasse jetzt verfügbar ist
                if exist('GeneratorController', 'class') == 8
                    fprintf('GeneratorController jetzt verfügbar, versuche erneut...\n');
                    GeneratorController.generateIterative(opts);
                else
                    fprintf('GeneratorController immer noch nicht als Klasse verfügbar.\n');
                end
            end
        catch ME2
            fprintf('Alternative Ausführung fehlgeschlagen: %s\n', ME2.message);
        end
    end
end