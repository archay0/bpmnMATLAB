nnnnnnnnnnnnnnnnnnnn   addpath(genpath('/Path/to/bpmnmatlab'));
nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn*   `productDescription` (string): A brief description of the product or process you want to model (e.g., 'Assembly Process for a Bicycle').
n*   `outputFile` (string): The path where the generated BPMN XML data should be saved (e.g., 'output/generated_bicycle_process.xml').
n    *   `options.model` (string): Specify the LLM model to use (default: 'Microsoft/Mai-DS-R1: Free').
nnnnnn% Simple generation
generate_bpmn_data('Manufacturing Process for a smartphone', 10, 'output/smartphone_process.xml')
n% Generation with Custom options
options = struct('model', 'Anthropic/Claude-3-Haiku-20240307', 'temperature', 0.5);
generate_bpmn_data('Order Fulfillment Workflow', 5, 'output/Order_fulfillment.xml', options)
nnnn*   Ensure your API environment is configured correctly as described in the "API integration" section above.
nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn