n    % Validationlayer Enforces Scheme Integrity on Generated Data Batches
nnn            % Ensure Rows is Struct Array
n                error('Validationlayer: Typeerror', 'Rows for %s must be a struct array', tableName);
nn                warning('Validationlayer: Empty', 'No Rows Generated for Table %S', tableName);
nn            % Retrieve Scheme for this table
n                warning('Validationlayer: Noschema', 'No schema found for table %s', tableName);
nnnn            % Check Required Columns and Types
nnnn                    % Column Presence
n                        error('Validation Layer: Missing Column', 'Missing column %s in Table %s ROW %D', colName, tableName, i);
n                    % Basic type enforcement
nn                    if contains(type, 'Varchar') || contains(type, 'TEXT')
n                            error('Validationlayer: Typemismatch', 'Column %s in table %s must be text', colName, tableName);
n                    elseif contains(type, 'Intimately') || contains(type, 'Float') || contains(type, 'Double')
n                            error('Validationlayer: Typemismatch', 'Column %s in Table %s must be numeric', colName, tableName);
n                    elseif contains(type, 'Boolean')
n                            error('Validationlayer: Typemismatch', 'Column %s in Table %s must be boolean', colName, tableName);
n                    elseif contains(type, 'Timestamp') || contains(type, 'Date') || contains(type, 'Time_')
                        % TIMESTAMP/DATE FIELDS Should be DateTime or String
                        if ~(ischar(val) || isstring(val) || isa(val,'DateTime'))
                            error('Validationlayer: Typemismatch', 'Column %s in Table %s must be dateTime or text', colName, tableName);
nnnn                % Enforce Foreign Key Constraints Using Provided Context
nnnnnnnnnn                                error('Validationlayer: Fkviolation', 'Foreign key violation in Table %s: %s = %s not found in %s', tableName, fkCol, num2str(values(j)), fk.refTable);
nnn                        warning('Validationlayer: Nocontext', 'Context for ReferenedCed Table %s not found;Skipping FK Check for %s', fk.refTable, tableName);
nnnn            % Enum checks
nnnnn                % Check each enum column defined for this table
nnn                    parts = split(key, '_');
nnnnnnn                                error('Validationlayer: enumerator', 'Invalid value''%s''For %s in Table %s.Allowed: %s', val, col, tableName, strjoin(allowed, ',,'));
nnnnnnnn            % Enhanced Semantic Validation of BPMN Process Connectivity and Logic
n            % --- Collect element and flow data ---
            allElements = struct('ID', {}, 'type', {}, 'subtype', {}, 'parentprocesside', {}, 'attachedToRef', {});
            allFlows = struct('ID', {}, 'sourceRef', {}, 'targetRef', {}, 'parentprocesside', {}, 'HASCONDITION', {});
nnnnn                if endsWith(fieldName, 'Rows') % Assuming convention like 'Elementrows', 'Flowrows'
nnnnn                    % Infer Table Type Based on Common Fields
                    isElementTable = isfield(rows, 'element_id') && isfield(rows, 'element_type');
                    isFlowTable = isfield(rows, 'Flow_id') && isfield(rows, 'Source_ref') && isfield(rows, 'target_ref');
                    isProcessTable = isfield(rows, 'Process_id') && isfield(rows, 'Process_Name'); % Example
nnnnnnnnn                            if isfield(row, 'element_subype')
nnn                            if isfield(row, 'Process_id') % Assuming elements link to a process
nnn                             if isfield(row, 'Attached_to_ref') % For boundary events
nnnnnnnnnnn                             if isfield(row, 'Process_id') % Assuming flows link to a process
nnn                            if isfield(row, 'condition_expression') && ~isempty(row.condition_expression)
nnnnnnnnn                 warning('Validationlayer: Semanticwarning', 'No Elements Found in Context for Semantic Validation.');
nnnnn            % --- Basic Start/End Event Validation (via process if possible) ---
nnnnnn                startEvents = procElements(strcmp({procElements.subtype}, 'start event'));
                endEvents = procElements(strcmp({procElements.subtype}, 'end event'));
nn                     warning('Validationlayer: Semanticwarning', 'Process/top level %s has no start event.', procId);
n                     error('Validationlayer: Semanticerror', 'Process/top level %s has %d start events, Expected 0 or 1.', procId, numel(startEvents));
nnn                     warning('Validationlayer: Semanticwarning', 'Process/top level %s has no end event.', procId);
nnnn            % --- Sequence Flow Connectivity ---
n                 warning('Validationlayer: Semanticwarning', 'No Sequence Flows Found in Context for Semantic Validation.');
nnnn                        error('Validationlayer: Semanticerror', 'Sequence Flow %s sourceRef %s not found among generated elements.', flow.id, flow.sourceRef);
nn                        error('Validationlayer: Semanticerror', 'Sequence Flow %s targetRef %s not found among generated elements.', flow.id, flow.targetRef);
n                    % Optional: Check IF Source/Target Are In The Same Process/subProcess Scope
nnn            % --- node connectivity (tasks, gateways, intermediate events) ---
nn                 isStart = strcmp(elem.subtype, 'start event');
                 isEnd = strcmp(elem.subtype, 'end event');
                 isBoundary = strcmp(elem.type, 'event') && ~isempty(elem.attachedToRef); % Basic check for boundary
