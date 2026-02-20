---
description: Project Synchronization & Scaffolding Protocol
---

# 프로젝트 동기화 프로토콜 (/sync)

> **목적**: 프로젝트 상태 분석 → `.agent/` 시스템 설치/동기화
>
> **트리거**: 새 워크스페이스 감지, 사용자 명시적 `/sync` 요청

---

## Step 1: 프로젝트 상태 분석

```
1. .agent/ 디렉토리 존재 확인
2. package.json, requirements.txt 등으로 프로젝트 타입 감지
3. README.md로 프로젝트 목적 파악
4. 기존 파일 구조 분석
```

**프로젝트 타입 감지 규칙**:

| 파일 | 타입 |
|------|------|
| `package.json` + `next` | Next.js |
| `package.json` + `react` | React SPA |
| `requirements.txt` + `fastapi` | FastAPI |
| `go.mod` | Go |
| 기타 | Generic |

---

## Step 2: .agent/ 설치 판단

**`.agent/` 없는 경우**:

```
사용자에게 확인:
"이 프로젝트에 자비스 시스템을 설치하시겠습니까?
 [Y] 설치  [N] 글로벌 규칙만 사용"
```

**`.agent/` 있는 경우**:

```
1. 글로벌 템플릿과 비교
2. 누락 파일 식별
3. 업데이트 필요 파일 식별
4. 동기화 계획 보고
```

---

## Step 3: 프로젝트별 .agent/ 구성

**프로젝트 `.agent/`에는 프로젝트 특화 파일만 배치**:

```
[project-root]/.agent/
  ├─ rules/
  │  └─ TECH_STACK.md    # 프로젝트별 기술 스택 오버라이드
  │
  └─ memory/
     ├─ CODEBASE_MAP.md      # 프로젝트 구조
     ├─ DECISION_LOG.md      # 기술 결정
     ├─ DOMAIN_KNOWLEDGE.md  # 비즈니스 로직
     ├─ TECH_DEBT.md         # 기술 부채
     └─ SUCCESS_PATTERNS.md  # 성공 패턴
```

**글로벌에서 관리하는 파일 (프로젝트에 복사하지 않음)**:

```
- rules/DOCTRINE.md       → 글로벌에서 관리
- rules/ANTI_PATTERNS.md   → 글로벌에서 관리
- rules/EVOLUTION_LOG.md   → 글로벌에서 관리
- workflows/*              → 글로벌에서 관리
- personas/*               → 글로벌에서 관리
- skills/*                 → 글로벌 + 프로젝트 전용
```

---

## Step 4: 메모리 초기화

// turbo

```
자동 생성:

1. CODEBASE_MAP.md
   - 디렉토리 구조 스캔
   - 주요 모듈 식별
   
2. DECISION_LOG.md
   - ADR-001: 프로젝트 초기화 기록
   
3. DOMAIN_KNOWLEDGE.md
   - 프로젝트 개요 (package.json description 기반)
```

---

## Step 5: Git 통합 (선택)

```
.gitignore에 추가:
  .agent/memory/SESSION_*.md  (임시 세션 파일만)
  
주의: memory/ 자체는 커밋 (팀 공유 목적)
```

---

## Step 6: 완료 보고

```
🎉 프로젝트 동기화 완료!

프로젝트: [이름]
타입: [감지된 타입]
.agent/ 구성: rules(1), memory(5)

사용 가능 명령:
- /plan: 기획 시작
- /feature: 기능 구현
- /learn: 지식 저장
- /evolve: 자가 진화
```

---

**관리자**: @JARVIS
**마지막 업데이트**: 2026-02-13
