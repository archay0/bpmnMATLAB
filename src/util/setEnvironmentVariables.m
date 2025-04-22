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
    % Gemäß GitHub Models API Dokumentation:
    % - Die Umgebungsvariable heißt GITHUB_TOKEN (nicht GITHUB_API_TOKEN)
    % - Der Token benötigt "models:read" Berechtigungen
    % - Der Endpunkt ist: https://models.github.ai/inference
    % - Das Modell ist: openai/gpt-4.1-mini (oder openai/o1 für Codex)
    %
    % Siehe auch: loadEnvironment, getenv

    fprintf('Setze Umgebungsvariablen für API-Zugriff...\n');

    % HIER DEINE TATSÄCHLICHEN API-SCHLÜSSEL UND ANDERE UMGEBUNGSVARIABLEN EINFÜGEN
    % =============================================================================
    
    % GitHub Models API Token - RICHTIGER NAME IST GITHUB_TOKEN
    % Ersetze 'your_github_token_here' durch deinen tatsächlichen GitHub-Token
    % HINWEIS: Der Token muss "models:read" Berechtigungen haben
    setenv('GITHUB_TOKEN', 'your_github_token_here');
    
    % Für Kompatibilität mit bestehender Codebasis auch unter GITHUB_API_TOKEN setzen
    setenv('GITHUB_API_TOKEN', getenv('GITHUB_TOKEN'));
    
    % OpenAI API Token (falls benötigt)
    % setenv('OPENAI_API_KEY', 'your_openai_api_key_here');
    
    % =============================================================================
    
    % Bestätige erfolgreiches Setzen (ohne die tatsächlichen Werte anzuzeigen)
    if ~isempty(getenv('GITHUB_TOKEN'))
        fprintf('✓ GITHUB_TOKEN wurde gesetzt.\n');
        
        % Zeige die ersten und letzten 4 Zeichen (für Debugging)
        tokenValue = getenv('GITHUB_TOKEN');
        tokenLength = length(tokenValue);
        if tokenLength > 10
            firstChars = tokenValue(1:4);
            lastChars = tokenValue(end-3:end);
            fprintf('  Token Format: %s...%s (Länge: %d)\n', firstChars, lastChars, tokenLength);
        end
    else
        warning('GITHUB_TOKEN wurde nicht korrekt gesetzt!');
    end
    
    fprintf('Umgebungsvariablen wurden erfolgreich gesetzt.\n');
    
    % Zeige Hilfetext mit Python OpenAI SDK Beispiel
    fprintf('\n--- Beispiel für Verwendung mit Python OpenAI SDK ---\n');
    fprintf('import os\n');
    fprintf('from openai import OpenAI\n\n');
    fprintf('token = os.environ["GITHUB_TOKEN"]  # Verwende diese Umgebungsvariable\n');
    fprintf('endpoint = "https://models.github.ai/inference"\n');
    fprintf('model = "openai/gpt-4.1-mini"  # oder "openai/o1" für Code\n\n');
    fprintf('client = OpenAI(\n');
    fprintf('    base_url=endpoint,\n');
    fprintf('    api_key=token,\n');
    fprintf(')\n\n');
    fprintf('response = client.chat.completions.create(\n');
    fprintf('    messages=[\n');
    fprintf('        { "role": "system", "content": "You are a helpful assistant." },\n');
    fprintf('        { "role": "user", "content": "What is the capital of France?" }\n');
    fprintf('    ],\n');
    fprintf('    temperature=1.0,\n');
    fprintf('    top_p=1.0,\n');
    fprintf('    model=model\n');
    fprintf(')\n\n');
    fprintf('print(response.choices[0].message.content)\n');
    fprintf('--------------------------------------------------------\n\n');
end