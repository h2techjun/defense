# Defense - Gateway of Regrets: Soul Defense

## 프로젝트 개요
한국 민속 기반 타워디펜스 RPG. Flame 엔진 + Riverpod 상태관리. 영혼 수호, 타워 배치, 영웅 파티, 무한의 탑, 시즌패스.

## 🌐 Workmate 허브 노출
이 프로젝트는 **workmate.tools/projects 의 게임 탭**에 카드로 노출됨.
- 카드 링크 URL: `https://h2techjun.github.io/defense/` (GitHub Pages 웹 빌드)
- 카탈로그 항목: `D:/02_PROJECT/10_worktool/lib/projectsCatalog.ts` 의 `id: "defense"`
- **외부 URL이 죽으면 워크메이트 카드 링크 깨짐** — GH Pages 배포 중단 시 카탈로그도 함께 갱신.
- 빌드 사이즈 542MB (이미지 251MB + 오디오 125MB) — Workmate 직접 호스팅 불가, 외부 링크 영구 유지.

## 기술 스택
| 구분 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.6+ / Dart 3.6+ |
| 게임 엔진 | Flame 1.30 |
| 상태관리 | Riverpod 2.6 + flame_riverpod 5.0 |
| 오디오 | flame_audio 2.10 |
| DB/Auth | Supabase (supabase_flutter 2.12) |
| 저장소 | shared_preferences |
| 환경변수 | flutter_dotenv |
| 타겟 | Windows, Web, Android |

## 구조
```
defense/
├── lib/
│   ├── main.dart                 # 앱 진입점
│   ├── game_screen.dart          # Flame GameWidget 래퍼
│   ├── game/
│   │   ├── defense_game.dart     # FlameGame 메인 클래스
│   │   ├── components/
│   │   │   ├── actors/           # 적, 아군 유닛
│   │   │   ├── effects/          # 시각 이펙트
│   │   │   ├── items/            # 아이템
│   │   │   ├── objects/          # 맵 오브젝트
│   │   │   ├── renderers/        # 커스텀 렌더러
│   │   │   ├── towers/           # 타워 컴포넌트
│   │   │   └── ui/               # 인게임 UI 컴포넌트
│   │   ├── mixins/               # 게임 로직 믹스인
│   │   ├── systems/              # ECS 시스템
│   │   └── world/                # 월드/맵 관리
│   ├── state/                    # Riverpod 프로바이더
│   ├── ui/                       # Flutter UI (menus, dialogs, hud, widgets)
│   ├── data/                     # 정적 게임 데이터
│   ├── audio/                    # 오디오 매니저
│   ├── services/                 # 외부 서비스 연동
│   ├── l10n/                     # 다국어 (assets/i18n/)
│   └── common/                   # 상수, 유틸리티
├── assets/                       # 이미지/오디오/i18n/data
├── android/                      # AAB + proguard + 키스토어
├── tool/                         # build_web.ps1 / deploy_patch.py / audit
└── releases/                     # 빌드 결과물
```

## 명령어
```powershell
flutter pub get                           # 의존성 설치
flutter run -d windows                    # Windows 실행
flutter run -d chrome                     # Web 실행
flutter build web --release               # Web 프로덕션 빌드
flutter test                              # 유닛 테스트
flutter test integration_test/            # 통합 테스트
python tool/defense_audit.py              # 시스템 audit
```

## 환경변수 (`.env` — pubspec assets에 등록)
```
SUPABASE_URL              # https://YOUR.supabase.co
SUPABASE_ANON_KEY         # anon 공개 키
```
`.env` 파일은 `pubspec.yaml` assets 에 등록되어 빌드에 번들됨. 시크릿 관리 주의.

## 규칙
- `game/`은 Flame 컴포넌트만 — Flutter 위젯 혼용 금지
- `state/`의 Riverpod 프로바이더가 game/과 ui/ 사이 유일한 통신 채널
- 레벨 데이터는 `assets/data/levels/`에 JSON으로 관리
- `.env` 파일에 Supabase 키 관리 (pubspec.yaml에 assets로 등록됨)
- 다국어 파일은 `assets/i18n/`에 위치

## CrazyGames 웹 배포
> **빌드만으로는 안 됨 — deploy_patch.py 필수!**

```powershell
# 1. 빌드 (환경변수 자동 주입)
powershell -File tool/build_web.ps1

# 2. 후처리 (필수! 안 하면 검은 화면)
python tool/deploy_patch.py

# 3. build/web 폴더를 CrazyGames Developer Portal에 업로드
```

### deploy_patch.py 역할
1. `<base href>` → `"./"` (CDN 호환 상대경로)
2. AssetManifest / FontManifest 인라인 임베딩 (CDN 403 우회)
3. 서비스워커 제거 (CrazyGames SW와 충돌 방지)
4. canvaskit/ 로컬 삭제 → CDN 자동 로드 (~24-32MB 절감)
5. .js.symbols 디버그 파일 제거

### SDK 라이프사이클
| 시점 | 호출 |
|------|------|
| main() | `loadingStart()` → `init()` |
| 게임 화면 로드 완료 | `loadingStop()` → `gameplayStart()` |
| 스테이지 종료 | `gameplayStop()` → `requestMidgameAd()` |
| 광고 종료 | `gameplayStart()` (재개) |
| 승리/달성 | `happytime()` |

## 🔍 자동 검증 도구 (`tool/`)
| 도구 | 역할 |
|---|---|
| `tool/defense_audit.py` | INTERNET/shrinkResources/proguard/.env/version 정합성 |
| `tool/build_web.ps1` | Web 빌드 (환경변수 주입) |
| `tool/deploy_patch.py` | CrazyGames 배포 후처리 (5단계) |

## 📚 사고 학습 (재발 방지)
- **CrazyGames 검은 화면**: 빌드만 하고 deploy_patch.py 안 돌리면 base href, ServiceWorker, CDN 403 모두 깨짐
- **빌드 사이즈 542MB**: 이미지 251MB + 오디오 125MB. Workmate 직접 호스팅 불가, 외부 GH Pages 유지
- **flame_riverpod 5.0**: 4.x 와 API 다름. 마이그레이션 시 주의
- **assets/i18n/**: 표준 flutter intl 패키지 아님 → 수동 JSON 로드. 키 누락 시 silent fail
- **.env 가 git 포함되면 시크릿 노출** — `.gitignore` 검증 필수

## 참고 플레이북
`~/.claude/rules/playbooks.md` (전역) — Flutter 게임 패턴, Web 배포, Android 릴리스, Playwright Flutter Web
