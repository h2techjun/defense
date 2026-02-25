import os
import time

BASE = r"d:\00_Project\05_Defense\assets\images"
cutoff = time.mktime(time.strptime("2026-02-25 00:00:00", "%Y-%m-%d %H:%M:%S"))

old_files = []
new_files = []

for root, dirs, files in os.walk(BASE):
    for f in files:
        if not f.endswith(".png"):
            continue
        full = os.path.join(root, f)
        rel = os.path.relpath(full, BASE).replace("\\", "/")
        mt = os.path.getmtime(full)
        sz = os.path.getsize(full)
        date_str = time.strftime("%m/%d %H:%M", time.localtime(mt))
        if mt < cutoff:
            old_files.append((rel, sz, date_str))
        else:
            new_files.append((rel, sz, date_str))

print(f"=== 02/24 이전(어제) 파일: {len(old_files)}개 ===")
for r, s, d in sorted(old_files):
    print(f"  {r:55s} {s:>10,} bytes  {d}")

print(f"\n=== 02/25 (오늘) 파일: {len(new_files)}개 ===")
for r, s, d in sorted(new_files):
    print(f"  {r:55s} {s:>10,} bytes  {d}")
