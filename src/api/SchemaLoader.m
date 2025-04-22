classdef SchemaLoader
    % SchemaLoader reads and parses the BPMN database schema

    methods(Static)
        function schema = load()
            % Load raw schema markdown
            mdPath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'doc', 'DatabaseSchema.md');
            try
                fid = fopen(mdPath, 'r');
                raw = fread(fid, '*char')';
                fclose(fid);
            catch
                error('SchemaLoader:FileRead', 'Could not read DatabaseSchema.md at %s', mdPath);
            end

            % Initialize schema struct
            schema = struct();

            % Find table headers and parse each section
            [tokens, starts, ends] = regexp(raw, '###\s*\d+\.\s*([^\n]+)', 'tokens','start','end');
            numTables = numel(tokens);
            for i = 1:numTables
                tblNameRaw = strtrim(tokens{i}{1});

                % Validate and sanitize table name for use as struct field
                if ~isvarname(tblNameRaw)
                    tblName = matlab.lang.makeValidName(tblNameRaw, 'ReplacementStyle', 'underscore');
                    if ~strcmp(tblName, tblNameRaw)
                        warning('SchemaLoader:InvalidName', 'Table name "%s" was converted to "%s" to be a valid MATLAB field name.', tblNameRaw, tblName);
                    end
                else
                    tblName = tblNameRaw;
                end

                % Skip if the table name is empty after sanitization
                if isempty(tblName)
                    warning('SchemaLoader:EmptyTableName', 'Skipping table with empty or invalid name originating from: "%s" ', tblNameRaw);
                    continue;
                end

                blockStart = ends(i) + 1;
                if i < numTables
                    blockEnd = starts(i+1) - 1;
                else
                    blockEnd = numel(raw);
                end
                block = raw(blockStart:blockEnd);
                lines = regexp(block, '\n', 'split');

                cols = [];
                fks = [];
                inTable = false;
                for ln = 1:numel(lines)
                    line = strtrim(lines{ln});
                    % Detect header row of markdown table
                    if startsWith(line, '|') && contains(line, 'Column') && contains(line, 'Type')
                        inTable = true;
                        continue;
                    end
                    % Skip separator row
                    if inTable && startsWith(line, '|') && all(ismember(strrep(line,'|',''), '- '))
                        continue;
                    end
                    % Parse data rows
                    if inTable && startsWith(line, '|')
                        parts = regexp(line, '\|', 'split');
                        name = strtrim(parts{2});
                        type = strtrim(parts{3});
                        desc = strtrim(parts{4});
                        cols(end+1) = struct('name', name, 'type', type, 'description', desc); %#ok<AGROW>
                        % Check for foreign key in description
                        fkMatch = regexp(desc, '[Ff]oreign key to ([^\.\s]+)', 'tokens');
                        if ~isempty(fkMatch)
                            fkTable = fkMatch{1}{1};
                            fks(end+1) = struct('column', name, 'refTable', fkTable, 'refColumn', name); %#ok<AGROW>
                        end
                    elseif inTable && isempty(line)
                        % blank line ends table
                        break;
                    end
                end
                schema.(tblName) = struct('columns', cols, 'foreignKeys', fks);
            end

            % Keep raw markdown for reference
            schema.rawMarkdown = raw;
        end
    end
end