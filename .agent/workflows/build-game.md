---
description: Flutter 게임 빌드 및 배포 워크플로우
---

# Flutter Game Build & Deploy

## 1. 빌드 전 체크

// turbo

```bash
flutter analyze --no-fatal-infos
```

## 2. 웹 빌드 (릴리즈)

```bash
flutter build web --release
```

## 3. 빌드 결과 확인

// turbo

```bash
ls build/web/
```

## 4. 로컬 테스트 서버

```bash
cd build/web && python -m http.server 8080
```

## 5. Android APK 빌드 (선택)

```bash
flutter build apk --release
```

## 6. Firebase Hosting 배포 (선택)

```bash
firebase deploy --only hosting
```
