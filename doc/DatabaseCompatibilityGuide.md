# Database Compatibility Guide for bpmnMATLAB

This document provides comprehensive guidance on how to structure your database to be compatible with the bpmnMATLAB utility. Following these guidelines will ensure that your database can be seamlessly integrated with our BPMN generation tools.

## Table of Contents

1. [Introduction](#introduction)
2. [Required Database Schema](#required-database-schema)
3. [Table Structures](#table-structures)
4. [Data Types and Constraints](#data-types-and-constraints)
5. [Relationship Mapping](#relationship-mapping)
6. [Query Support](#query-support)
7. [Example Database Schema](#example-database-schema)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

## Introduction

The bpmnMATLAB utility connects to databases to extract business process information and generate BPMN 2.0 compliant diagrams. For this to work effectively, your database must be structured in a way that maps to BPMN concepts and elements.

This guide applies to any relational database system, including MySQL, PostgreSQL, SQLite, MS SQL Server, and Oracle. The examples use standard SQL syntax that can be adapted to your specific database system.

## Required Database Schema

At a minimum, your database must include tables for the following elements:

1. **Process Definitions**: For storing high-level process information
2. **BPMN Elements**: For storing all BPMN nodes (tasks, events, gateways)
3. **Sequence Flows**: For storing connections between elements
4. **Element Positions**: For storing layout information (coordinates)

Additional tables that enhance functionality include:

5. **Element Attributes**: For storing type-specific attributes
6. **Pools and Lanes**: For organizational structure
7. **Data Objects**: For data elements in the process
8. **Message Flows**: For communications between pools
9. **Waypoints**: For complex flow paths

## Table Structures

### 1. Process Definitions Table

This is the root table that contains the overall process information.

```sql
CREATE TABLE process_definitions (
    process_id VARCHAR(50) PRIMARY KEY,
    process_name VARCHAR(255) NOT NULL,
    description TEXT,
    version VARCHAR(20),
    is_executable BOOLEAN DEFAULT false,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    namespace VARCHAR(255)
);
```

### 2. BPMN Elements Table

Stores all BPMN elements with common attributes.

```sql
CREATE TABLE bpmn_elements (
    element_id VARCHAR(50) PRIMARY KEY,
    process_id VARCHAR(50) NOT NULL,
    element_type VARCHAR(50) NOT NULL,
    element_subtype VARCHAR(50),
    element_name VARCHAR(255),
    is_interrupting BOOLEAN DEFAULT true,
    is_executable BOOLEAN DEFAULT false,
    parent_element_id VARCHAR(50),
    FOREIGN KEY (process_id) REFERENCES process_definitions(process_id),
    FOREIGN KEY (parent_element_id) REFERENCES bpmn_elements(element_id)
);
```

The `element_type` should be one of: 'task', 'event', 'gateway', 'subprocess', 'dataobject', 'datastore', or 'textannotation'.

The `element_subtype` provides more specificity, such as 'userTask', 'startEvent', 'exclusiveGateway', etc.

### 3. Element Attributes Table

Stores type-specific attributes for elements.

```sql
CREATE TABLE element_attributes (
    attribute_id VARCHAR(50) PRIMARY KEY,
    element_id VARCHAR(50) NOT NULL,
    attribute_name VARCHAR(100) NOT NULL,
    attribute_value TEXT,
    attribute_type VARCHAR(50) DEFAULT 'string',
    FOREIGN KEY (element_id) REFERENCES bpmn_elements(element_id)
);
```

### 4. Sequence Flows Table

Stores sequence flow connections between elements.

```sql
CREATE TABLE sequence_flows (
    flow_id VARCHAR(50) PRIMARY KEY,
    process_id VARCHAR(50) NOT NULL,
    source_ref VARCHAR(50) NOT NULL,
    target_ref VARCHAR(50) NOT NULL,
    condition_expr TEXT,
    is_default BOOLEAN DEFAULT false,
    FOREIGN KEY (process_id) REFERENCES process_definitions(process_id),
    FOREIGN KEY (source_ref) REFERENCES bpmn_elements(element_id),
    FOREIGN KEY (target_ref) REFERENCES bpmn_elements(element_id)
);
```

### 5. Element Positions Table

Stores visual layout information for elements.

```sql
CREATE TABLE element_positions (
    position_id VARCHAR(50) PRIMARY KEY,
    element_id VARCHAR(50) NOT NULL,
    x FLOAT NOT NULL,
    y FLOAT NOT NULL,
    width FLOAT NOT NULL,
    height FLOAT NOT NULL,
    is_expanded BOOLEAN DEFAULT true,
    FOREIGN KEY (element_id) REFERENCES bpmn_elements(element_id)
);
```

### 6. Waypoints Table

Stores waypoints for flow connectors.

```sql
CREATE TABLE waypoints (
    waypoint_id VARCHAR(50) PRIMARY KEY,
    flow_id VARCHAR(50) NOT NULL,
    sequence INT NOT NULL,
    x FLOAT NOT NULL,
    y FLOAT NOT NULL,
    FOREIGN KEY (flow_id) REFERENCES sequence_flows(flow_id)
);
```

### 7. Pools and Lanes Table

Stores pool and lane information.

```sql
CREATE TABLE pools_and_lanes (
    container_id VARCHAR(50) PRIMARY KEY,
    container_type VARCHAR(50) NOT NULL,  -- 'pool' or 'lane'
    name VARCHAR(255),
    process_ref VARCHAR(50),  -- Only for pools
    parent_id VARCHAR(50),    -- For nested lanes
    FOREIGN KEY (process_ref) REFERENCES process_definitions(process_id),
    FOREIGN KEY (parent_id) REFERENCES pools_and_lanes(container_id)
);
```

### 8. Lane Element References Table

Maps elements to lanes.

```sql
CREATE TABLE lane_element_references (
    ref_id VARCHAR(50) PRIMARY KEY,
    lane_id VARCHAR(50) NOT NULL,
    flow_node_ref VARCHAR(50) NOT NULL,
    FOREIGN KEY (lane_id) REFERENCES pools_and_lanes(container_id),
    FOREIGN KEY (flow_node_ref) REFERENCES bpmn_elements(element_id)
);
```

### 9. Message Flows Table

Stores message flows between pools/participants.

```sql
CREATE TABLE message_flows (
    flow_id VARCHAR(50) PRIMARY KEY,
    source_ref VARCHAR(50) NOT NULL,
    target_ref VARCHAR(50) NOT NULL,
    message_id VARCHAR(50),
    message_name VARCHAR(255),
    FOREIGN KEY (source_ref) REFERENCES bpmn_elements(element_id),
    FOREIGN KEY (target_ref) REFERENCES bpmn_elements(element_id)
);
```

## Data Types and Constraints

### ID Fields

All ID fields should be strings (VARCHAR) that follow a consistent pattern:
- Process IDs: "Process_[unique number]"
- Element IDs: "[ElementType]_[unique number]" (e.g., "Task_1", "Gateway_2")
- Flow IDs: "Flow_[unique number]"

### Element Types

The following element types should be used in the `element_type` column:

| Element Type | Description |
|-------------|-------------|
| task | Regular task |
| event | Any type of event |
| gateway | Decision point |
| subprocess | Container for nested process |
| dataobject | Data object |
| datastore | Data store |
| textannotation | Text annotation |

### Element Subtypes

The following element subtypes should be used in the `element_subtype` column:

| Element Type | Valid Subtypes |
|-------------|-------------|
| task | task, userTask, serviceTask, scriptTask, businessRuleTask, manualTask, receiveTask, sendTask |
| event | startEvent, endEvent, intermediateThrowEvent, intermediateCatchEvent, boundaryEvent |
| gateway | exclusiveGateway, inclusiveGateway, parallelGateway, eventBasedGateway, complexGateway |
| subprocess | subProcess, transaction, adHocSubProcess, callActivity |

### Event Definitions

For events, you should store the event definition type in the element attributes table:

| Event Type | Valid Event Definitions |
|-------------|-------------|
| startEvent | messageEventDefinition, timerEventDefinition, conditionalEventDefinition, signalEventDefinition, errorEventDefinition, escalationEventDefinition |
| endEvent | messageEventDefinition, errorEventDefinition, terminateEventDefinition, signalEventDefinition, compensationEventDefinition |
| intermediateThrowEvent | messageEventDefinition, escalationEventDefinition, linkEventDefinition, compensationEventDefinition, signalEventDefinition |
| intermediateCatchEvent | messageEventDefinition, timerEventDefinition, conditionalEventDefinition, linkEventDefinition, signalEventDefinition |
| boundaryEvent | messageEventDefinition, timerEventDefinition, errorEventDefinition, escalationEventDefinition, compensationEventDefinition, signalEventDefinition |

## Relationship Mapping

### Core Relationships

1. **Process to Elements**: One-to-many (One process has many elements)
2. **Elements to Flows**: One-to-many (Elements can be the source or target of multiple flows)
3. **Elements to Attributes**: One-to-many (Each element can have multiple attributes)
4. **Elements to Positions**: One-to-one (Each element has one position)
5. **Flows to Waypoints**: One-to-many (Each flow can have multiple waypoints)

### Organizational Relationships

1. **Process to Pools**: One-to-one (Each pool references exactly one process)
2. **Pools to Lanes**: One-to-many (A pool can contain multiple lanes)
3. **Lanes to Elements**: Many-to-many (Elements can be in multiple lanes via lane_element_references)

## Query Support

Your database schema should support the following key queries that are used by the bpmnMATLAB utility:

### 1. Query Process Definitions

```sql
SELECT process_id, process_name, description, version
FROM process_definitions
WHERE [filter criteria]
ORDER BY process_id;
```

### 2. Query Process Elements

```sql
SELECT e.element_id, e.element_type, e.element_subtype, e.element_name, 
       p.x, p.y, p.width, p.height, p.is_expanded
FROM bpmn_elements e
LEFT JOIN element_positions p ON e.element_id = p.element_id
WHERE e.process_id = '[process_id]'
ORDER BY e.element_id;
```

### 3. Query Element Attributes

```sql
SELECT a.element_id, a.attribute_name, a.attribute_value
FROM element_attributes a
JOIN bpmn_elements e ON a.element_id = e.element_id
WHERE e.process_id = '[process_id]'
ORDER BY a.element_id, a.attribute_name;
```

### 4. Query Sequence Flows with Waypoints

```sql
SELECT f.flow_id, f.source_ref, f.target_ref, f.condition_expr,
       w.sequence, w.x, w.y
FROM sequence_flows f
LEFT JOIN waypoints w ON f.flow_id = w.flow_id
WHERE f.process_id = '[process_id]'
ORDER BY f.flow_id, w.sequence;
```

### 5. Query Pools, Lanes and their Elements

```sql
SELECT pl.container_id, pl.container_type, pl.name,
       lr.flow_node_ref AS element_id
FROM pools_and_lanes pl
LEFT JOIN lane_element_references lr ON pl.container_id = lr.lane_id
WHERE pl.process_ref = '[process_id]' OR pl.container_id IN (
    SELECT container_id FROM pools_and_lanes WHERE process_ref = '[process_id]'
)
ORDER BY pl.container_type, pl.container_id, lr.flow_node_ref;
```

## Example Database Schema

Here is an example SQL script to create a complete database schema:

```sql
-- Create schema
CREATE SCHEMA bpmn_schema;
USE bpmn_schema;

-- Create tables
CREATE TABLE process_definitions (
    process_id VARCHAR(50) PRIMARY KEY,
    process_name VARCHAR(255) NOT NULL,
    description TEXT,
    version VARCHAR(20),
    is_executable BOOLEAN DEFAULT false,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    namespace VARCHAR(255)
);

CREATE TABLE bpmn_elements (
    element_id VARCHAR(50) PRIMARY KEY,
    process_id VARCHAR(50) NOT NULL,
    element_type VARCHAR(50) NOT NULL,
    element_subtype VARCHAR(50),
    element_name VARCHAR(255),
    is_interrupting BOOLEAN DEFAULT true,
    is_executable BOOLEAN DEFAULT false,
    parent_element_id VARCHAR(50),
    FOREIGN KEY (process_id) REFERENCES process_definitions(process_id),
    FOREIGN KEY (parent_element_id) REFERENCES bpmn_elements(element_id)
);

CREATE TABLE element_attributes (
    attribute_id VARCHAR(50) PRIMARY KEY,
    element_id VARCHAR(50) NOT NULL,
    attribute_name VARCHAR(100) NOT NULL,
    attribute_value TEXT,
    attribute_type VARCHAR(50) DEFAULT 'string',
    FOREIGN KEY (element_id) REFERENCES bpmn_elements(element_id)
);

CREATE TABLE sequence_flows (
    flow_id VARCHAR(50) PRIMARY KEY,
    process_id VARCHAR(50) NOT NULL,
    source_ref VARCHAR(50) NOT NULL,
    target_ref VARCHAR(50) NOT NULL,
    condition_expr TEXT,
    is_default BOOLEAN DEFAULT false,
    FOREIGN KEY (process_id) REFERENCES process_definitions(process_id),
    FOREIGN KEY (source_ref) REFERENCES bpmn_elements(element_id),
    FOREIGN KEY (target_ref) REFERENCES bpmn_elements(element_id)
);

CREATE TABLE element_positions (
    position_id VARCHAR(50) PRIMARY KEY,
    element_id VARCHAR(50) NOT NULL UNIQUE,
    x FLOAT NOT NULL,
    y FLOAT NOT NULL,
    width FLOAT NOT NULL,
    height FLOAT NOT NULL,
    is_expanded BOOLEAN DEFAULT true,
    FOREIGN KEY (element_id) REFERENCES bpmn_elements(element_id)
);

CREATE TABLE waypoints (
    waypoint_id VARCHAR(50) PRIMARY KEY,
    flow_id VARCHAR(50) NOT NULL,
    sequence INT NOT NULL,
    x FLOAT NOT NULL,
    y FLOAT NOT NULL,
    FOREIGN KEY (flow_id) REFERENCES sequence_flows(flow_id),
    UNIQUE (flow_id, sequence)
);

CREATE TABLE pools_and_lanes (
    container_id VARCHAR(50) PRIMARY KEY,
    container_type VARCHAR(50) NOT NULL,
    name VARCHAR(255),
    process_ref VARCHAR(50),
    parent_id VARCHAR(50),
    FOREIGN KEY (process_ref) REFERENCES process_definitions(process_id),
    FOREIGN KEY (parent_id) REFERENCES pools_and_lanes(container_id)
);

CREATE TABLE lane_element_references (
    ref_id VARCHAR(50) PRIMARY KEY,
    lane_id VARCHAR(50) NOT NULL,
    flow_node_ref VARCHAR(50) NOT NULL,
    FOREIGN KEY (lane_id) REFERENCES pools_and_lanes(container_id),
    FOREIGN KEY (flow_node_ref) REFERENCES bpmn_elements(element_id)
);

CREATE TABLE message_flows (
    flow_id VARCHAR(50) PRIMARY KEY,
    source_ref VARCHAR(50) NOT NULL,
    target_ref VARCHAR(50) NOT NULL,
    message_id VARCHAR(50),
    message_name VARCHAR(255),
    FOREIGN KEY (source_ref) REFERENCES bpmn_elements(element_id),
    FOREIGN KEY (target_ref) REFERENCES bpmn_elements(element_id)
);
```

## Best Practices

### 1. Use Consistent Naming Conventions

* Use descriptive IDs that include element types
* Maintain consistency in your naming conventions
* Use clear, descriptive names for processes and elements

### 2. Store Complete Position Information

* Always include x, y, width, and height for all elements
* Store waypoints for sequence flows to ensure proper rendering
* If using pools and lanes, ensure proper nesting and hierarchy

### 3. Handle Element Types Correctly

* Use appropriate element subtypes that match BPMN 2.0 specification
* Store type-specific attributes in the element_attributes table
* Ensure correct parent-child relationships for nested elements

### 4. Include Documentation and Metadata

* Add descriptions for all processes and complex elements
* Include version information for process definitions
* Store creation and modification timestamps

### 5. Ensure Database Integrity

* Use foreign key constraints to maintain relationships
* Create indexes on frequently queried columns
* Validate data before insertion to ensure BPMN compatibility

### 6. Optimize for the BPMN Generator

* Group related elements in close proximity in your position data
* Use meaningful condition expressions for sequence flows
* Add layout hints using the element_attributes table

## Troubleshooting

### Common Issues and Solutions

1. **Missing Elements in the Generated BPMN**
   * Check that all elements have entries in the element_positions table
   * Ensure element types and subtypes are correctly specified
   * Verify foreign key relationships

2. **Incorrect Flow Connections**
   * Validate source_ref and target_ref values in sequence_flows table
   * Ensure elements referenced in flows exist in bpmn_elements table
   * Check waypoint coordinates for proper flow direction

3. **Layout Problems**
   * Verify coordinates in element_positions table
   * Check that pools and lanes have correct dimensions
   * Ensure waypoints correctly connect source and target elements

4. **Missing Attributes**
   * Verify that element-specific attributes are stored correctly
   * Check attribute names against BPMN specification
   * Ensure attribute values use correct data types

5. **Database Connection Issues**
   * Verify database credentials and connection parameters
   * Check that necessary database privileges are granted
   * Test connection with simple queries before running the BPMN generator

By following this guide, you can structure your database to be fully compatible with the bpmnMATLAB utility, enabling seamless generation of complex BPMN diagrams from your process data.