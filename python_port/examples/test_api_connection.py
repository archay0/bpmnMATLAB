#!/usr/bin/env python3
"""
Test script to verify the OpenRouter API connection.

This script checks if the OpenRouter API connection works correctly
with Microsoft/Mai-DS-R1:Free model.
"""

import os
import sys
import json
from datetime import datetime

# Add the source directory to the module path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../')))

from src.api.data_generator import DataGenerator
from src.api.api_config import APIConfig
from src.util.config import Config

def main():
    """Main function testing the API connection"""
    # Ensure environment variables are loaded
    if not Config.OPENROUTER_API_KEY:
        print("ERROR: OPENROUTER_API_KEY is missing in environment or .env file")
        print("Please set this key and restart.")
        return
    
    print("-" * 50)
    print("OpenRouter API Connection Test")
    print("-" * 50)
    print(f"Using API key: {Config.OPENROUTER_API_KEY[:8]}...{Config.OPENROUTER_API_KEY[-4:]}")
    print(f"Using model: {Config.DEFAULT_MODEL}")
    print("-" * 50)
    
    # Prepare a simple test prompt
    test_prompt = "Please respond with a simple 'Hello World!' message to confirm connectivity."
    
    # Get default API options
    api_options = APIConfig.get_default_options()
    api_options['debug'] = True
    
    # Time the API response time
    start_time = datetime.now()
    print(f"Sending test prompt to {Config.DEFAULT_MODEL}...")
    
    try:
        # Call the API
        formatted_prompt = APIConfig.format_prompt(test_prompt)
        response = DataGenerator.call_llm(formatted_prompt, api_options)
        
        # Calculate elapsed time
        elapsed = (datetime.now() - start_time).total_seconds()
        
        print("-" * 50)
        print(f"API call successful! (Time: {elapsed:.2f} seconds)")
        print("-" * 50)
        print("Response:")
        print(response)
        print("-" * 50)
        
        return True
    except Exception as e:
        # Calculate elapsed time even for failures
        elapsed = (datetime.now() - start_time).total_seconds()
        
        print("-" * 50)
        print(f"API call failed! (Time: {elapsed:.2f} seconds)")
        print("-" * 50)
        print(f"Error: {str(e)}")
        print("-" * 50)
        
        return False

if __name__ == "__main__":
    main()