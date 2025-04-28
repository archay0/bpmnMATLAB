"""
DataGenerator module provides methods to call LLM API and process the response.
"""

import json
import re
from .api_caller import APICaller

class DataGenerator:
    """
    Provides methods to process prompts, call the LLM API, 
    and convert the response to structured data.
    """
    
    @staticmethod
    def call_llm(prompt, options=None):
        """
        Sends a prompt to the language model and parses the response into Python data.
        Includes error handling and retry logic for malformed JSON responses.
        
        Args:
            prompt (str): The prompt to send to the LLM
            options (dict, optional): Options for API call
            
        Returns:
            list/dict: The processed data from the LLM
        """
        if options is None:
            options = {}
            
        # Initialize variables
        max_retries = 1  # Allow one retry
        retry_count = 0
        rows = []  # Initialize output
        last_error = None
        text = ""
        
        while retry_count <= max_retries:
            try:
                # Use the current prompt (original or fix-it version)
                current_prompt = prompt
                
                # Make the API call
                print(f"--- Calling LLM (Attempt {retry_count + 1}/{max_retries + 1}) ---")
                text = APICaller.send_prompt(current_prompt, options)
                
                # Process the response
                if not text:
                    if retry_count < max_retries:
                        retry_count += 1
                        print("Empty response received, retrying...")
                        continue
                    else:
                        print("Empty response on final attempt.")
                        return []  # Return empty list after all retries
                
                # Special handling for models that might return JSON as string
                if isinstance(text, str) and text.startswith("{") and "message" in text and "Hello" not in text:
                    try:
                        # Try to parse it as a dict that contains a message with JSON
                        parsed_container = json.loads(text)
                        if isinstance(parsed_container, dict) and "message" in parsed_container:
                            message_content = parsed_container["message"]
                            if isinstance(message_content, str):
                                # Try to parse the message content as JSON
                                text = message_content
                    except:
                        pass  # Continue with regular processing if this fails
                
                # Clean the text - remove markdown code blocks if present
                text = DataGenerator._clean_json_text(text)
                
                # Try to parse JSON
                try:
                    rows = json.loads(text)
                    
                    # Validate the result based on expected format
                    if isinstance(rows, (list, dict)):
                        return rows
                    else:
                        raise ValueError(f"Response is not a list or dictionary: {type(rows)}")
                    
                except json.JSONDecodeError as je:
                    last_error = je
                    if retry_count < max_retries:
                        # Create a fix-it prompt
                        fix_prompt = (
                            f"The following text should be valid JSON but has errors. "
                            f"Please fix the errors and return only the corrected JSON:\n\n{text}"
                        )
                        prompt = fix_prompt
                        retry_count += 1
                        print(f"JSON decode error: {je}. Retrying with fix-it prompt...")
                        continue
                    else:
                        # Try to extract JSON-like content as a last resort
                        print(f"Failed to parse JSON after retries. Attempting extraction...")
                        rows = DataGenerator._extract_json_content(text)
                        if rows:
                            return rows
                        else:
                            print("JSON extraction failed.")
                            return []  # Return empty list if JSON extraction fails
            
            except Exception as e:
                last_error = e
                if retry_count < max_retries:
                    retry_count += 1
                    print(f"Error: {e}. Retrying...")
                    continue
                else:
                    print(f"Error on final attempt: {e}")
                    return []  # Return empty list after all retries
        
        # This should only be reached if all retries failed
        return []  # Return empty list as a last resort
    
    @staticmethod
    def _clean_json_text(text):
        """
        Cleans text to extract valid JSON from possible markdown or text.
        
        Args:
            text (str): Text possibly containing JSON content
            
        Returns:
            str: Cleaned text with only JSON content
        """
        # Remove code block markers
        text = re.sub(r'```(?:json)?\s*|\s*```', '', text)
        
        # Find the first { or [ and the last } or ]
        start_match = re.search(r'[\[\{]', text)
        end_match = re.search(r'[\]\}](?=[^\]\}]*$)', text)
        
        if start_match and end_match:
            start = start_match.start()
            end = end_match.start() + 1
            return text[start:end]
        
        return text
    
    @staticmethod
    def _extract_json_content(text):
        """
        Attempts to extract JSON-like content from text when parsing fails.
        This is a fallback method for handling malformed JSON.
        
        Args:
            text (str): Text that failed JSON parsing
            
        Returns:
            list/dict: Extracted data or empty list if extraction fails
        """
        try:
            # Try to find content within square brackets or braces
            list_match = re.search(r'\[(.*)\]', text, re.DOTALL)
            dict_match = re.search(r'\{(.*)\}', text, re.DOTALL)
            
            if list_match:
                # Try to reconstruct a list
                items = list_match.group(1).split('},')
                if len(items) > 1:
                    reconstructed = '['
                    for i, item in enumerate(items):
                        if i < len(items) - 1:
                            reconstructed += item + '},'
                        else:
                            reconstructed += item
                    reconstructed += ']'
                    return json.loads(reconstructed)
            
            if dict_match:
                # Try to reconstruct a dictionary
                return json.loads('{' + dict_match.group(1) + '}')
                
        except Exception as e:
            print(f"Extraction attempt failed: {e}")
        
        return []