---
description: Feature Implementation Protocol
---

# Feature Implementation Protocol
**Trigger:** `/feature`
**Description:** 승인된 계획에 따라 기능을 구현하고, 코딩 표준을 준수하며 검증 수행

## 1. Context Loading
- 현재 작업과 관련된 파일만 선별하여 컨텍스트에 로드하십시오. (불필요한 파일 로드 금지)
- `PLAN.md`가 존재한다면 그 내용을 최우선 지침으로 삼으십시오.

## 2. Incremental Coding (점진적 코딩)
- 한 번에 하나의 파일/함수만 수정하십시오.
- 수정할 때마다 기존 코드를 주석 처리하지 말고, 과감하게 리팩토링하되 원본 로직을 파괴하지 않도록 주의하십시오.
- **Style Guide:** 변수명, 함수명은 프로젝트의 기존 컨벤션을 따르십시오. (CamelCase, snake_case 등)

## 3. Verification Loop (검증 루프)
- 코드를 작성한 후 즉시 다음을 수행하십시오:
  - **Syntax Check:** 문법 오류가 없는지 확인.
  - **Type Check:** (TypeScript/Python의 경우) 타입 불일치 확인.
  - **Linting:** 프로젝트에 설정된 Linter 실행.

## 4. Visual Confirmation (UI 작업 시)
- 프론트엔드 작업이라면 반드시 **브라우저 에이전트**를 실행하십시오.
- 변경된 UI의 스크린샷을 찍어 Artifact로 제출하십시오.