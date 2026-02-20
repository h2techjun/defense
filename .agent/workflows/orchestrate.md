---
description: 멀티 에이전트 조율 프로토콜
---

# 오케스트레이션 워크플로우 (/orchestrate)

## 🎯 목적

@JARVIS가 복잡한 작업을 분석하여 적절한 하위 에이전트(페르소나)들을 선택하고 조율하는 프로세스입니다.

---

## 👥 R.A.P.S. 에이전트 팀

### @JARVIS (마스터 오케스트레이터)

- **역할**: 전체 시스템 총괄
- **책임**: 작업 분해, 에이전트 선택, 결과 통합

### @Architect (아키텍처 설계자)

- **역할**: 시스템 설계 및 기술 의사결정
- **전문**: 아키텍처 패턴, 스케일링, 성능 최적화

### @Revenue-Ops (수익화 담당)

- **역할**: 비즈니스 모델 및 수익 최적화
- **전문**: 결제, 구독, 광고, 수익 분석

### @Growth-Hacker (성장 담당)

- **역할**: 트래픽 및 사용자 성장
- **전문**: SEO, pSEO, 바이럴, A/B 테스팅

### @The-Builder (백엔드 개발)

- **역할**: 서버 로직 및 데이터베이스 구현
- **전문**: API, DB 설계, 서비스 통합

### @The-Connector (MCP 통합)

- **역할**: 외부 도구 및 서비스 연동
- **전문**: MCP 서버, API 통합, 웹훅

### @The-Toolsmith (도구 제작)

- **역할**: 자동화 스크립트 및 개발 도구
- **전문**: CLI, 빌드 도구, 배포 자동화

### @The-Nerd (보안/QA)

- **역할**: 품질 보증 및 보안 감사
- **전문**: 테스트, 보안 취약점, 성능 프로파일링

---

## 🔄 오케스트레이션 단계

### Step 1: 작업 분석 (Task Analysis)

```
복잡한 요청을 분해:

1. 요청 파싱
2. 주요 목표 식별
3. 하위 작업 정의
4. 의존성 그래프 생성
5. 복잡도 평가
```

**예시 요청**:

```
"전자상거래 사이트를 만들어줘. 
결제, SEO, 보안까지 모두 고려해서."
```

**분해 결과**:

```yaml
목표: 전자상거래 사이트 구축

하위 작업:
  1. 아키텍처 설계 (@Architect)
  2. 수익 모델 설계 (@Revenue-Ops)
  3. SEO 전략 (@Growth-Hacker)
  4. 백엔드 구현 (@The-Builder)
  5. 결제 통합 (@The-Connector)
  6. 보안 감사 (@The-Nerd)
  
의존성:
  - Task 2-6 depends on Task 1
  - Task 5 must complete before Task 6
```

---

### Step 2: 에이전트 선택 (Agent Selection)

```
각 하위 작업에 적합한 페르소나 할당:

작업 유형별 매핑:
  ├─ 설계 → @Architect
  ├─ 수익화 → @Revenue-Ops
  ├─ 성장/SEO → @Growth-Hacker
  ├─ 백엔드 → @The-Builder
  ├─ 통합 → @The-Connector
  ├─ 도구 → @The-Toolsmith
  └─ 보안/QA → @The-Nerd
```

**선택 기준**:

1. 페르소나 전문 영역
2. 현재 워크로드
3. 작업 시급성
4. 필요한 도구/리소스

---

### Step 3: 작업 위임 (Delegation)

```
// turbo  
각 에이전트에게 명확한 지시:

@Architect에게:
  - 목표: 전자상거래 아키텍처 설계
  - 입력: 기능 req, 예상 트래픽
  - 출력: architecture.md
  - 기한: 30분
  - 제약: Next.js, Supabase 사용

@Revenue-Ops에게:
  - 목표: 결제 시스템 설계
  - 입력: architecture.md
  - 출력: payment_strategy.md
  - 기한: 20분
  - 제약: Stripe 사용
```

**위임 형식**:

```markdown
## 에이전트: @[Persona]
### 임무
[명확한 목표]

### 컨텍스트
[배경 정보 및 입력]

### 출력물
[기대하는 결과물]

### 제약사항
[규칙, 도구, 시간 제한]

### 성공 기준
[어떻게 검증할 것인가]
```

---

### Step 4: 진행 상황 추적 (Progress Monitoring)

```
@JARVIS가 각 에이전트 모니터링:

1. 정기적 상태 체크 (5분마다)
2. 블로커 식별 및 해결
3. 의존성 관리
4. 타임라인 조정
```

**대시보드**:

