"""
logical_validator.py

Provides a utility to perform logical/semantic checks on generated BPMN data by invoking the LLM.
"""
import json
from .data_generator import DataGenerator
from .prompt_builder import PromptBuilder

class LogicalValidator:
    """
    Uses the LLM itself to validate the logical integrity of BPMN-related JSON data.
    """

    @staticmethod
    def check_integrity(context, api_options=None):
        """
        Sends an integrity-check prompt to the LLM using the current context.

        Args:
            context (dict): Generation context with tables like allElementRows, allFlowRows, etc.
            api_options (dict, optional): Options for the API call (model, temperature, debug, etc.)

        Returns:
            list[dict] or str: Parsed list of issues (with 'problem_type' and 'description'), or raw text on failure.
        """
        if api_options is None:
            api_options = {'debug': False}

        # Build integrity prompt
        prompt = PromptBuilder.build_integrity_prompt(context)

        # Call LLM to check integrity
        result = DataGenerator.call_llm(prompt, api_options)

        # Attempt to parse JSON issues
        try:
            issues = result if isinstance(result, list) else json.loads(result)
        except Exception:
            # Return raw text if parsing fails
            issues = result

        return issues
