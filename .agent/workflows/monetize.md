---
description: Monetization Implementation Protocol
---

# Monetization Implementation Protocol
**Trigger:** `/monetize`
**Goal:** 광고, 결제, 포인트 시스템을 구현하여 앱의 수익성을 확보

## 1. Context Analysis (사용자 등급 확인)
- 이 기능이 Free, Pay-per-use, Subroscription 중 어디에 영향을 미치는지 정의하십시오.
- **Database Check:** `users` 테이블의 `credit_balance`, `subscription_tier` 컬럼과 연동되는지 확인하십시오.

## 2. Ad Integration (광고 구현 시)
- **Rewarded Ads:** 보상형 광고라면, `onRewardEarned` 콜백 이벤트가 서버 측에서 안전하게 검증된 후 포인트를 지급하도록 설계하십시오. (클라이언트 조작 방지)
- **Display Ads:** 로딩 컴포넌트(`Spinner`)나 결과 페이지 하단에 배치하십시오. Layout Shift(CLS)를 방지하기 위해 고정 높이를 할당하십시오.

## 3. Payment Integration (결제 구현 시)
- **Routing:** 사용자의 IP/Locale을 감지하여 한국(Toss) vs 글로벌(Stripe) 결제 모듈을 분기하십시오.
- **Webhooks:** 결제 완료 신호를 처리할 Webhook Endpoint의 멱등성(Idempotency)을 보장하십시오.

## 4. Verification
- 샌드박스(테스트) 모드에서 결제 및 광고 로드가 정상 작동하는지 검증하십시오.