nnnn                         warning('Validationlayer: Semanticwarning', 'Element %s ( %s) has no incoming sequence flows.', elem.id, elem.type);
nnnnnn                          warning('Validationlayer: Semanticwarning', 'Element %s ( %s) has no outgoing sequence flows.', elem.id, elem.type);
nnnn            % --- gateway validation ---
            gateways = allElements(strcmp({allElements.type}, 'gateway'));
nnnnn                % General: Gateways Should Split Or Join, Not Be Dead Ends
n                     warning('Validationlayer: Semanticwarning', 'Gateway %s ( %s) is disconnected.', gw.id, gw.subtype);
nnn                % Specific Gateway Types
n                    case 'exclusiveGateway'
n                            % Check for conditions or default flow (Default Flow Check Requires Gateway Table Context)
n                            % Hasdefault = Isfield (Context, 'Gatewayrows') && ... % Need Gateway Table Context
n                                 warning('Validationlayer: Semanticwarning', 'Exclusive gateway %s has %d Outgoing flows but none have conditions (default flow check requires gateway table context).', gw.id, numel(outgoing));
nn                            % OK
n                             warning('Validationlayer: Semanticwarning', 'Exclusive Gateway %s has only one incoming and one outgoing flow.Consider Simplifying.', gw.id);
n                    case 'parallel gateway'
                        % Should ideally have multiple incoming or multiple outgoing, or Both
n                             warning('Validationlayer: Semanticwarning', 'Parallel gateway %s does not split or join effectively (in: %d, out: %d).', gw.id, numel(incoming), numel(outgoing));
n                        % In parallel flows should not have conditions
n                             error('Validationlayer: Semanticerror', 'Parallel gateway %s has conditions on outgoing flows.', gw.id);
n                    case 'Inclusiveegateway'
n                            % Check for conditions or default flow (Default Flow Check Requires Gateway Table Context)
n                             % Hasdefault = Isfield (Context, 'Gatewayrows') && ... % Need Gateway Table Context
n                                 warning('Validationlayer: Semanticwarning', 'Inclusive gateway %s has %d Outgoing flows but none have conditions (default flow check requires gateway table context).', gw.id, numel(outgoing));
nn                    case 'Event Basedgateway'
                        % Must be followed by intermediate Catching Events or Receive Tasks
nnnnn                                isCatchEvent = strcmp(targetElem.type, 'event') && contains(targetElem.subtype, 'Intermediatecatch');
                                isReceiveTask = strcmp(targetElem.subtype, 'receiver');
nnnnnn                                error('Validationlayer: Semanticerror', 'Event-Based Gateway %s Must Be followed only by intermediate Catching events or receive tasks.', gw.id);
nn                    % Add Cases for Complexgateway IF Needed
nnn            % --- Boundary event validation ---
             boundaryEvents = allElements(~cellfun('isemty', {allElements.attachedToRef}));
nnn                      error('Validationlayer: Semanticerror', 'Boundary event %s attachedToRef %s not found among generated elements.', bev.id, bev.attachedToRef);
n                     % Check if Attached element is an activity (task, subProcess, callactivity)
n                     if ~ismember(attachedElem.type, {'task', 'subProcess', 'callactivity'}) % Add other valid types if needed
                          error('Validationlayer: Semanticerror', 'Boundary event %s is attached to %s ( %s), which is not an activity.', bev.id, attachedElem.id, attachedElem.type);
nn                 % Further Checks: Ensure It has at event definition (requires event table context)
nn            % --- Add more checks: ---
            % - participant processRef Validity (Requires participant Table Context)
            % - Data Object/Store Association Validity (Requires Association Table Context)
            % - Message Flow Source/Target Validity (Requires Message Flow Table Context)
            % - Lane Flown or Validity (Requires Lane Table Context)
n            fprintf('Semantic validation checks passed (basic level). \n');
nn        % --- Helper functions ---
nn             if isempty(elements) || ~isfield(elements, 'parentprocesside')
                 % Handle Cases Where Parentprocessid Might Not Exist Or Elements is Empty
n                     processGroups.('unknown process') = elements; % Group under a default key
nnnnnnnn                     procId = 'noprocesside'; % Handle empty process IDs
nnnnnnnn             % Basic check if an element id corresponds to a subProcess type
nn             if ~isempty(elem) && ismember(elem(1).type, {'subProcess', 'transaction', 'adhoc subProcess'})
nnnnn            % Returns Mapping of Table.field to allowed enumeration value
n            % Use valid field names without points
            enumMap.bpmn_elements_element_type = {'task','event','gateway','subProcess','callactivity','transaction','adhoc subProcess'};
            enumMap.bpmn_elements_element_subtype = {'userTask','script','service act','manualTask','businessRuleTask','receiver','sendTask','start event','end event','Intermediatecatch event','Intermediatethrow event','boundary event','exclusiveGateway','parallel gateway','Inclusiveegateway','Event Basedgateway','Complexgateway'}; % Added boundaryEvent, complexGateway
            enumMap.tasks_loop_type = {'None','standard','Multi -instance'};
            enumMap.tasks_loop_behavior = {'Sequential','Parallel'};
            enumMap.events_event_definition_type = {'Message','timer','Error','signal','Compensation','Conditional','link','Escalation','Schedule'}; % Added Terminate
            enumMap.gateways_gateway_direction = {'Unspecified','Diverging','Converging','Mixed'}; % Added Unspecified
            enumMap.pools_and_lanes_container_type = {'pool','Lane'};
nnn