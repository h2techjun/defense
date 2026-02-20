---
name: Security Automation
description: 보안 취약점 자동 스캔 및 RLS 정책 검증
version: 1.0.0
---

# 🛡️ Security Automation Skill

## 목적

코드베이스를 **자동으로 스캔**하여 보안 취약점을 조기에 발견하고, Supabase RLS 정책의 무결성을 검증합니다.

## 1. 비밀 스캔 (Secret Scanning)

### 스캔 대상 패턴

```typescript
const SECRET_PATTERNS = {
  // API 키
  gemini: /AIza[0-9A-Za-z\\-_]{35}/g,
  openai: /sk-[a-zA-Z0-9]{48}/g,
  supabase_key: /eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*/g,

  // 데이터베이스
  postgres_url: /postgres:\/\/[^\s]+/g,

  // 일반 비밀
  private_key: /-----BEGIN (RSA |EC |)PRIVATE KEY-----/g,
  aws_key: /(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}/g,

  // 토큰
  github_token: /gh[pousr]_[A-Za-z0-9_]{36,255}/g,
  slack_token: /xox[baprs]-([0-9a-zA-Z]{10,48})/g,
};
```

### 스캔 스크립트

```python
#!/usr/bin/env python3
"""
Security Scanner - 하드코딩된 비밀 탐지
"""

import re
import os
from pathlib import Path
from typing import List, Tuple

# 제외 경로
EXCLUDED_PATHS = [
    'node_modules',
    '.git',
    '.next',
    'dist',
    'build',
    '.agent/skills'  # 스킬 문서는 예외
]

# 제외 파일
EXCLUDED_FILES = [
    '.env.example',
    'package-lock.json',
    'pnpm-lock.yaml'
]

PATTERNS = {
    'Gemini API Key': r'AIza[0-9A-Za-z\\-_]{35}',
    'OpenAI API Key': r'sk-[a-zA-Z0-9]{48}',
    'Supabase JWT': r'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*',
    'PostgreSQL URL': r'postgres:\/\/[^\s]+',
    'Private Key': r'-----BEGIN (RSA |EC |)PRIVATE KEY-----',
}

def scan_file(file_path: Path) -> List[Tuple[str, int, str]]:
    """파일 스캔하여 비밀 찾기"""
    findings = []

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                for pattern_name, pattern in PATTERNS.items():
                    if re.search(pattern, line):
                        findings.append((pattern_name, line_num, line.strip()))
    except:
        pass  # 바이너리 파일 등 무시

    return findings

def scan_directory(root_dir: str) -> dict:
    """디렉토리 전체 스캔"""
    results = {}

    for root, dirs, files in os.walk(root_dir):
        # 제외 디렉토리 스킵
        dirs[:] = [d for d in dirs if d not in EXCLUDED_PATHS]

        for file in files:
            # 제외 파일 스킵
            if file in EXCLUDED_FILES:
                continue

            file_path = Path(root) / file
            findings = scan_file(file_path)

            if findings:
                results[str(file_path)] = findings

    return results

def generate_report(results: dict) -> str:
    """리포트 생성"""
    if not results:
        return "✅ 하드코딩된 비밀이 발견되지 않았습니다."

    report = "🚨 보안 위험 발견!\n\n"

    for file_path, findings in results.items():
        report += f"**{file_path}**\n"
        for pattern_name, line_num, line in findings:
            report += f"  - Line {line_num}: {pattern_name}\n"
            report += f"    `{line[:80]}...`\n"
        report += "\n"

    return report

if __name__ == '__main__':
    import sys
    root = sys.argv[1] if len(sys.argv) > 1 else '.'

    print("🔍 보안 스캔 시작...")
    results = scan_directory(root)
    print(generate_report(results))

    # 비밀 발견 시 exit code 1
    sys.exit(1 if results else 0)
```

### Git Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "🔍 보안 스캔 실행 중..."
python .agent/skills/security-automation/scan_secrets.py

if [ $? -ne 0 ]; then
  echo "❌ 하드코딩된 비밀이 발견되었습니다!"
  echo "   커밋을 중단합니다."
  exit 1
fi

echo "✅ 보안 스캔 통과"
```

## 2. RLS 정책 검증

### 필수 RLS 체크

```sql
-- 모든 테이블이 RLS 활성화되어 있는지 확인
SELECT
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false;
-- 결과가 있으면 RLS 비활성화된 테이블 존재

-- 각 테이블의 정책 확인
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'public';
```

### 검증 스크립트

```python
#!/usr/bin/env python3
"""
RLS Policy Validator
"""

from supabase import create_client
import os

SUPABASE_URL = os.getenv('NEXT_PUBLIC_SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')  # 서비스 키 필요

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def check_rls_enabled():
    """모든 테이블의 RLS 활성화 여부 확인"""
    result = supabase.rpc('check_rls_status').execute()

    disabled_tables = [
        row['tablename']
        for row in result.data
        if not row['rowsecurity']
    ]

    if disabled_tables:
        print(f"🚨 RLS 비활성화 테이블: {', '.join(disabled_tables)}")
        return False

    print("✅ 모든 테이블에 RLS 활성화됨")
    return True

