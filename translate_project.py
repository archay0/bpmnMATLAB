"""
translate_project.py

Scan all .m and .md files (excluding output directories) under this project,
translate German comments, strings, and documentation to English using
Google Translate (googletrans library), and overwrite files in place.
"""
import os
import re
from googletrans import Translator

def is_target_file(filename):
    return filename.endswith('.m') or filename.endswith('.md')

# Directories to skip
SKIP_DIRS = {'output', 'coverage', 'release', 'matlab_codecov_js-ui'}

def translate_text(text, translator):
    if not text.strip():
        return text
    try:
        translated = translator.translate(text, src='de', dest='en')
        return translated.text
    except Exception as e:
        print(f"Translation error for '{text}': {e}")
        return text


def process_file(path, translator):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.readlines()

    output_lines = []
    # Patterns for MATLAB comments (%) and string literals
    comment_pattern = re.compile(r'^(?P<indent>\s*%+\s?)(?P<text>.*)$')
    string_pattern = re.compile(r"(?P<prefix>['\"])(?P<text>[^'\"]+)(?P<suffix>['\"])")
    
    # New patterns for MATLAB-specific elements
    error_pattern = re.compile(r'(error\([\'"])(?P<text>.*?)([\'"])')
    fprintf_pattern = re.compile(r'(fprintf\([^,]*,[\'"])(?P<text>.*?)([\'"])')
    function_doc_pattern = re.compile(r'^(function\s+.*?)\s*(?P<comment>%.*)$')

    for line in content:
        # Translate comment lines
        m = comment_pattern.match(line)
        if m:
            prefix = m.group('indent')
            text = m.group('text')
            en = translate_text(text, translator)
            output_lines.append(prefix + en + '\n')
            continue

        # Check for function declaration with comment
        m = function_doc_pattern.match(line)
        if m:
            func_part = m.group(1)
            comment_part = m.group('comment')
            en_comment = translate_text(comment_part[1:].strip(), translator)
            output_lines.append(f"{func_part} % {en_comment}\n")
            continue

        # Process the line for different patterns
        processed_line = line
        
        # Transform error messages
        processed_line = re.sub(
            error_pattern,
            lambda m: f"{m.group(1)}{translate_text(m.group('text'), translator)}{m.group(3)}",
            processed_line
        )
        
        # Transform fprintf messages
        processed_line = re.sub(
            fprintf_pattern,
            lambda m: f"{m.group(1)}{translate_text(m.group('text'), translator)}{m.group(3)}",
            processed_line
        )
        
        # Transform string literals
        processed_line = string_pattern.sub(
            lambda m: m.group('prefix') + translate_text(m.group('text'), translator) + m.group('suffix'),
            processed_line
        )
        
        output_lines.append(processed_line)

    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(output_lines)
    print(f"Translated: {path}")


def main():
    translator = Translator()
    success_count = 0
    error_count = 0
    
    print("Starting translation of MATLAB and Markdown files...")
    
    for root, dirs, files in os.walk('.'):
        # skip unwanted directories
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in files:
            if is_target_file(fname):
                file_path = os.path.join(root, fname)
                try:
                    process_file(file_path, translator)
                    success_count += 1
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")
                    error_count += 1
    
    print(f"Translation complete. Successfully processed: {success_count} files, Errors: {error_count}")

if __name__ == '__main__':
    main()
