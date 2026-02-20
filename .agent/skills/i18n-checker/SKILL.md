# 🌐 i18n-checker Skill
> `src/lib/i18n/dictionaries.ts` 파일의 다국어 키 일관성을 검사하고 누락된 번역을 찾아냅니다.

## 🎯 Purpose
- 20개 이상의 로케일이 포함된 거대 딕셔너리 파일에서 특정 로케일에만 누락된 키(Key)를 자동으로 식별합니다.
- 빌드 전 타입 에러를 예방하고 모든 언어에서 동일한 UX를 보장합니다.

## 🛠️ Components
- **Script**: `scripts/check-i18n.js` (다국어 구조 분석기)
- **Logic**: 기준이 되는 로케일('ko')의 키 구조를 추출하여 다른 모든 로케일과 비교합니다.

## 🚀 How to Use
에이전트에게 다음과 같이 요청하십시오:
- "i18n 누락된 거 있는지 확인해줘"
- "i18n-checker 실행해줘"

## 📝 Example Output
```text
[i18n-checker] 분석 시작...
- Base Locale: ko
- Target Locales: 20
- Missing Keys in 'es': nav.proAccount, auth.guestLogin
- Missing Keys in 'fr': pricingRule.extra
결과: 3개의 누락된 키가 발견되었습니다.
```
