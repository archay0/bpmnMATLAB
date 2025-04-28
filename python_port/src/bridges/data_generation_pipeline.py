import os
import json
from src.api.data_generator import DataGenerator
from src.api.prompt_builder import PromptBuilder
from src.api.schema_loader import SchemaLoader
from src.api.validation_layer import ValidationLayer
from src.api.logical_validator import LogicalValidator

class DataGenerationPipeline:
    """
    Orchestrates generation of BPMN data tables via LLM, schema validation, and logical integrity checks.
    """
    def __init__(self, api_options=None, output_dir=None):
        self.api_options = api_options or {}
        # default output directory under python_port/output
        self.output_dir = output_dir or os.path.abspath(os.path.join(os.path.dirname(__file__), '../../output'))
        os.makedirs(self.output_dir, exist_ok=True)
        # load standard schemas
        self.schemas = SchemaLoader.load()

    def run(self):
        context = {}

        # 1. Generate process phases
        phases_prompt = PromptBuilder.build_process_map_prompt(self.api_options.get('product_description', 'Sample product'))
        phases = DataGenerator.call_llm(phases_prompt, self.api_options)
        # Save raw phases JSON
        self._save_json('process_phases.json', phases)
        # Validate structure
        phases_valid = ValidationLayer.validate('process_phases', phases)
        context['process_phases'] = phases_valid

        # 2. Generate process definitions
        pd_schema = self.schemas.get('process_definitions')
        pd_prompt = PromptBuilder.build_entity_prompt('process_definitions', pd_schema, {'phases': phases_valid}, batch_size=1)
        proc_defs = DataGenerator.call_llm(pd_prompt, self.api_options)
        self._save_json('process_definitions.json', proc_defs)
        proc_defs_valid = ValidationLayer.validate('process_definitions', proc_defs)
        context['process_definitions'] = proc_defs_valid

        # 3. Generate BPMN elements
        elem_schema = self.schemas.get('bpmn_elements')
        elem_prompt = PromptBuilder.build_entity_prompt('bpmn_elements', elem_schema, context['process_definitions'][0], batch_size=10)
        elements = DataGenerator.call_llm(elem_prompt, self.api_options)
        self._save_json('bpmn_elements.json', elements)
        elems_valid = ValidationLayer.validate('bpmn_elements', elements, context=context)
        context['allElementRows'] = elems_valid

        # 4. Generate sequence flows
        flow_prompt = PromptBuilder.build_flow_prompt(context)
        flows = DataGenerator.call_llm(flow_prompt, self.api_options)
        self._save_json('sequence_flows.json', flows)
        flows_valid = ValidationLayer.validate('sequence_flows', flows, context=context)
        context['allFlowRows'] = flows_valid

        # 5. Perform logical integrity check
        issues = LogicalValidator.check_integrity(context, self.api_options)
        self._save_json('integrity_issues.json', issues)

        print(f"Generation pipeline completed. Output files saved to {self.output_dir}")
        print("Integrity issues:", issues)
        return context

    def _save_json(self, filename, data):
        out_path = os.path.join(self.output_dir, filename)
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"Saved {filename} ({len(data) if hasattr(data, '__len__') else 'N/A'} items)")

if __name__ == '__main__':
    # Example usage
    api_opts = {'debug': True, 'product_description': 'Automated warehouse management system'}
    pipeline = DataGenerationPipeline(api_opts)
    pipeline.run()
