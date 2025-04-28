# BPMN MATLAB Python Port

Dieses Projekt ist eine Python-Portierung des BPMN MATLAB-Projekts. Die Portierung wird schrittweise durchgeführt, beginnend mit dem Daten-Generator.

## Portierungsplan

### Phase 1: Daten-Generator
- Implementierung der grundlegenden Datenstrukturen
- Portierung des DataGenerator
- Portierung des APIConfig und APICaller
- Portierung des PromptBuilder
- Implementierung von Tests für die Datengeneration

### Phase 2: Datenbank-Funktionalität
- Portierung des DatabaseManager
- Portierung des DataGeneratorConnector
- Implementierung der Datenbankschnittstellen

### Phase 3: BPMN-Generator
- Portierung der BPMN-Elementklassen
- Portierung des BPMNGenerator
- Implementierung der BPMN-Export-Funktionalität

### Phase 4: Benutzeroberfläche und CLI
- Implementierung einer Kommandozeilenschnittstelle
- Optionale Web-UI

## Testgetriebene Entwicklung
Für jeden portierten Bestandteil werden Tests entwickelt, um die Funktionalität schrittweise zu validieren. Diese erlauben es uns, jede Komponente isoliert zu testen, bevor sie in den gesamten Workflow integriert wird.

## Installation und Einrichtung

### Systemvoraussetzungen
- Python 3.8 oder höher
- pip (Python-Paketmanager)

### Installation des Python-Ports

1. Klone das Repository oder navigiere zum bestehenden Repository:
```bash
git clone <repository-url>
cd <repository-directory>/python_port
```

2. Erstelle und aktiviere eine virtuelle Umgebung (empfohlen):
```bash
python -m venv venv
source venv/bin/activate  # Unter Windows: venv\Scripts\activate
```

3. Installiere die Projektabhängigkeiten:
```bash
pip install -r requirements.txt
```

4. Erstelle eine `.env`-Datei für die API-Schlüssel:
```bash
touch .env
```

5. Füge die erforderlichen API-Schlüssel zur `.env`-Datei hinzu:
```
OPENROUTER_API_KEY=your_api_key_here
DEBUG_MODE=true
```

### Ausführen der Tests

Um die Unit-Tests auszuführen:
```bash
python -m unittest discover -s tests
```

Oder mit pytest:
```bash
pytest tests/
```

## Verwendung des Python-Ports

### Beispiel: Generierung von BPMN-Prozessphasen

Führe das Beispielskript aus:
```bash
python examples/generate_process_phases.py
```

Dieses Skript:
1. Fragt nach einer Produktbeschreibung
2. Generiert Prozessphasen mit Hilfe des LLM-Modells
3. Speichert die generierten Daten als JSON im `output`-Verzeichnis

### Anpassung der Generierungsoption

Du kannst die API-Optionen und Parameter im Python-Code anpassen:

```python
from src.api.api_config import APIConfig
from src.api.data_generator import DataGenerator
from src.api.prompt_builder import PromptBuilder

# API-Optionen anpassen
api_options = APIConfig.get_default_options()
api_options['model'] = 'custom-model-name'
api_options['temperature'] = 0.8

# Prompt erstellen
prompt = PromptBuilder.build_process_map_prompt("Dein Produkt oder Prozess")

# Daten generieren
result = DataGenerator.call_llm(prompt, api_options)
```

## Aktuelle Einschränkungen

In der aktuellen Phase 1 ist nur die Daten-Generator-Komponente portiert. Dies ermöglicht:
- Verbindung zum LLM und Datengeneration
- Formatierung und Verarbeitung von Prompts
- Generierung von BPMN-Prozessphasen

Die vollständige BPMN-Generierung und -Validierung wird in späteren Phasen implementiert.

## Umgebungsvariablen
Die Anwendung verwendet Umgebungsvariablen für API-Schlüssel und Datenbankverbindungen, die in einer `.env`-Datei konfiguriert werden können.