---
description: Adaptive Tooling & Assetization Workflow
---

# 🛠️ Adaptive Tooling & Assetization Workflow
**Trigger:** `/toolup`
**Goal:** 반복 작업을 자동화하는 스킬(Skill)을 생성하고, 이를 프로젝트 또는 전역 라이브러리에 등록하여 자산화합니다.

## 1. 🧠 Bottleneck Identification & Scope Analysis
- **Task Analysis:** 현재 반복되는 작업이 무엇인지 정의합니다. (예: "DB 스키마 변경 시 마이그레이션 파일 자동 생성")
- **Scope Decision (중요):** 이 도구의 범위를 결정하고 사용자에게 확인받습니다.
  - **[Local]:** `.agent/skills/` (현재 프로젝트의 비즈니스 로직 전용)
  - **[Global]:** `~/.gemini/antigravity/skills/` (모든 프로젝트에서 사용 가능한 범용 도구 - 예: Git 포매터, JSON 변환기) [1]

## 2. 📂 Scaffold Skill Directory
- 선택된 Scope 경로 하위에 `<skill-kebab-case-name>` 폴더를 생성합니다.
- 표준 구조를 생성합니다 [2]:
  - `skills/<name>/SKILL.md` (메타데이터 및 지침)
  - `skills/<name>/scripts/` (실행 스크립트 저장소)

## 3. 📝 Implement Execution Script
- `scripts/` 폴더 내에 Python, Bash, 또는 Node.js 스크립트를 작성합니다.
- **멱등성(Idempotency):** 스크립트는 여러 번 실행해도 시스템을 망가뜨리지 않도록 안전하게 작성되어야 합니다.
- 필요한 의존성(Dependency)이 있다면 스크립트 상단 주석에 명시하거나 `requirements.txt`를 함께 생성합니다.

## 4. 🧠 Generate SKILL.md (The Brain)
- 에이전트가 이 스킬을 언제, 어떻게 사용해야 하는지 정의하는 `SKILL.md`를 생성합니다 [3].
- **필수 포함 항목:**
  - **YAML Frontmatter:** `name`과 `description`을 정확히 작성해야 에이전트가 의도를 파악하고 스킬을 로드합니다.
  - **Instructions:** 스크립트 실행 명령어와 파라미터 설명을 작성합니다.

## 5. 🔗 Auto-Registration & Verification
- **권한 부여:** 생성된 스크립트에 실행 권한(`chmod +x`)을 부여합니다.
- **테스트 실행:** 에이전트에게 방금 만든 스킬을 바로 실행해보라고 지시하여(`Run this skill now`), `SKILL.md`가 제대로 연결되었는지 검증합니다.
- **문서화:** 생성된 스킬의 목적과 사용법을 `docs/TOOLS.md` 또는 프로젝트 README에 간단히 기록합니다.

#### **G. `sync.md` (프로젝트 자동 설정)**
```markdown
# Project Auto-Configuration Sync
**Trigger:** `/sync`
**Goal:** 프로젝트의 상태를 분석하여 `.agent` 설정을 자동 생성 및 현행화

1. **Scan & Detection:**
   - 프로젝트 루트의 파일(`package.json`, `requirements.txt`)을 스캔하여 기술 스택을 파악하십시오.

2. **Auto-Generation:**
   - 감지된 스택에 맞는 **규칙(Rules)**을 `.agent/rules/`에 생성하십시오.
   - 필요한 **워크플로우(Workflows)**를 `.agent/workflows/`에 복사하십시오.
   - 최적의 **에이전트 페르소나(Personas)**를 `.agent/personas.md`에 정의하십시오.

3. **Report:**
   - 생성되거나 업데이트된 설정 파일 목록을 요약 보고하십시오.
