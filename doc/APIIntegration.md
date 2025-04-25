nnnnnnnnnnnnnnnnnnnsetenv('OpenRouter_api_Key', 'your_openrouter_api_Key_Here');
nnnnnnn% Example of an API call
noptions.model = 'Microsoft/Mai-DS-R1: Free'; % OpenRouter-Modell
noptions.system_message = 'You are a BPMN expert.';
nprompt = 'Create a BPMN diagram for a pizza delivery service.';
nn% Processing of the answer
nnnnnnnnnnnnnnnnnnnnnnnnnrun('/tests/topenrouterapi.m')
n