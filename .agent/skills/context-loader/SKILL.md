---
name: Context Auto-Loader
description: 사용자 요청 유형을 분석하여 필요한 규칙/페르소나 파일을 자동으로 로드
version: 2.0.0
---

# 🧠 Context Auto-Loader Skill v2.0

## 목적

사용자 요청을 분석하여 **필요한 파일만 선택적으로 로드**함으로써 응답 속도를 향상시킵니다.

## 작동 방식

### Step 1: 요청 분류

사용자 요청에서 키워드를 추출하여 카테고리 분류:

```
REQUEST_PATTERNS = {
  coding:    ["코드", "구현", "함수", "클래스", "버그", "에러"],
  security:  ["보안", "인증", "권한", "RLS", "비밀번호", "API 키"],
  feature:   ["기능", "추가", "새로운", "개발"],
  debug:     ["디버그", "오류", "작동 안", "문제", "프리즈"],
  ui:        ["UI", "UX", "디자인", "스타일", "레이아웃"],
  deploy:    ["배포", "deploy", "production", "vercel", "빌드"],
  payment:   ["결제", "수익", "stripe", "가격", "광고", "수익화"],
  docs:      ["문서", "README", "가이드", "설명"],
  game:      ["게임", "타워", "웨이브", "Flame", "적", "영웅", "스프라이트", "밸런스", "맵"],
  refactor:  ["리팩토링", "정리", "분리", "최적화", "성능"],
  system:    ["점검", "진화", "스웜", "에이전트", "시스템"],
}
```

### Step 2: 파일 매핑

> **규칙**: 프로젝트 `.agent/`가 존재하면 글로벌보다 우선 로드

#### 코딩/구현 작업

```
required:  [.agent/rules/CODING_STANDARDS.md, .agent/rules/TECH_STACK.md]
personas:  [@The-Builder, @Architect]
optional:  [.agent/rules/ANTI_PATTERNS.md]
```

#### 보안/인증 작업

```
required:  [@The-Nerd, .agent/rules/TECH_STACK.md]
workflows: [.agent/workflows/security.md]
```

#### 새 기능 개발

```
required:  [.agent/workflows/feature.md]
personas:  [@Architect, @Designer, @The-Builder, @Tester, @Reviewer]
```

#### 버그 디버깅

```
required:  [.agent/workflows/debug.md]
personas:  [@The-Nerd, @The-Builder, @Tester]
```

#### 🎮 게임 개발 (NEW)

```
required:  [.agent/rules/CODING_STANDARDS.md, .agent/rules/GRAPHICS_PIPELINE.md]
personas:  [@The-Builder, @Designer, @Tester]
optional:  [.agent/rules/ANTI_PATTERNS.md (AP-016~020 게임 특화)]
memory:    [.agent/memory/DOMAIN_KNOWLEDGE.md (게임 용어/밸런스)]
```

#### UI/UX 작업

```
required:  [@Designer]
optional:  [.agent/rules/CODING_STANDARDS.md]
```

#### 배포

```
required:  [.agent/workflows/deploy.md, @The-Nerd]
```

#### 결제/수익화

```
required:  [@Revenue-Ops, @The-Nerd]
```

#### 문서 작업

```
required:  [@Librarian]
workflows: [.agent/workflows/doc-update.md]
```

#### 리팩토링 (NEW)

```
required:  [.agent/workflows/refactor.md, .agent/rules/ANTI_PATTERNS.md]
personas:  [@Architect, @Reviewer]
```

#### 시스템 관리 (NEW)

```
required:  [.agent/rules/DOCTRINE.md, .agent/rules/EVOLUTION_LOG.md]
personas:  [@Minerva, @The-Toolsmith]
```

### Step 3: 프로젝트 우선 로드

```
1. 프로젝트 .agent/ 존재 확인
2. 프로젝트 .agent/rules/TECH_STACK.md 우선 로드 (override)
3. 프로젝트 .agent/rules/CODING_STANDARDS.md 우선 로드
4. 없는 파일은 글로벌 .agent/에서 fallback
```

### Step 4: 스마트 캐싱

이미 로드된 파일은 재로드하지 않음. 마스터 @Minerva가 세션 초기화 시 필수 파일(TECH_STACK, CODEBASE_MAP)을 미리 로드.

## 사용 예시

### 예시 1: 게임 기능 구현

```
사용자: "타워 Tier 4 분기 시스템 구현해줘"

자동 로드:
✓ CODING_STANDARDS.md (프로젝트)
✓ TECH_STACK.md (프로젝트 — Flame/Flutter)
✓ GRAPHICS_PIPELINE.md (프로젝트)
✓ @The-Builder.md
✓ @Designer.md
✓ ANTI_PATTERNS.md (AP-016~020 게임 패턴)
✓ DOMAIN_KNOWLEDGE.md (타워 체계 용어)
```

### 예시 2: 보안 이슈

```
사용자: "API 키가 노출됐어"

자동 로드:
✓ @The-Nerd.md
✓ security.md
✓ TECH_STACK.md (환경 변수 섹션)
```

### 예시 3: 시스템 점검

```
사용자: "시스템 점검해줘"

자동 로드:
✓ DOCTRINE.md
✓ EVOLUTION_LOG.md
✓ @Minerva.md
✓ @The-Toolsmith.md
```

## 최적화 전략

1. **우선순위 로딩**: 필수 → 권장 → 선택 순서
2. **병렬 로드**: 독립적인 파일은 동시 로드
3. **증분 로드**: 대화 진행 중 복잡도 증가 시 추가 로드

---

**실행 방법**: @Minerva가 매 대화 시작 시 자동 실행
**마지막 업데이트**: 2026-03-03 (v2.0 — 게임/리팩토링/시스템 카테고리 추가, @Minerva 반영)
