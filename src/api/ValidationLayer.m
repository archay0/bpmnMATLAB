classdef ValidationLayer
    % ValidationLayer enforces schema integrity on generated data batches

    methods(Static)
        function validate(tableName, rows, schema, context)
            % Ensure rows is struct array
            if ~isstruct(rows)
                error('ValidationLayer:TypeError', 'Rows for %s must be a struct array', tableName);
            end
            if isempty(rows)
                warning('ValidationLayer:Empty', 'No rows generated for table %s', tableName);
            end

            % Retrieve schema for this table
            if ~isfield(schema, tableName)
                warning('ValidationLayer:NoSchema', 'No schema found for table %s', tableName);
                return;
            end
            tblSchema = schema.(tableName);

            % Check required columns and types
            for i = 1:numel(rows)
                row = rows(i);
                for c = tblSchema.columns
                    colName = c.name;
                    % Column presence
                    if !isfield(row, colName)
                        error('ValidationLayer:MissingColumn', 'Missing column %s in table %s row %d', colName, tableName, i);
                    end
                    % Basic type enforcement
                    val = row.(colName);
                    type = upper(c.type);
                    if contains(type, 'VARCHAR') || contains(type, 'TEXT')
                        if !(ischar(val) || isstring(val))
                            error('ValidationLayer:TypeMismatch', 'Column %s in table %s must be text', colName, tableName);
                        end
                    elseif contains(type, 'INT') || contains(type, 'FLOAT') || contains(type, 'DOUBLE')
                        if !isnumeric(val)
                            error('ValidationLayer:TypeMismatch', 'Column %s in table %s must be numeric', colName, tableName);
                        end
                    elseif contains(type, 'BOOLEAN')
                        if !(islogical(val) || isequal(val,0) || isequal(val,1))
                            error('ValidationLayer:TypeMismatch', 'Column %s in table %s must be boolean', colName, tableName);
                        end
                    elseif contains(type, 'TIMESTAMP') || contains(type, 'DATE') || contains(type, 'TIME_')
                        % Timestamp/date fields should be datetime or string
                        if !(ischar(val) || isstring(val) || isa(val,'datetime'))
                            error('ValidationLayer:TypeMismatch', 'Column %s in table %s must be datetime or text', colName, tableName);
                        end
                    end
                end

                % Enforce foreign key constraints using provided context
                for fk = tblSchema.foreignKeys
                    fkCol = fk.column;
                    if ~isfield(row, fkCol)
                        continue; % missing column handled earlier
                    end
                    values = [rows.(fkCol)];
                    if isfield(context, fk.refTable)
                        validIds = context.(fk.refTable);
                        for j = 1:numel(values)
                            if ~ismember(values(j), validIds)
                                error('ValidationLayer:FKViolation', 'Foreign key violation in table %s: %s=%s not found in %s', tableName, fkCol, num2str(values(j)), fk.refTable);
                            end
                        end
                    else
                        warning('ValidationLayer:NoContext', 'Context for referenced table %s not found; skipping FK check for %s', fk.refTable, tableName);
                    end
                end
            end

            % Enum checks
            enumMap = ValidationLayer.getEnumMap();
            for i = 1:numel(rows)
                row = rows(i);
                for fk = [] % placeholder to satisfy syntax
                end
                % Check each enum column defined for this table
                keys = fieldnames(enumMap);
                for k = 1:numel(keys)
                    key = keys{k};
                    parts = split(key, '.');
                    if numel(parts)==2 && strcmp(parts{1}, tableName)
                        col = parts{2};
                        if isfield(row, col)
                            val = row.(col);
                            allowed = enumMap.(key);
                            if ~any(strcmp(val, allowed))
                                error('ValidationLayer:EnumError', 'Invalid value ''%s'' for %s in table %s. Allowed: %s', val, col, tableName, strjoin(allowed, ','));
                            end
                        end
                    end
                end
            end
        end

        function validateSemantic(context)
            % Enhanced semantic validation of BPMN process connectivity and logic

            % --- Collect Element and Flow Data ---
            allElements = struct('id', {}, 'type', {}, 'subtype', {}, 'parentProcessId', {}, 'attachedToRef', {});
            allFlows = struct('id', {}, 'sourceRef', {}, 'targetRef', {}, 'parentProcessId', {}, 'hasCondition', {});
            allProcesses = {}; % Store process IDs

            elemFields = fieldnames(context);
            for f = elemFields'
                fieldName = f{1};
                if endsWith(fieldName, 'Rows') % Assuming convention like 'elementRows', 'flowRows'
                    rows = context.(fieldName);
                    if ~isstruct(rows) || isempty(rows)
                        continue;
                    end

                    % Infer table type based on common fields
                    isElementTable = isfield(rows, 'element_id') && isfield(rows, 'element_type');
                    isFlowTable = isfield(rows, 'flow_id') && isfield(rows, 'source_ref') && isfield(rows, 'target_ref');
                    isProcessTable = isfield(rows, 'process_id') && isfield(rows, 'process_name'); % Example

                    if isProcessTable
                         allProcesses = [allProcesses; {rows.process_id}'];
                    elseif isElementTable
                        for i = 1:numel(rows)
                            row = rows(i);
                            elem.id = row.element_id;
                            elem.type = row.element_type;
                            elem.subtype = '';
                            if isfield(row, 'element_subtype')
                                elem.subtype = row.element_subtype;
                            end
                            elem.parentProcessId = ''; % Determine parent process later if needed
                            if isfield(row, 'process_id') % Assuming elements link to a process
                                elem.parentProcessId = row.process_id;
                            end
                             elem.attachedToRef = '';
                             if isfield(row, 'attached_to_ref') % For boundary events
                                 elem.attachedToRef = row.attached_to_ref;
                             end
                            allElements(end+1) = elem;
                        end
                    elseif isFlowTable
                         for i = 1:numel(rows)
                            row = rows(i);
                            flow.id = row.flow_id;
                            flow.sourceRef = row.source_ref;
                            flow.targetRef = row.target_ref;
                            flow.parentProcessId = ''; % Determine parent process later
                             if isfield(row, 'process_id') % Assuming flows link to a process
                                flow.parentProcessId = row.process_id;
                             end
                            flow.hasCondition = false; % Check for condition expression later
                            if isfield(row, 'condition_expression') && ~isempty(row.condition_expression)
                                flow.hasCondition = true;
                            end
                            allFlows(end+1) = flow;
                         end
                    end
                end
            end

            if isempty(allElements)
                 warning('ValidationLayer:SemanticWarning', 'No elements found in context for semantic validation.');
                 return; % Cannot validate without elements
            end

            allElementIds = {allElements.id}';

            % --- Basic Start/End Event Validation (per process if possible) ---
            processGroups = ValidationLayer.groupElementsByProcess(allElements);
            processIds = fieldnames(processGroups);

            for p = 1:numel(processIds)
                procId = processIds{p};
                procElements = processGroups.(procId);
                startEvents = procElements(strcmp({procElements.subtype}, 'startEvent'));
                endEvents = procElements(strcmp({procElements.subtype}, 'endEvent'));

                if numel(startEvents) == 0 && ~ValidationLayer.isSubprocess(procId, allElements) % Allow subprocesses without start/end
                     warning('ValidationLayer:SemanticWarning', 'Process/Top-Level %s has no start event.', procId);
                elseif numel(startEvents) > 1
                     error('ValidationLayer:SemanticError', 'Process/Top-Level %s has %d start events, expected 0 or 1.', procId, numel(startEvents));
                end

                if numel(endEvents) == 0 && ~ValidationLayer.isSubprocess(procId, allElements)
                     warning('ValidationLayer:SemanticWarning', 'Process/Top-Level %s has no end event.', procId);
                end
            end


            % --- Sequence Flow Connectivity ---
            if isempty(allFlows)
                 warning('ValidationLayer:SemanticWarning', 'No sequence flows found in context for semantic validation.');
            else
                for i = 1:numel(allFlows)
                    flow = allFlows(i);
                    if !ismember(flow.sourceRef, allElementIds)
                        error('ValidationLayer:SemanticError', 'Sequence flow %s sourceRef %s not found among generated elements.', flow.id, flow.sourceRef);
                    end
                    if !ismember(flow.targetRef, allElementIds)
                        error('ValidationLayer:SemanticError', 'Sequence flow %s targetRef %s not found among generated elements.', flow.id, flow.targetRef);
                    end
                    % Optional: Check if source/target are in the same process/subprocess scope
                end
            end

            % --- Node Connectivity (Tasks, Gateways, Intermediate Events) ---
             for i = 1:numel(allElements)
                 elem = allElements(i);
                 isStart = strcmp(elem.subtype, 'startEvent');
                 isEnd = strcmp(elem.subtype, 'endEvent');
                 isBoundary = strcmp(elem.type, 'event') && !isempty(elem.attachedToRef); % Basic check for boundary

                 if !isStart && !isBoundary % Start events don't need incoming, boundary events handled differently
                     incomingFlows = allFlows(strcmp({allFlows.targetRef}, elem.id));
                     if isempty(incomingFlows)
                         warning('ValidationLayer:SemanticWarning', 'Element %s (%s) has no incoming sequence flows.', elem.id, elem.type);
                     end
                 end

                 if !isEnd && !isBoundary % End events don't need outgoing
                     outgoingFlows = allFlows(strcmp({allFlows.sourceRef}, elem.id));
                     if isempty(outgoingFlows)
                          warning('ValidationLayer:SemanticWarning', 'Element %s (%s) has no outgoing sequence flows.', elem.id, elem.type);
                     end
                 end
             end

            % --- Gateway Validation ---
            gateways = allElements(strcmp({allElements.type}, 'gateway'));
            for i = 1:numel(gateways)
                gw = gateways(i);
                outgoing = allFlows(strcmp({allFlows.sourceRef}, gw.id));
                incoming = allFlows(strcmp({allFlows.targetRef}, gw.id));

                % General: Gateways should split or join, not be dead ends
                if isempty(outgoing) && isempty(incoming)
                     warning('ValidationLayer:SemanticWarning', 'Gateway %s (%s) is disconnected.', gw.id, gw.subtype);
                     continue;
                end

                % Specific Gateway Types
                switch gw.subtype
                    case 'exclusiveGateway'
                        if numel(outgoing) > 1
                            % Check for conditions or default flow (default flow check requires gateway table context)
                            hasCondition = any([outgoing.hasCondition]);
                            % hasDefault = isfield(context, 'gatewayRows') && ... % Need gateway table context
                            if !hasCondition % && !hasDefault
                                 warning('ValidationLayer:SemanticWarning', 'Exclusive Gateway %s has %d outgoing flows but none have conditions (default flow check requires gateway table context).', gw.id, numel(outgoing));
                            end
                        elseif numel(outgoing) == 0 && numel(incoming) > 0 % Converging
                            % OK
                        elseif numel(outgoing) == 1 && numel(incoming) == 1
                             warning('ValidationLayer:SemanticWarning', 'Exclusive Gateway %s has only one incoming and one outgoing flow. Consider simplifying.', gw.id);
                        end
                    case 'parallelGateway'
                        % Should ideally have multiple incoming OR multiple outgoing, or both
                        if numel(outgoing) < 2 && numel(incoming) < 2
                             warning('ValidationLayer:SemanticWarning', 'Parallel Gateway %s does not split or join effectively (In: %d, Out: %d).', gw.id, numel(incoming), numel(outgoing));
                        end
                        % Parallel flows should NOT have conditions
                        if any([outgoing.hasCondition])
                             error('ValidationLayer:SemanticError', 'Parallel Gateway %s has conditions on outgoing flows.', gw.id);
                        end
                    case 'inclusiveGateway'
                         if numel(outgoing) > 1
                            % Check for conditions or default flow (default flow check requires gateway table context)
                             hasCondition = any([outgoing.hasCondition]);
                             % hasDefault = isfield(context, 'gatewayRows') && ... % Need gateway table context
                             if !hasCondition % && !hasDefault
                                 warning('ValidationLayer:SemanticWarning', 'Inclusive Gateway %s has %d outgoing flows but none have conditions (default flow check requires gateway table context).', gw.id, numel(outgoing));
                             end
                         end
                    case 'eventBasedGateway'
                        % Must be followed by intermediate catching events or receive tasks
                        if numel(outgoing) > 0
                            validTargets = true;
                            for k = 1:numel(outgoing)
                                targetElem = allElements(strcmp({allElements.id}, outgoing(k).targetRef));
                                if isempty(targetElem) continue; end % Error handled earlier
                                isCatchEvent = strcmp(targetElem.type, 'event') && contains(targetElem.subtype, 'intermediateCatch');
                                isReceiveTask = strcmp(targetElem.subtype, 'receiveTask');
                                if !isCatchEvent && !isReceiveTask
                                    validTargets = false;
                                    break;
                                end
                            end
                            if !validTargets
                                error('ValidationLayer:SemanticError', 'Event-Based Gateway %s must be followed only by Intermediate Catching Events or Receive Tasks.', gw.id);
                            end
                        end
                    % Add cases for complexGateway if needed
                end
            end

            % --- Boundary Event Validation ---
             boundaryEvents = allElements(!cellfun('isempty', {allElements.attachedToRef}));
             for i = 1:numel(boundaryEvents)
                 bev = boundaryEvents(i);
                 if !ismember(bev.attachedToRef, allElementIds)
                      error('ValidationLayer:SemanticError', 'Boundary Event %s attachedToRef %s not found among generated elements.', bev.id, bev.attachedToRef);
                 else
                     % Check if attached element is an Activity (Task, SubProcess, CallActivity)
                     attachedElem = allElements(strcmp({allElements.id}, bev.attachedToRef));
                     if !ismember(attachedElem.type, {'task', 'subProcess', 'callActivity'}) % Add other valid types if needed
                          error('ValidationLayer:SemanticError', 'Boundary Event %s is attached to %s (%s), which is not an Activity.', bev.id, attachedElem.id, attachedElem.type);
                     end
                 end
                 % Further checks: Ensure it has an event definition (requires event table context)
             end

            % --- Add more checks: ---
            % - Participant processRef validity (requires participant table context)
            % - Data Object/Store association validity (requires association table context)
            % - Message Flow source/target validity (requires message flow table context)
            % - Lane flowNodeRef validity (requires lane table context)

            fprintf('Semantic validation checks passed (basic level).\n');
        end

        % --- Helper Functions ---
        function processGroups = groupElementsByProcess(elements)
             processGroups = struct();
             if isempty(elements) || !isfield(elements, 'parentProcessId')
                 % Handle cases where parentProcessId might not exist or elements is empty
                 if !isempty(elements)
                     processGroups.('unknownProcess') = elements; % Group under a default key
                 end
                 return;
             end

             uniqueProcessIds = unique({elements.parentProcessId});
             for i = 1:numel(uniqueProcessIds)
                 procId = uniqueProcessIds{i};
                 if isempty(procId)
                     procId = 'noProcessId'; % Handle empty process IDs
                 elseif !isvarname(procId)
                      procId = matlab.lang.makeValidName(procId); % Ensure valid struct field name
                 end
                 processGroups.(procId) = elements(strcmp({elements.parentProcessId}, uniqueProcessIds{i}));
             end
        end

        function isSub = isSubprocess(elementId, allElements)
             % Basic check if an element ID corresponds to a subprocess type
             isSub = false;
             elem = allElements(strcmp({allElements.id}, elementId));
             if !isempty(elem) && ismember(elem(1).type, {'subProcess', 'transaction', 'adHocSubProcess'})
                 isSub = true;
             end
        end

        function enumMap = getEnumMap()
            % Returns mapping of table.field to allowed enumeration values
            enumMap = struct();
            enumMap.('bpmn_elements.element_type') = {'task','event','gateway','subProcess','callActivity','transaction','adHocSubProcess'};
            enumMap.('bpmn_elements.element_subtype') = {'userTask','scriptTask','serviceTask','manualTask','businessRuleTask','receiveTask','sendTask','startEvent','endEvent','intermediateCatchEvent','intermediateThrowEvent','boundaryEvent','exclusiveGateway','parallelGateway','inclusiveGateway','eventBasedGateway','complexGateway'}; % Added boundaryEvent, complexGateway
            enumMap.('tasks.loop_type') = {'None','Standard','MultiInstance'};
            enumMap.('tasks.loop_behavior') = {'Sequential','Parallel'};
            enumMap.('events.event_definition_type') = {'Message','Timer','Error','Signal','Compensation','Conditional','Link','Escalation','Terminate'}; % Added Terminate
            enumMap.('gateways.gateway_direction') = {'Unspecified','Diverging','Converging','Mixed'}; % Added Unspecified
            enumMap.('pools_and_lanes.container_type') = {'Pool','Lane'};
        end
    end
end