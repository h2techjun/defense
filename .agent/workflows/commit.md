---
description: Smart Commit Protocol
---

# Smart Commit Protocol
**Trigger:** `/commit`
**Description:** Conventional Commits 표준에 따른 커밋 메시지 생성 및 Staging

## 1. Diff Review
- `git diff --staged`를 분석하여 변경된 파일과 로직의 핵심을 파악하십시오.
- 불필요한 공백 제거나 디버그용 `console.log`가 포함되어 있다면 제거를 제안하십시오.

## 2. Message Generation (Conventional Commits)
- 다음 형식을 준수하여 메시지를 작성하십시오:
  - `feat`: 새로운 기능 추가
  - `fix`: 버그 수정
  - `docs`: 문서 변경
  - `style`: 코드 포맷팅, 세미콜론 누락 등 (로직 변경 없음)
  - `refactor`: 코드 리팩토링
  - `test`: 테스트 코드 추가/수정
  - `chore`: 빌드 업무 수정, 패키지 매니저 설정 등

## 3. Execution
- 사용자에게 생성된 메시지를 보여주고, 승인 시 `git commit -m "..."` 명령을 실행하십시오.