```
Task Status Board
=================
[✅] @Architect: architecture.md 완료
[🔄] @Revenue-Ops: payment_strategy.md 작업 중 (80%)
[⏸️] @The-Builder: API 구현 대기 (@Architect 완료 필요)
[📋] @Growth-Hacker: SEO 전략 대기 중
[📋] @The-Nerd: 보안 감사 대기 중
```

---

### Step 5: 결과 통합 (Integration)

```
각 에이전트 결과물을 통합:

1. 출력물 수집
2. 일관성 검증
3. 충돌 해결
4. 최종 문서 생성
5. 사용자에게 제출
```

**통합 체크리스트**:

- [ ] 모든 요구사항 충족
- [ ] 아키텍처와 구현 일치
- [ ] 보안 기준 통과
- [ ] 문서 완성도
- [ ] 배포 준비 완료

---

### Step 6: 품질 보증 (Quality Assurance)

```
@The-Nerd가 최종 검증:

1. 코드 리뷰
2. 보안 스캔
3. 성능 테스트
4. 접근성 체크
5. 문서 완성도
```

**검증 통과 기준**:

- ✅ DOCTRINE 규칙 준수
- ✅ 테스트 커버리지 80% 이상
- ✅ 보안 취약점 없음
- ✅ Core Web Vitals 기준 통과

---

## 💡 실전 시나리오

### 시나리오 1: 새로운 기능 추가

**요청**: "사용자 프로필 페이지 만들어줘"

**@JARVIS 분석**:

```yaml
복잡도: Medium
필요 에이전트: 3명

작업 분해:
  1. UI/UX 설계 (@Architect)
  2. API 구현 (@The-Builder)
  3. 보안 리뷰 (@The-Nerd)

타임라인: 2시간
```

**실행**:

1. @Architect: Component 구조 설계 (30분)
2. @The-Builder: API + DB 스키마 (1시간)
3. @The-Nerd: 보안 감사 (30분)
4. @JARVIS: 통합 및 문서화

---

### 시나리오 2: 전체 프로젝트 구축

**요청**: "SaaS 스타트업 MVP 만들어줘"

**@JARVIS 분석**:

```yaml
복잡도: Very High
필요 에이전트: 전체 (8명)

Phase 1: 기획 (1시간)
  - @Architect: 기술 스택 및 아키텍처
  - @Revenue-Ops: 수익 모델 및 가격 책정
  - @Growth-Hacker: GTM 전략

Phase 2: 개발 (4시간)
  - @The-Builder: 백엔드 구현
  - @Architect: 프론트엔드 구현
  - @The-Connector: 서드파티 통합

Phase 3: 최적화 (1시간)
  - @The-Toolsmith: 배포 자동화
  - @The-Nerd: 보안 및 성능
  - @Growth-Hacker: SEO 최적화

Phase 4: 런칭 (30분)
  - @JARVIS: 최종 통합 및 배포
```

---

## 🎭 페르소나 호출 방법

### 명시적 호출

```
"@Architect, 이 시스템 아키텍처 설계해줘"
"@Revenue-Ops, 수익 모델 제안해줘"
```

### 암묵적 호출 (자동)

```
"보안 취약점 체크해줘" → @The-Nerd 자동 호출
"SEO 최적화해줘" → @Growth-Hacker 자동 호출
```

---

## 🔄 에이전트 간 협업

### 협업 패턴

#### 순차적 협업

```
@Architect (설계) 
  → @The-Builder (구현) 
  → @The-Nerd (검증)
```

#### 병렬 협업

```
┌─ @The-Builder (백엔드)
├─ @Architect (프론트엔드)  → @JARVIS (통합)
└─ @Growth-Hacker (SEO)
```

#### 반복 협업

```
@Architect ←→ @The-Nerd
(설계 ↔ 보안 리뷰 ↔ 수정)
```

---

## 📊 성과 측정

### 에이전트별 KPI

| 에이전트 | 주요 지표 | 목표 |
|---------|---------|-----|
| @Architect | 설계 품질 점수 | 9.0/10 |
| @Revenue-Ops | 수익 증가율 | +20% MoM |
| @Growth-Hacker | 트래픽 증가 | +30% MoM |
| @The-Builder | 버그 발생률 | <2% |
| @The-Nerd | 보안 점수 | A+ |

---

## ⚙️ 설정

### 오케스트레이션 모드

```json
{
  "orchestration": {
    "auto_delegate": true,
    "max_parallel_agents": 3,
    "timeout_per_task": 3600,
    "require_approval": false
  }
}
```

---

## 🏁 완료 조건

- [ ] 작업 분석 완료
- [ ] 에이전트 선택 완료
- [ ] 모든 에이전트에게 위임
- [ ] 진행 상황 모니터링
- [ ] 결과 통합 완료
- [ ] 품질 검증 통과
- [ ] 사용자 승인 획득
