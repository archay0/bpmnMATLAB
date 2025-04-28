"""
validation_layer.py

Provides validation for all generated data structures according to schemas.
"""
import os
from jsonschema import validate as js_validate, ValidationError
from .schema_loader import SchemaLoader

class ValidationLayer:
    """
    Provides schema-based validation for generated data tables using JSON Schema.
    """
    
    @staticmethod
    def validate(level, data, context=None):
        """
        Validates data based on a schema and enriches it with context-dependent values.
        
        Args:
            level (str): Level of the data (e.g., process_definitions)
            data (list): Data to validate
            context (dict, optional): Context data for validation
            
        Returns:
            list: Validated and enriched data
        """
        if not data:
            return []
        
        schema = ValidationLayer._get_schema(level)
        if not schema:
            print(f"[ValidationLayer] No schema found for '{level}', skipping validation.")
            return data
        
        # For sequence_flows, adapt process_id from context if needed
        if level == 'sequence_flows' and context and 'process_definitions' in context:
            process_id = None
            
            # Extract process_id from process definitions
            if isinstance(context['process_definitions'], list) and len(context['process_definitions']) > 0:
                process_id = context['process_definitions'][0].get('process_id')
            elif isinstance(context['process_definitions'], dict) and 'process_id' in context['process_definitions']:
                process_id = context['process_definitions']['process_id']
                
            # Apply process_id to flows that are missing it
            if process_id:
                for flow in data:
                    if isinstance(flow, dict) and ('process_id' not in flow or not flow['process_id']):
                        flow['process_id'] = process_id
        
        # For elements, adapt process_id from context if needed
        if level == 'bpmn_elements' and context and 'process_definitions' in context:
            process_id = None
            
            # Extract process_id from process definitions
            if isinstance(context['process_definitions'], list) and len(context['process_definitions']) > 0:
                process_id = context['process_definitions'][0].get('process_id')
            elif isinstance(context['process_definitions'], dict) and 'process_id' in context['process_definitions']:
                process_id = context['process_definitions']['process_id']
                
            # Apply process_id to elements that are missing it
            if process_id:
                for element in data:
                    if isinstance(element, dict) and ('process_id' not in element or not element['process_id']):
                        element['process_id'] = process_id
                        
        # For pools, adapt process_id from context if needed
        if level == 'pools' and context and 'process_definitions' in context:
            process_id = None
            
            # Extract process_id from process definitions
            if isinstance(context['process_definitions'], list) and len(context['process_definitions']) > 0:
                process_id = context['process_definitions'][0].get('process_id')
                
            # Apply process_id to pools that are missing it
            if process_id:
                for pool in data:
                    if isinstance(pool, dict) and ('process_id' not in pool or not pool['process_id']):
                        pool['process_id'] = process_id
                        
        # For lanes, adapt pool_id and process_id if provided in context
        if level == 'lanes' and context:
            pool_id = None
            process_id = None
            
            # Extract pool_id from context if present
            if 'pool' in context and isinstance(context['pool'], dict):
                pool_id = context['pool'].get('pool_id')
                
            # Extract process_id from context if present
            if 'process_definitions' in context and isinstance(context['process_definitions'], list) and len(context['process_definitions']) > 0:
                process_id = context['process_definitions'][0].get('process_id')
                
            # Apply pool_id and process_id to lanes that are missing them
            for lane in data:
                if isinstance(lane, dict):
                    if pool_id and ('pool_id' not in lane or not lane['pool_id']):
                        lane['pool_id'] = pool_id
                    if process_id and ('process_id' not in lane or not lane['process_id']):
                        lane['process_id'] = process_id
        
        # Ensure all data has required IDs (generate if missing)
        if level == 'sequence_flows':
            ValidationLayer._ensure_flow_ids(data)
        elif level == 'bpmn_elements':
            ValidationLayer._ensure_element_ids(data)
        elif level == 'pools':
            ValidationLayer._ensure_pool_ids(data)
        elif level == 'lanes':
            # Get pool_id from context if available
            pool_id = None
            if context and 'pool' in context and isinstance(context['pool'], dict):
                pool_id = context['pool'].get('pool_id')
            ValidationLayer._ensure_lane_ids(data, pool_id)
            
        # Validate each item against the schema
        result = []
        for idx, item in enumerate(data):
            if not isinstance(item, dict):
                print(f"[ValidationLayer] Item {idx} is not a dictionary. Skipping.")
                continue
                
            # Check required fields and add defaults
            valid_item = item.copy()
            is_valid = True
            
            for field, field_schema in schema.items():
                # Check if field exists
                if field not in valid_item:
                    # Add default value if available
                    if 'default' in field_schema:
                        valid_item[field] = field_schema['default']
                    # For required fields with no default, report error
                    elif field_schema.get('required', False):
                        print(f"[ValidationLayer] Validation error for {level}[{idx}]: '{field}' is a required property")
                        is_valid = False
                
                # Field exists - validate type
                elif field in valid_item:
                    if 'type' in field_schema:
                        valid_item[field] = ValidationLayer._validate_type(
                            valid_item[field], 
                            field_schema['type'],
                            field_schema.get('format', None),
                            field
                        )
            
            # Apply special validation for specific fields/levels
            if level == 'process_definitions' and 'process_id' in valid_item:
                if not valid_item['process_id'].startswith('PROC_'):
                    print(f"[ValidationLayer] Correcting process_id format: {valid_item['process_id']} -> PROC_{valid_item['process_id'][-3:]}")
                    valid_item['process_id'] = f"PROC_{valid_item['process_id'][-3:]}"
            
            # Add to result if valid
            if is_valid:
                result.append(valid_item)
        
        return result
    
    @staticmethod
    def _ensure_flow_ids(flows):
        """
        Ensure all flows have valid flow_id format
        
        Args:
            flows (list): List of flow dictionaries
        """
        for i, flow in enumerate(flows):
            if isinstance(flow, dict):
                # Generate ID if missing or invalid format
                if 'flow_id' not in flow or not flow['flow_id'] or not isinstance(flow['flow_id'], str):
                    flow['flow_id'] = f"FLOW_{(i+1):03d}"
                # Correct format if needed    
                elif not flow['flow_id'].startswith('FLOW_'):
                    flow['flow_id'] = f"FLOW_{flow['flow_id'][-3:]}"
    
    @staticmethod
    def _ensure_element_ids(elements):
        """
        Ensure all elements have valid element_id format
        
        Args:
            elements (list): List of element dictionaries
        """
        for i, element in enumerate(elements):
            if isinstance(element, dict):
                # Get element type to determine ID prefix
                element_type = element.get('element_type', '').lower()
                prefix = 'ELEM_'
                
                if element_type == 'event':
                    subtype = element.get('element_subtype', '').lower()
                    if 'start' in subtype:
                        prefix = 'START_'
                    elif 'end' in subtype:
                        prefix = 'END_'
                    else:
                        prefix = 'EVEN_'
                elif element_type == 'task':
                    prefix = 'TASK_'
                elif element_type == 'gateway':
                    prefix = 'GATE_'
                    
                # Generate ID if missing or invalid format
                if 'element_id' not in element or not element['element_id'] or not isinstance(element['element_id'], str):
                    element['element_id'] = f"{prefix}{(i+1):03d}"
    
    @staticmethod
    def _ensure_pool_ids(pools):
        """
        Ensure all pools have valid pool_id format
        
        Args:
            pools (list): List of pool dictionaries
        """
        for i, pool in enumerate(pools):
            if isinstance(pool, dict):
                # Generate ID if missing or invalid format
                if 'pool_id' not in pool or not pool['pool_id'] or not isinstance(pool['pool_id'], str):
                    pool['pool_id'] = f"POOL_{(i+1):03d}"
                # Correct format if needed    
                elif not pool['pool_id'].startswith('POOL_'):
                    pool['pool_id'] = f"POOL_{pool['pool_id'][-3:]}"

    @staticmethod
    def _ensure_lane_ids(lanes, pool_id=None):
        """
        Ensure all lanes have valid lane_id format
        
        Args:
            lanes (list): List of lane dictionaries
            pool_id (str, optional): Pool ID to assign to lanes missing it
        """
        for i, lane in enumerate(lanes):
            if isinstance(lane, dict):
                # Generate ID if missing or invalid format
                if 'lane_id' not in lane or not lane['lane_id'] or not isinstance(lane['lane_id'], str):
                    lane['lane_id'] = f"LANE_{(i+1):03d}"
                # Correct format if needed    
                elif not lane['lane_id'].startswith('LANE_'):
                    lane['lane_id'] = f"LANE_{lane['lane_id'][-3:]}"
                
                # Ensure pool_id is set if provided
                if pool_id and ('pool_id' not in lane or not lane['pool_id']):
                    lane['pool_id'] = pool_id

    @staticmethod
    def _validate_type(value, expected_type, format_type=None, field_name=None):
        """
        Validate and convert value to expected type if needed
        
        Args:
            value: The value to validate
            expected_type: Expected type(s) from schema
            format_type: Optional format specifier (e.g., date-time)
            field_name: Field name for error messages
            
        Returns:
            The validated value, potentially converted to correct type
        """
        # Handle array of types
        if isinstance(expected_type, list):
            # Try each type in the list
            for type_option in expected_type:
                # Skip null if the value is not None
                if type_option == 'null' and value is not None:
                    continue
                    
                try:
                    return ValidationLayer._validate_type(value, type_option, format_type, field_name)
                except ValueError:
                    continue
                    
            # If we get here, none of the types worked
            return value
            
        # Handle specific types
        if expected_type == 'string':
            if not isinstance(value, str):
                if field_name:
                    print(f"[ValidationLayer] Converting {field_name} to string: {value}")
                return str(value)
        elif expected_type == 'number':
            if not isinstance(value, (int, float)):
                try:
                    return float(value)
                except (ValueError, TypeError):
                    if field_name:
                        print(f"[ValidationLayer] Invalid number format in {field_name}: {value}")
                    return 0
        elif expected_type == 'integer':
            if not isinstance(value, int):
                try:
                    return int(value)
                except (ValueError, TypeError):
                    if field_name:
                        print(f"[ValidationLayer] Invalid integer format in {field_name}: {value}")
                    return 0
        elif expected_type == 'boolean':
            if not isinstance(value, bool):
                if isinstance(value, str):
                    return value.lower() in ('true', 'yes', '1')
                return bool(value)
        elif expected_type == 'null':
            return None
            
        # Handle special formats
        if format_type == 'date-time' and isinstance(value, str):
            # Simple validation check, could be enhanced
            if not ('T' in value and ':' in value):
                return "2025-04-26T12:00:00Z"  # Default date-time
        
        return value
    
    @staticmethod
    def _get_schema(level):
        """
        Get schema for a specific level from SchemaLoader
        
        Args:
            level (str): Level to get schema for (e.g., process_definitions)
            
        Returns:
            dict: Schema definition or None if not found
        """
        # Get all schemas
        schemas = SchemaLoader.load()
        
        # Special handling for process phases which aren't in standard schemas
        if level == 'process_phases':
            return {
                'phase_id': {'type': 'string', 'required': True},
                'phase_name': {'type': 'string', 'required': True},
                'description': {'type': 'string', 'required': True},
                'order': {'type': 'integer', 'required': False}
            }
            
        # Return the requested schema if available
        return schemas.get(level, None)