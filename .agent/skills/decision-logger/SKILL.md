---
name: Decision Logger
description: 중요한 의사결정을 자동으로 DECISION_LOG.md에 기록
version: 1.0.0
---

# 📝 Decision Logger Skill

## 목적

프로젝트의 중요한 의사결정을 **자동으로 감지하고 기록**하여 미래의 문맥 이해를 돕습니다.

## 작동 방식

### Decision 감지 패턴

다음 상황에서 자동으로 로깅:

#### 1. 기술 스택 변경

```typescript
// 감지 키워드
const TECH_CHANGES = [
  '도입', '제거', '업그레이드', '마이그레이션',
  '~로 변경', '~에서 ~로', '라이브러리 추가'
]

// 예시
"Gemini 2.0 Flash로 업그레이드"
→ 자동 로깅
```

#### 2. 아키텍처 결정

```typescript
const ARCHITECTURE_DECISIONS = [
  'DB 스키마', '테이블 추가', 'API 엔드포인트',
  'monorepo', '폴더 구조', '모듈 분리'
]

// 예시
"사용자 테이블에 tier 컬럼 추가"
→ 자동 로깅
```

#### 3. 보안 정책

```typescript
const SECURITY_DECISIONS = [
  'RLS 정책', '인증 방식', 'API 키 회전',
  '접근 제어', '권한 관리'
]

// 예시
"관리자 페이지에 수동 세션 복구 로직 추가"
→ 자동 로깅
```

#### 4. 비즈니스 로직

```typescript
const BUSINESS_DECISIONS = [
  '가격 정책', '플랜 변경', '기능 제한',
  '사용량 제한', '쿼터'
]

// 예시
"Free 플랜 월 10회로 제한"
→ 자동 로깅
```

#### 5. 성능 최적화

```typescript
const PERFORMANCE_DECISIONS = [
  '캐싱', '인덱스 추가', '쿼리 최적화',
  '레이지 로딩', 'CDN'
]

// 예시
"번역 결과를 Redis에 캐싱"
→ 자동 로깅
```

### 로그 포맷

```markdown
## 2026-02-07

### 🔧 기술 스택

- **결정**: Gemini 2.0 Flash 도입
- **이유**: Long Context 지원으로 대용량 문서 처리 가능
- **영향**: 번역 품질 20% 향상, 비용 30% 절감
- **담당**: @Architect, @The-Nerd

### 🛡️ 보안

- **결정**: 관리자 API에 수동 세션 복구 적용
- **이유**: 미들웨어 의존성 제거, 무결성 보장
- **파일**: `app/api/admin/*/route.ts`
- **담당**: @The-Guardian

### 💰 비즈니스

- **결정**: Guest 등급 신설 (이메일 없는 사용자)
- **이유**: 무명 사용자 관리 및 전환 추적
- **영향**: 전환율 측정 가능, 마케팅 최적화
- **담당**: @Growth-Hacker, @Architect
```

## 자동 실행 조건

### Trigger 1: 파일 변경 감지

```typescript
// DB 스키마 파일 변경 시
if (changedFile.includes("supabase/migrations")) {
  logDecision({
    category: "Database",
    file: changedFile,
    description: extractCommitMessage(),
  });
}
```

### Trigger 2: 환경 변수 추가

```typescript
// .env.example 변경 시
if (changedFile === ".env.example") {
  logDecision({
    category: "Configuration",
    description: "새 환경 변수 추가",
    variables: extractNewVariables(),
  });
}
```

### Trigger 3: 사용자 명시적 요청

```typescript
// 사용자가 "이 결정 기록해줘" 요청 시
if (userRequest.includes("기록")) {
  await manualLog();
}
```

## 구현 예시

### Python 스크립트 (자동화)

```python
#!/usr/bin/env python3
"""
Decision Logger - 자동 의사결정 기록
"""

import os
import re
from datetime import datetime
from pathlib import Path

DECISION_LOG = Path('.agent/memory/DECISION_LOG.md')

PATTERNS = {
    'tech': r'(도입|제거|업그레이드|마이그레이션)',
    'db': r'(테이블|스키마|컬럼|인덱스)',
    'security': r'(RLS|인증|권한|보안)',
    'business': r'(가격|플랜|제한|쿼터)'
}

def detect_decision(commit_message: str) -> dict:
    """커밋 메시지에서 의사결정 추출"""
    for category, pattern in PATTERNS.items():
        if re.search(pattern, commit_message):
            return {
                'category': category,
                'message': commit_message,
                'date': datetime.now().strftime('%Y-%m-%d')
            }
    return None

def log_decision(decision: dict):
    """DECISION_LOG.md에 기록"""
    with open(DECISION_LOG, 'a', encoding='utf-8') as f:
        f.write(f"\n## {decision['date']}\n\n")
        f.write(f"- {decision['message']}\n")

# Git hook 으로 실행
if __name__ == '__main__':
    import sys
    commit_msg = sys.argv[1]

    decision = detect_decision(commit_msg)
    if decision:
        log_decision(decision)
        print(f"✅ Decision logged: {decision['category']}")
```

### Git Hook 설정

```bash
# .git/hooks/post-commit
#!/bin/sh
python .agent/skills/decision-logger/log_decision.py "$(git log -1 --pretty=%B)"
```

## DECISION_LOG.md 구조

```markdown
# 프로젝트 의사결정 로그

> 중요한 기술적/비즈니스적 결정 기록

## 2026-02-07

### 🔧 기술

- Gemini 2.0 Flash 도입 (Long Context 활용)
- pdf2json 파서로 변경 (28% 성능 향상)

### 🛡️ 보안

- 모든 관리자 API에 수동 세션 복구 적용

### 💰 비즈니스

- Guest 등급 신설 (무명 사용자 관리)

## 2026-02-01

### 🔧 기술

- Turborepo 도입 (빌드 70% 단축)

### 💰 비즈니스

- Team 플랜 가격 $29.99 확정
```

## 검색 및 활용

### 특정 날짜 검색

```bash
grep "2026-02" .agent/memory/DECISION_LOG.md
```

### 카테고리별 검색

```bash
grep "🔧 기술" .agent/memory/DECISION_LOG.md
```

### 전체 히스토리 조회

```bash
cat .agent/memory/DECISION_LOG.md
```

## 통합: JARVIS와 연동

```typescript
// JARVIS가 중요한 변경 감지 시 자동 로깅
async function onMajorChange(change: Change) {
  if (shouldLog(change)) {
    await logDecision({
      date: new Date(),
      category: inferCategory(change),
      description: change.summary,
      files: change.files,
      agents: change.involvedAgents,
    });

    // 사용자에게 알림
    console.log("📝 의사결정이 자동으로 기록되었습니다.");
  }
}
```

## 월간 요약 자동 생성

```python
def generate_monthly_summary(month: str):
    """월별 의사결정 요약"""
    decisions = parse_decision_log(month)

    summary = f"""
# {month} 의사결정 요약

## 주요 기술 변경
{format_list(decisions['tech'])}

## 보안 강화
{format_list(decisions['security'])}

## 비즈니스 전략
{format_list(decisions['business'])}

## 영향 분석
- 성능: {calculate_performance_impact(decisions)}
- 비용: {calculate_cost_impact(decisions)}
- 보안: {calculate_security_impact(decisions)}
    """

    return summary
```

---

**실행 시점**:

- Git 커밋 시 자동 실행 (post-commit hook)
- JARVIS가 주요 변경 감지 시 자동 실행
- 사용자 명시적 요청 시 수동 실행
