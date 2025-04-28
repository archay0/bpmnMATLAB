"""
APIConfig module handles API configuration settings for LLM API calls.
Analogous to the MATLAB APIConfig class.
"""

from ..util.config import Config

class APIConfig:
    """
    Manages API configuration for language model interactions.
    Provides methods to get standard API settings and format prompts.
    """
    
    # Set the default model explicitly
    DEFAULT_MODEL = "thudm/glm-z1-9b:free"  # Valid model for OpenRouter
    
    @staticmethod
    def get_default_options():
        """
        Returns default API options for LLM interactions
        
        Returns:
            dict: Dictionary with default API options
        """
        return Config.get_api_options()
    
    @staticmethod
    def format_prompt(prompt):
        """
        Formats a prompt with standard instructions for better LLM responses.
        
        Args:
            prompt (str): The original prompt text
            
        Returns:
            str: Formatted prompt with additional instructions
        """
        format_instructions = (
            "\n\nIMPORTANT: Respond exclusively with a valid JSON array or object. "
            "Do not use code blocks with ```json or ```. "
            "Start your answer directly with [ or { and do not add any additional text."
        )
        return prompt + format_instructions