# API-Integration für BPMN MATLAB

Diese Dokumentation beschreibt die Integration von externen Sprachmodellen über die OpenRouter API in das BPMN MATLAB-Projekt.

## OpenRouter API-Integration

Das BPMN MATLAB-Projekt unterstützt nun die Verwendung der OpenRouter API mit dem `microsoft/mai-ds-r1:free` Modell für die Generierung von BPMN-Diagrammen und -Daten.

### Konfiguration

1. Stellen Sie sicher, dass Ihr OpenRouter API-Key in der `.env`-Datei im Hauptverzeichnis des Projekts definiert ist:

```
OPENROUTER_API_KEY=your_openrouter_api_key_here
```

2. Alternativ können Sie den API-Schlüssel auch direkt in der MATLAB-Session setzen:

```matlab
setenv('OPENROUTER_API_KEY', 'your_openrouter_api_key_here');
```

### Verwendung

Die API kann über die `APICaller`-Klasse verwendet werden:

```matlab
% Beispiel für einen API-Aufruf
options = struct();
options.model = 'microsoft/mai-ds-r1:free'; % OpenRouter-Modell
options.temperature = 0.7;
options.system_message = 'Du bist ein BPMN-Experte.';

prompt = 'Erstelle ein BPMN-Diagramm für einen Pizza-Lieferservice.';
response = APICaller.sendPrompt(prompt, options);

% Verarbeitung der Antwort
content = response.choices(1).message.content;
disp(content);
```

### Verfügbare Modelle

Das System ist standardmäßig auf `microsoft/mai-ds-r1:free` konfiguriert, aber OpenRouter unterstützt auch andere Modelle. Um ein anderes Modell zu verwenden, ändern Sie die `model`-Option beim API-Aufruf.

### Technische Implementierung

Die Implementierung verwendet `curl` zur Kommunikation mit der OpenRouter API und stellt sicher, dass alle erforderlichen HTTP-Header korrekt gesetzt sind. Die API-Antworten werden in ein Format konvertiert, das mit dem Rest des BPMN MATLAB-Projekts kompatibel ist.

### Fehlerbehandlung

Wenn beim API-Aufruf ein Fehler auftritt, wird eine detaillierte Fehlermeldung ausgegeben. Stellen Sie sicher, dass:

1. Ihr API-Schlüssel korrekt ist und gültigen Zugriff auf die OpenRouter API hat
2. Das ausgewählte Modell für Ihren API-Schlüssel verfügbar ist
3. Eine Internetverbindung besteht

## Testen der API-Integration

Ein Testskript ist in `/tests/TestOpenRouterAPI.m` verfügbar. Führen Sie es aus, um die API-Integration zu überprüfen.

```matlab
run('/tests/TestOpenRouterAPI.m')
```