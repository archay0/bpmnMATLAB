n    % Test chemavalidation unit tests for schemaloader and validationlayer
nnn            % Verify schemaloader.load parses expected tables
n            % Scheme Should be a Struct and Contain Key Tables
            testCase.verifyClass(schema, 'struct');
            testCase.verifyTrue(isfield(schema, 'Process_definitions'));
            % Check columns for process_definitions
nnn            testCase.verifyTrue(any(strcmp(names, 'Process_id')));
            testCase.verifyTrue(any(strcmp(names, 'Process_Name')));
nnn            % Create A Valid Row for Process_Definitions
n            % Construct a row with minimal request fields
nnn                    case 'Process_id'
                        row.process_id = 'Test';
                    case 'Process_Name'
                        row.process_name = 'Test name';
                    case 'description'
                        row.description = 'Desc';
                    case 'version'
                        row.version = '1.0';
                    case 'is_executable'
n                    case 'created_date'
                        row.created_date = datetime('snow');
                    case 'updated_date'
                        row.updated_date = datetime('snow');
                    case 'created_by'
                        row.created_by = 'tester';
                    case 'namespace'
                        row.namespace = 'NS';
n                        % Assign Default Values ​​Based on Type
                        if contains(c.type, 'Varchar') || contains(c.type, 'TEXT')
n                        elseif contains(c.type, 'Boolean')
n                        elseif contains(c.type, 'Intimately') || contains(c.type, 'Float')
n                        elseif contains(c.type, 'Timestamp') || contains(c.type, 'Date')
                            row.(c.name) = datetime('snow');
nnnnn            % Validate Should not error
            testCase.verifyWarningFree(@() ValidationLayer.validate('Process_definitions', row, schema, struct('Process_definitions', {{'Test'}})));
nnn            % Missing Required Column Should Error
n            row = struct('Process_id', 'P1'); % missing others
            fcn = @() ValidationLayer.validate('Process_definitions', row, schema, struct());
            testCase.verifyError(fcn, 'Validation Layer: Missing Column');
nnn            % Type Mismatch in Numeric Field
n            % CREATE ROW WRONG Type for is_executable (Expects Boolean)
nn                if strcmp(c.name, 'Process_id')
                    row.process_id = 'P1';
                elseif strcmp(c.name, 'Process_Name')
                    row.process_name = 'name';
                elseif strcmp(c.name, 'is_executable')
                    row.is_executable = 'notebook';
n                    % Assign default
                    if contains(c.type, 'Varchar') || contains(c.type, 'TEXT')
n                    elseif contains(c.type, 'Boolean')
n                    elseif contains(c.type, 'Timestamp') || contains(c.type, 'Date')
                        row.(c.name) = datetime('snow');
nnnnn            fcn = @() ValidationLayer.validate('Process_definitions', row, schema, struct('Process_definitions', {{'P1'}}));
            testCase.verifyError(fcn, 'Validationlayer: Typemismatch');
nnn            % Foreign key violation
n            % Message_flows has FK to Element IDS
            rows = struct('Flow_id', 'F1', 'Source_ref', 'E999', 'target_ref', 'E1', 'Message_id', 'M1');
            % Context has no element IDS, according to FK Should Warn or Error
            fcn = @() ValidationLayer.validate('Message_flows', rows, schema, struct());
            % INCENCE Context Missing, Warning Expected Rather Than Error
nnnn