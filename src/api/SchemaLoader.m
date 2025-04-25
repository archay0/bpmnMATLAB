classdef SchemaLoader
    % Schemaloader Reads and Parses the BPMN Database Scheme

    methods(Static)
        function schema = load()
            % Load Raw Scheme Markdown
            mdPath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'Doc', 'DatabaseSchema.md');
            try
                fid = fopen(mdPath, 'r');
                raw = fread(fid, '*Char')';
                fclose(fid);
            catch
                error('Schemaloader: Fileread', 'Could not read database scheme.md at %s', mdPath);
            end

            % Initialize Scheme Struct
            schema = struct();

            % Find table header and parse each section
            % Regex updated to capture the number as well, to difference
            [tokens, starts, ends] = regexp(raw, '### \ S*(\ d+) \. \ S*([^\ n]+)', 'tokens','start','end');
            numTables = numel(tokens);
            for i = 1:numTables
                sectionNumberStr = tokens{i}{1}; % Capture the section number (e.g., '1')
                tblNameRaw = strtrim(tokens{i}{2}); % Capture the text part

                % Check If this Section Number Corresponds to the Start of Example Querties
                % Assuming Example Quample Start AT Section 15 Based on Databaseschema.md Structure
                % (This is a bit fragile, relies on the md structure)
                try
                    sectionNumber = str2double(sectionNumberStr);
                    % Check If Section Number Indicates on Example Query Section
                    % In The Current MD, Tables are 1-14, Examples start after that.
                    if sectionNumber > 14 
                         fprintf('Schemaloader: Skipping potential Example query header based on section Number> 14:"%s. %s"\ n', sectionNumberStr, tblNameRaw);
                         continue;
                    end
                catch
                    % Ignore IF Conversion Fails, Proceed with name Check
                    fprintf('Schemaloader: Could not parse section Number: %s.Proceeding with name check. \ N', sectionNumberStr);
                end

                % So Keep the Original Check for Safety, in Case Numbering Changes or Parsing Fails
                 if endsWith(tblNameRaw, ':')
                     fprintf('Schemaloader: Skipping Examle Query Header Ending with Colon:"%s"\ n', tblNameRaw);
                     continue;
                 end

                % Validate and Sanitize Table Name for Use as Struct Field
                if ~isvarname(tblNameRaw)
                    tblName = matlab.lang.makeValidName(tblNameRaw, 'Replacement style', 'undercore');
                    if ~strcmp(tblName, tblNameRaw)
                        warning('Schemaloader: Invalid name', 'Table name"%s"What converted to"%s"to be a valid matlab field name.', tblNameRaw, tblName);
                    end
                else
                    tblName = tblNameRaw;
                end

                % Skip if the table name is empty after sanitation
                if isempty(tblName)
                    warning('Schemaloader: Emptytablename', 'Skipping Table with Empty or invalid name Originating from:"%s" ', tblNameRaw);
                    continue;
                end

                blockStart = ends(i) + 1;
                if i < numTables
                    blockEnd = starts(i+1) - 1;
                else
                    blockEnd = numel(raw);
                end
                block = raw(blockStart:blockEnd);
                lines = regexp(block, '\ n', 'split');

                % Initialize as Empty Struct Arrays with Defined Fields
                cols = struct('name', {}, 'type', {}, 'description', {});
                fks = struct('column', {}, 'refuge', {}, 'refcolumn', {});
                inTable = false;
                for ln = 1:numel(lines)
                    line = strtrim(lines{ln});
                    % Detect Header Row of Markdown Table
                    if startsWith(line, '|') && contains(line, 'Column') && contains(line, 'Type')
                        inTable = true;
                        continue;
                    end
                    % Skip separator ROW
                    if inTable && startsWith(line, '|') && all(ismember(strrep(line,'|',''),'- '))
                        continue;
                    end
                    % PARSE Data Rows
                    if inTable && startsWith(line, '|')
                        parts = regexp(line, '\ |', 'split');
                        % More robust Bounds Checking - Make Sure We Have All Required Elements
                        % Parts (1) is empty because the line starts with |
                        if numel(parts) >= 5 && length(parts) > 3 % Ensure enough parts exist with a double-check
                            % ONLY Access Array Elements that Are Guaranteed to Exist
                            if length(parts) > 1
                                name = strtrim(parts(2));
                            else
                                name = '';
                            end
                            
                            if length(parts) > 2
                                type = strtrim(parts(3));
                            else
                                type = '';
                            end
                            
                            if length(parts) > 3
                                desc = strtrim(parts(4));
                            else
                                desc = '';
                            end
                            
                            % Append to Struct Array
                            cols(end+1) = struct('name', name, 'type', type, 'description', desc);
                            
                            % Check for Foreign Key in Description only if we have a description
                            if ~isempty(desc)
                                fkMatch = regexp(desc, '[Ff] Foreign key to ([^\. \ S]+)', 'tokens');
                                if ~isempty(fkMatch) && ~isempty(fkMatch{1}) && numel(fkMatch{1}) > 0
                                    fkTableRaw = fkMatch{1}{1};
                                    % Sanitize the referned table name as well
                                    if ~isvarname(fkTableRaw)
                                         fkTable = matlab.lang.makeValidName(fkTableRaw, 'Replacement style', 'undercore');
                                    else
                                         fkTable = fkTableRaw;
                                    end
                                    % Append to Struct Array
                                    fks(end+1) = struct('column', name, 'refuge', fkTable, 'refcolumn', name);
                                end
                            end
                        else
                             warning('Schemaloader: Malformedrow', 'Skipping Malformed Table Row in Table %S: %S', tblName, line);
                        end
                    elseif inTable && isempty(line)
                        % Blank line ends table
                        break;
                    end
                end
                schema.(tblName) = struct('columns', cols, 'Foreignkeys', fks);
            end

            % Keep Raw Markdown for Reference
            schema.rawMarkdown = raw;
        end
    end
end