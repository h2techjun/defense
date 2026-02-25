"""
에셋 정합성 검증:
1. 코드에서 참조하는 모든 이미지 경로 추출
2. 실제 파일 존재 여부 확인
3. pubspec.yaml 에셋 선언 확인
"""
import os
import re

BASE_DIR = r"d:\00_Project\05_Defense"
ASSETS_DIR = os.path.join(BASE_DIR, "assets", "images")
LIB_DIR = os.path.join(BASE_DIR, "lib")

# 1. 코드에서 이미지 경로 참조 추출
referenced = set()
for root, dirs, files in os.walk(LIB_DIR):
    for f in files:
        if not f.endswith('.dart'):
            continue
        full = os.path.join(root, f)
        with open(full, 'r', encoding='utf-8', errors='ignore') as fh:
            content = fh.read()
        # 패턴: 'assets/images/...' 또는 '...png' 형태
        for m in re.finditer(r"'assets/images/([^']+\.png)'", content):
            referenced.add(m.group(1))
        # 게임 엔진에서: images.load('path') 형태
        for m in re.finditer(r"images\.load\('([^']+\.png)'\)", content):
            referenced.add(m.group(1))
        # _getImagePath 등에서: return 'path/file.png'
        for m in re.finditer(r"return '([a-z_/]+\.png)'", content):
            if '/' in m.group(1):
                referenced.add(m.group(1))

# 2. 실제 파일 목록
actual = set()
for root, dirs, files in os.walk(ASSETS_DIR):
    for f in files:
        if f.endswith('.png'):
            rel = os.path.relpath(os.path.join(root, f), ASSETS_DIR).replace('\\', '/')
            actual.add(rel)

# 3. 비교
missing = referenced - actual
unused = actual - referenced

print(f"📋 코드 참조 이미지: {len(referenced)}개")
print(f"📁 실제 파일: {len(actual)}개")
print(f"✅ 매칭: {len(referenced & actual)}개")

if missing:
    print(f"\n🚨 코드가 참조하지만 파일 없음: {len(missing)}개")
    for m in sorted(missing):
        print(f"  ❌ {m}")
else:
    print(f"\n✅ 모든 코드 참조 이미지 존재!")

if unused:
    print(f"\n📦 파일 있지만 코드 미참조: {len(unused)}개")
    for u in sorted(unused):
        print(f"  📂 {u}")
else:
    print(f"\n✅ 모든 파일이 코드에서 참조됨!")

# 4. pubspec.yaml 체크
pubspec = os.path.join(BASE_DIR, "pubspec.yaml")
with open(pubspec, 'r', encoding='utf-8') as f:
    pub_content = f.read()

missing_dirs = []
for subdir in ['bg', 'heroes', 'towers', 'enemies', 'objects', 'effects', 'ui']:
    path = f"assets/images/{subdir}/"
    if path not in pub_content:
        missing_dirs.append(path)

if missing_dirs:
    print(f"\n⚠️ pubspec.yaml에 누락된 에셋 디렉토리: {len(missing_dirs)}개")
    for d in missing_dirs:
        print(f"  ❌ {d}")
else:
    print(f"\n✅ pubspec.yaml에 모든 에셋 디렉토리 등록됨!")
