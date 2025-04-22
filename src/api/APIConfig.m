classdef APIConfig
    % APIConfig enthält zentrale Konfigurationseinstellungen für die API-Integration
    
    properties (Constant)
        % Standard-API-Modellkonfiguration
        DEFAULT_MODEL = 'microsoft/mai-ds-r1:free';
        DEFAULT_TEMPERATURE = 0.7;
        DEFAULT_SYSTEM_MESSAGE = 'Du bist ein Experte für Business Process Model and Notation (BPMN). Generiere präzise, konsistente und standardkonforme BPMN-Informationen.';
        
        % Debug-Einstellungen
        DEBUG_MODE = false; % Auf true setzen für ausführliche API-Protokollierung
        
        % Definiert die Formatierungsanweisungen für die API-Antworten
        FORMAT_INSTRUCTIONS = ['Antworte ausschließlich mit einem gültigen JSON-Array oder -Objekt. ', ...
                             'Achte auf eine korrekte und vollständige JSON-Syntax ohne zusätzlichen Text.'];
    end
    
    methods(Static)
        function options = getDefaultOptions()
            % Gibt die Standardoptionen für API-Aufrufe zurück
            options = struct();
            options.model = APIConfig.DEFAULT_MODEL;
            options.temperature = APIConfig.DEFAULT_TEMPERATURE;
            options.system_message = APIConfig.DEFAULT_SYSTEM_MESSAGE;
            options.debug = APIConfig.DEBUG_MODE;
        end
        
        function prompt = formatPrompt(prompt)
            % Fügt Format-Anweisungen zum Prompt hinzu
            prompt = sprintf('%s\n\n%s', prompt, APIConfig.FORMAT_INSTRUCTIONS);
        end
    end
end