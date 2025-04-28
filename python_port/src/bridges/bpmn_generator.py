"""
BPMN Generator

Converts the generated data structure into standard BPMN 2.0 XML format.
"""

import os
import xml.dom.minidom
import uuid

class BPMNGenerator:
    """
    Generates BPMN 2.0 XML files from the data structure produced by the data generation pipeline.
    """
    
    # BPMN 2.0 namespace and schema declarations
    BPMN_NS = "http://www.omg.org/spec/BPMN/20100524/MODEL"
    BPMNDI_NS = "http://www.omg.org/spec/BPMN/20100524/DI"
    DC_NS = "http://www.omg.org/spec/DD/20100524/DC"
    DI_NS = "http://www.omg.org/spec/DD/20100524/DI"
    
    def __init__(self, output_path=None):
        """
        Initialize a new BPMN generator
        
        Args:
            output_path (str): Path to save the BPMN XML file, if None a default path will be used
        """
        self.output_path = output_path
        self.dom = None
        self.process_node = None
        self.diagram_node = None
        self.plane_node = None
        self.definitions_node = None
        self.elements = {}  # Map from element_id to element node
        
    def generate_from_context(self, context):
        """
        Generate BPMN XML from the data generation context
        
        Args:
            context (dict): The output from the data generation pipeline
            
        Returns:
            str: Path to the generated BPMN file
        """
        # Create the document
        self._initialize_document()
        
        # Create the process
        self._create_process(context)
        
        # Create all BPMN elements
        self._create_elements(context)
        
        # Create all sequence flows
        self._create_flows(context)
        
        # Save to file
        return self._save_to_file()
    
    def _initialize_document(self):
        """Initialize the XML document with BPMN structure"""
        # Create document with properly defined namespace
        impl = xml.dom.minidom.getDOMImplementation()
        # Use a simple document creation to avoid namespace issues
        self.dom = impl.createDocument(None, "definitions", None)
        
        # Get the root element
        self.definitions_node = self.dom.documentElement
        
        # Set namespaces
        self.definitions_node.setAttribute("xmlns", self.BPMN_NS)
        self.definitions_node.setAttribute("xmlns:bpmndi", self.BPMNDI_NS)
        self.definitions_node.setAttribute("xmlns:dc", self.DC_NS)
        self.definitions_node.setAttribute("xmlns:di", self.DI_NS)
        self.definitions_node.setAttribute("id", f"Definitions_{uuid.uuid4().hex[:8]}")
        self.definitions_node.setAttribute("targetNamespace", self.BPMN_NS)
        
        # Create diagram root
        self.diagram_node = self.dom.createElement("bpmndi:BPMNDiagram")
        self.diagram_node.setAttribute("id", "BPMNDiagram_1")
        self.definitions_node.appendChild(self.diagram_node)
        
    def _create_process(self, context):
        """Create the process element"""
        # Extract process info
        process_id = "Process_1"
        process_name = "Default Process"
        
        if 'process_definitions' in context and context['process_definitions']:
            process_def = context['process_definitions'][0]  # Use first process
            if isinstance(process_def, dict):
                if 'process_id' in process_def:
                    process_id = process_def['process_id']
                if 'process_name' in process_def:
                    process_name = process_def['process_name']
        
        # Create process node without prefix
        self.process_node = self.dom.createElement("process")
        self.process_node.setAttribute("id", process_id)
        self.process_node.setAttribute("name", process_name)
        self.definitions_node.appendChild(self.process_node)
        
        # Create diagram plane
        self.plane_node = self.dom.createElement("bpmndi:BPMNPlane")
        self.plane_node.setAttribute("id", f"BPMNPlane_{process_id}")
        self.plane_node.setAttribute("bpmnElement", process_id)
        self.diagram_node.appendChild(self.plane_node)
    
    def _create_elements(self, context):
        """Create all BPMN elements in the process"""
        # Skip if no elements
        if 'bpmn_elements' not in context or not context['bpmn_elements']:
            return
        
        for element in context['bpmn_elements']:
            element_id = element.get('element_id', f"Element_{uuid.uuid4().hex[:8]}")
            element_name = element.get('element_name', "")
            element_type = element.get('element_type', "")
            element_subtype = element.get('element_subtype', "")
            
            # Convert element types to BPMN 2.0 specification
            bpmn_node = None
            
            if element_type == "event":
                if element_subtype == "startEvent":
                    bpmn_node = self._create_start_event(element_id, element_name)
                elif element_subtype == "endEvent":
                    bpmn_node = self._create_end_event(element_id, element_name)
                else:  # Generic event
                    bpmn_node = self._create_intermediate_event(element_id, element_name, element_subtype)
            
            elif element_type == "task":
                bpmn_node = self._create_task(element_id, element_name, element_subtype)
            
            elif element_type == "gateway":
                bpmn_node = self._create_gateway(element_id, element_name, element_subtype)
            
            # Create diagram elements
            if bpmn_node:
                # Store for reference
                self.elements[element_id] = bpmn_node
                
                # Create shape
                x = element.get('position_x', (len(self.elements) * 150) % 800)
                y = element.get('position_y', 100 + ((len(self.elements) * 150) // 800) * 150)
                width = element.get('width', 100)
                height = element.get('height', 80)
                
                self._create_shape(element_id, x, y, width, height)
    
    def _create_flows(self, context):
        """Create all sequence flows in the process"""
        # Skip if no flows
        if 'sequence_flows' not in context or not context['sequence_flows']:
            return
            
        for flow in context['sequence_flows']:
            flow_id = flow.get('flow_id', f"Flow_{uuid.uuid4().hex[:8]}")
            source_ref = flow.get('source_ref', "")
            target_ref = flow.get('target_ref', "")
            condition = flow.get('condition_expr', None)
            
            # Skip invalid flows
            if not source_ref or not target_ref or source_ref not in self.elements or target_ref not in self.elements:
                continue
            
            # Create sequence flow
            flow_node = self.dom.createElement("sequenceFlow")
            flow_node.setAttribute("id", flow_id)
            flow_node.setAttribute("sourceRef", source_ref)
            flow_node.setAttribute("targetRef", target_ref)
            
            # Add condition if specified
            if condition:
                cond_node = self.dom.createElement("conditionExpression")
                cond_text = self.dom.createTextNode(condition)
                cond_node.appendChild(cond_text)
                flow_node.appendChild(cond_node)
                
            # Add to process
            self.process_node.appendChild(flow_node)
            
            # Create edge for diagram
            self._create_edge(flow_id, source_ref, target_ref)
    
    def _create_start_event(self, element_id, name):
        """Create a start event"""
        event_node = self.dom.createElement("startEvent")
        event_node.setAttribute("id", element_id)
        if name:
            event_node.setAttribute("name", name)
        self.process_node.appendChild(event_node)
        return event_node
    
    def _create_end_event(self, element_id, name):
        """Create an end event"""
        event_node = self.dom.createElement("endEvent")
        event_node.setAttribute("id", element_id)
        if name:
            event_node.setAttribute("name", name)
        self.process_node.appendChild(event_node)
        return event_node
    
    def _create_intermediate_event(self, element_id, name, subtype):
        """Create an intermediate event with proper subtype"""
        event_type = "intermediateThrowEvent"
        
        # Custom handling for more specific intermediate events
        if "Catch" in subtype:
            event_type = "intermediateCatchEvent"
        
        event_node = self.dom.createElement(event_type)
        event_node.setAttribute("id", element_id)
        if name:
            event_node.setAttribute("name", name)
        
        # Add event definitions for specific types
        if "Message" in subtype:
            def_node = self.dom.createElement("messageEventDefinition")
            def_node.setAttribute("id", f"MessageEventDefinition_{element_id}")
            event_node.appendChild(def_node)
        elif "Timer" in subtype:
            def_node = self.dom.createElement("timerEventDefinition")
            def_node.setAttribute("id", f"TimerEventDefinition_{element_id}")
            event_node.appendChild(def_node)
        elif "Error" in subtype:
            def_node = self.dom.createElement("errorEventDefinition")
            def_node.setAttribute("id", f"ErrorEventDefinition_{element_id}")
            event_node.appendChild(def_node)
            
        self.process_node.appendChild(event_node)
        return event_node
    
    def _create_task(self, element_id, name, subtype):
        """Create a task with proper subtype"""
        task_type = "task"
        
        # Map subtype to BPMN 2.0 task types
        if subtype == "userTask" or subtype == "user":
            task_type = "userTask"
        elif subtype == "serviceTask" or subtype == "service":
            task_type = "serviceTask"
        elif subtype == "scriptTask" or subtype == "script":
            task_type = "scriptTask"
        elif subtype == "businessRuleTask" or subtype == "business-rule":
            task_type = "businessRuleTask"
        elif subtype == "manualTask" or subtype == "manual":
            task_type = "manualTask"
        elif subtype == "receiveTask" or subtype == "receive":
            task_type = "receiveTask"
        elif subtype == "sendTask" or subtype == "send":
            task_type = "sendTask"
            
        task_node = self.dom.createElement(task_type)
        task_node.setAttribute("id", element_id)
        if name:
            task_node.setAttribute("name", name)
            
        self.process_node.appendChild(task_node)
        return task_node
    
    def _create_gateway(self, element_id, name, subtype):
        """Create a gateway with proper subtype"""
        gateway_type = "exclusiveGateway"  # Default
        
        # Map subtype to BPMN 2.0 gateway types
        if subtype == "parallelGateway" or subtype == "parallel":
            gateway_type = "parallelGateway"
        elif subtype == "inclusiveGateway" or subtype == "inclusive":
            gateway_type = "inclusiveGateway"
        elif subtype == "eventBasedGateway" or subtype == "event-based":
            gateway_type = "eventBasedGateway"
        elif subtype == "complexGateway" or subtype == "complex":
            gateway_type = "complexGateway"
            
        gateway_node = self.dom.createElement(gateway_type)
        gateway_node.setAttribute("id", element_id)
        if name:
            gateway_node.setAttribute("name", name)
            
        self.process_node.appendChild(gateway_node)
        return gateway_node
    
    def _create_shape(self, element_id, x, y, width, height):
        """Create a BPMNShape for diagram visualization"""
        shape = self.dom.createElement("bpmndi:BPMNShape")
        shape.setAttribute("id", f"BPMNShape_{element_id}")
        shape.setAttribute("bpmnElement", element_id)
        
        # Create bounds
        bounds = self.dom.createElement("dc:Bounds")
        bounds.setAttribute("x", str(x))
        bounds.setAttribute("y", str(y))
        bounds.setAttribute("width", str(width))
        bounds.setAttribute("height", str(height))
        shape.appendChild(bounds)
        
        self.plane_node.appendChild(shape)
        return shape
    
    def _create_edge(self, flow_id, source_ref, target_ref):
        """Create a BPMNEdge for flow visualization"""
        # Calculate waypoints based on source and target positions
        # For simplicity, we'll just create direct lines between elements
        
        edge = self.dom.createElement("bpmndi:BPMNEdge")
        edge.setAttribute("id", f"BPMNEdge_{flow_id}")
        edge.setAttribute("bpmnElement", flow_id)
        
        # Simplified waypoint calculation
        # In a real implementation, we'd use the element positions to calculate better waypoints
        wp1 = self.dom.createElement("di:waypoint")
        wp1.setAttribute("x", "0")  # These would be calculated based on element positions
        wp1.setAttribute("y", "0")
        
        wp2 = self.dom.createElement("di:waypoint")
        wp2.setAttribute("x", "100")  # These would be calculated based on element positions
        wp2.setAttribute("y", "100")
        
        edge.appendChild(wp1)
        edge.appendChild(wp2)
        
        self.plane_node.appendChild(edge)
        return edge
    
    def _save_to_file(self):
        """Save the XML to a file"""
        # Create output path if not specified
        if not self.output_path:
            output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../output'))
            os.makedirs(output_dir, exist_ok=True)
            self.output_path = os.path.join(output_dir, "generated_bpmn.bpmn")
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(os.path.abspath(self.output_path)), exist_ok=True)
        
        # Write to file with pretty formatting
        with open(self.output_path, "w", encoding="utf-8") as f:
            f.write(self.dom.toprettyxml(indent="  "))
            
        return self.output_path