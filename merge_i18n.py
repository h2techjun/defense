import json
import subprocess

def run_git_show(commit_ish, path):
    out = subprocess.check_output(['git', 'show', f'{commit_ish}:{path}'])
    return json.loads(out.decode('utf-8'))

en_current = run_git_show("HEAD", "assets/i18n/en.json")
ko_old = run_git_show("f37c3a6", "assets/i18n/ko.json")

missing = {}
merged = ko_old.copy()

for k, v in en_current.items():
    if k not in ko_old:
        missing[k] = v
        merged[k] = v # Temporarily put English value, will translate manually

final_ko = {}
for k in en_current.keys():
    if k in merged:
        final_ko[k] = merged[k]

with open("missing.json", "w", encoding="utf-8") as f:
    json.dump(missing, f, ensure_ascii=False, indent=4)

with open("assets/i18n/ko.json", "w", encoding="utf-8") as f:
    json.dump(final_ko, f, ensure_ascii=False, indent=4)

print(f"Merged {len(final_ko)} keys. Dumped {len(missing)} missing keys to missing.json")
