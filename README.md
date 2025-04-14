# bpmnMATLAB

A MATLAB utility for BPMN (Business Process Model and Notation) file generation, manipulation, and visualization.

## Overview

This repository contains MATLAB scripts and functions for creating, editing, importing and managing BPMN 2.0 files. The utility connects to databases to extract process information and generates standard-compliant BPMN XML files that can be imported into any BPMN-compatible tool.

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
3. Run the examples to understand the functionality:
   ```matlab
   cd /path/to/bpmnMATLAB/examples
   SimpleProcessExample    % Generate a simple BPMN diagram
   ComplexBPMNExample     % Generate a complex BPMN diagram
   AdvancedBPMNFeatures  % Try advanced features like transactions and parallel event-based gateways
   ```
4. Check the documentation in the `doc/` folder for detailed guides:
   - `DatabaseSchema.md` - Detailed database schema description
   - `DatabaseCompatibilityGuide.md` - Comprehensive guide for database compatibility

## Requirements

- MATLAB R2019b or newer
- Database Toolbox (for database connections)
- XML Toolbox (for XML handling)
- Image Processing Toolbox (for SVG/PNG export)

## Project Status & Implementation Roadmap

The project is in an advanced state with most features implemented. This section outlines what's currently working and what's still planned.

### Current Status (April 2025)

- **Core functionality**: The BPMN generation framework is fully functional and can generate valid BPMN 2.0 XML files with advanced features.
- **Database connectivity**: MySQL and PostgreSQL database connectors are implemented and tested.
- **MATLAB Compiler compatibility**: The code has been optimized for use with MATLAB Compiler.
- **Import/Export**: The utility can now import existing BPMN files, edit them, and export to SVG/PNG formats.
- **Advanced BPMN Features**: Support added for transactions, parallel event-based gateways, and groups.
- **Examples**: Basic, complex, and advanced examples are available to demonstrate functionality.
- **Documentation**: Database schema and compatibility guides are available.

### Implementation Progress

#### Completed Features:
- Full implementation of basic BPMN elements (events, activities, gateways)
- Advanced elements including parallel event-based gateways and transactions
- Database integration with support for multiple database systems
- Sequence flow and message flow generation
- Data object and data store support
- Pools and lanes with proper nesting
- SVG/PNG export functionality
- Import from existing BPMN files
- Group artifacts
- Transaction boundaries support
- MATLAB Compiler compatibility

#### In Progress:
- Validation of BPMN structural integrity
- Advanced layout algorithms
- Choreography and Conversation diagrams

#### Planned Features (Priority Order):
1. Advanced structural validation
2. Style management (colors, fonts, custom icons)
3. Correlation keys and properties
4. Complete conversation support
5. Complete choreography support

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
  - [x] Parallel Event-based

- [x] **Connecting Objects**
  - [x] Sequence Flows (with conditions)
  - [x] Message Flows
  - [x] Associations
  - [x] Data Associations

- [x] **Artifacts**
  - [x] Data Objects
  - [x] Data Stores
  - [x] Text Annotations
  - [x] Groups

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
  - [x] Transaction boundaries
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

- [x] **Validation**
  - [x] Basic BPMN structural validation (elements and connections)
  - [ ] Advanced structural validation (correct gateway usage, etc.)
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
  - [x] SVG/PNG visualization export
  - [x] Import from existing BPMN files

- [x] **Tool Integration**
  - [x] Compatibility with Camunda, Activiti, jBPM
  - [x] Compatibility with modeling tools (Visio, draw.io)

## Compilation Instructions

To compile the BPMN generator using MATLAB Compiler:

1. Open MATLAB and navigate to the project directory
2. Use the MATLAB Compiler tool (`mcc`) to compile:
   ```matlab
   mcc -m generate_bpmn_main.m -a src/ -o bpmn_generator
   ```
3. The compiled executable will be created in the current directory
4. For deployment, include the necessary MATLAB Runtime libraries

## Database Schema Requirements

For a database to properly represent BPMN processes, it should include:

1. **Process Tables** - Store process definitions and metadata
2. **Element Tables** - Store all BPMN elements with type-specific attributes
3. **Flow Tables** - Store sequence flows and other connections
4. **Position Tables** - Store visual layout information
5. **Property Tables** - Store custom properties and extensions

For detailed guidance on database compatibility, refer to our comprehensive guide in `doc/DatabaseCompatibilityGuide.md`.

## Contributing

Contributions are welcome! Check the Implementation Progress and Planned Features sections above for areas that need development. Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Implement your feature or bug fix
4. Add appropriate tests
5. Submit a pull request

## License

This project is licensed under the MIT License.
