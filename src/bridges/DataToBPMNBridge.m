classdef DataToBPMNBridge < handle
    % DataToBPMNBridge Mediates between DataGenerator and BPMNGenerator
    %   Consumes raw table data and uses BPMNGenerator to build a BPMN model.

    properties
        DataGenerator    % Instance of DataGenerator
        BPMNGenerator    % Instance of BPMNGenerator
    end

    methods
        function obj = DataToBPMNBridge(dataGen, bpmnGen)
            % Constructor: assign the DataGenerator and BPMNGenerator instances
            obj.DataGenerator = dataGen;
            obj.BPMNGenerator = bpmnGen;
        end

        function run(obj)
            % RUN Execute the full data-to-BPMN bridging process
            %   1) Generate or fetch raw data tables
            %   2) Iterate over each table and map rows to BPMN elements
            %   3) Save or return the final BPMN output

            % Step 1: produce raw data struct
            rawData = obj.DataGenerator.generateAll();  % e.g., struct of table arrays

            % Step 2: iterate and map tables
            tableNames = fieldnames(rawData);
            for i = 1:numel(tableNames)
                tblName = tableNames{i};
                rows = rawData.(tblName);
                % TODO: dispatch table-specific mapping, e.g.:
                % if strcmp(tblName, 'tasks'), use addTask() calls
                % elseif strcmp(tblName, 'sequence_flows'), use addSequenceFlow()
                % Implement custom mapping logic here
            end

            % Step 3: finalize and save BPMN
            obj.BPMNGenerator.saveToBPMNFile();
        end
    end
end