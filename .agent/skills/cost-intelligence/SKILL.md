---
name: Cost Intelligence Dashboard
description: API 사용량 및 비용을 추적하고 최적화 제안 생성
version: 1.0.0
scope: project-specific
---

# 💰 Cost Intelligence Dashboard Skill

## 목적

프로젝트의 **API 비용을 실시간으로 추적**하고, 예산 초과 전에 경고하며, 최적화 방안을 자동으로 제안합니다.

## 추적 대상

### 1. Gemini API

- **모델**: gemini-2.0-flash-exp
- **가격**:
  - Input: $0.075 / 1M tokens (128K 이하)
  - Output: $0.30 / 1M tokens
- **월간 예산**: $100 (설정 가능)

### 2. Supabase

- **Storage**: 1GB 무료, 초과 시 $0.021/GB
- **Database**: 500MB 무료, 초과 시 $0.125/GB
- **Bandwidth**: 5GB 무료, 초과 시 $0.09/GB

### 3. Vercel

- **Functions**: 100GB-hour 무료
- **Bandwidth**: 100GB 무료
- **Deployments**: 100회 무료

## 데이터 수집

### 방법 1: Usage Logs (권장)

```sql
-- Supabase에 사용량 로그 테이블 생성
CREATE TABLE usage_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id),
  service TEXT NOT NULL, -- 'gemini', 'supabase', 'vercel'
  action TEXT NOT NULL, -- 'translation', 'upload', 'download'
  tokens_used INTEGER,
  cost_usd DECIMAL(10, 4),
  metadata JSONB
);

-- RLS 정책
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own usage"
  ON usage_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Service can insert usage"
  ON usage_logs FOR INSERT
  WITH CHECK (true); -- API 키로 보호
```

### 방법 2: API 래퍼

```typescript
// lib/gemini-with-tracking.ts
import { GoogleGenerativeAI } from "@google/generative-ai";
import { createClient } from "@/lib/supabase/server";

export async function trackGeminiUsage(
  inputTokens: number,
  outputTokens: number,
  userId: string,
) {
  const inputCost = (inputTokens / 1_000_000) * 0.075;
  const outputCost = (outputTokens / 1_000_000) * 0.3;
  const totalCost = inputCost + outputCost;

  const supabase = createClient();
  await supabase.from("usage_logs").insert({
    user_id: userId,
    service: "gemini",
    action: "translation",
    tokens_used: inputTokens + outputTokens,
    cost_usd: totalCost,
    metadata: {
      input_tokens: inputTokens,
      output_tokens: outputTokens,
      model: "gemini-2.0-flash-exp",
    },
  });

  return totalCost;
}

// 사용 예시
export async function translateWithTracking(text: string, userId: string) {
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);
  const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-exp" });

  const result = await model.generateContent(text);
  const response = result.response;

  // 사용량 추적
  await trackGeminiUsage(
    response.usageMetadata.promptTokenCount,
    response.usageMetadata.candidatesTokenCount,
    userId,
  );

  return response.text();
}
```

## 대시보드 구성

### 1. 월간 비용 현황

```typescript
// app/api/admin/cost-dashboard/route.ts
export async function GET() {
  const supabase = createClient();

  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);

  const { data: monthlyCost } = await supabase
    .from("usage_logs")
    .select("service, cost_usd")
    .gte("created_at", startOfMonth.toISOString());

  const costByService = monthlyCost.reduce((acc, log) => {
    acc[log.service] = (acc[log.service] || 0) + log.cost_usd;
    return acc;
  }, {});

  return Response.json({
    month: startOfMonth.toISOString(),
    total: Object.values(costByService).reduce((a, b) => a + b, 0),
    byService: costByService,
    budget: 100,
    percentUsed:
      (Object.values(costByService).reduce((a, b) => a + b, 0) / 100) * 100,
  });
}
```

### 2. 실시간 경고

```typescript
// lib/cost-alerts.ts
const THRESHOLDS = {
  warning: 0.8, // 80%
  critical: 0.95, // 95%
};

export async function checkBudget() {
  const { total, budget } = await getMonthlyCost();
  const percentUsed = total / budget;

  if (percentUsed >= THRESHOLDS.critical) {
    await sendAlert({
      level: "critical",
      message: `🚨 비용 초과 임박! ${(percentUsed * 100).toFixed(1)}% 사용`,
      action: "즉시 최적화 필요",
    });
  } else if (percentUsed >= THRESHOLDS.warning) {
    await sendAlert({
      level: "warning",
      message: `⚠️ 예산의 ${(percentUsed * 100).toFixed(1)}% 사용 중`,
      action: "최적화 검토 권장",
    });
  }
}
```

### 3. 사용 패턴 분석

