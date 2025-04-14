# Database Schema for BPMN Generation

This document outlines the recommended database schema to support comprehensive BPMN generation.

## Overview

To properly represent all aspects of BPMN 2.0, the database schema must capture:
1. Process definitions and metadata
2. All BPMN element types with their specific attributes
3. Connections between elements
4. Visual layout information
5. Custom properties and extensions

## Core Tables

### 1. process_definitions

Stores the top-level process information.

| Column | Type | Description |
|--------|------|-------------|
| process_id | VARCHAR(50) | Primary key, unique identifier |
| process_name | VARCHAR(255) | Display name of the process |
| description | TEXT | Process description |
| version | VARCHAR(20) | Process version |
| is_executable | BOOLEAN | Whether process is executable |
| created_date | TIMESTAMP | Creation timestamp |
| updated_date | TIMESTAMP | Last update timestamp |
| created_by | VARCHAR(100) | Creator information |
| namespace | VARCHAR(255) | XML namespace |

### 2. bpmn_elements

Stores all BPMN elements with common attributes.

| Column | Type | Description |
|--------|------|-------------|
| element_id | VARCHAR(50) | Primary key, unique identifier |
| process_id | VARCHAR(50) | Foreign key to process_definitions |
| element_type | VARCHAR(50) | Type of element (task, event, gateway, etc.) |
| element_subtype | VARCHAR(50) | Subtype (userTask, startEvent, etc.) |
| element_name | VARCHAR(255) | Display name of the element |
| is_interrupting | BOOLEAN | For events, whether they are interrupting |
| is_executable | BOOLEAN | Whether element is executable |
| parent_element_id | VARCHAR(50) | For nested elements, null if top-level |

### 3. element_attributes

Stores type-specific attributes for elements.

| Column | Type | Description |
|--------|------|-------------|
| attribute_id | VARCHAR(50) | Primary key |
| element_id | VARCHAR(50) | Foreign key to bpmn_elements |
| attribute_name | VARCHAR(100) | Name of attribute |
| attribute_value | TEXT | Value of attribute |
| attribute_type | VARCHAR(50) | Data type of the attribute |

### 4. sequence_flows

Stores sequence flow connections between elements.

| Column | Type | Description |
|--------|------|-------------|
| flow_id | VARCHAR(50) | Primary key |
| process_id | VARCHAR(50) | Foreign key to process_definitions |
| source_ref | VARCHAR(50) | ID of source element |
| target_ref | VARCHAR(50) | ID of target element |
| condition_expr | TEXT | Optional condition expression |
| is_default | BOOLEAN | Whether this is default flow |

### 5. message_flows

Stores message flows between pools/participants.

| Column | Type | Description |
|--------|------|-------------|
| flow_id | VARCHAR(50) | Primary key |
| source_ref | VARCHAR(50) | ID of source element |
| target_ref | VARCHAR(50) | ID of target element |
| message_id | VARCHAR(50) | Reference to message |

### 6. element_positions

Stores visual layout information.

| Column | Type | Description |
|--------|------|-------------|
| position_id | VARCHAR(50) | Primary key |
| element_id | VARCHAR(50) | Foreign key to bpmn_elements or flow_id |
| x | FLOAT | X coordinate |
| y | FLOAT | Y coordinate |
| width | FLOAT | Width of element |
| height | FLOAT | Height of element |
| is_expanded | BOOLEAN | For sub-processes, whether expanded |

### 7. waypoints

Stores waypoints for flow connectors.

| Column | Type | Description |
|--------|------|-------------|
| waypoint_id | VARCHAR(50) | Primary key |
| flow_id | VARCHAR(50) | Flow identifier (sequence or message) |
| sequence | INT | Ordering of waypoints |
| x | FLOAT | X coordinate |
| y | FLOAT | Y coordinate |

## Element-Specific Tables

### 8. tasks

Stores task-specific attributes.

