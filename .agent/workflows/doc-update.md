---
description: Documentation Synchronization
---

# Documentation Synchronization
**Trigger:** `/doc-update`
**Description:** 코드 변경 사항을 문서(README, API Spec)에 반영

## 1. Diff Analysis
- 최근 `git diff`를 분석하여 로직, 파라미터, 반환값이 변경된 함수를 식별하십시오.

## 2. Docstring & Comment Update
- 코드 내부의 주석(JSDoc, Docstring)이 현재 로직과 일치하는지 확인하고 업데이트하십시오.
- 파라미터 설명(`@param`)과 반환값(`@return`)을 최신화하십시오.

## 3. External Docs Update
- `README.md`: 설치 방법, 환경 변수, 주요 기능 변경 사항을 반영하십시오.
- `API.md` 또는 Swagger: 엔드포인트 변경 사항을 반영하십시오.

## 4. Consistency Check
- 문서 간에 상충되는 내용이 없는지 교차 검증하십시오.