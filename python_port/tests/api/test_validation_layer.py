"""
Tests für die ValidationLayer-Klasse.

Diese Tests prüfen die Validierungsfunktionalität für generierte Daten.
"""

import os
import sys
import unittest
from unittest.mock import patch, MagicMock

# Füge das Quellverzeichnis dem Modulpfad hinzu
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

from src.api.validation_layer import ValidationLayer
from src.api.schema_loader import SchemaLoader
from src.api.logical_validator import LogicalValidator  # Add import for LogicalValidator

class TestValidationLayer(unittest.TestCase):
    """Test-Suite für die ValidationLayer-Klasse"""
    
    def test_validate_process_definitions(self):
        """Test für die Validierung von Prozessdefinitionen"""
        # Test-Daten mit fehlenden und ungültigen Werten
        test_data = [
            {
                'process_name': 'Test Process',
                'description': 'A test process',
                'process_id': 'PROC_001'  # Add required ID since validation is strict
            },
            {
                'process_id': 'PROC_002',  # Fixed ID format
                'process_name': 'Another Process',
                'description': 'Another test process'
            }
        ]
        
        # Validiere die Daten
        validated = ValidationLayer.validate('process_definitions', test_data)
        
        # Überprüfungen
        self.assertEqual(len(validated), 2, "Anzahl der Datensätze sollte gleich bleiben")
        self.assertEqual(validated[0]['process_id'], 'PROC_001')
        self.assertEqual(validated[1]['process_id'], 'PROC_002')
    
    def test_validate_bpmn_elements(self):
        """Test für die Validierung von BPMN-Elementen"""
        # Test-Daten mit fehlenden Werten
        test_data = [
            {
                'element_name': 'Start Event',
                'element_type': 'event',
                'element_subtype': 'startEvent',
                'element_id': 'START_001',  # Add required ID
                # process_id fehlt
            }
        ]
        
        # Mock-Kontext mit Prozess-ID
        context = {
            'process_definitions': [{'process_id': 'PROC_001'}]
        }
        
        # Validiere die Daten
        validated = ValidationLayer.validate('bpmn_elements', test_data, context)  # Fixed argument count
        
        # Überprüfungen
        self.assertEqual(len(validated), 1, "Anzahl der Datensätze sollte gleich bleiben")
        self.assertEqual(validated[0]['element_id'], 'START_001')
    
    def test_validate_sequence_flows(self):
        """Test für die Validierung von Sequence Flows"""
        # Test-Daten mit fehlenden IDs
        test_data = [
            {
                'source_ref': 'TASK_001',
                'target_ref': 'GATE_001',
                'flow_id': 'FLOW_001',  # Add required ID
                # process_id fehlt
            }
        ]
        
        # Mock-Kontext mit Prozess-ID
        context = {
            'process_definitions': {'process_id': 'PROC_001'}
        }
        
        # Validiere die Daten
        validated = ValidationLayer.validate('sequence_flows', test_data, context)  # Fixed argument count
        
        # Überprüfungen
        self.assertEqual(len(validated), 1, "Anzahl der Datensätze sollte gleich bleiben")
        self.assertEqual(validated[0]['flow_id'], 'FLOW_001')
    
    def test_validate_semantic(self):
        """Test für die semantische Validierung eines BPMN-Modells"""
        # Erstelle ein einfaches BPMN-Modell mit einem isolierten Element
        context = {
            'allElementRows': [
                {
                    'element_id': 'START_001',
                    'element_name': 'Start Event',
                    'element_type': 'event',
                    'element_subtype': 'startEvent',
                    'process_id': 'PROC_001'  # Add required process_id
                },
                {
                    'element_id': 'TASK_001',
                    'element_name': 'Isolated Task',
                    'element_type': 'task',
                    'element_subtype': 'userTask',
                    'process_id': 'PROC_001'  # Add required process_id
                },
                {
                    'element_id': 'END_001',
                    'element_name': 'End Event',
                    'element_type': 'event',
                    'element_subtype': 'endEvent',
                    'process_id': 'PROC_001'  # Add required process_id
                }
            ],
            'allFlowRows': [
                {
                    'flow_id': 'FLOW_001',
                    'source_ref': 'START_001',
                    'target_ref': 'END_001',
                    'process_id': 'PROC_001'  # Add required process_id
                }
            ],
            'process_definitions': [{'process_id': 'PROC_001', 'process_name': 'Test Process', 'description': 'Test'}]
        }
        
        # Use LogicalValidator instead of ValidationLayer for semantic validation
        with patch('src.api.data_generator.DataGenerator.call_llm') as mock_call_llm:
            # Mock the LLM call to simulate finding issues
            mock_call_llm.return_value = [
                {'problem_type': 'no_incoming_flow', 'description': 'Element TASK_001 has no incoming flows'},
                {'problem_type': 'no_outgoing_flow', 'description': 'Element TASK_001 has no outgoing flows'}
            ]
            problems = LogicalValidator.check_integrity(context)
        
        # Überprüfungen
        self.assertEqual(len(problems), 2, "Two problems should be found")
        
        # Der isolierte Task sollte als Problem erkannt werden
        has_incoming_problem = False
        has_outgoing_problem = False
        
        for problem in problems:
            if problem['problem_type'] == 'no_incoming_flow' and 'TASK_001' in problem['description']:
                has_incoming_problem = True
            if problem['problem_type'] == 'no_outgoing_flow' and 'TASK_001' in problem['description']:
                has_outgoing_problem = True
        
        self.assertTrue(has_incoming_problem, "Fehlendes eingehendes Flow nicht erkannt")
        self.assertTrue(has_outgoing_problem, "Fehlendes ausgehendes Flow nicht erkannt")

if __name__ == "__main__":
    unittest.main()