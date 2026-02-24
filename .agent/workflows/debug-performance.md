---
description: 게임 프리즈/성능 문제 디버깅 워크플로우
---

# Game Performance Debug

## 1. 컴포넌트 수 확인

게임 내에서 world.children.length를 print하여 확인.
200개 이상이면 성능 저하 원인.

## 2. 적 물량 확인

// turbo

```powershell
Select-String -Path "lib/data/wave_builder.dart" -Pattern "baseCount|clamp"
```

## 3. 파티클 수 확인

// turbo

```powershell
Get-ChildItem -Path "lib/game/" -Filter "*.dart" -Recurse | Select-String -Pattern "Particle|particle" | Select-Object -First 20
```

## 4. 매 프레임 순회 확인

// turbo

```powershell
Get-ChildItem -Path "lib/game/" -Filter "*.dart" -Recurse | Select-String -Pattern "whereType|children\." | Select-Object -First 20
```

## 5. 수정 후 핫 리로드

Flutter run 프로세스에서 `r` 입력.

## 6. 프로파일 모드 실행 (선택)

```powershell
flutter run -d chrome --profile --web-port=8080
```
