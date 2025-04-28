"""
Schema-Loader module provides access to database schema definitions
for BPMN elements and other data structures.
"""

class SchemaLoader:
    """
    Loads and provides schema definitions for data validation
    and prompt generation.
    """
    
    @staticmethod
    def load():
        """
        Loads all schema definitions
        
        Returns:
            dict: Dictionary containing schema definitions for all entity types
        """
        schemas = {
            'process_definitions': SchemaLoader._get_process_definitions_schema(),
            'bpmn_elements': SchemaLoader._get_bpmn_elements_schema(),
            'sequence_flows': SchemaLoader._get_sequence_flows_schema(),
            'resources': SchemaLoader._get_resources_schema(),
            'pools': SchemaLoader._get_pools_schema(),
            'lanes': SchemaLoader._get_lanes_schema(),
            'modules': SchemaLoader._get_modules_schema(),
            'parts': SchemaLoader._get_parts_schema(),
            'subparts': SchemaLoader._get_subparts_schema()
        }
        return schemas
    
    @staticmethod
    def _get_process_definitions_schema():
        """Returns schema for process definitions"""
        return {
            'process_id': {'type': 'string', 'required': True},
            'process_name': {'type': 'string', 'required': True},
            'description': {'type': 'string', 'required': True},
            'version': {'type': 'string', 'required': False, 'default': '1.0'},
            'author': {'type': ['string', 'null'], 'required': False},
            'creation_date': {'type': ['string', 'null'], 'format': 'date-time', 'required': False},
            'last_modified': {'type': ['string', 'null'], 'format': 'date-time', 'required': False},
            'status': {'type': ['string', 'null'], 'required': False, 'default': 'Draft'}
        }
    
    @staticmethod
    def _get_bpmn_elements_schema():
        """Returns schema for BPMN elements"""
        return {
            'element_id': {'type': 'string', 'required': True},
            'element_name': {'type': 'string', 'required': True},
            'element_type': {'type': 'string', 'required': True},
            'element_subtype': {'type': 'string', 'required': False},
            'process_id': {'type': 'string', 'required': True},
            'parent_id': {'type': 'string', 'required': False},
            'description': {'type': 'string', 'required': False},
            'position_x': {'type': 'number', 'required': False},
            'position_y': {'type': 'number', 'required': False},
            'width': {'type': 'number', 'required': False},
            'height': {'type': 'number', 'required': False}
        }
    
    @staticmethod
    def _get_sequence_flows_schema():
        """Returns schema for sequence flows"""
        return {
            'flow_id': {'type': 'string', 'required': True},
            'source_ref': {'type': 'string', 'required': True},
            'target_ref': {'type': 'string', 'required': True},
            'process_id': {'type': 'string', 'required': True},
            'condition_expr': {'type': 'string', 'required': False},
            'description': {'type': 'string', 'required': False}
        }
    
    @staticmethod
    def _get_resources_schema():
        """Returns schema for resources"""
        return {
            'resource_id': {'type': 'string', 'required': True},
            'resource_name': {'type': 'string', 'required': True},
            'resource_type': {'type': 'string', 'required': True},
            'element_id': {'type': 'string', 'required': True},
            'process_id': {'type': 'string', 'required': True},
            'capability': {'type': 'string', 'required': False},
            'availability': {'type': 'string', 'required': False}
        }
    
    @staticmethod
    def _get_modules_schema():
        """Returns schema for modules"""
        return {
            'module_id': {'type': 'string', 'required': True},
            'module_name': {'type': 'string', 'required': True},
            'process_id': {'type': 'string', 'required': True},
            'description': {'type': 'string', 'required': False},
            'version': {'type': 'string', 'required': False, 'default': '1.0'},
            'dependencies': {'type': 'string', 'required': False}
        }
    
    @staticmethod
    def _get_parts_schema():
        """Returns schema for parts"""
        return {
            'part_id': {'type': 'string', 'required': True},
            'part_name': {'type': 'string', 'required': True},
            'module_id': {'type': 'string', 'required': True},
            'description': {'type': 'string', 'required': False},
            'quantity': {'type': 'number', 'required': False, 'default': 1},
            'material': {'type': 'string', 'required': False}
        }
    
    @staticmethod
    def _get_subparts_schema():
        """Returns schema for subparts"""
        return {
            'subpart_id': {'type': 'string', 'required': True},
            'subpart_name': {'type': 'string', 'required': True},
            'part_id': {'type': 'string', 'required': True},
            'description': {'type': 'string', 'required': False},
            'quantity': {'type': 'number', 'required': False, 'default': 1},
            'dimensions': {'type': 'string', 'required': False}
        }
        
    @staticmethod
    def _get_pools_schema():
        """Returns schema for BPMN pools"""
        return {
            'pool_id': {'type': 'string', 'required': True},
            'pool_name': {'type': 'string', 'required': True},
            'process_id': {'type': 'string', 'required': True},
            'description': {'type': 'string', 'required': True},
            'participant_type': {'type': 'string', 'required': False, 'default': 'organization'}
        }
        
    @staticmethod
    def _get_lanes_schema():
        """Returns schema for BPMN lanes"""
        return {
            'lane_id': {'type': 'string', 'required': True},
            'lane_name': {'type': 'string', 'required': True},
            'pool_id': {'type': 'string', 'required': True},
            'process_id': {'type': 'string', 'required': True},
            'description': {'type': 'string', 'required': True},
            'role': {'type': 'string', 'required': False},
            'element_refs': {'type': 'array', 'required': False, 'items': {'type': 'string'}}
        }
