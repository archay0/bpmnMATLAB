# Data Generation Plan for Deep BPMN Schema

This document outlines a design for generating BPMN data objects according to our database schema. It supports both iterative and one-shot generation modes, leveraging our GitHub Models API.

## 1. Objectives
- Produce complete BPMN entity records (elements, flows, attributes) matching the database design.
- Support incremental (iterative) generation for individual components.
- Support full-scenario (one-shot) generation covering all BPMN elements in a single API call.
- Ensure generated data is validated and persisted via `BPMNDatabaseConnector`.

## 2. Components in `src/api`
1. **SchemaLoader.m**
   - Reads and parses `doc/DatabaseSchema.md` or introspects the database via `BPMNDatabaseConnector`.
   - Builds an in-memory model of tables, columns, constraints.

2. **DataGenerator.m**
   - Implements two modes:
     - *Iterative Mode*: generates one entity or table batch at a time.
     - *One-Shot Mode*: accepts full schema description and returns all required records.
   - Calls GitHub Models API using `GITHUB_API_TOKEN` to produce JSON payloads.

3. **APICaller.m**
   - Wraps HTTP requests to the GitHub Models API.
   - Handles rate limits, retries, and logging.

4. **GeneratorController.m**
   - Coordinates SchemaLoader, DataGenerator, and persists output.
   - Exposes main entry points: `generateIterative()` and `generateAll()`.

5. **ValidationLayer.m**
   - Validates API responses against table schemas and referential integrity.
   - Logs or throws detailed errors on mismatch.

## 3. Workflow

### Iterative Mode
1. Load schema for a target table.
2. Request generation of `n` rows via API.
3. Validate rows.
4. Insert into database.
5. Repeat for next table or relations.

### One-Shot Mode
1. Serialize full schema metadata.
2. Single API call to generate all tables in correct order.
3. Validate and batch-insert respecting foreign keys.

## 4. Integration and Usage
- Add commands in `generate_bpmn_export.m` to invoke `GeneratorController`.
- Expose parameters via environment variables (`.env`): mode, batch size, table order.

## 5. Testing
- Add unit tests under `tests/TestDataGenerator.m`.
- Mock API responses to verify validation and insertion.

## 6. Completed Implementations
- SchemaLoader.load() now parses `DatabaseSchema.md` to extract each table's columns and foreign keys into a metadata struct.
- ValidationLayer.validate() enforces required columns, basic type checks, and foreign-key integrity using the generated context.

## 6a. Remaining Next Steps
1. Extend ValidationLayer to handle complex types (timestamps, enums) and custom attribute validations.
2. Add CLI integration in `generate_bpmn_main.m` to call `GeneratorController.generateIterative` with appropriate options.
3. Write unit tests for SchemaLoader and ValidationLayer under `tests/TestSchemaValidation.m`.
4. Implement `generateAll()` one-shot mode if needed.

## 7. Iterative vs One‑Shot Recommendation
- Iterative mode provides better control and validation at each stage, ideal for complex products with subparts, routes, bins, and dynamic relationships.
- One‑shot mode can bootstrap small or well‑defined schemas in a single call but risks missing foreign‐key constraints and specific component logic.
- **Recommendation**: Use iterative generation for deep BPMN structures; generate each entity group in sequence, passing context (e.g., parent IDs) to subsequent calls.

## 8. Extended Workflow for Complex Product Scenarios
1. Define primary product entity (product table) via API call.
2. Generate subparts linked to the product (subparts table) using product IDs.
3. Create route definitions (routes table) referencing subparts and product flow.
4. Generate bin assignments (bins table) tied to routes and locations.
5. Produce BPMN elements (tasks, gateways, events) mapping to these tables.
6. Validate referential integrity after each batch insertion.
7. Use `GeneratorController.generateIterative({order: ['product','subparts','routes','bins','elements']})` to automate sequencing.

## 9. Prompt Templates for LLM API
- **Entity call:** "Generate 10 rows for table `subparts` given product IDs [1,2,3], columns: id, name, weight, product_id."
- **Full call (one‑shot):** "Produce JSON for tables: product, subparts, routes, bins, elements. Include keys and constraints as defined in `DatabaseSchema.md`."

## 10. Comprehensive BPMN Concepts to Model
Below is a non‑exhaustive list of BPMN constructs to include so the prompt guardrails cover every necessary element:

- Tasks (user, service, script, manual, business rule, send, receive)
- Events:
  - Start, End
  - Intermediate (timer, message, signal, error, escalation, compensation, conditional, link)
  - Boundary events on tasks/subprocesses
- Gateways (exclusive, parallel, inclusive, complex, event‑based)
- Subprocesses & Call Activities (embedded, event‑subprocess, ad‑hoc, transaction)
- Sequence Flows (conditional, default)
- Message Flows (between pools/participants)
- Pools & Lanes (participants, roles)
- Data Artifacts (data objects, data stores, associations)
- Text Annotations & Groups
- Multi‑instance markers & loop characteristics
- Resource assignments & roles (e.g., performers, tools)
- Transaction & Compensation handlers
- Conditional expressions & default paths

Including each of these in your prompt builder ensures the LLM generates a fully compliant, deep BPMN schema for any product workflow.

## 11. Handling Multi-Level Modules, Parts, and Processes

The iterative generator naturally supports nested modules, parts, and manufacturing steps:

1. Modules as subprocesses:
   - Each product module (e.g. 'image module') is modeled as a bpmn_elements entry with element_type='subProcess'.
   - The element_id of the module is used as parent_element_id for all its child parts.

2. Parts and subparts:
   - Parts are nested under their module; subparts nested under parts, recursively.
   - Use the same bpmn_elements table, setting parent_element_id to link each level.

3. Manufacturing/process phases per level:
   - For each module/part context, PromptBuilder.buildPhaseEntitiesPrompt generates relevant tasks (e.g. machining, wire treatment, chemical bath).
   - The context passed to each prompt includes the parent element_id to scope the tasks correctly.

4. Referential integrity and depth:
   - ValidationLayer enforces parent_element_id and process_id foreign keys at every level.
   - No fixed nesting limit; you can extend arbitrarily deep by iterating through contexts.

5. Controller sequencing:
   - Adjust opts.order to reflect hierarchy: e.g.
     ['process_definitions','modules','parts','subparts','sequenceFlows','resources']
   - For each level, call buildEntityPrompt and buildPhaseEntitiesPrompt in sequence to fully populate that layer before descending.

This ensures a deep, standards‑compliant BPMN diagram that captures every module, part, subpart, and process step.

## 12. Current Plan (April 22, 2025)

**Today's Focus:**

1.  **Finalize Semantic Validation:**
    *   Complete the implementation of semantic validation rules within `ValidationLayer.m`.
    *   Ensure validation covers logical process flow, data consistency, and BPMN 2.0 semantic rules as outlined in section 10.
    *   Integrate semantic checks tightly with the data generation process in `DataGenerator.m`.
2.  **Prepare for Data Generation:**
    *   Verify that `GeneratorController.m` correctly orchestrates the schema loading, generation, validation, and persistence steps.
    *   Configure `generate_bpmn_main.m` or relevant scripts to trigger initial data generation runs using the iterative mode.
    *   Perform test runs to generate a small batch of data and validate its correctness in the database.
