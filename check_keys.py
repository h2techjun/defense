import json
import subprocess
import os

def run_git_show(commit_ish, path):
    try:
        out = subprocess.check_output(['git', 'show', f'{commit_ish}:{path}'])
        return json.loads(out.decode('utf-8'))
    except Exception as e:
        print(f"Error loading {path} from {commit_ish}: {e}")
        return None

def main():
    print("loading en.json (HEAD)...")
    en_current = run_git_show("HEAD", "assets/i18n/en.json")
    
    print("loading ko.json (from f37c3a6)...")
    ko_old = run_git_show("f37c3a6", "assets/i18n/ko.json")
    
    if not en_current or not ko_old:
        # maybe alternative commits
        ko_old = run_git_show("5aa937f", "assets/i18n/ko.json")
        if not ko_old:
            return

    # find missing keys in ko_old compared to en_current
    missing_keys = []
    for k in en_current:
        if k not in ko_old:
            missing_keys.append(k)

    print(f"Total keys in EN: {len(en_current)}")
    print(f"Total keys in old KO: {len(ko_old)}")
    print(f"Missing keys in KO: {len(missing_keys)}")
    
    for k in missing_keys:
        print(f"  - {k}: {en_current[k]}")

if __name__ == "__main__":
    main()
