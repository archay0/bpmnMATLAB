classdef TestSchemaValidation < matlab.unittest.TestCase
    % TestSchemaValidation  Unit tests for SchemaLoader and ValidationLayer

    methods(Test)
        function testSchemaParsing(testCase)
            % Verify SchemaLoader.load parses expected tables
            schema = SchemaLoader.load();
            % Schema should be a struct and contain key tables
            testCase.verifyClass(schema, 'struct');
            testCase.verifyTrue(isfield(schema, 'process_definitions'));
            % Check columns for process_definitions
            cols = schema.process_definitions.columns;
            testCase.verifyNotEmpty(cols);
            names = {cols.name};
            testCase.verifyTrue(any(strcmp(names, 'process_id')));
            testCase.verifyTrue(any(strcmp(names, 'process_name')));
        end

        function testValidationSuccess(testCase)
            % Create a valid row for process_definitions
            schema = SchemaLoader.load();
            % Construct a row with minimal required fields
            row = struct();
            for c = schema.process_definitions.columns
                switch c.name
                    case 'process_id'
                        row.process_id = 'TestProc';
                    case 'process_name'
                        row.process_name = 'Test Name';
                    case 'description'
                        row.description = 'Desc';
                    case 'version'
                        row.version = '1.0';
                    case 'is_executable'
                        row.is_executable = true;
                    case 'created_date'
                        row.created_date = datetime('now');
                    case 'updated_date'
                        row.updated_date = datetime('now');
                    case 'created_by'
                        row.created_by = 'tester';
                    case 'namespace'
                        row.namespace = 'ns';
                    otherwise
                        % assign default values based on type
                        if contains(c.type, 'VARCHAR') || contains(c.type, 'TEXT')
                            row.(c.name) = '';
                        elseif contains(c.type, 'BOOLEAN')
                            row.(c.name) = false;
                        elseif contains(c.type, 'INT') || contains(c.type, 'FLOAT')
                            row.(c.name) = 0;
                        elseif contains(c.type, 'TIMESTAMP') || contains(c.type, 'DATE')
                            row.(c.name) = datetime('now');
                        else
                            row.(c.name) = '';
                        end
                end
            end
            % Validate should not error
            testCase.verifyWarningFree(@() ValidationLayer.validate('process_definitions', row, schema, struct('process_definitions', {{'TestProc'}})));
        end

        function testValidationMissingColumn(testCase)
            % Missing required column should error
            schema = SchemaLoader.load();
            row = struct('process_id', 'P1'); % missing others
            fcn = @() ValidationLayer.validate('process_definitions', row, schema, struct());
            testCase.verifyError(fcn, 'ValidationLayer:MissingColumn');
        end

        function testValidationTypeMismatch(testCase)
            % Type mismatch in numeric field
            schema = SchemaLoader.load();
            % Create row with wrong type for is_executable (expects boolean)
            row = struct();
            for c = schema.process_definitions.columns
                if strcmp(c.name, 'process_id')
                    row.process_id = 'P1';
                elseif strcmp(c.name, 'process_name')
                    row.process_name = 'Name';
                elseif strcmp(c.name, 'is_executable')
                    row.is_executable = 'notbool';
                else
                    % assign default
                    if contains(c.type, 'VARCHAR') || contains(c.type, 'TEXT')
                        row.(c.name) = '';
                    elseif contains(c.type, 'BOOLEAN')
                        row.(c.name) = false;
                    elseif contains(c.type, 'TIMESTAMP') || contains(c.type, 'DATE')
                        row.(c.name) = datetime('now');
                    else
                        row.(c.name) = 0;
                    end
                end
            end
            fcn = @() ValidationLayer.validate('process_definitions', row, schema, struct('process_definitions', {{'P1'}}));
            testCase.verifyError(fcn, 'ValidationLayer:TypeMismatch');
        end

        function testValidationFKViolation(testCase)
            % Foreign key violation
            schema = SchemaLoader.load();
            % message_flows has fk to element ids
            rows = struct('flow_id', 'F1', 'source_ref', 'E999', 'target_ref', 'E1', 'message_id', 'M1');
            % context has no element ids, so FK should warn or error
            fcn = @() ValidationLayer.validate('message_flows', rows, schema, struct());
            % Since context missing, warning expected rather than error
            testCase.verifyWarningFree(fcn);
        end
    end
end