def check_missing_policies():
    """정책이 없는 테이블 확인"""
    tables = supabase.rpc('list_public_tables').execute()
    policies = supabase.rpc('list_policies').execute()

    policy_dict = {}
    for policy in policies.data:
        table = policy['tablename']
        if table not in policy_dict:
            policy_dict[table] = []
        policy_dict[table].append(policy)

    missing = []
    for table in tables.data:
        table_name = table['tablename']
        if table_name not in policy_dict:
            missing.append(table_name)

    if missing:
        print(f"⚠️ 정책 없는 테이블: {', '.join(missing)}")
        return False

    print("✅ 모든 테이블에 정책 존재")
    return True

def validate_user_isolation():
    """사용자 격리 정책 검증"""
    # auth.uid() 사용하는 정책인지 확인
    policies = supabase.rpc('list_policies').execute()

    weak_policies = []
    for policy in policies.data:
        qual = policy.get('qual', '')
        if 'auth.uid()' not in qual:
            weak_policies.append({
                'table': policy['tablename'],
                'policy': policy['policyname']
            })

    if weak_policies:
        print("⚠️ 사용자 격리 확인 필요:")
        for wp in weak_policies:
            print(f"  - {wp['table']}.{wp['policy']}")
        return False

    print("✅ 모든 정책에 사용자 격리 적용됨")
    return True

if __name__ == '__main__':
    print("🛡️ RLS 정책 검증 시작\n")

    rls_ok = check_rls_enabled()
    policies_ok = check_missing_policies()
    isolation_ok = validate_user_isolation()

    if rls_ok and policies_ok and isolation_ok:
        print("\n✅ 모든 보안 검증 통과!")
        exit(0)
    else:
        print("\n❌ 보안 검증 실패!")
        exit(1)
```

## 3. 종속성 취약점 스캔

### npm audit 자동화

```bash
#!/bin/bash
# .agent/skills/security-automation/check_dependencies.sh

echo "🔍 종속성 취약점 스캔..."

# npm audit 실행
audit_output=$(npm audit --json)

# Critical/High 취약점만 추출
critical=$(echo "$audit_output" | jq '.metadata.vulnerabilities.critical')
high=$(echo "$audit_output" | jq '.metadata.vulnerabilities.high')

if [ "$critical" -gt 0 ] || [ "$high" -gt 0 ]; then
  echo "🚨 Critical: $critical, High: $high 취약점 발견!"
  npm audit
  exit 1
fi

echo "✅ 취약점 없음"
```

### GitHub Action 통합

```yaml
# .github/workflows/security.yml
name: Security Scan

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: "0 0 * * 1" # 매주 월요일

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: 비밀 스캔
        run: |
          python .agent/skills/security-automation/scan_secrets.py

      - name: 종속성 취약점 스캔
        run: |
          npm ci
          npm audit --audit-level=high

      - name: RLS 정책 검증
        env:
          NEXT_PUBLIC_SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_KEY }}
        run: |
          python .agent/skills/security-automation/validate_rls.py
```

## 4. OWASP Top 10 체크리스트

### 자동 체크

```typescript
// 보안 헤더 검증
export function checkSecurityHeaders(response: Response) {
  const requiredHeaders = {
    "X-Frame-Options": "DENY",
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "geolocation=(), microphone=(), camera=()",
  };

  const missing = Object.entries(requiredHeaders).filter(
    ([header, value]) => response.headers.get(header) !== value,
  );

  if (missing.length > 0) {
    console.warn("⚠️ 누락된 보안 헤더:", missing);
  }
}

// SQL Injection 방지 확인
export function validateQuery(query: string) {
  // 직접 쿼리 금지 (ORM만 사용)
  if (query.includes("SELECT") || query.includes("INSERT")) {
    throw new Error("❌ 직접 SQL 쿼리 금지! Supabase 클라이언트를 사용하세요.");
  }
}

// XSS 방지
export function sanitizeInput(input: string) {
  return input
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#x27;");
}
```

## 5. 통합 보안 리포트

### 일일 리포트

```markdown
# 보안 스캔 리포트 - 2026-02-07

## 📊 요약

- **비밀 스캔**: ✅ 통과
- **RLS 정책**: ✅ 모든 테이블 활성화
- **종속성**: ⚠️ 1개 High 취약점

## 🔍 상세 결과

### 비밀 스캔

- 스캔 파일 수: 234
- 발견 건수: 0

### RLS 정책

- RLS 활성화 테이블: 12/12
- 정책 있는 테이블: 12/12
- 사용자 격리 적용: 12/12

### 종속성 취약점

**High (1건)**:

- `next@14.0.3` → `14.0.4` (XSS 취약점 수정)
  - 권장: `npm install next@latest`

## 📋 액션 아이템

1. Next.js 업데이트 (High 우선순위)
2. 다음 스캔: 2026-02-08 00:00
```

---

**실행 스케줄**:

- **비밀 스캔**: 매 커밋 시 (pre-commit hook)
- **RLS 검증**: 매일 00:00 (cron)
- **종속성 스캔**: 매주 월요일 (GitHub Action)
- **통합 리포트**: 매일 아침 9시 (Slack 알림)
