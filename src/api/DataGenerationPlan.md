nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn7. Use `GeneratorController.generateIterative({order: ['product','subpars','Routes','bin','elements']})` to automate sequencing.
nn- **Entity call:** "Generates 10 Rows for Table `SubParts` Given Product IDS [1,2,3], Columns: ID, Name, Weight, Product_ID."
- **Full call (one‑shot):** "Produce Json for Tables: Product, SubParts, Routes, Bins, Elements.Include keys and constraints as defined in `database scheme.md '."
nnnnnnnnnnnnnnnnnnnnnnnnnnnn   - Each product module (e.g. 'Image modules') is modeled as a bpmn_elements entry with element_type='subProcess'.
nnnnnnnnnnnnnnnn     ['Process_definitions','module','parts','subpars','sequenceFlows','resources']
nnnnnnnnnnnnnnnn