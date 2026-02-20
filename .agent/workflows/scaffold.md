---
description: Project Auto-Scaffolding with Agent System (자동 초기화)
---

# 프로젝트 자동 스캐폴딩 프로토콜 (/scaffold)

> **목적**: 새 프로젝트 시작 시 프로젝트별 `.agent/` 구성 자동 생성
>
> **원칙**: 글로벌에서 전체 관리, 프로젝트에는 필요한 것만

---

## 📐 글로벌 vs 프로젝트 분리 원칙

### 글로벌에서 관리 (프로젝트에 복사하지 않음)

```
~/.gemini/antigravity/.agent/
  ├─ rules/DOCTRINE.md       # 전역 철칙
  ├─ rules/ANTI_PATTERNS.md  # 전역 안티패턴
  ├─ rules/EVOLUTION_LOG.md  # 전역 진화 이력
  ├─ rules/TECH_STACK.md     # 전역 기술 스택
  ├─ workflows/*             # 모든 워크플로우
  ├─ personas/*              # 모든 페르소나
  └─ skills/*                # 범용 스킬
```

### 프로젝트별 생성 (프로젝트 특화)

```
[project]/.agent/
  ├─ rules/
  │  └─ TECH_STACK.md        # 오버라이드 (프로젝트 고유 기술)
  │
  └─ memory/
     ├─ CODEBASE_MAP.md      # 프로젝트 구조
     ├─ DECISION_LOG.md      # 프로젝트 기술 결정
     ├─ DOMAIN_KNOWLEDGE.md  # 프로젝트 비즈니스 로직
     ├─ TECH_DEBT.md         # 프로젝트 기술 부채
     └─ SUCCESS_PATTERNS.md  # 프로젝트 성공 패턴
```

---

## 📋 워크플로우

### Step 1: 워크스페이스 감지

```
새 프로젝트 디렉토리에서 작업 시작
  → .agent/ 존재 확인
  → 없으면 사용자에게 설치 제안
```

### Step 2: 프로젝트 타입 감지

| 감지 파일 | 타입 | 기본 스택 |
|----------|------|----------|
| `package.json` + `next` | Next.js | Next.js, Tailwind, Supabase |
| `package.json` + `react` | React | Vite, React |
| `requirements.txt` + `fastapi` | FastAPI | FastAPI, SQLAlchemy |
| `go.mod` | Go | Go |
| 기타 | Generic | 범용 |

### Step 3: 프로젝트 .agent/ 생성

// turbo

```powershell
# 프로젝트 .agent/ 디렉토리 생성
$workspace = "D:\00_Project\[프로젝트명]"

New-Item -ItemType Directory -Force "$workspace\.agent\rules"
New-Item -ItemType Directory -Force "$workspace\.agent\memory"
```

### Step 4: 메모리 파일 초기화

각 파일을 프로젝트 정보로 초기화:

1. **CODEBASE_MAP.md**: 디렉토리 구조 스캔하여 생성
2. **DECISION_LOG.md**: ADR-001 "프로젝트 초기화" 기록
3. **DOMAIN_KNOWLEDGE.md**: package.json description 기반 개요
4. **TECH_DEBT.md**: 빈 템플릿
5. **SUCCESS_PATTERNS.md**: 빈 템플릿

### Step 5: TECH_STACK Override 생성 (해당 시)

프로젝트 고유 기술이 있는 경우만:

```markdown
# TECH_STACK Override: [프로젝트명]

## 추가 기술
- [프로젝트 고유 라이브러리]

## 설정 변경
- [글로벌 기본과 다른 설정]
```

### Step 6: 완료 보고

```
🎉 프로젝트 스캐폴딩 완료!

프로젝트: [이름]
타입: [감지]
생성된 파일:
  .agent/rules/TECH_STACK.md (오버라이드)
  .agent/memory/CODEBASE_MAP.md
  .agent/memory/DECISION_LOG.md
  .agent/memory/DOMAIN_KNOWLEDGE.md
  .agent/memory/TECH_DEBT.md
  .agent/memory/SUCCESS_PATTERNS.md
```

---

## 🔧 고급 옵션

| 옵션 | 설명 |
|------|------|
| Full | rules + memory (기본) |
| Lite | memory만 |
| Custom | 사용자 선택 |

---

## 🚨 주의사항

- 기존 `.agent/` 있으면 백업 후 진행
- 글로벌 파일을 프로젝트에 복사하지 않음
- 프로젝트 메모리는 Git 커밋 대상 (팀 공유)

---

**관리자**: @JARVIS
**마지막 업데이트**: 2026-02-13
