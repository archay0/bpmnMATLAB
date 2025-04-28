"""
Configuration management for the BPMN Python Port.
Handles loading environment variables and providing default configurations.
"""

import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    """Configuration class that manages application settings and API credentials."""
    
    # Database Configuration
    DB_TYPE = os.getenv('DB_TYPE', 'mysql')
    DB_HOST = os.getenv('DB_HOST', 'localhost')
    DB_PORT = int(os.getenv('DB_PORT', '3306'))
    DB_NAME = os.getenv('DB_NAME', 'bpmn_db')
    DB_USER = os.getenv('DB_USER', 'root')
    DB_PASSWORD = os.getenv('DB_PASSWORD', '')
    
    # API Configuration
    GITHUB_API_TOKEN = os.getenv('GITHUB_API_TOKEN', '')
    OPENROUTER_API_KEY = os.getenv('OPENROUTER_API_KEY', '')
    
    # Application Settings
    DEBUG_MODE = os.getenv('DEBUG_MODE', 'false').lower() == 'true'
    TEMP_DIR = os.getenv('TEMP_DIR', '/tmp/bpmn_temp')
    
    # Default API Options - Updated to use the confirmed free model
    DEFAULT_MODEL = 'microsoft/mai-ds-r1:free'  # Free model as specified
    DEFAULT_TEMPERATURE = 0.7
    
    @classmethod
    def get_api_options(cls, custom_options=None):
        """
        Returns API options by combining defaults with any custom options.
        
        Args:
            custom_options (dict, optional): Custom API options to override defaults
            
        Returns:
            dict: Combined API options
        """
        options = {
            'model': cls.DEFAULT_MODEL,
            'temperature': cls.DEFAULT_TEMPERATURE,
            'debug': cls.DEBUG_MODE,
            'fallback_on_error': True,
            'max_tokens': 1024,
            'http_referer': 'https://github.com/bpmn-python-port',
            'x_title': 'BPMN-MATLAB Python Port'
        }
        
        if custom_options:
            options.update(custom_options)
            
        return options

    @classmethod
    def get_db_connection_params(cls):
        """
        Returns database connection parameters based on environment variables
        
        Returns:
            dict: Database connection parameters
        """
        return {
            'db_type': cls.DB_TYPE,
            'host': cls.DB_HOST,
            'port': cls.DB_PORT,
            'database': cls.DB_NAME,
            'user': cls.DB_USER,
            'password': cls.DB_PASSWORD
        }

    @staticmethod
    def ensure_temp_dir():
        """Ensures that the temporary directory exists"""
        os.makedirs(Config.TEMP_DIR, exist_ok=True)