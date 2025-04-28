#!/usr/bin/env python3
"""
Example script for generating a complete BPMN process.

This script demonstrates how to use the DataGenerator to generate a complete BPMN process
with process definitions, elements, and flows.
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
from src.api.schema_loader import SchemaLoader
from src.api.validation_layer import ValidationLayer
from src.util.config import Config

def main():
    """Main function that generates a complete BPMN process"""
    # Ensure environment variables are loaded
    if not Config.OPENROUTER_API_KEY:
        print("ERROR: OPENROUTER_API_KEY is missing in the environment or .env file")
        print("Please set this key and restart.")
        return
    
    print("-" * 50)
    print("BPMN Process Generator Demo")
    print("-" * 50)
    
    # Get product description from user
    product_description = input("Enter a product description (or press Enter for the default value): ")
    if not product_description:
        product_description = "An automated order processing system for an online retail company"
    
    print(f"\nGenerating BPMN process for: {product_description}")
    
    # Prepare API options
    api_options = APIConfig.get_default_options()
    api_options['debug'] = True
    
    # Load schema
    schema = SchemaLoader.load()
    
    # Initialize context for generation
    context = {
        'description': product_description
    }
    
    # 1. Generate process phases
    print("\n1. Generating process phases...")
    prompt = PromptBuilder.build_process_map_prompt(product_description)
    phases = DataGenerator.call_llm(APIConfig.format_prompt(prompt), api_options)
    context['phases'] = phases
    
    print(f"   ✅ {len(phases)} process phases generated.")
    
    # 2. Generate process definitions
    print("\n2. Generating process definitions...")
    proc_prompt = PromptBuilder.build_entity_prompt('process_definitions', schema['process_definitions'], context, 1)
    proc_data = DataGenerator.call_llm(APIConfig.format_prompt(proc_prompt), api_options)
    
    # Validate the generated process definitions
    proc_data = ValidationLayer.validate('process_definitions', proc_data, schema['process_definitions'], context)
    context['process_definitions'] = proc_data
    
    print(f"   ✅ Process definition generated: {proc_data[0].get('process_name', 'Unnamed')}")
    
    # 3. Generate BPMN elements
    print("\n3. Generating BPMN elements...")
    elements_prompt = PromptBuilder.build_phase_entities_prompt('process', 'BPMN Elements', 
                                                               [p['process_id'] for p in proc_data], 10)
    elements_data = DataGenerator.call_llm(APIConfig.format_prompt(elements_prompt), api_options)
    
    # Validate the generated BPMN elements
    elements_data = ValidationLayer.validate('bpmn_elements', elements_data, schema['bpmn_elements'], context)
    context['bpmn_elements'] = elements_data
    context['allElementRows'] = elements_data
    
    print(f"   ✅ {len(elements_data)} BPMN elements generated.")
    
    # Count element types
    element_types = {}
    for elem in elements_data:
        elem_type = elem.get('element_type', 'unknown')
        if elem_type not in element_types:
            element_types[elem_type] = 0
        element_types[elem_type] += 1
    
    for elem_type, count in element_types.items():
        print(f"      - {elem_type}: {count}")
    
    # 4. Generate Sequence Flows
    print("\n4. Generating Sequence Flows...")
    flows_prompt = PromptBuilder.build_flow_prompt(context)
    flows_data = DataGenerator.call_llm(APIConfig.format_prompt(flows_prompt), api_options)
    
    # Validate the generated Sequence Flows
    flows_data = ValidationLayer.validate('sequence_flows', flows_data, schema['sequence_flows'], context)
    context['sequence_flows'] = flows_data
    context['allFlowRows'] = flows_data
    
    print(f"   ✅ {len(flows_data)} Sequence Flows generated.")
    
    # 5. Semantic validation of the entire model
    print("\n5. Performing semantic validation...")
    issues = ValidationLayer.validate_semantic(context)
    
    if issues:
        print(f"   ⚠️ {len(issues)} semantic issues found:")
        for issue in issues:
            print(f"      - {issue['problem_type']}: {issue['description']}")
    else:
        print("   ✅ No semantic issues found.")
    
    # Save the generated data
    output_dir = os.path.join(os.path.dirname(__file__), "../output")
    os.makedirs(output_dir, exist_ok=True)
    
    # Create filename from timestamp and product description
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_desc = "".join(c if c.isalnum() else "_" for c in product_description[:30])
    output_file = os.path.join(output_dir, f"bpmn_process_{timestamp}_{safe_desc}.json")
    
    # Save complete context as JSON
    output_data = {
        'product_description': product_description,
        'timestamp': datetime.now().isoformat(),
        'process_definitions': context.get('process_definitions', []),
        'phases': context.get('phases', []),
        'bpmn_elements': context.get('bpmn_elements', []),
        'sequence_flows': context.get('sequence_flows', []),
        'semantic_issues': issues
    }
    
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)
        
    print(f"\nThe generated process data has been saved to {output_file}.")
    
if __name__ == "__main__":
    main()