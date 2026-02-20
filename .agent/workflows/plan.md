---
description: Strategic Planning Protocol
---

# Strategic Planning Protocol
**Trigger:** `/plan`
**Description:** 기능 구현 전 기술 설계, 영향도 분석, 단계별 실행 계획 수립

## 1. Requirement Analysis (요구사항 분석)
- 사용자의 모호한 요청을 기술적 사양(Technical Spec)으로 구체화하십시오.
- **Goal:** 무엇을 만들 것인가? (What)
- **Context:** 기존 코드베이스의 어떤 부분과 연결되는가?
- **Constraints:** 기술적 제약 사항은 무엇인가? (예: 특정 라이브러리 버전, 성능 요구사항)

## 2. Requirement & Business Analysis
- 기술적 요구사항뿐만 아니라, **"이 기능이 수익 창출에 어떻게 기여하는가?"**를 분석하십시오.
- 포인트 차감 여부, 유료화 대상 여부를 결정하십시오.

## 3. Architecture Design (아키텍처 설계)
- 변경하거나 생성할 파일 목록을 트리 구조로 시각화하십시오.
- 데이터 흐름(Data Flow)과 상태 관리(State Management) 전략을 정의하십시오.
- **Security Check:** 이 변경이 보안 취약점(인증 우회, 데이터 노출 등)을 유발할 가능성이 있는지 점검하십시오.

## 4. Implementation Steps (실행 단계)
- 작업을 **Atomic Unit(최소 실행 단위)**으로 쪼개어 번호를 매기십시오.
- 각 단계는 독립적으로 테스트 가능해야 합니다.
- 예시:
  1. [Backend] API 스키마 정의 및 DB 마이그레이션
  2. [Backend] 서비스 로직 구현 및 단위 테스트
  3. [Frontend] UI 컴포넌트 스캐폴딩
  4. [Integration] 프론트-백엔드 연동

## 5. Artifact Generation
- 위 내용을 담은 `PLAN.md` 아티팩트를 생성하십시오.
- 사용자에게 **"이 계획대로 진행하시겠습니까?"**라고 묻고 승인을 대기하십시오.