```sql
-- 가장 비용이 많이 드는 사용자
SELECT
  user_id,
  SUM(cost_usd) as total_cost,
  COUNT(*) as request_count,
  AVG(tokens_used) as avg_tokens
FROM usage_logs
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY user_id
ORDER BY total_cost DESC
LIMIT 10;

-- 시간대별 사용 패턴
SELECT
  EXTRACT(HOUR FROM created_at) as hour,
  SUM(cost_usd) as cost,
  COUNT(*) as requests
FROM usage_logs
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY hour
ORDER BY hour;

-- 서비스별 비용 추이
SELECT
  DATE_TRUNC('day', created_at) as date,
  service,
  SUM(cost_usd) as daily_cost
FROM usage_logs
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY date, service
ORDER BY date, service;
```

## 최적화 제안 엔진

### 자동 제안 생성

```typescript
interface OptimizationSuggestion {
  title: string;
  description: string;
  potentialSaving: number; // USD
  difficulty: "easy" | "medium" | "hard";
  impact: "low" | "medium" | "high";
}

export async function generateOptimizations(): Promise<
  OptimizationSuggestion[]
> {
  const usage = await analyzeUsagePatterns();
  const suggestions: OptimizationSuggestion[] = [];

  // 제안 1: 캐싱
  if (usage.duplicateRequests > 0.3) {
    suggestions.push({
      title: "번역 결과 캐싱",
      description: `동일한 텍스트가 ${(usage.duplicateRequests * 100).toFixed(0)}% 반복됩니다. Redis 캐싱으로 비용 절감 가능.`,
      potentialSaving: usage.monthlyCost * usage.duplicateRequests,
      difficulty: "medium",
      impact: "high",
    });
  }

  // 제안 2: 배치 처리
  if (usage.avgRequestSize < 1000) {
    suggestions.push({
      title: "배치 처리 도입",
      description: "작은 요청들을 묶어서 처리하면 오버헤드 감소.",
      potentialSaving: usage.monthlyCost * 0.15,
      difficulty: "hard",
      impact: "medium",
    });
  }

  // 제안 3: 프롬프트 최적화
  if (usage.avgTokensPerRequest > 10000) {
    suggestions.push({
      title: "프롬프트 최적화",
      description: "불필요한 컨텍스트 제거로 토큰 수 감소.",
      potentialSaving: usage.monthlyCost * 0.2,
      difficulty: "easy",
      impact: "medium",
    });
  }

  // 제안 4: 모델 다운그레이드
  if (usage.taskComplexity === "low") {
    suggestions.push({
      title: "간단한 작업은 gemini-1.5-flash 사용",
      description: "복잡도 낮은 작업에 저렴한 모델 사용 (50% 비용 절감).",
      potentialSaving: usage.monthlyCost * 0.5,
      difficulty: "medium",
      impact: "high",
    });
  }

  return suggestions.sort((a, b) => b.potentialSaving - a.potentialSaving);
}
```

## 리포트 생성

### 월간 리포트

```markdown
# 2026년 2월 비용 리포트

## 📊 요약

- **총 비용**: $87.42 / $100 (예산의 87.4%)
- **전월 대비**: +23% 증가
- **예상 월말 비용**: $95.20

## 서비스별 분석

### Gemini API ($72.50)

- 번역 요청: 1,245건
- 평균 토큰: 8,523 tokens/request
- 가장 비싼 사용자: user_abc123 ($15.20)

### Supabase ($10.12)

- Storage: 2.3GB ($0.02)
- Database: 650MB ($0.10)
- Bandwidth: 12GB ($10.00)

### Vercel ($4.80)

- Functions: 45GB-hour
- Deployments: 23회

## 🎯 최적화 제안

1. **번역 결과 캐싱** [높은 영향]
   - 예상 절감: $21.75/월
   - 중복 요청 30% 감소

2. **배치 처리 도입** [중간 영향]
   - 예상 절감: $10.88/월
   - API 오버헤드 감소

3. **프롬프트 최적화** [중간 영향]
   - 예상 절감: $14.50/월
   - 불필요한 토큰 20% 제거

## 📈 다음 달 예산 권장

- 현재 추세 유지: $110
- 최적화 적용 시: $80
```

### Slack/Discord 알림

```typescript
// lib/cost-notifications.ts
export async function sendDailyCostUpdate() {
  const today = await getDailyCost();
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;

  if (today > 10) {
    // $10 초과 시 알림
    await fetch(webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        text: `💰 오늘 비용: $${today.toFixed(2)} (높음!)`,
        attachments: [
          {
            color: "warning",
            text: "최적화 검토가 필요합니다.",
          },
        ],
      }),
    });
  }
}
```

## Cron Job 설정

### Vercel Cron

```typescript
// app/api/cron/cost-check/route.ts
export async function GET(request: Request) {
  // Vercel Cron 인증
  const authHeader = request.headers.get("authorization");
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }

  // 비용 체크 및 알림
  await checkBudget();
  await sendDailyCostUpdate();

  return Response.json({ success: true });
}
```

### vercel.json

```json
{
  "crons": [
    {
      "path": "/api/cron/cost-check",
      "schedule": "0 9 * * *"
    }
  ]
}
```

---

**실행 방법**:

1. `usage_logs` 테이블 생성
2. API 래퍼로 모든 Gemini 호출 감싸기
3. Cron job 설정하여 매일 아침 9시 체크
4. 대시보드 UI에서 실시간 모니터링
