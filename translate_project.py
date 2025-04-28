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
    string_pattern = re.compile(r"(?P<prefix>['"])(?P<text>[^'"]+)(?P<suffix>['"])" )

    for line in content:
        # Translate comment lines
        m = comment_pattern.match(line)
        if m:
            prefix = m.group('indent')
            text = m.group('text')
            en = translate_text(text, translator)
            output_lines.append(prefix + en + '\n')
            continue

        # Transform string literals
        def repl(match):
            prefix = match.group('prefix')
            text = match.group('text')
            suffix = match.group('suffix')
            en = translate_text(text, translator)
            return prefix + en + suffix

        new_line = string_pattern.sub(repl, line)
        output_lines.append(new_line)

    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(output_lines)
    print(f"Translated: {path}")


def main():
    translator = Translator()
    for root, dirs, files in os.walk('.'):
        # skip unwanted directories
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in files:
            if is_target_file(fname):
                file_path = os.path.join(root, fname)
                process_file(file_path, translator)

if __name__ == '__main__':
    main()
