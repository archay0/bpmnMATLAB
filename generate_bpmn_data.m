function generate_bpmn_data(productDescription, batchSize, outputFile)
% generate_bpmn_data - CLI for iterative BPMN data generation
% Usage: generate_bpmn_data(productDescription, batchSize, outputFile)
%  productDescription: brief text description of the product
%  batchSize: number of rows per table per iteration
%  outputFile: path to save the generated BPMN XML

    if nargin < 3
        error('Usage: generate_bpmn_data(productDescription, batchSize, outputFile)');
    end
    if ischar(batchSize) || isstring(batchSize)
        batchSize = str2double(batchSize);
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

    % Invoke GeneratorController
    GeneratorController.generateIterative(opts);
end