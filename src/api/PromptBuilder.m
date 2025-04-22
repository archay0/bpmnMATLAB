classdef PromptBuilder
    % PromptBuilder constructs LLM prompts for each BPMN data generation stage

    methods(Static)
        function prompt = buildSchemaPrompt(schema)
            % Embed table and relationship metadata into a prompt
            prompt = sprintf([
                'You are given the following database schema:\n%s\n', ...
                'Generate JSON rows that strictly adhere to these tables and foreign-key constraints.'
            ], jsonencode(schema));
        end

        function prompt = buildProcessMapPrompt(productDescription)
            % Ask LLM to break a product description into BPMN phases
            prompt = sprintf([
                'Given the product: "%s", list major BPMN stages (e.g. raw material prep, subassembly, testing, packaging) ', ...
                'as an ordered JSON array with names and short descriptions.'
            ], productDescription);
        end

        function prompt = buildPhaseEntitiesPrompt(phaseName, phaseDesc, context, batchSize)
            % Generate tasks/gateways/events for a specific phase
            prompt = sprintf([
                'Phase: %s - %s\n', ...
                'Context IDs: %s\n', ...
                'Generate %d JSON rows for BPMN entities (tasks, gateways, events) with these columns.'
            ], phaseName, phaseDesc, jsonencode(context), batchSize);
        end

        function prompt = buildFlowPrompt(context)
            % Define sequence and conditional flows linking phases
            prompt = sprintf([
                'With these phase entity IDs: %s\n', ...
                'Generate BPMN sequenceFlow and messageFlow JSON objects that connect them into a coherent process.'
            ], jsonencode(context));
        end

        function prompt = buildResourcePrompt(context, resourceSchema)
            % Assign bins, roles, and tools to tasks
            prompt = sprintf([
                'Given tasks: %s and resources schema: %s\n', ...
                'Generate JSON rows for resource assignments (bins, tools, performers).'  
            ], jsonencode(context), jsonencode(resourceSchema));
        end

        function prompt = buildIntegrityPrompt(fullContext)
            % Validate referential integrity before export
            prompt = sprintf([
                'Full BPMN context: %s\n', ...
                'List any missing links, orphan elements, or FK violations. Return empty list if all good.'
            ], jsonencode(fullContext));
        end

        function prompt = buildExportPrompt(finalContext)
            % Produce final BPMN-XML or combined JSON diagram
            prompt = sprintf([
                'Final BPMN context: %s\n', ...
                'Output a single valid BPMN-XML snippet encompassing tasks, events, gateways, and flows.'
            ], jsonencode(finalContext));
        end

        function prompt = buildEntityPrompt(tableName, tableSchema, context, batchSize)
            % Generic prompt for table-specific row generation
            prompt = sprintf([
                'Generate %d rows for table "%s" with schema %s and context IDs %s.'
            ], batchSize, tableName, jsonencode(tableSchema), jsonencode(context));
        end
    end
end