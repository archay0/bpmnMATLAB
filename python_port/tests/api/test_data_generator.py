"""
Tests für den DataGenerator.

Diese Tests prüfen die grundlegende Funktionalität des DataGenerator-Moduls,
ohne tatsächlich API-Aufrufe zu machen (Mock-Tests).
"""

import os
import sys
import unittest
from unittest.mock import patch, MagicMock
import json

# Füge das Quellverzeichnis dem Modulpfad hinzu
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

from src.api.data_generator import DataGenerator
from src.api.api_config import APIConfig
from src.api.prompt_builder import PromptBuilder

class TestDataGenerator(unittest.TestCase):
    """Test-Suite für DataGenerator-Klasse"""

    def test_clean_json_text(self):
        """Test für die Methode zum Bereinigen von JSON-Text"""
        # Test mit Markdown-Codeblock
        text_with_markdown = "```json\n[{\"id\": 1, \"name\": \"Test\"}]\n```"
        cleaned = DataGenerator._clean_json_text(text_with_markdown)
        self.assertEqual(cleaned, "[{\"id\": 1, \"name\": \"Test\"}]")
        
        # Test mit extra Text und JSON
        mixed_text = "Hier ist dein JSON:\n{\"data\": [1, 2, 3]}\nDas war's!"
        cleaned = DataGenerator._clean_json_text(mixed_text)
        self.assertEqual(cleaned, "{\"data\": [1, 2, 3]}")
    
    def test_extract_json_content(self):
        """Test für die Methode zum Extrahieren von JSON-Inhalten"""
        # Test mit teilweise gültigen JSON-Array
        partial_array = "[{\"id\": 1, \"name\": \"Test\"}, {\"id\": 2, \"name\": \"Test2\""
        extracted = DataGenerator._extract_json_content(partial_array)
        # Expect the successful extraction of the first complete item
        self.assertEqual(extracted, {"id": 1, "name": "Test"})
        
        # Test mit gültigen JSON-Objekt in Text
        text_with_object = "Hier ist ein Objekt: {\"key\": \"value\", \"number\": 42}"
        extracted = DataGenerator._extract_json_content(text_with_object)
        self.assertEqual(extracted, {"key": "value", "number": 42})
    
    @patch('src.api.data_generator.APICaller')
    def test_call_llm_success(self, mock_api_caller):
        """Test für erfolgreichen LLM-API-Aufruf"""
        # Mock die APICaller-Klasse für den Test
        mock_response = '[{"id": "PROC_001", "name": "Sample Process"}]'
        mock_api_caller.send_prompt.return_value = mock_response
        
        # Rufe die zu testende Methode auf
        result = DataGenerator.call_llm("Test prompt", {"model": "test-model"})
        
        # Überprüfe Ergebnisse
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["id"], "PROC_001")
        self.assertEqual(result[0]["name"], "Sample Process")
        
        # Überprüfe, ob APICaller korrekt aufgerufen wurde
        mock_api_caller.send_prompt.assert_called_once()
    
    @patch('src.api.data_generator.APICaller')
    def test_call_llm_retry_on_error(self, mock_api_caller):
        """Test für Wiederholungslogik bei JSON-Fehler"""
        # Erstes Ergebnis ist ungültiges JSON, zweites ist gültig
        mock_api_caller.send_prompt.side_effect = [
            "Invalid {JSON", 
            '[{"fixed": true}]'
        ]
        
        # Rufe die zu testende Methode auf
        result = DataGenerator.call_llm("Test prompt")
        
        # Überprüfe Ergebnisse
        self.assertEqual(len(result), 1)
        self.assertTrue(result[0]["fixed"])
        
        # Überprüfe, ob APICaller zweimal aufgerufen wurde (Erstversuch + Wiederholung)
        self.assertEqual(mock_api_caller.send_prompt.call_count, 2)
    
    @patch('src.api.data_generator.APICaller')
    def test_call_llm_empty_response(self, mock_api_caller):
        """Test für den Umgang mit leeren API-Antworten"""
        # API gibt leere Antwort zurück
        mock_api_caller.send_prompt.return_value = ""
        
        # Rufe die zu testende Methode auf
        result = DataGenerator.call_llm("Test prompt")
        
        # Überprüfe, ob leere Liste zurückgegeben wird
        self.assertEqual(result, [])


if __name__ == "__main__":
    unittest.main()