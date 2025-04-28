#!/usr/bin/env python3
"""
Simple example script to test the DataGenerator module.

This script generates process phases for a simple process using the LLM.
It demonstrates the basic usage of DataGenerator and PromptBuilder.
"""

import os
import sys
import json
from datetime import datetime

# Add the source directory to the module path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../')))

from src.api.data_generator import DataGenerator
from src.api.api_config import APIConfig
from src.api.prompt_builder import PromptBuilder
from src.util.config import Config

def main():
    """Main function that tests the data generator"""
    # Ensure environment variables are loaded
    if not Config.OPENROUTER_API_KEY:
        print("ERROR: OPENROUTER_API_KEY is missing in the environment or .env file")
        print("Please set this key and restart.")
        return
    
    print("-" * 50)
    print("BPMN Data Generator Demo")
    print("-" * 50)
    
    # Get product description from user
    product_description = input("Enter a product description (or press Enter for the default value): ")
    if not product_description:
        product_description = "An automated warehouse management system for an e-commerce company"
    
    print(f"\nGenerating process phases for: {product_description}")
    
    # Prepare API options
    api_options = APIConfig.get_default_options()
    api_options['debug'] = True
    
    # Create prompt with PromptBuilder
    prompt = PromptBuilder.build_process_map_prompt(product_description)
    print("\nSending prompt to the LLM...")
    
    # Time the API response time
    start_time = datetime.now()
    
    # Generate data with DataGenerator
    response = DataGenerator.call_llm(prompt, api_options)
    
    # Time end
    elapsed = (datetime.now() - start_time).total_seconds()
    
    # Output the results
    print(f"\nData successfully generated! (Time: {elapsed:.2f} seconds)")
    print("\nGenerated process phases:")
    print("-" * 50)
    
    # Handle different response formats
    phases = []
    
    # If response is already a list, use it directly
    if isinstance(response, list):
        phases = response
    # If response is a string, try to print it nicely and save as is
    elif isinstance(response, str):
        print("Response received as text:")
        print(response)
        print("-" * 30)
        # Try to save the string as is
        output_dir = os.path.join(os.path.dirname(__file__), "../output")
        os.makedirs(output_dir, exist_ok=True)
        output_file = os.path.join(output_dir, "process_phases_raw.txt")
        
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(response)
            
        print(f"\nThe raw response has been saved to {output_file}.")
        return
    # If response is a dictionary, check if it contains phases
    elif isinstance(response, dict):
        # Check for common patterns in responses
        if "phases" in response:
            phases = response["phases"]
        elif "process_phases" in response:
            phases = response["process_phases"]
        else:
            # Use the dictionary as is (might be a single phase)
            phases = [response]
    
    # Output the generated phases
    if phases:
        for phase in phases:
            print(f"ID: {phase.get('phase_id', 'Unknown')}")
            print(f"Name: {phase.get('phase_name', 'Unnamed')}")
            print(f"Description: {phase.get('description', 'No description')}")
            print("-" * 30)
        
        # Save the data to a JSON file
        output_dir = os.path.join(os.path.dirname(__file__), "../output")
        os.makedirs(output_dir, exist_ok=True)
        output_file = os.path.join(output_dir, "process_phases.json")
        
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(phases, f, indent=2, ensure_ascii=False)
            
        print(f"\nThe generated data has been saved to {output_file}.")
    else:
        print("No phases generated. Check the API connection and input parameters.")

if __name__ == "__main__":
    main()