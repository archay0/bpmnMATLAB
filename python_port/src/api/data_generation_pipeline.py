"""
Data Generation Pipeline

Coordinates the entire BPMN data generation process from product description to validated tables.
"""

import os
import json
import time
from datetime import datetime
from .data_generator import DataGenerator
from .prompt_builder import PromptBuilder
from .schema_loader import SchemaLoader
from .validation_layer import ValidationLayer
from .logical_validator import LogicalValidator
from .api_config import APIConfig

class DataGenerationPipeline:
    """
    Orchestrates the complete pipeline for BPMN data generation:
    1. Generating process phases
    2. Creating process definitions
    3. Generating BPMN elements (tasks, events, gateways)
    4. Creating sequence flows
    5. Validating the integrity of the overall model
    """

    def __init__(self, product_description=None, api_options=None, output_dir=None):
        """
        Initialize the pipeline with product description and options
        
        Args:
            product_description (str): Description of the product or process to model
            api_options (dict): Options for API calls (model, temperature, etc.)
            output_dir (str): Directory to save output files
        """
        self.product_description = product_description
        self.api_options = api_options or APIConfig.get_default_options()
        
        # Include product description in API options for reference
        if product_description:
            self.api_options['product_description'] = product_description
            
        # Setup output directory
        base_output_dir = output_dir or os.path.abspath(os.path.join(os.path.dirname(__file__), '../../output'))
        
        # Create timestamped subfolder for this run
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.run_name = f"run_{timestamp}"
        self.output_dir = os.path.join(base_output_dir, self.run_name)
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Load schemas
        self.schemas = SchemaLoader.load()
        
        # Initialize context to store all generated data
        self.context = {}
        
        # Performance metrics
        self.timings = {}
        
    def run(self, batch_sizes=None):
        """
        Run the complete pipeline to generate BPMN data
        
        Args:
            batch_sizes (dict): Number of items to generate for each entity type
                                e.g. {'elements': 10, 'flows': 15}
                                
        Returns:
            dict: The complete context with all generated data
        """
        if not self.product_description:
            raise ValueError("Product description is required to run the pipeline")
            
        # Default batch sizes if not provided
        if batch_sizes is None:
            batch_sizes = {
                'phases': 5,
                'processes': 1,
                'elements': 10,
                'max_element_batches': 3,
                'flows': 15,
                'resources': 5,
                'pools': 2,
                'lanes_per_pool': 3
            }
            
        # Record start time
        pipeline_start = time.time()
        success = True
        data_generated = False
        
        try:
            # Step 1: Generate process phases
            try:
                self._generate_phases(batch_sizes.get('phases', 5))
                if self.context.get('process_phases'):
                    data_generated = True
            except Exception as e:
                print(f"Phase generation failed: {str(e)}")
                success = False
            
            # Step 2: Generate process definitions
            if success and data_generated:
                try:
                    self._generate_process_definitions(batch_sizes.get('processes', 1))
                    if not self.context.get('process_definitions'):
                        data_generated = False
                except Exception as e:
                    print(f"Process definition generation failed: {str(e)}")
                    success = False
                    data_generated = False
            
            # Step 3: Generate BPMN elements (tasks, events, gateways) recursively
            if success and data_generated:
                try:
                    elements = self._generate_bpmn_elements_recursive(
                        batch_sizes.get('elements', 10),
                        batch_sizes.get('max_element_batches', 3)
                    )
                    if not elements or len(elements) == 0:
                        data_generated = False
                except Exception as e:
                    print(f"BPMN elements generation failed: {str(e)}")
                    success = False
                    data_generated = False
            
            # Step 4: Generate pools and lanes based on generated elements
            if success and data_generated and self.context.get('bpmn_elements'):
                try:
                    pool_batch_sizes = {
                        'pools': batch_sizes.get('pools', 2),
                        'lanes_per_pool': batch_sizes.get('lanes_per_pool', 3)
                    }
                    self._generate_pools_and_lanes(pool_batch_sizes)
                except Exception as e:
                    print(f"Pools and lanes generation failed: {str(e)}")
                    # Continue even if pool/lane generation fails
            
            # Step 5: Generate sequence flows
            if success and data_generated and self.context.get('bpmn_elements'):
                try:
                    self._generate_sequence_flows(batch_sizes.get('flows', 15))
                    if not self.context.get('sequence_flows'):
                        data_generated = False
                except Exception as e:
                    print(f"Sequence flows generation failed: {str(e)}")
                    success = False
                    data_generated = False
                
            # Step 6: Generate resources (optional)
            if success and data_generated and self.context.get('bpmn_elements') and batch_sizes.get('resources', 0) > 0:
                try:
                    self._generate_resources(batch_sizes.get('resources', 5))
                except Exception as e:
                    print(f"Resource generation failed: {str(e)}")
                    # Continue even if resource generation fails
                
            # Step 7: Check for logical integrity issues
            if success and data_generated and self.context.get('bpmn_elements') and self.context.get('sequence_flows'):
                try:
                    self._validate_integrity()
                except Exception as e:
                    print(f"Integrity validation failed: {str(e)}")
                    # Continue even if integrity validation fails
                
        except Exception as e:
            print(f"Pipeline error: {str(e)}")
            success = False
            
        finally:
            # Save complete context regardless of success
            self._save_json('complete_context.json', self.context)
            
            # Save timing information
            total_time = time.time() - pipeline_start
            self.timings['total'] = total_time
            self._save_json('performance_metrics.json', self.timings)
            
            # Add product specifications to the context
            self._add_product_specifications()
            
            # Generate summary report
            summary = {
                'timestamp': datetime.now().isoformat(),
                'product_description': self.product_description,
                'success': success and data_generated,
                'phases_count': len(self.context.get('process_phases', [])),
                'processes_count': len(self.context.get('process_definitions', [])),
                'elements_count': len(self.context.get('bpmn_elements', [])),
                'flows_count': len(self.context.get('sequence_flows', [])),
                'resources_count': len(self.context.get('resources', [])),
                'pools_count': len(self.context.get('pools', [])),
                'lanes_count': len(self.context.get('lanes', [])),
                'total_runtime_seconds': total_time
            }
            self._save_json('generation_summary.json', summary)
            
            print(f"Pipeline completed {'successfully' if success and data_generated else 'with errors'} in {total_time:.2f} seconds")
            print(f"Output files saved to: {self.output_dir}")
            
            # Return the context even if there were errors
            return self.context
            
    def _generate_phases(self, batch_size):
        """Generate process phases"""
        start_time = time.time()
        
        print(f"1. Generating {batch_size} process phases...")
        prompt = PromptBuilder.build_process_map_prompt(self.product_description)
        phases = DataGenerator.call_llm(prompt, self.api_options)
        
        # Save raw output
        self._save_json('raw_phases.json', phases)
        
        # Validate
        if phases:
            valid_phases = ValidationLayer.validate('process_phases', phases)
            self.context['process_phases'] = valid_phases
        
        # Store timing
        self.timings['phases'] = time.time() - start_time
        
        print(f"   Generated {len(self.context.get('process_phases', []))} valid phases")
    
    def _generate_process_definitions(self, batch_size):
        """Generate process definitions"""
        start_time = time.time()
        
        print(f"2. Generating {batch_size} process definition(s)...")
        
        # Get the schema
        schema = self.schemas.get('process_definitions')
        
        # Build prompt with phases as context
        context_data = {'phases': self.context.get('process_phases', [])}
        prompt = PromptBuilder.build_entity_prompt('process_definitions', schema, 
                                                  context_data, batch_size)
        process_defs = DataGenerator.call_llm(prompt, self.api_options)
        
        # Save raw output
        self._save_json('raw_process_definitions.json', process_defs)
        
        # Validate
        valid_processes = ValidationLayer.validate('process_definitions', process_defs)
        self.context['process_definitions'] = valid_processes
        
        # Store timing
        self.timings['process_definitions'] = time.time() - start_time
        
        print(f"   Generated {len(self.context.get('process_definitions', []))} valid process definitions")
    
    def _generate_bpmn_elements(self, batch_size):
        """Generate BPMN elements (tasks, events, gateways)"""
        start_time = time.time()
        
        print(f"3. Generating {batch_size} BPMN elements...")
        
        # Get the schema
        schema = self.schemas.get('bpmn_elements')
        
        # If we have a process definition, use it as context
        if self.context.get('process_definitions') and len(self.context['process_definitions']) > 0:
            process_def = self.context['process_definitions'][0]
            prompt = PromptBuilder.build_entity_prompt('bpmn_elements', schema, process_def, batch_size)
            elements = DataGenerator.call_llm(prompt, self.api_options)
            
            # Save raw output
            self._save_json('raw_bpmn_elements.json', elements)
            
            # Validate with the process context
            valid_elements = ValidationLayer.validate('bpmn_elements', elements, 
                                                     {'process_definitions': self.context['process_definitions']})
            self.context['bpmn_elements'] = valid_elements
            # Also store as allElementRows for compatibility with other tools
            self.context['allElementRows'] = valid_elements
        else:
            print("   No process definitions available. Skipping elements generation.")
        
        # Store timing
        self.timings['bpmn_elements'] = time.time() - start_time
        
        print(f"   Generated {len(self.context.get('bpmn_elements', []))} valid BPMN elements")
    
    def _generate_bpmn_elements_recursive(self, batch_size, max_batches=3):
        """
        Generate BPMN elements recursively in batches, building upon previous elements
        
        Args:
            batch_size (int): Number of elements to generate per batch
            max_batches (int): Maximum number of batches to generate
            
        Returns:
            list: All generated BPMN elements
        """
        start_time = time.time()
        
        print(f"3. Generating BPMN elements (up to {batch_size*max_batches} total in {max_batches} batches)...")
        
        # Get the schema
        schema = self.schemas.get('bpmn_elements')
        
        # If we don't have a process definition, we can't generate elements
        if not self.context.get('process_definitions') or len(self.context['process_definitions']) == 0:
            print("   No process definitions available. Skipping elements generation.")
            return []
            
        process_def = self.context['process_definitions'][0]
        all_elements = []
        
        # Initialize BPMN elements in context if they don't exist
        if 'bpmn_elements' not in self.context:
            self.context['bpmn_elements'] = []
            
        # Generate elements in batches
        for batch_num in range(1, max_batches + 1):
            print(f"   Generating batch {batch_num}/{max_batches} of elements...")
            
            # Build prompt with current context (including previously generated elements)
            prompt_context = {
                **process_def,
                'existing_elements': self.context.get('bpmn_elements', []),
                'phases': self.context.get('process_phases', [])
            }
            
            prompt = PromptBuilder.build_entity_prompt('bpmn_elements', schema, prompt_context, batch_size)
            elements = DataGenerator.call_llm(prompt, self.api_options)
            
            # Save raw output for this batch
            self._save_json(f'raw_bpmn_elements_batch_{batch_num}.json', elements)
            
            # Skip further processing if no elements were generated
            if not elements:
                print(f"   Batch {batch_num} returned no elements. Stopping element generation.")
                break
                
            # Validate with the current context
            valid_elements = ValidationLayer.validate('bpmn_elements', elements, {
                'process_definitions': self.context['process_definitions'],
                'existing_elements': self.context.get('bpmn_elements', [])
            })
            
            if not valid_elements:
                print(f"   Batch {batch_num} did not produce any valid elements. Stopping element generation.")
                break
                
            # Add the new elements to our collection
            all_elements.extend(valid_elements)
            
            # Update the context with the new elements
            self.context['bpmn_elements'] = all_elements
            # Also update allElementRows for compatibility
            self.context['allElementRows'] = all_elements
            
            # Save the current state of all elements
            self._save_json('bpmn_elements.json', all_elements)
            
            print(f"   Batch {batch_num} added {len(valid_elements)} elements (total: {len(all_elements)})")
            
            # Stop if we've generated enough elements or if this batch was smaller than requested
            if len(all_elements) >= batch_size * max_batches or len(valid_elements) < batch_size:
                break
                
        # Store timing
        self.timings['bpmn_elements'] = time.time() - start_time
        
        print(f"   Generated a total of {len(all_elements)} valid BPMN elements")
        return all_elements
    
    def _generate_sequence_flows(self, batch_size):
        """Generate sequence flows between elements"""
        start_time = time.time()
        
        print("4. Generating sequence flows...")
        
        # Need elements to create flows between them
        if not self.context.get('bpmn_elements'):
            print("   No BPMN elements available. Skipping flow generation.")
            return
        
        # Build prompt with elements as context
        prompt = PromptBuilder.build_flow_prompt(self.context)
        flows = DataGenerator.call_llm(prompt, self.api_options)
        
        # Save raw output
        self._save_json('raw_sequence_flows.json', flows)
        
        # Validate
        valid_flows = ValidationLayer.validate('sequence_flows', flows, self.context)
        self.context['sequence_flows'] = valid_flows
        # Also store as allFlowRows for compatibility with other tools
        self.context['allFlowRows'] = valid_flows
        
        # Store timing
        self.timings['sequence_flows'] = time.time() - start_time
        
        print(f"   Generated {len(self.context.get('sequence_flows', []))} valid sequence flows")
    
    def _generate_resources(self, batch_size):
        """Generate resources for tasks"""
        start_time = time.time()
        
        print(f"5. Generating {batch_size} resources...")
        
        # Need elements to assign resources to them
        if not self.context.get('bpmn_elements'):
            print("   No BPMN elements available. Skipping resource generation.")
            return
            
        # Get the schema
        schema = self.schemas.get('resources')
        
        # Build prompt with elements as context
        prompt = PromptBuilder.build_resource_prompt(self.context, schema)
        resources = DataGenerator.call_llm(prompt, self.api_options)
        
        # Save raw output
        self._save_json('raw_resources.json', resources)
        
        # Validate
        valid_resources = ValidationLayer.validate('resources', resources, self.context)
        self.context['resources'] = valid_resources
        
        # Store timing
        self.timings['resources'] = time.time() - start_time
        
        print(f"   Generated {len(self.context.get('resources', []))} valid resources")
    
    def _validate_integrity(self):
        """Check logical integrity of the BPMN model"""
        start_time = time.time()
        
        print("6. Validating logical integrity...")
        
        # Need elements and flows to validate integrity
        if not self.context.get('bpmn_elements') or not self.context.get('sequence_flows'):
            print("   Missing elements or flows. Skipping integrity validation.")
            return
            
        # Perform logical integrity check
        issues = LogicalValidator.check_integrity(self.context, self.api_options)
        
        # Save results
        self._save_json('integrity_issues.json', issues)
        
        # Store in context
        self.context['integrity_issues'] = issues
        
        # Store timing
        self.timings['integrity_validation'] = time.time() - start_time
        
        # Check if we got a proper list of issues
        if isinstance(issues, list):
            if len(issues) > 0:
                print(f"   Found {len(issues)} integrity issues:")
                for i, issue in enumerate(issues[:5]):  # Show at most 5 issues
                    print(f"     - {issue.get('problem_type', 'Unknown')}: {issue.get('description', 'No description')}")
                if len(issues) > 5:
                    print(f"     - ... and {len(issues) - 5} more issues")
            else:
                print("   No integrity issues found!")
        else:
            print("   Integrity validation returned non-standard format")
    
    def _generate_pools_and_lanes(self, batch_sizes=None):
        """
        Generate pools and lanes for the BPMN diagram
        
        Args:
            batch_sizes (dict): Configuration for how many pools and lanes to generate
                                e.g. {'pools': 2, 'lanes_per_pool': 3}
        """
        if not batch_sizes:
            batch_sizes = {
                'pools': 2,
                'lanes_per_pool': 3
            }
            
        start_time = time.time()
        
        print(f"6. Generating {batch_sizes['pools']} pools with up to {batch_sizes['lanes_per_pool']} lanes each...")
        
        # Get the schema
        pool_schema = self.schemas.get('pools', {})
        lane_schema = self.schemas.get('lanes', {})
        
        # Need elements to associate with pools and lanes
        if not self.context.get('bpmn_elements'):
            print("   No BPMN elements available. Skipping pools and lanes generation.")
            return
            
        # Initialize pools and lanes in context if they don't exist
        if 'pools' not in self.context:
            self.context['pools'] = []
        if 'lanes' not in self.context:
            self.context['lanes'] = []
            
        # Generate pools first
        pools_prompt = PromptBuilder.build_pool_prompt(self.context, pool_schema, batch_sizes['pools'])
        pools = DataGenerator.call_llm(pools_prompt, self.api_options)
        
        # Save raw pools output
        self._save_json('raw_pools.json', pools)
        
        # Validate pools
        if pools:
            valid_pools = ValidationLayer.validate('pools', pools, self.context)
            # Append to existing pools if any
            self.context['pools'].extend(valid_pools)
            # Save pools
            self._save_json('pools.json', self.context['pools'])
            
            # For each pool, generate lanes
            for pool in valid_pools:
                lanes_prompt = PromptBuilder.build_lane_prompt(pool, self.context, lane_schema, batch_sizes['lanes_per_pool'])
                lanes = DataGenerator.call_llm(lanes_prompt, self.api_options)
                
                # Save raw lanes output for this pool
                self._save_json(f'raw_lanes_pool_{pool["pool_id"]}.json', lanes)
                
                # Validate lanes
                if lanes:
                    valid_lanes = ValidationLayer.validate('lanes', lanes, {'pool': pool, **self.context})
                    # Append to existing lanes
                    self.context['lanes'].extend(valid_lanes)
                    
            # Save all lanes
            self._save_json('lanes.json', self.context['lanes'])
            
        # Store timing
        self.timings['pools_and_lanes'] = time.time() - start_time
        
        print(f"   Generated {len(self.context.get('pools', []))} pools and {len(self.context.get('lanes', []))} lanes")
    
    def _save_json(self, filename, data):
        """Save data to JSON file"""
        filepath = os.path.join(self.output_dir, filename)
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"Error saving {filename}: {str(e)}")
    
    def _add_product_specifications(self):
        """Add detailed product specifications to the context data"""
        if not self.product_description:
            return
            
        print("7. Adding product specifications...")
        
        # Build prompt to get product specifications
        prompt = f"""
        Based on the description: "{self.product_description}", provide detailed specifications 
        for this product in JSON format.
        
        Include the following fields:
        - product_name: A short name for the product
        - dimensions: Physical dimensions (width, height, depth)
        - weight: Product weight with unit
        - materials: List of primary materials used in manufacturing
        - component_parts: List of main parts/components with estimated costs
        - total_cost: Estimated total manufacturing cost
        - retail_price: Suggested retail price
        - manufacturing_time: Estimated time to manufacture one unit
        
        Return only the JSON object with no additional text.
        """
        
        try:
            # Get specifications from LLM
            specs = DataGenerator.call_llm(prompt, self.api_options)
            
            # If result isn't a dict, try the first item if it's a list
            if isinstance(specs, list) and len(specs) > 0:
                specs = specs[0]
                
            # If we got valid specs
            if isinstance(specs, dict) and "product_name" in specs:
                # Add to context
                self.context['product_specifications'] = specs
                # Save specifications
                self._save_json('product_specifications.json', specs)
                print(f"   Added detailed specifications for {specs.get('product_name', '')}")
            else:
                print("   Failed to generate valid product specifications structure")
        except Exception as e:
            print(f"   Failed to generate product specifications: {str(e)}")


if __name__ == "__main__":
    # Example usage
    description = "An automated warehouse management system with robotic picking and sorting"
    pipeline = DataGenerationPipeline(description)
    pipeline.run()