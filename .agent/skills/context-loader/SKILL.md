---
name: Context Auto-Loader
description: 사용자 요청 유형을 분석하여 필요한 규칙/페르소나 파일을 자동으로 로드
version: 1.0.0
---

# 🧠 Context Auto-Loader Skill

## 목적

사용자 요청을 분석하여 **필요한 파일만 선택적으로 로드**함으로써 응답 속도를 향상시킵니다.

## 작동 방식

### Step 1: 요청 분류

사용자 요청에서 키워드를 추출하여 카테고리 분류:

```typescript
const REQUEST_PATTERNS = {
  coding: ["코드", "구현", "함수", "클래스", "버그", "에러"],
  security: ["보안", "인증", "권한", "RLS", "비밀번호", "API 키"],
  feature: ["기능", "추가", "새로운", "개발"],
  debug: ["디버그", "오류", "작동 안", "문제"],
  ui: ["UI", "UX", "디자인", "스타일", "레이아웃"],
  deploy: ["배포", "deploy", "production", "vercel"],
  payment: ["결제", "수익", "stripe", "가격"],
  documentation: ["문서", "README", "가이드", "설명"],
};
```

### Step 2: 파일 매핑

각 카테고리별 필수 로드 파일:

#### 코딩/구현 작업

```json
{
  "required": [
    ".agent/rules/CODING_STANDARDS.md",
    ".agent/rules/TECH_STACK.md"
  ],
  "personas": [
    ".agent/personas/@The-Builder.md",
    ".agent/personas/@Architect.md"
  ],
  "optional": [".agent/rules/ANTI_PATTERNS.md"]
}
```

#### 보안/인증 작업

```json
{
  "required": [
    ".agent/personas/@The-Guardian.md",
    ".agent/rules/TECH_STACK.md"
  ],
  "workflows": [".agent/workflows/security.md"]
}
```

#### 새 기능 개발

```json
{
  "required": [".agent/workflows/feature.md"],
  "personas": [
    "@Architect",
    "@Designer",
    "@The-Builder",
    "@Tester",
    "@The-Reviewer"
  ]
}
```

#### 버그 디버깅

```json
{
  "required": [".agent/workflows/debug.md"],
  "personas": ["@The-Nerd", "@The-Builder", "@Tester"]
}
```

#### UI/UX 작업

```json
{
  "required": [".agent/personas/@Designer.md"],
  "optional": [".agent/rules/CODING_STANDARDS.md"]
}
```

#### 배포

```json
{
  "required": [".agent/workflows/deploy.md", ".agent/personas/@The-Guardian.md"]
}
```

#### 결제/수익화

```json
{
  "required": [
    ".agent/personas/@Revenue-Ops.md",
    ".agent/personas/@The-Guardian.md"
  ]
}
```

#### 문서 작업

```json
{
  "required": [".agent/personas/@Librarian.md"],
  "workflows": [".agent/workflows/doc-update.md"]
}
```

### Step 3: 스마트 캐싱

이미 로드된 파일은 재로드하지 않음:

```typescript
const loadedFiles = new Set<string>();

function loadContextFiles(category: string) {
  const filesToLoad = getFilesForCategory(category);

  const newFiles = filesToLoad.filter((file) => !loadedFiles.has(file));

  // 새 파일만 로드
  for (const file of newFiles) {
    view_file(file);
    loadedFiles.add(file);
  }
}
```

## 사용 예시

### 예시 1: 코딩 요청

```
사용자: "로그인 기능 구현해줘"

자동 로드:
✓ CODING_STANDARDS.md
✓ TECH_STACK.md
✓ @The-Builder.md
✓ @Architect.md
```

### 예시 2: 보안 이슈

```
사용자: "API 키가 노출됐어"

자동 로드:
✓ @The-Guardian.md
✓ security.md
✓ TECH_STACK.md (Supabase 환경 변수 섹션)
```

### 예시 3: 복합 요청

```
사용자: "회원가입 UI 만들고 DB 연결해줘"

자동 로드:
✓ @Designer.md (UI)
✓ @Architect.md (DB 설계)
✓ @The-Builder.md (구현)
✓ TECH_STACK.md (Next.js + Supabase)
✓ @The-Guardian.md (인증 보안)
```

## 최적화 전략

### 1. 우선순위 로딩

중요도 순으로 로드:

1. **필수 (Required)** - 즉시 로드
2. **권장 (Recommended)** - 작업 시작 시 로드
3. **선택 (Optional)** - 필요시만 로드

### 2. 병렬 로드

여러 파일을 병렬로 로드하여 속도 향상:

```typescript
await Promise.all([
  view_file(".agent/personas/@Builder.md"),
  view_file(".agent/rules/CODING_STANDARDS.md"),
  view_file(".agent/rules/TECH_STACK.md"),
]);
```

### 3. 증분 로드

대화가 진행되면서 추가 파일 로드:

```
초기: 최소 파일만 로드
↓
사용자 추가 질문 시: 관련 파일 추가 로드
↓
복잡도 증가 시: 전문가 페르소나 추가 로드
```

## 성능 측정

### 목표

- 초기 로드 시간: **< 2초**
- 추가 파일 로드: **< 500ms**
- 캐시 적중률: **> 70%**

### 모니터링

```typescript
const metrics = {
  totalLoads: 0,
  cacheHits: 0,
  averageLoadTime: 0,
};

function trackLoad(file: string, cached: boolean, time: number) {
  metrics.totalLoads++;
  if (cached) metrics.cacheHits++;
  metrics.averageLoadTime =
    (metrics.averageLoadTime * (metrics.totalLoads - 1) + time) /
    metrics.totalLoads;
}
```

## 에러 처리

### 파일 없음

```typescript
try {
  await view_file(filePath);
} catch (error) {
  console.warn(`Optional file not found: ${filePath}`);
  // 선택 파일이면 무시, 필수 파일이면 경고
}
```

### 타임아웃

```typescript
const loadWithTimeout = (file: string, timeout = 3000) => {
  return Promise.race([
    view_file(file),
    new Promise((_, reject) => setTimeout(() => reject("Timeout"), timeout)),
  ]);
};
```

## 향후 개선

1. **ML 기반 예측**: 사용자 패턴 학습하여 미리 로드
2. **컨텍스트 압축**: 필요한 섹션만 추출
3. **동적 우선순위**: 사용 빈도에 따라 우선순위 자동 조정

---

**실행 방법**: JARVIS가 매 대화 시작 시 자동 실행
