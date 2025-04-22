function setEnvironmentVariables()
    % setEnvironmentVariables - Direktes Setzen der Umgebungsvariablen in MATLAB
    %
    % Diese Funktion setzt die erforderlichen Umgebungsvariablen direkt,
    % anstatt sie aus einer Datei zu laden. Dieses Skript sollte nicht
    % in Git commitet werden, da es sensible Informationen enthält.
    %
    % Verwendung:
    %   setEnvironmentVariables();
    %
    % API-Konfiguration:
    % - GitHub Models API: Benötigt GITHUB_TOKEN mit "models:read" Berechtigungen
    % - OpenRouter API: Benötigt OPENROUTER_API_KEY
    %
    % Siehe auch: loadEnvironment, getenv

    fprintf('Setze Umgebungsvariablen für API-Zugriff...\n');
    
    % HIER DEINE TATSÄCHLICHEN API-SCHLÜSSEL UND ANDERE UMGEBUNGSVARIABLEN EINFÜGEN
    % =============================================================================
    
    % OpenRouter API Token - RICHTIGER NAME IST OPENROUTER_API_KEY
    % Ersetze 'your_openrouter_api_key_here' durch deinen tatsächlichen OpenRouter-Token
    setenv('OPENROUTER_API_KEY', 'your_openrouter_api_key_here');
    
    % GitHub Models API Token (falls benötigt)
    % setenv('GITHUB_TOKEN', 'your_github_token_here');
    % setenv('GITHUB_API_TOKEN', getenv('GITHUB_TOKEN'));
    
    % OpenAI API Token (falls benötigt)
    % setenv('OPENAI_API_KEY', 'your_openai_api_key_here');
    
    % =============================================================================
    
    % Bestätige erfolgreiches Setzen (ohne die tatsächlichen Werte anzuzeigen)
    if ~isempty(getenv('OPENROUTER_API_KEY'))
        fprintf('✓ OPENROUTER_API_KEY gesetzt\n');
    else
        fprintf('✗ OPENROUTER_API_KEY nicht gesetzt\n');
    end
    
    if ~isempty(getenv('GITHUB_TOKEN'))
        fprintf('✓ GITHUB_TOKEN gesetzt\n');
    else
        fprintf('✗ GITHUB_TOKEN nicht gesetzt\n');
    end
    
    fprintf('Umgebungsvariablen wurden erfolgreich gesetzt.\n');
    
    % Ausgabe eines Beispiels für OpenRouter API-Nutzung
    fprintf('\n--------------------------------------------------------\n');
    fprintf('Beispiel für OpenRouter API-Nutzung (Python):\n\n');
    fprintf('import requests\n\n');
    fprintf('openrouter_url = "https://openrouter.ai/api/v1/chat/completions"\n');
    fprintf('api_key = "%s"  # Dein OpenRouter API-Schlüssel\n', 'YOUR_OPENROUTER_API_KEY');
    fprintf('model = "microsoft/mai-ds-r1:free"\n\n');
    fprintf('headers = {\n');
    fprintf('    "Content-Type": "application/json",\n');
    fprintf('    "Authorization": f"Bearer {api_key}",\n');
    fprintf('    "HTTP-Referer": "http://localhost:3000",\n');
    fprintf('    "X-Title": "BPMN MATLAB Generator"\n');
    fprintf('}\n\n');
    fprintf('data = {\n');
    fprintf('    "messages": [\n');
    fprintf('        { "role": "system", "content": "You are a helpful assistant." },\n');
    fprintf('        { "role": "user", "content": "What is the capital of France?" }\n');
    fprintf('    ],\n');
    fprintf('    "temperature": 0.7,\n');
    fprintf('    "model": model\n');
    fprintf('}\n\n');
    fprintf('response = requests.post(openrouter_url, headers=headers, json=data)\n');
    fprintf('print(response.json()["choices"][0]["message"]["content"])\n');
    fprintf('--------------------------------------------------------\n\n');
end