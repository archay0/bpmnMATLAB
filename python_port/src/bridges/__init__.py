"""
Bridges Package

Contains components that bridge between different parts of the BPMN generation pipeline.
This includes converters between data formats and generators for specific output formats.
"""

# Make classes available at the package level
from .bpmn_generator import BPMNGenerator

__all__ = ['BPMNGenerator']