| Column | Type | Description |
|--------|------|-------------|
| task_id | VARCHAR(50) | Primary key (also element_id) |
| implementation | VARCHAR(255) | Implementation technology |
| script | TEXT | For script tasks, the script content |
| script_format | VARCHAR(50) | For script tasks, the script language |
| operation_ref | VARCHAR(50) | For service tasks, operation reference |
| is_for_compensation | BOOLEAN | Whether task is for compensation |
| loop_type | VARCHAR(50) | None, Standard, MultiInstance |
| loop_cardinality | VARCHAR(100) | For multi-instance, cardinality |
| loop_behavior | VARCHAR(50) | Sequential or Parallel for multi-instance |

### 9. events

Stores event-specific attributes.

| Column | Type | Description |
|--------|------|-------------|
| event_id | VARCHAR(50) | Primary key (also element_id) |
| event_definition_type | VARCHAR(50) | Message, Timer, Error, etc. |
| event_definition_ref | VARCHAR(50) | Reference to definition |
| is_interrupting | BOOLEAN | For boundary events |
| attached_to_ref | VARCHAR(50) | For boundary events |
| time_date | VARCHAR(255) | For timer events, date expression |
| time_cycle | VARCHAR(255) | For timer events, cycle expression |
| time_duration | VARCHAR(255) | For timer events, duration |

### 10. gateways

Stores gateway-specific attributes.

| Column | Type | Description |
|--------|------|-------------|
| gateway_id | VARCHAR(50) | Primary key (also element_id) |
| gateway_direction | VARCHAR(50) | Diverging, Converging, Mixed |
| instantiate | BOOLEAN | For event-based gateways |
| event_gateway_type | VARCHAR(50) | For event-based gateways |

### 11. pools_and_lanes

Stores pool and lane information.

| Column | Type | Description |
|--------|------|-------------|
| container_id | VARCHAR(50) | Primary key |
| container_type | VARCHAR(50) | Pool or Lane |
| name | VARCHAR(255) | Display name |
| process_ref | VARCHAR(50) | For pools, reference to process |
| parent_id | VARCHAR(50) | For nested lanes, parent lane |

### 12. lane_element_references

Maps elements to lanes.

| Column | Type | Description |
|--------|------|-------------|
| ref_id | VARCHAR(50) | Primary key |
| lane_id | VARCHAR(50) | Foreign key to pools_and_lanes |
| flow_node_ref | VARCHAR(50) | Reference to element |

### 13. data_objects

Stores data object information.

| Column | Type | Description |
|--------|------|-------------|
| data_object_id | VARCHAR(50) | Primary key |
| process_id | VARCHAR(50) | Foreign key to process_definitions |
| name | VARCHAR(255) | Display name |
| is_collection | BOOLEAN | Whether it's a collection |
| item_subject_ref | VARCHAR(50) | Data type reference |

### 14. data_associations

Stores data input/output associations.

| Column | Type | Description |
|--------|------|-------------|
| association_id | VARCHAR(50) | Primary key |
| source_ref | VARCHAR(50) | Source element |
| target_ref | VARCHAR(50) | Target element |
| transformation | TEXT | Optional transformation expression |

## Example Queries

### 1. Get all elements for a process:

```sql
SELECT e.*, ea.attribute_name, ea.attribute_value
FROM bpmn_elements e
LEFT JOIN element_attributes ea ON e.element_id = ea.element_id
WHERE e.process_id = 'Process_1'
ORDER BY e.element_id;
```

### 2. Get sequence flows with waypoints:

```sql
SELECT sf.*, wp.sequence, wp.x, wp.y
FROM sequence_flows sf
JOIN waypoints wp ON sf.flow_id = wp.flow_id
WHERE sf.process_id = 'Process_1'
ORDER BY sf.flow_id, wp.sequence;
```

### 3. Get elements with positions:

```sql
SELECT e.*, ep.x, ep.y, ep.width, ep.height
FROM bpmn_elements e
LEFT JOIN element_positions ep ON e.element_id = ep.element_id
WHERE e.process_id = 'Process_1';
```

## Implementation Notes

1. The schema is designed to be vendor-neutral and can be implemented in any relational database system.
2. For NoSQL databases, adjust the schema to use document-based or graph-based models as appropriate.
3. Consider adding indexes on commonly queried columns like process_id, element_id, and foreign key references.
4. For large processes, consider performance optimization techniques like partitioning or materialized views.