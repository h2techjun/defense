---
description: Deep Debugging Protocol
---

# Deep Debugging Protocol
**Trigger:** `/debug`
**Description:** 에러 로그 분석, 근본 원인 규명, 솔루션 제시 및 검증

## 1. Log Analysis & RCA (근본 원인 분석)
- 에러 로그를 단순히 읽지 말고, 스택 트레이스(Stack Trace)를 역추적하십시오.
- **Five Whys:** "왜 에러가 발생했는가?"를 3번 이상 반복하여 근본 원인을 찾으십시오.
- 가설(Hypothesis)을 세우고 이를 검증할 방법을 계획하십시오.

## 2. Reproduction (재현)
- 버그를 재현할 수 있는 최소한의 코드(Reproduction Script)나 테스트 케이스를 작성하십시오.
- 이 테스트가 실패함을 먼저 확인하십시오 (Red 단계).

## 3. Fix Implementation (수정)
- 사이드 이펙트를 최소화하는 가장 방어적인 수정 코드를 작성하십시오.
- "임시 방편(Hack)"이나 "매직 넘버" 사용을 금지합니다.

## 4. Verification (검증)
- 앞서 작성한 재현 테스트가 성공(Green)하는지 확인하십시오.
- 수정 사항이 기존 기능(Regression)을 망가뜨리지 않았는지 관련 테스트를 실행하십시오.
