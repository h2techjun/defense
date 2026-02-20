---
description: Autonomous Agent Hiring Protocol
---

# Autonomous Agent Hiring Protocol

**Trigger:** `/hire`
**Description:** 특정 작업에 특화된 새로운 에이전트 페르소나를 정의하고 생성함.

## 1. Role Definition (정의)

- **Need Analysis:** 현재 팀에 부족한 역량이 무엇인지 분석하십시오. (예: "Three.js 3D 렌더링 전문가 필요")
- **Persona Design:**
  - **Role Name:** 직관적인 영어 이름 (예: `threejs-expert`)
  - **Responsibility:** 구체적으로 어떤 파일과 작업을 담당할지 정의.
  - **Lane (Constraints):** 건드리지 말아야 할 파일이나 영역 설정.

## 2. File Generation (생성)

- `.agent/personas/<agent-name>.md` 파일을 생성하십시오.
- **Template Compliance:** 아래 표준 템플릿을 반드시 준수해야 합니다.

  ```markdown
  # Role: <Display Name>
  **파일:** `.agent/personas/<agent-name>.md`
  
  당신은 <Project Name>의 <Role Description>입니다.
  - **Mission:** <구체적인 목표>
  - **Responsibility:**
    1. <담당 업무 1>
    2. <담당 업무 2>
  - **Lane (Permissions):**
    - Read/Write: <수정 가능한 폴더 경로>
    - Read-Only: <참조만 가능한 경로>
  - **Strict Rule:** 검증 게이트를 통과하지 못한 코드는 커밋하지 마십시오.
