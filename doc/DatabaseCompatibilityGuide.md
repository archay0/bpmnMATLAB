nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnThe `element_type` should be one of: 'task', 'event', 'gateway', 'subProcess', 'dataobject', 'datastore', or 'text notation'.
nThe `element_subtype` provides more specificity, such as 'userTask', 'start event', 'exclusiveGateway', etc.
nnnnnnnnnnn    attribute_type VARCHAR(50) DEFAULT 'string',
nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    container_type VARCHAR(50) NOT NULL,  -- 'pool' or 'lane'
nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn- Process IDs: "Process_ [Unique Number]"
- Element IDs: "[Element type] _ [Unique Number]" (e.g., "Task_1", "Gateway_2")
- Flow IDs: "Flow_ [Unique Number]"
nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnWHERE e.process_id = '[Process_ID]'
nnnnnnnnnWHERE e.process_id = '[Process_ID]'
nnnnnnnnnnWHERE f.process_id = '[Process_ID]'
nnnnnnnnnnWHERE pl.process_ref = '[Process_ID]' OR pl.container_id IN (
    SELECT container_id FROM pools_and_lanes WHERE process_ref = '[Process_ID]'
nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn    attribute_type VARCHAR(50) DEFAULT 'string',
nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn