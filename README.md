# bpmnMATLAB

A MATLAB utility for BPMN (Business Process Model and Notation) file generation from database data.

## Overview

This repository contains MATLAB scripts and functions for creating, editing, and managing BPMN 2.0 files. The utility connects to databases to extract process information and generates standard-compliant BPMN XML files that can be imported into any BPMN-compatible tool.

## Directory Structure

- `src/` - Core source code for BPMN generation
- `tests/` - Test scripts to validate functionality
- `examples/` - Example scripts demonstrating usage
- `doc/` - Documentation

## Getting Started

1. Clone this repository to your local machine
2. Add the repository folder to your MATLAB path:
   ```matlab
   addpath(genpath('/path/to/bpmnMATLAB'));
   ```
3. Configure your API access by creating a `.env` file in the project root with your API keys:
   ```
   # API Configuration
   OPENROUTER_API_KEY=your_openrouter_api_key_here
   ```
4. Run the examples to understand the functionality:
   ```matlab
   cd /path/to/bpmnMATLAB/examples
   SimpleProcessExample % Generate a simple BPMN diagram
   ComplexBPMNExample  % Generate a complex BPMN diagram
   ```
5. Check the documentation in the `doc/` folder for detailed guides:
   - `DatabaseSchema.md` - Detailed database schema description
   - `DatabaseCompatibilityGuide.md` - Comprehensive guide for database compatibility
   - `APIIntegration.md` - Guide for API integration with OpenRouter

## Requirements

- MATLAB R2019b or newer
- Database Toolbox (for database connections)
- XML Toolbox (for XML handling)
- Internet connection (for API access)

## Comprehensive BPMN Generation Checklist

To create a database-to-BPMN generator capable of handling any complexity, we need to implement the following functionalities:

### Core BPMN Element Support
- [x] **Event Types**
  - [x] Start Events (normal, message, timer, signal, conditional, error, escalation)
  - [x] End Events (normal, message, error, terminate, signal, compensation)
  - [x] Intermediate Events (catching/throwing for message, timer, error, compensation, signal)
  - [x] Boundary Events (interrupting/non-interrupting for message, timer, error, etc.)
  
- [x] **Activity Types**
  - [x] Tasks (user, service, script, business rule, manual, receive, send)
  - [x] Sub-processes (embedded, event, transaction, ad-hoc, call activity)
  - [x] Multi-instance activities (parallel/sequential)
  - [x] Loop activities
  
- [x] **Gateway Types**
  - [x] Exclusive (XOR)
  - [x] Inclusive (OR)
  - [x] Parallel (AND)
  - [x] Event-based
  - [x] Complex
  - [ ] Parallel Event-based

- [x] **Connecting Objects**
  - [x] Sequence Flows (with conditions)
  - [x] Message Flows
  - [x] Associations
  - [x] Data Associations

- [x] **Artifacts**
  - [x] Data Objects
  - [x] Data Stores
  - [x] Text Annotations
  - [ ] Groups

- [x] **Swimlanes**
  - [x] Pools (participants)
  - [x] Lanes (roles/responsibilities)
  - [x] Nested lanes

### Advanced BPMN Features
- [ ] **Correlation**
  - [ ] Correlation keys and properties
  
- [ ] **Conversations**
  - [ ] Conversation links
  - [ ] Conversation elements

- [ ] **Choreographies**
  - [ ] Choreography tasks
  - [ ] Sub-choreographies

- [x] **Process Execution**
  - [ ] Transaction boundaries
  - [x] Compensation handling
  - [x] Error handling

### Database Integration Requirements
- [x] **Schema Design**
  - [x] Process definition tables
  - [x] Element tables with element-specific attributes
  - [x] Relationship/flow tables
  - [x] Position/layout information tables
  
- [x] **Data Mapping Capabilities**
  - [x] Flexible mapping between database fields and BPMN elements
  - [x] Support for custom attributes and extensions
  - [x] Default positioning algorithms when coordinates not specified

- [ ] **Validation**
  - [ ] BPMN structural validation (correct connections, etc.)
  - [ ] Semantic validation (process makes sense)

### Visualization & Layout
- [x] **Automatic Layout**
  - [x] Smart positioning of elements when not defined
  - [ ] Avoiding element overlaps
  - [ ] Optimizing flow paths
  
- [ ] **Style Management**
  - [ ] Colors, fonts, sizes
  - [ ] Custom icons and markers

### Import/Export Capabilities
- [x] **File Formats**
  - [x] BPMN 2.0 XML
  - [ ] SVG/PNG visualization export
  - [ ] Import from existing BPMN files

