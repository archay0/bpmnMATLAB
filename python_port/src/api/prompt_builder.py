"""
PromptBuilder handles the creation of specialized prompts for the LLM.
"""

import json

class PromptBuilder:
    """
    PromptBuilder creates structured prompts for generating BPMN data through LLMs.
    The prompts are designed to elicit specific data structures for BPMN elements.
    """
    
    @staticmethod
    def build_process_map_prompt(product_description):
        """
        Builds a prompt to get high-level process phases for a product.
        
        Args:
            product_description (str): Description of the product/process
            
        Returns:
            str: Formatted prompt for process map generation
        """
        return f"""
        As a BPMN expert, define the main phases for a process to manufacture/operate: "{product_description}".
        
        Return an array of objects with fields 'phase_id', 'phase_name', and 'description'.
        The phases should represent a logical sequence, from the first to the last phase of the process.
        Limit yourself to 4-7 main phases.
        
        Example:
        [
            {{
                "phase_id": "PH_001",
                "phase_name": "Requirements Analysis",
                "description": "Capturing and analyzing product requirements"
            }},
            ...
        ]
        """
        
    @staticmethod
    def build_entity_prompt(level, schema, context, batch_size):
        """
        Builds a prompt to generate entities for a specific level.
        
        Args:
            level (str): The hierarchical level (process_definitions, modules, etc.)
            schema (dict): Schema definition for the entity
            context (dict): Current generation context
            batch_size (int): Number of entities to generate
            
        Returns:
            str: Formatted prompt for entity generation
        """
        # Cleaned and simplified schema name for description
        friendly_name = level.replace('_', ' ').title()
        
        # Extract product/process description from context
        product_desc = ""
        if context and isinstance(context, dict):
            if 'description' in context:
                product_desc = context['description']
            elif 'product_description' in context:
                product_desc = context['product_description']
        
        # Optional phases from context
        phases_desc = ""
        if context and 'phases' in context:
            phases_json = json.dumps(context['phases'], indent=2)
            phases_desc = f"\nThe process consists of the following phases:\n{phases_json}\n"
        
        # Prepare schema fields if available
        schema_fields = "not specified"
        if schema:
            fields = []
            for field, config in schema.items():
                field_type = config.get('type', 'string')
                is_required = config.get('required', False)
                fields.append(f"- {field}: {field_type}" + (" (required)" if is_required else ""))
            schema_fields = "\n".join(fields)

        # Special handling for BPMN elements
        if level == 'bpmn_elements':
            return PromptBuilder._build_bpmn_elements_prompt(schema, context, batch_size)
        
        return f"""
        Generate {batch_size} {friendly_name} entries for: "{product_desc}".
        
        {phases_desc}
        
        Schema definition for {level}:
        {schema_fields}
        
        The data should be realistic and detailed.
        Return the data as a JSON array, where each element is an object conforming to the schema definition.
        """

    @staticmethod
    def _build_bpmn_elements_prompt(schema, context, batch_size):
        """Special prompt builder for BPMN elements with more structure"""
        # Extract process info
        process_id = ""
        process_name = ""
        process_desc = ""
        
        if isinstance(context, dict):
            if 'process_id' in context:
                process_id = context['process_id']
                process_name = context.get('process_name', '')
                process_desc = context.get('description', '')
        
        # If we have phases, include them
        phases_json = ""
        if context and isinstance(context, dict) and 'phases' in context:
            phases_json = json.dumps(context['phases'], indent=2)
        
        return f"""
        Generate a complete set of {batch_size} BPMN elements for process: "{process_name or process_desc}".
        
        Process ID: {process_id}
        
        {"Process phases:\n" + phases_json if phases_json else ""}
        
        Include the following types of elements to create a complete process flow:
        
        1. Start Events:
           - Must include at least one start event
           - Can be normal start events or with triggers (message, timer, etc.)
           
        2. Tasks:
           - Include user tasks, service tasks, etc.
           - Give descriptive names that match the process
           
        3. Gateways:
           - Include exclusive gateways (XOR) for decision points
           - Include parallel gateways (AND) for concurrent activities
           
        4. End Events:
           - Must include at least one end event
           
        Each element should have these fields:
        - element_id: A unique ID (e.g., "START_001", "TASK_001", "GATE_001", "END_001")
        - element_name: Descriptive name
        - element_type: One of "event", "task", "gateway"
        - element_subtype: Specific type (e.g., "startEvent", "userTask", "exclusiveGateway")
        - process_id: The ID of the process ({process_id})
        - description: Brief description of the element's purpose
        
        Return the data as a JSON array, with elements in logical process order (start to end).
        """

    @staticmethod 
    def build_integrity_prompt(context):
        """
        Builds a prompt to check the logical integrity of the generated BPMN model.
        
        Args:
            context (dict): Current generation context with all data
            
        Returns:
            str: Formatted prompt for integrity checking
        """
        # Extract elements info
        elements_info = "No elements available"
        if context and 'bpmn_elements' in context and context['bpmn_elements']:
            elements = []
            for elem in context['bpmn_elements']:
                if isinstance(elem, dict):
                    elements.append(f"- ID: {elem.get('element_id', 'Unknown')}, Name: {elem.get('element_name', 'Unnamed')}, Type: {elem.get('element_type', 'Unknown')}/{elem.get('element_subtype', 'Unknown')}")
            elements_info = "BPMN Elements:\n" + "\n".join(elements)
        
        # Extract flows info
        flows_info = "No sequence flows available"
        if context and 'sequence_flows' in context and context['sequence_flows']:
            flows = []
            for flow in context['sequence_flows']:
                if isinstance(flow, dict):
                    flows.append(f"- ID: {flow.get('flow_id', 'Unknown')}, Source: {flow.get('source_ref', 'Unknown')} → Target: {flow.get('target_ref', 'Unknown')}")
            flows_info = "Sequence Flows:\n" + "\n".join(flows)
        
        return f"""
        As a BPMN expert, analyze the following BPMN model elements and flows for logical integrity issues.
        
        {elements_info}
        
        {flows_info}
        
        Check for the following types of issues:
        1. Missing start or end events
        2. Elements without incoming flows (except start events)
        3. Elements without outgoing flows (except end events)
        4. Disconnected elements or subgraphs
        5. Inconsistencies in gateway pairs (splits without joins)
        6. Potential deadlocks or infinite loops
        7. Invalid flow connections (e.g., flows connecting incompatible elements)
        8. Excessive branching or merging
        
        Return a list of identified issues in JSON format. Each issue should have:
        - "problem_type": Short label describing the issue type
        - "description": Detailed description of the issue
        - "elements": List of element IDs involved in the issue
        - "severity": "high", "medium", or "low"
        
        If no issues are found, return an empty array [].
        """
    
    @staticmethod
    def build_phase_entities_prompt(level, entity_type, parent_ids, batch_size):
        """
        Builds a prompt to generate phase-specific entities.
        
        Args:
            level (str): The hierarchical level
            entity_type (str): Type of entity to generate
            parent_ids (list): IDs of parent entities
            batch_size (int): Number of entities to generate
            
        Returns:
            str: Formatted prompt for phase entity generation
        """
        # Parent IDs in JSON format
        parent_json = json.dumps(parent_ids, indent=2)
        
        # Clean name for description
        friendly_level = level.replace('_', ' ').title()
        entity_type_desc = entity_type if entity_type else "Entities"
        
        return f"""
        Generate {batch_size} {entity_type_desc} as BPMN elements for the level {friendly_level}.
        
        These elements should relate to the following parent IDs:
        {parent_json}
        
        Each element should have the following fields:
        - element_id: A unique ID (string)
        - element_name: Descriptive name (string)
        - element_type: Type of BPMN element (e.g., Task, Gateway, Event)
        - element_subtype: Specific subtype (e.g., UserTask, ExclusiveGateway)
        - description: Brief description of its function
        - parent_id: The ID of the parent element (from the list above)
        
        Return the data as a JSON array.
        """
        
    @staticmethod
    def build_flow_prompt(context):
        """
        Builds a prompt to generate sequence flows between BPMN elements.
        
        Args:
            context (dict): Current generation context with elements
            
        Returns:
            str: Formatted prompt for flow generation
        """
        # Extract elements from context
        element_desc = "Available elements:"
        if context and 'bpmn_elements' in context and context['bpmn_elements']:
            elements = []
            for elem in context['bpmn_elements']:
                if isinstance(elem, dict) and 'element_id' in elem and 'element_name' in elem:
                    elements.append(f"- ID: {elem['element_id']}, Name: {elem['element_name']}, Type: {elem.get('element_type', 'Unknown')}/{elem.get('element_subtype', 'Unknown')}")
            element_desc = "Available elements:\n" + "\n".join(elements)
        
        return f"""
        Based on the following BPMN elements, generate the necessary Sequence Flows to connect them into a complete BPMN process.
        
        {element_desc}
        
        Generate Sequence Flows with the following fields:
        - flow_id: A unique ID for the flow (e.g., "FLOW_001", "FLOW_002")
        - source_ref: The ID of the source element (where the flow comes from)
        - target_ref: The ID of the target element (where the flow goes to)
        - process_id: The process ID that these flows belong to
        - condition_expr: Optional condition expression for conditional flows (especially for gateways)
        
        Follow these rules:
        1. Each element (except for start and end events) should have at least one incoming and outgoing flow
        2. Start events have only outgoing flows
        3. End events have only incoming flows
        4. Exclusive gateways should have conditional flows
        5. Parallel gateways do not need conditions
        
        Return the data as a JSON array with well-formed sequence flows that create a logical process.
        """
    
    @staticmethod
    def build_resource_prompt(context, resource_schema):
        """
        Builds a prompt to generate resources for BPMN elements.
        
        Args:
            context (dict): Current generation context
            resource_schema (dict): Schema for resource data
            
        Returns:
            str: Formatted prompt for resource generation
        """
        # Prepare schema fields
        schema_fields = "not specified"
        if resource_schema:
            fields = []
            for field, config in resource_schema.items():
                field_type = config.get('type', 'string')
                is_required = config.get('required', False)
                fields.append(f"- {field}: {field_type}" + (" (required)" if is_required else ""))
            schema_fields = "\n".join(fields)
        
        # Extract elements with task type from context
        tasks = []
        if context and 'bpmn_elements' in context:
            for elem in context['bpmn_elements']:
                if isinstance(elem, dict) and elem.get('element_type', '').lower() == 'task':
                    tasks.append(f"- ID: {elem.get('element_id', 'Unknown')}, Name: {elem.get('element_name', 'Unnamed')}")
        
        tasks_desc = "No tasks found."
        if tasks:
            tasks_desc = "Available tasks for resource assignment:\n" + "\n".join(tasks)
        
        # Extract process ID if available
        process_id = ""
        if context and 'process_definitions' in context and len(context['process_definitions']) > 0:
            process_id = context['process_definitions'][0].get('process_id', '')
        
        return f"""
        Generate resources (people, roles, systems, or equipment) for the BPMN tasks.
        
        {tasks_desc}
        
        Schema definition for resources:
        {schema_fields}
        
        Each resource should be assigned to one or more tasks and include:
        - resource_id: A unique ID (e.g., "RES_001", "RES_002")
        - resource_name: Name of the resource
        - resource_type: Type of resource (e.g., "human", "system", "equipment")
        - element_id: ID of the element this resource is assigned to
        - process_id: {process_id}
        - capability: Optional description of resource capabilities
        - availability: Optional availability information
        
        Consider the type of tasks when assigning appropriate resources.
        
        Return the data as a JSON array.
        """
    
    @staticmethod
    def build_pool_prompt(context, schema, batch_size):
        """
        Builds a prompt to generate pools for a BPMN diagram.
        
        Args:
            context (dict): Current generation context with elements, processes, etc.
            schema (dict): Schema for pool data
            batch_size (int): Number of pools to generate
            
        Returns:
            str: Formatted prompt for pool generation
        """
        # Extract process info
        process_id = ""
        process_name = ""
        process_desc = ""
        
        if context and 'process_definitions' in context and len(context['process_definitions']) > 0:
            proc_def = context['process_definitions'][0]
            process_id = proc_def.get('process_id', '')
            process_name = proc_def.get('process_name', '')
            process_desc = proc_def.get('description', '')
            
        # Extract element types for organizational insights
        element_types = {}
        if context and 'bpmn_elements' in context:
            for elem in context['bpmn_elements']:
                if isinstance(elem, dict) and 'element_type' in elem:
                    elem_type = elem.get('element_type', '')
                    if elem_type not in element_types:
                        element_types[elem_type] = 0
                    element_types[elem_type] += 1
                    
        elements_summary = "Elements in the process:"
        if element_types:
            elements_summary += "\n" + "\n".join([f"- {k.title()}: {v}" for k, v in element_types.items()])
        
        # Product information if available
        product_info = ""
        if context and 'product_specifications' in context:
            specs = context['product_specifications']
            if isinstance(specs, dict):
                product_info = f"Product: {specs.get('product_name', 'Unknown')}"
        
        return f"""
        As a BPMN expert with organizational design experience, generate {batch_size} pools for this BPMN diagram.
        
        Process: {process_name or process_desc}
        Process ID: {process_id}
        {product_info}
        
        {elements_summary}
        
        In Business Process Model and Notation (BPMN), pools represent participants in a process, such as different organizations, 
        departments, or systems that interact within the overall process. A pool contains a process and is often used in collaboration 
        diagrams to show message flows between different participants.
        
        For each pool, generate:
        - pool_id: A unique identifier (format: "POOL_001", "POOL_002", etc.)
        - pool_name: A descriptive name for the participant (organization, department, system)
        - process_id: The ID of the process this pool belongs to ({process_id})
        - description: A clear description of the pool's purpose in the process
        - participant_type: The type of participant ("organization", "department", "system", or "role")
        
        Create pools that represent different participants involved in the manufacturing/operation process. 
        Consider the entire lifecycle from design to delivery.
        
        Return the data as a JSON array with {batch_size} pools that collaborate on this process.
        The pools should represent a complete cross-functional view that a professor would expect in a university-level BPMN course.
        """
        
    @staticmethod
    def build_lane_prompt(pool, context, schema, batch_size):
        """
        Builds a prompt to generate lanes for a specific pool.
        
        Args:
            pool (dict): Pool data for which to generate lanes
            context (dict): Current generation context
            schema (dict): Schema for lane data
            batch_size (int): Maximum number of lanes to generate
            
        Returns:
            str: Formatted prompt for lane generation
        """
        pool_id = pool.get('pool_id', 'Unknown')
        pool_name = pool.get('pool_name', 'Unknown')
        pool_desc = pool.get('description', '')
        process_id = pool.get('process_id', '')
        
        # Extract task information from context
        task_info = []
        if context and 'bpmn_elements' in context:
            for elem in context['bpmn_elements']:
                if isinstance(elem, dict) and elem.get('element_type') == 'task':
                    task_info.append(f"- {elem.get('element_id', '')}: {elem.get('element_name', '')} ({elem.get('element_subtype', 'task')})")
        
        tasks_summary = ""
        if task_info:
            tasks_summary = "Tasks that may be assigned to lanes:\n" + "\n".join(task_info[:10])
            if len(task_info) > 10:
                tasks_summary += f"\n(and {len(task_info) - 10} more tasks...)"
        
        return f"""
        As a BPMN expert with organizational design experience, generate up to {batch_size} lanes for the following pool:
        
        Pool ID: {pool_id}
        Pool Name: {pool_name}
        Pool Description: {pool_desc}
        Process ID: {process_id}
        
        {tasks_summary}
        
        In Business Process Model and Notation (BPMN), lanes subdivide pools and represent roles, departments, or systems within 
        an organization. Lanes are used to categorize and organize activities according to who performs them.
        
        For each lane, generate:
        - lane_id: A unique identifier (format: "LANE_001", "LANE_002", etc.)
        - lane_name: A descriptive name for the role or department
        - pool_id: The ID of the pool this lane belongs to ({pool_id})
        - process_id: The ID of the process ({process_id})
        - description: A clear description of the lane's purpose and responsibilities
        - role: The functional role represented by this lane
        - element_refs: An array of element IDs that should be placed in this lane (optional)
        
        Create lanes that represent the hierarchical or functional divisions within the {pool_name}.
        The lanes should provide a logical grouping of activities by role or function, as would be expected
        in a professional BPMN diagram created for a university course on business process modeling.
        
        Ensure the lanes cover all aspects of the process within this pool.
        
        Return the data as a JSON array with appropriate lanes for this pool.
        """