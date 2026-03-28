# Gateway of Regrets - 출시 준비도 평가 & 로드맵

> **작성일**: 2026-03-28
> **완성도**: ~90% (MVP 기준)
> **결론**: 핵심 게임은 상용 수준. 스토어 출시를 위한 인프라 작업 2-3주 필요.

---

## 잘 되어있는 부분 (출시 준비 완료)

- 5종 타워 (10개 분기 포함), 5종 영웅, 31종 적 - 콘텐츠 충분
- 100개 레벨 (5챕터 x 20스테이지), 무한의 탑, 일일 도전
- 메타 시스템 완비: 업적, 시즌패스, 유물, 스킨, 설화도감, 소환
- 20개 언어 i18n 지원
- 클라우드 세이브 (Supabase) + 로컬 세이브
- 글래스모피즘 UI 테마 + 반응형 디자인
- 사운드 시스템 (BGM 10트랙+ / SFX)
- 광고 기반 수익 모델 설계 완료
- 에러 핸들링 전반적으로 양호 (168개 try/catch)
- 코드 아키텍처 깔끔 (Flame + Riverpod + Flutter 분리)

---

## Phase 1: 출시 필수 (1-2주)

### 1. [CRITICAL] Android 빌드 설정 - 스토어 제출 불가
- [ ] `applicationId`를 `com.example.gateway_of_regrets` → 실제 패키지명으로 변경
- [ ] 릴리즈 서명 keystore 생성 및 설정
- [ ] ProGuard/R8 난독화 설정
- **파일**: `android/app/build.gradle.kts`

### 2. [CRITICAL] AdMob SDK 초기화 미완성
- [ ] `MobileAds.instance.initialize()` 주석 해제 및 연동
- [ ] 실제 AdMob 앱 ID 등록
- [ ] AndroidManifest에 AdMob 메타데이터 추가
- **파일**: `lib/services/ad_manager.dart:184`

### 3. [HIGH] 크래시 리포팅/애널리틱스 없음
- [ ] Firebase Crashlytics 추가 (pubspec.yaml + 초기화)
- [ ] Firebase Analytics 추가 (유저 행동 추적)
- [ ] 출시 후 크래시 모니터링 환경 구성

### 4. [HIGH] 모바일 소형 화면 최적화 미완
- [ ] HUD/폰트/레이아웃 소형 스마트폰 비율 문제 수정
- [ ] 실제 디바이스 테스트 (5인치 이하)

### 5. [HIGH] 앱 라이프사이클 관리 부재
- [ ] `didChangeAppLifecycleState` 리스너 추가
- [ ] 백그라운드 전환 시 게임 자동 일시정지
- [ ] 포그라운드 복귀 시 상태 복원

---

## Phase 2: 품질 개선 (1주)

### 6. [MEDIUM] 디버그 코드 정리
- [ ] `print()` 2곳 제거 (rally_flag_component.dart)
- [ ] debug 프로퍼티 정리 (base_enemy.dart)
- [ ] bare catch 24개+ → 구체적 예외 타입 지정

### 7. [MEDIUM] i18n 하드코딩 잔여 제거
- [ ] hero_lore_read, et_tab_tower, et_tab_daily, sp_tab 등 14곳
- [ ] revive_text (hero_skill_panel.dart)

### 8. [MEDIUM] .env 보안 정리
- [ ] .env가 git에 커밋되었는지 확인
- [ ] .gitignore에 .env 추가 (필요시)
- [ ] git history에서 .env 제거 (필요시)

### 9. [MEDIUM] 미구현 TODO 마무리 또는 제거
- [ ] 에너지 탄환 발사 로직 (base_enemy.dart)
- [ ] 타워 파괴 시각 이펙트 (base_enemy.dart)
- [ ] 영웅 레벨 실제 연동 (hero_manage_screen.dart)

---

## Phase 3: 출시 후 (지속)

- [ ] 테스트 코드 작성 (핵심 로직: 데미지 계산, 웨이브, 세이브/로드)
- [ ] 밸런스 조정 (유저 데이터 기반)
- [ ] 성능 프로파일링 및 최적화
- [ ] iOS 빌드 설정 (향후)

---

## 게임 밸런스 우려사항

1. **천뢰 타워(Heavenly Thunder)**: 500 데미지로 다른 Tier3 대비 2.6배 → 후반 필수 타워화 우려
2. **보스 HP 스케일링**: Ch1(5,250) → Ch5(37,500)으로 +614% 증가, 타워 데미지와 불균형 가능
3. **일부 적 카운터 메커니즘 불명확**: 얼굴도둑(Face Stealer) 면역 전환 등
