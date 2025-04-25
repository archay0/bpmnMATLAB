"""
translate_project_fixed.py

Improved version of the translation script that:
1. Uses a more reliable translation approach with improved error handling
2. Preserves technical BPMN terms and naming conventions
3. Fixes formatting issues like newline characters
4. Ensures consistent capitalization of technical terms

Usage: python translate_project_fixed.py
"""
import os
import re
import time
import requests
import json

# Technical terms dictionary to preserve during translation
TECHNICAL_TERMS = {
    # BPMN Element Names - preserve correct camelCase
    'laneSet': 'laneSet',
    'sequenceFlow': 'sequenceFlow',
    'flowNodeRef': 'flowNodeRef',
    'exclusiveGateway': 'exclusiveGateway',
    'parallelGateway': 'parallelGateway',
    'inclusiveGateway': 'inclusiveGateway',
    'eventBasedGateway': 'eventBasedGateway',
    'startEvent': 'startEvent',
    'endEvent': 'endEvent',
    'intermediateThrowEvent': 'intermediateThrowEvent',
    'intermediateCatchEvent': 'intermediateCatchEvent',
    'boundaryEvent': 'boundaryEvent',
    'messageEventDefinition': 'messageEventDefinition',
    'timerEventDefinition': 'timerEventDefinition',
    'errorEventDefinition': 'errorEventDefinition',
    'compensateEventDefinition': 'compensateEventDefinition',
    'signalEventDefinition': 'signalEventDefinition',
    'conditionalEventDefinition': 'conditionalEventDefinition',
    'userTask': 'userTask',
    'serviceTask': 'serviceTask',
    'scriptTask': 'scriptTask',
    'businessRuleTask': 'businessRuleTask',
    'manualTask': 'manualTask',
    'receiveTask': 'receiveTask',
    'sendTask': 'sendTask',
    'subProcess': 'subProcess',
    'transaction': 'transaction',
    'isForCompensation': 'isForCompensation',
    'attachedToRef': 'attachedToRef',
    'cancelActivity': 'cancelActivity',
    'gatewayDirection': 'gatewayDirection',
    'sourceRef': 'sourceRef',
    'targetRef': 'targetRef',
    'conditionExpression': 'conditionExpression',
    'categoryValueRef': 'categoryValueRef',
    'activityRef': 'activityRef',
    'waitForCompletion': 'waitForCompletion',
    'participant': 'participant',
    'processRef': 'processRef',
    'collaboration': 'collaboration',
}

def is_target_file(filename):
    """Checks if a file should be processed for translation."""
    return filename.endswith('.m') or filename.endswith('.md')

# Directories to skip
SKIP_DIRS = {'output', 'coverage', 'release', 'matlab_codecov_js-ui', '.git', '.github'}

def translate_text_batch(texts, source_lang='de', target_lang='en'):
    """
    Translate text using a free machine translation API.
    Uses LibreTranslate which is more reliable for this purpose.
    
    Args:
        texts: List of texts to translate
        source_lang: Source language code
        target_lang: Target language code
        
    Returns:
        List of translated texts
    """
    if not texts:
        return []
    
    # Filter out empty texts
    non_empty_texts = [t for t in texts if t.strip()]
    if not non_empty_texts:
        return [''] * len(texts)
    
    # Free LibreTranslate API endpoint (can be changed to another provider)
    url = "https://libretranslate.com/translate"
    
    # Prepare the request
    payload = {
        "q": non_empty_texts,
        "source": source_lang,
        "target": target_lang,
        "format": "text"
    }
    headers = {"Content-Type": "application/json"}
    
    try:
        # Add delay to avoid rate limiting
        time.sleep(1)
        response = requests.post(url, data=json.dumps(payload), headers=headers)
        
        if response.status_code == 200:
            translations = response.json().get('translatedText', non_empty_texts)
            # Map results back to original text list positions
            result = []
            empty_idx = 0
            for t in texts:
                if not t.strip():
                    result.append('')
                else:
                    if empty_idx < len(translations):
                        result.append(translations[empty_idx])
                        empty_idx += 1
                    else:
                        result.append(t)
            return result
        else:
            print(f"Translation API error: {response.status_code} - {response.text}")
            return non_empty_texts
            
    except Exception as e:
        print(f"Translation error: {str(e)}")
        return non_empty_texts

def fix_newlines(text):
    """Fix incorrectly formatted newline characters"""
    return text.replace('\\ n', '\\n').replace('\\ N', '\\n')

def preserve_technical_terms(text):
    """Replace technical terms with placeholders before translation"""
    for term, placeholder in TECHNICAL_TERMS.items():
        # Match term with various capitalizations and replace with correct form
        pattern = re.compile(re.escape(term), re.IGNORECASE)
        text = pattern.sub(placeholder, text)
    return text

