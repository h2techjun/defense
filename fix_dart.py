import os

files = [
    r"d:\00_Project\05_Defense\lib\ui\dialogs\tower_upgrade_dialog.dart",
    r"d:\00_Project\05_Defense\lib\ui\menus\hero_deploy_screen.dart",
    r"d:\00_Project\05_Defense\lib\ui\menus\relic_equip_screen.dart"
]

for path in files:
    if not os.path.exists(path):
        continue
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    # 타워 대화상자 하드코딩 추가 대응
    if "tower_upgrade_dialog.dart" in path:
        content = content.replace("Text(\n                      '??,", "Text(\n                      '',")
        content = content.replace("label: '??,", "label: '',")
        content = content.replace("label: '??", "label: ''")
        content = content.replace("+${-cost}?? : '$cost??,", "'+${-cost} G' : '$cost G',")
        content = content.replace("'$cost??,", "'$cost G',")
        
    # 영웅 배치 스크린 (utf-8 ignore로 읽힌 형태 혹은 깨진 텍스트 대응)
    if "hero_deploy_screen.dart" in path:
        content = content.replace("Text('?뿺截?,", "Text('팀 구성',")
        content = content.replace("Text('??截?,", "Text('팀 구성',")
        content = content.replace("Text('??,", "Text('팀 구성',")
        
    # 유물 창
    if "relic_equip_screen.dart" in path:
        content = content.replace("relic?.iconEmoji ?? '??,", "relic?.iconEmoji ?? '',")
        content = content.replace("relic?.iconEmoji ?? '??", "relic?.iconEmoji ?? ''")

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

print("Dart syntax errors fixed safely with plain string replacement.")