- [x] **Tool Integration**
  - [x] Compatibility with Camunda, Activiti, jBPM
  - [x] Compatibility with modeling tools (Visio, draw.io)

## Database Schema Requirements

For a database to properly represent BPMN processes and detailed product compositions, it should include the following tables and fields:

1. **Process Tables**
   - Store process definitions and metadata (process ID, name, version, description, related product ID)

2. **Element Tables**
   - **Events**: event ID, type (start, intermediate, end), kind (message, timer, error, etc.), catching/throwing flag, interrupting flag
   - **Activities**: activity ID, type (task, sub-process, transaction, event sub-process, call activity), marker flags (loop, parallel MI, sequential MI, ad-hoc, compensation), callable reference
   - **Gateways**: gateway ID, type (exclusive, inclusive, parallel, complex, event-based, parallel event-based), merging/branching semantics
   - **Flows**: flow ID, type (sequence, conditional, default, message), source element ID, target element ID, condition expression
   - **Data**: data object ID, type (data object, data store, input, output, collection), persistence, associations (input/output references)
   - **Pools & Lanes**: pool ID, name, type (black/white box), lane ID, hierarchical parent reference
   - **Conversations & Collaboration**: conversation ID, sub-conversation reference, conversation links (source, target)
   - **Choreographies**: choreography ID, type (task, sub-choreography, call choreography), participants, multiple markers

3. **Relationship/Flow Tables**
   - Map connections between elements: sequenceFlow, messageFlow, association, dataAssociation

4. **Position/Layout Tables**
   - Coordinates, dimensions (width/height), docking information for diagram rendering

5. **Property Tables**
   - Custom attributes and extension elements associated with any BPMN element

6. **Product Composition Tables**
   - **Products**: product ID, name, description, version
   - **Parts**: part ID, name, description, parent product ID
   - **Assembly Processes**: process ID, part ID, sequence order, dependency references (sub-process IDs)

7. **Example Configuration Tables**
   - Templates or sample configurations to drive example-driven BPMN generation (e.g., product assembly workflow, part-specific subprocess flows)

## API Integration

This project now uses the OpenRouter API with the `microsoft/mai-ds-r1:free` model for AI-assisted BPMN generation. To use this feature:

1. Sign up for an account at [OpenRouter](https://openrouter.ai)
2. Create an API key and add it to your `.env` file
3. Run the initialization script to set up your environment:
   ```matlab
   initAPIEnvironment();
   ```

For more details on API integration, see `doc/APIIntegration.md`.

## Future Plans

- Generate comprehensive BPMN for a single product with subparts: automated creation of hierarchical subprocesses to represent product assembly, quality checks, packaging, and validation flows.
- Visualization export (SVG/PNG) for example product BPMN models, with style customization for parts and processes.
- Enhanced validation: structural and semantic checks tailored to product-specific workflows and subpart interactions.
- Style management: custom icons, color schemes, and layout optimizations for clear representation of complex product assemblies.
- **One‑shot data generation mode**: full-schema, one‑call generation via LLM will be implemented in a future release.

For detailed database schema guidance, refer to `doc/DatabaseSchema.md`.

## Project Structure
```
BPMN2_0_Poster_EN.pdf
compile_bpmn_tools.m
generate_bpmn_data.m
generate_bpmn_export.m
generate_bpmn_main.m
README.md
doc/
    APIIntegration.md
    DatabaseCompatibilityGuide.md
    DatabaseSchema.md
    temporary/
examples/
    AdvancedBPMNFeatures.m
    ComplexBPMNExample.m
    DatabaseBPMNExample.m
    OptimizedLayoutExample.m
    SimpleProcessExample.m
    output/
src/
    BPMNDatabaseConnector.m
    BPMNDiagramExporter.m
    BPMNElements.m
    BPMNGenerator.m
    BPMNLayoutOptimizer.m
    BPMNStyleManager.m
    BPMNToSimulink.m
    BPMNValidator.m
    api/
        APICaller.m
        APIConfig.m
        DataGenerator.m
        GeneratorController.m
        initAPIEnvironment.m
        PromptBuilder.m
        SchemaLoader.m
        ValidationLayer.m
    util/
        loadEnvironment.m
        setEnvironmentVariables.m
tests/
    runAllTests.m
    SimpleOpenRouterTest.m
    TestAPIConnection.m
    TestBPMNGeneration.m
    TestBPMNGenerator.m
    TestBPMNSuite.m
    TestOpenRouterAPI.m
    TestSchemaValidation.m
```