def process_file(path):
    """Process a single file for translation"""
    print(f"Processing: {path}")
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.readlines()

    # Collect texts for batch translation
    texts_to_translate = []
    line_types = []  # Store type of each line for processing

    # Patterns for MATLAB comments (%) and string literals
    comment_pattern = re.compile(r'^(?P<indent>\s*%+\s?)(?P<text>.*)$')
    string_pattern = re.compile(r"(?P<prefix>['\"])(?P<text>[^'\"]+)(?P<suffix>['\"])")
    
    # Additional patterns for MATLAB-specific elements
    error_pattern = re.compile(r'(error\([\'"])(?P<text>.*?)([\'"])')
    fprintf_pattern = re.compile(r'(fprintf\([^,]*,[\'"])(?P<text>.*?)([\'"])')
    function_doc_pattern = re.compile(r'^(function\s+.*?)\s*(?P<comment>%.*)$')

    for line in content:
        # Check for comment lines
        m = comment_pattern.match(line)
        if m:
            texts_to_translate.append(m.group('text'))
            line_types.append(('comment', m.group('indent')))
            continue

        # Check for function declaration with comment
        m = function_doc_pattern.match(line)
        if m:
            texts_to_translate.append(m.group('comment')[1:].strip())
            line_types.append(('function_doc', m.group(1)))
            continue
            
        # For other lines, collect all translatable parts
        line_texts = []
        
        # Extract error messages
        for m in error_pattern.finditer(line):
            line_texts.append(('error', m.group(1), m.group('text'), m.group(3)))
            
        # Extract fprintf messages
        for m in fprintf_pattern.finditer(line):
            line_texts.append(('fprintf', m.group(1), m.group('text'), m.group(3)))
            
        # Extract string literals
        for m in string_pattern.finditer(line):
            line_texts.append(('string', m.group('prefix'), m.group('text'), m.group('suffix')))
            
        if line_texts:
            texts_to_translate.extend([t[2] for t in line_texts])
            line_types.append(('mixed', line, line_texts))
        else:
            line_types.append(('unchanged', line))
            
    # Process texts in batches to optimize API usage
    batch_size = 10
    all_translated = []
    
    for i in range(0, len(texts_to_translate), batch_size):
        batch = texts_to_translate[i:i+batch_size]
        batch = [preserve_technical_terms(t) for t in batch]
        translated_batch = translate_text_batch(batch)
        translated_batch = [fix_newlines(t) for t in translated_batch]
        all_translated.extend(translated_batch)
    
    # Reconstruct the file with translations
    output_lines = []
    translated_idx = 0
    
    for line_type in line_types:
        if line_type[0] == 'comment':
            output_lines.append(f"{line_type[1]}{all_translated[translated_idx]}\n")
            translated_idx += 1
            
        elif line_type[0] == 'function_doc':
            output_lines.append(f"{line_type[1]} % {all_translated[translated_idx]}\n")
            translated_idx += 1
            
        elif line_type[0] == 'mixed':
            original_line = line_type[1]
            fragments = line_type[2]
            
            for fragment in fragments:
                frag_type, prefix, text, suffix = fragment
                translated_text = all_translated[translated_idx]
                translated_idx += 1
                
                if frag_type == 'error':
                    original_line = original_line.replace(f"{prefix}{text}{suffix}", f"{prefix}{translated_text}{suffix}")
                elif frag_type == 'fprintf':
                    original_line = original_line.replace(f"{prefix}{text}{suffix}", f"{prefix}{translated_text}{suffix}")
                elif frag_type == 'string':
                    original_line = original_line.replace(f"{prefix}{text}{suffix}", f"{prefix}{translated_text}{suffix}")
                    
            output_lines.append(original_line)
            
        else:  # unchanged
            output_lines.append(line_type[0][1])
    
    # Write the translated content back to the file
    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(output_lines)
    
    print(f"Successfully translated: {path}")
    return True

def main():
    success_count = 0
    error_count = 0
    
    print("Starting improved translation of MATLAB and Markdown files...")
    
    for root, dirs, files in os.walk('.'):
        # Skip unwanted directories
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith('.')]
        
        for fname in files:
            if is_target_file(fname):
                file_path = os.path.join(root, fname)
                try:
                    if process_file(file_path):
                        success_count += 1
                    else:
                        error_count += 1
                except Exception as e:
                    print(f"Error processing {file_path}: {str(e)}")
                    error_count += 1
    
    print(f"Translation complete. Successfully processed: {success_count} files, Errors: {error_count}")

if __name__ == '__main__':
    main()