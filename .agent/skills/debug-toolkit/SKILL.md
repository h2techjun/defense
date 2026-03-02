---
name: debug-toolkit
description: Create standalone scripts to debug API or Logic without UI
scope: project-specific
---

# 🛠️ Skill: Debug Toolkit
> UI나 프론트엔드 환경에 의존하지 않고, 백엔드 로직이나 외부 API 연결을 독립적으로 검증하는 스크립트를 생성합니다.

## Usage
1. 에러가 발생했으나 원인이 불분명할 때 (예: 500 API Error).
2. 외부 API 연결 상태를 빠르게 확인하고 싶을 때.
3. 특정 복잡한 로직을 격리하여 테스트하고 싶을 때.

## Implementation Guide
- `scripts/` 디렉토리에 `.ts` 파일을 생성합니다.
- `dotenv`를 사용하여 `.env` 변수를 로드합니다.
- 최소한의 외부 의존성만 사용하여 로직을 검증합니다.
- `console.log`로 단계별 성공/실패를 명확히 출력합니다.
