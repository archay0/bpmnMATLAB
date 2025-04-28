#!/usr/bin/env python3
"""
BPMN Data Generation CLI

Provides a command-line interface for generating BPMN data from product descriptions.
"""

import os
import sys
import traceback
import argparse
from src.api.data_generation_pipeline import DataGenerationPipeline
from src.api.api_config import APIConfig
from src.bridges.bpmn_generator import BPMNGenerator

# Add DEFAULT_MODEL to APIConfig if not exists
if not hasattr(APIConfig, 'DEFAULT_MODEL'):
    APIConfig.DEFAULT_MODEL = "anthropic/claude-3-haiku-20240307"

def main():
    """Main entry point for the BPMN data generation CLI"""
    
    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description='Generate BPMN data from a product or process description.',
        formatter_class=argparse.RawTextHelpFormatter
    )
    
    parser.add_argument(
        'description',
        help='Description of the product or process to model',
        nargs='?',
        default=None
    )
    
    parser.add_argument(
        '--interactive', '-i',
        action='store_true',
        help='Run in interactive mode (prompt for input)'
    )
    
    parser.add_argument(
        '--model', '-m',
        help=f'LLM model to use (default: {APIConfig.DEFAULT_MODEL})',
        default=APIConfig.DEFAULT_MODEL
    )
    
    parser.add_argument(
        '--temperature', '-t',
        help='Temperature for LLM generation (0.0-1.0)',
        type=float,
        default=0.7
    )
    
    parser.add_argument(
        '--phases',
        help='Number of process phases to generate',
        type=int,
        default=5
    )
    
    parser.add_argument(
        '--elements', '-e', 
        help='Number of BPMN elements to generate',
        type=int,
        default=15
    )
    
    parser.add_argument(
        '--flows', '-f',
        help='Number of sequence flows to generate',
        type=int,
        default=20
    )
    
    parser.add_argument(
        '--output-dir', '-o',
        help='Output directory for generated files',
        default=None
    )
    
    parser.add_argument(
        '--debug', '-d',
        action='store_true',
        help='Enable debug mode with additional output'
    )
    
    parser.add_argument(
        '--no-xml',
        action='store_true',
        help='Skip BPMN XML generation (generate only JSON data)'
    )
    
    args = parser.parse_args()
    
    # Always enable debug mode for now
    args.debug = True
    
    # Check if running in interactive mode or description provided
    product_description = args.description
    
    if args.interactive or not product_description:
        print("=" * 60)
        print("BPMN Data Generation CLI")
        print("=" * 60)
        print("This tool generates BPMN data from a product or process description.")
        print("The data will be processed through the complete generation pipeline:")
        print("  1. Process phases")
        print("  2. Process definitions")
        print("  3. BPMN elements (tasks, events, gateways)")
        print("  4. Sequence flows")
        print("  5. Resources (optional)")
        print("  6. Logical integrity validation")
        print("  7. BPMN XML generation")
        print()
        
        product_description = input("Enter product/process description: ")
        if not product_description:
            print("Error: Product description is required.")
            return 1
    
    # Configure API options    
    api_options = {
        'model': args.model,
        'temperature': args.temperature,
        'debug': args.debug
    }
    
    # Configure batch sizes
    batch_sizes = {
        'phases': args.phases,
        'processes': 1,  # Always generate 1 process definition
        'elements': args.elements,
        'flows': args.flows,
        'resources': 5   # Default resource count
    }
    
    try:
        print(f"\nGenerating BPMN data for: {product_description}")
        print(f"Model: {api_options['model']}, Temperature: {api_options['temperature']}\n")
        
        # Run the pipeline
        pipeline = DataGenerationPipeline(
            product_description=product_description,
            api_options=api_options,
            output_dir=args.output_dir
        )
        
        # Execute the pipeline
        try:
            context = pipeline.run(batch_sizes=batch_sizes)
                
            # Generate BPMN XML file if not disabled
            if not args.no_xml:
                print("\n7. Generating BPMN 2.0 XML file...")
                
                # Setup the BPMN generator
                bpmn_output_path = os.path.join(pipeline.output_dir, "generated_process.bpmn")
                bpmn_generator = BPMNGenerator(output_path=bpmn_output_path)
                
                # Generate the BPMN XML
                xml_path = bpmn_generator.generate_from_context(context)
                print(f"   BPMN XML file generated: {xml_path}")
            
            print("\nData generation completed successfully!")
            print(f"Results available in: {pipeline.output_dir}")
            
        except Exception as e:
            print(f"\nError during pipeline execution: {str(e)}")
            if args.debug:
                print("\nDetailed error information:")
                traceback.print_exc()
            return 1
        
        return 0
        
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
        return 130
        
    except Exception as e:
        print(f"\nError: {str(e)}")
        if args.debug:
            traceback.print_exc()
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"Critical error: {str(e)}")
        traceback.print_exc()
        sys.exit(1)