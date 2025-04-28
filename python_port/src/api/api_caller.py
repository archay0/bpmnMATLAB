"""
APICaller module handles the communication with language model APIs.
"""

import os
import json
import requests
import time
from ..util.config import Config

class APICaller:
    """
    Handles API calls to language models (OpenRouter API).
    Manages authentication, request formatting, and response handling.
    """
    
    # Updated API endpoint URL for OpenRouter
    OPENROUTER_API_BASE = "https://openrouter.ai/api/v1/chat/completions"
    
    @staticmethod
    def send_prompt(prompt, options=None):
        """
        Sends a prompt to the language model API and returns the response.
        
        Args:
            prompt (str): The prompt text to send
            options (dict, optional): Options to control the API request
                
        Returns:
            dict: The parsed JSON response from the API
            
        Raises:
            ValueError: If API key is missing or API call fails
        """
        if options is None:
            options = {}
            
        # Get API key from environment
        api_key = Config.OPENROUTER_API_KEY
        if not api_key:
            raise ValueError("OpenRouter API key not found. Please set OPENROUTER_API_KEY environment variable.")
        
        # Extract API parameters
        model = options.get('model', "openai/gpt-3.5-turbo")  # Changed to a more reliable model
        temperature = options.get('temperature', Config.DEFAULT_TEMPERATURE)
        
        # Debug output
        if options.get('debug', Config.DEBUG_MODE):
            print(f"--- APICaller: Sending request to model {model} ---")
            print(f"Temperature: {temperature}")
            print(f"Prompt length: {len(prompt)} characters")
            if len(prompt) > 100:
                print(f"Prompt starts with: {prompt[:100]}...")
        
        # Create request data according to OpenRouter's format
        data = {
            "model": model,
            "messages": [
                {"role": "user", "content": prompt}
            ],
            "temperature": temperature,
            "max_tokens": options.get('max_tokens', 1024),
        }
        
        # Remove stream parameter as it can cause issues
        if 'stream' in options and not options['stream']:
            data['stream'] = False
        
        # Add optional parameters if they exist in options
        if 'stop' in options:
            data['stop'] = options['stop']
        if 'top_p' in options:
            data['top_p'] = options['top_p']
        if 'presence_penalty' in options:
            data['presence_penalty'] = options['presence_penalty']
        if 'frequency_penalty' in options:
            data['frequency_penalty'] = options['frequency_penalty']
        
        # Set up headers according to OpenRouter requirements
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": options.get('http_referer', "https://github.com/bpmn-python-port"), 
            "X-Title": options.get('x_title', "BPMN-MATLAB Python Port")
        }
        
        # Make the API call with retry logic
        max_retries = 2
        retry_count = 0
        backoff_time = 1  # Start with 1 second backoff
        
        while retry_count < max_retries:
            try:
                if options.get('debug', Config.DEBUG_MODE):
                    print(f"API attempt {retry_count+1} of {max_retries}")
                
                response = requests.post(
                    APICaller.OPENROUTER_API_BASE,
                    headers=headers,
                    json=data,
                    timeout=30  # Add timeout
                )
                
                # Check for rate limiting and retry if needed
                if response.status_code == 429:
                    retry_count += 1
                    if retry_count < max_retries:
                        time.sleep(backoff_time)
                        backoff_time *= 2  # Exponential backoff
                        continue
                
                # Print actual error content for debugging
                if response.status_code >= 400 and options.get('debug', Config.DEBUG_MODE):
                    print(f"API Error: {response.status_code} - {response.text}")
                
                # Handle response
                response.raise_for_status()
                result = response.json()
                
                # Extract the actual text response based on OpenRouter's format
                if 'choices' in result and len(result['choices']) > 0:
                    choice = result['choices'][0]
                    if 'message' in choice:
                        content = choice['message'].get('content', '')
                        return content
                    elif 'delta' in choice:  # For streaming responses
                        content = choice['delta'].get('content', '')
                        return content
                    elif 'text' in choice:  # Fallback for non-chat models
                        return choice['text']
                
                # If we made it here but couldn't extract content, show the response
                if options.get('debug', Config.DEBUG_MODE):
                    print(f"Unexpected response format: {result}")
                
                return json.dumps(result)  # Return the full response as a string
                
            except requests.exceptions.RequestException as e:
                if options.get('debug', Config.DEBUG_MODE):
                    print(f"Request exception: {str(e)}")
                
                retry_count += 1
                if retry_count < max_retries:
                    time.sleep(backoff_time)
                    backoff_time *= 2  # Exponential backoff
                else:
                    # No fallback, just raise the error
                    raise ValueError(f"API call failed after {max_retries} attempts: {str(e)}")