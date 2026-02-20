
import re
import os

def extract_keys(content):
    """Extract nested keys from a JS-like object string."""
    keys = []
    # Simplified: Find all "key:" that are not inside strings
    # We look for words followed by : and { or " or '
    # This is a bit of a heuristic for this specific file format
    
    # Remove all string literals to avoid matching keys inside translations
    content_no_strings = re.sub(r'"[^"\\]*(?:\\.[^"\\]*)*"', '""', content)
    content_no_strings = re.sub(r"'[^'\\]*(?:\\.[^'\\]*)*'", "''", content_no_strings)
    
    # Walk through the lines and track indentation to get some structure
    lines = content_no_strings.split('\n')
    for line in lines:
        # Match something like "    appName: {" or "    badge: '',"
        m = re.search(r'^\s+([a-zA-Z0-9_]+):', line)
        if m:
            keys.append(m.group(1).strip())
    
    return set(keys)

def check_i18n(file_path):
    if not os.path.exists(file_path):
        print(f"Error: File not found: {file_path}")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        full_content = f.read()

    # Find each locale block
    # Pattern: "    ko: {"
    locales = {}
    locale_starts = list(re.finditer(r'^\s{4}([a-z]{2}):\s*\{', full_content, re.MULTILINE))
    
    for i, m in enumerate(locale_starts):
        lang = m.group(1)
        start_idx = m.end()
        # Find the end of this locale (either next locale or end of exported object)
        if i + 1 < len(locale_starts):
            end_idx = locale_starts[i+1].start()
        else:
            # Last locale, look for the closing }; of the object
            end_idx = full_content.find('\n    }', start_idx)
            if end_idx == -1: end_idx = len(full_content)
            
        block = full_content[start_idx:end_idx]
        locales[lang] = extract_keys(block)

    if not locales:
        print("❌ No locales found. Check file path and format.")
        return

    base_lang = 'ko' if 'ko' in locales else list(locales.keys())[0]
    base_keys = locales[base_lang]
    
    print(f"--- 🌐 i18n Integrity Report (Base: {base_lang}) ---")
    print(f"Total keys tracked in base: {len(base_keys)}")
    
    any_issue = False
    for lang, keys in locales.items():
        if lang == base_lang: continue
        
        missing = base_keys - keys
        extra = keys - base_keys
        
        if missing or extra:
            any_issue = True
            print(f"\n🚩 [{lang.upper()}]")
            if missing:
                print(f"   Missing Keys: {', '.join(sorted(missing))}")
            if extra:
                print(f"   Extra Keys: {', '.join(sorted(extra))}")
                
    if not any_issue:
        print("\n✅ All locales are perfectly synchronized.")
    else:
        print("\n⚠️ Synchronization issues found. Please check the missing keys above.")

if __name__ == "__main__":
    target = "d:/02_Project/00_Translation/src/lib/i18n/dictionaries.ts"
    check_i18n(target)
