---
description: Programmatic SEO (pSEO) Protocol
---

# Programmatic SEO (pSEO) 프로토콜 (/growth)

**Trigger:** `/growth`
**Goal:** 롱테일 키워드를 타겟팅한 수천 개의 랜딩 페이지 자동 생성

---

## Step 1: 키워드 전략 설계

```
1. 변수 조합 정의
   예: {SourceLang}, {TargetLang}, {FileFormat}
   
2. 고단가 키워드 식별
   - 법률(Legal), 비즈니스(Business), 금융(Finance) 관련
   - 검색량 높은 조합 우선

3. 키워드 매트릭스 생성
   - 총 조합 수 계산
   - 우선순위 정렬
```

---

## Step 2: 라우팅 구조 설계

```typescript
// Next.js 동적 라우팅
// /translate/[source]-to-[target]/[format]

// generateStaticParams로 빌드 시 정적 생성
export async function generateStaticParams() {
  const languages = ['korean', 'english', 'japanese', ...];
  const formats = ['pdf', 'docx', 'xlsx'];
  
  return languages.flatMap(source =>
    languages
      .filter(target => target !== source)
      .flatMap(target =>
        formats.map(format => ({
          slug: `${source}-to-${target}`,
          format,
        }))
      )
  );
}
```

---

## Step 3: 페이지 템플릿 구현

```
각 페이지에 필수 포함:
- H1: 고유 제목 (키워드 포함)
- Meta description: 고유 설명
- 구조화 데이터 (JSON-LD)
- 내부 링크 (관련 페이지 3-5개)
- CTA 버튼
```

---

## Step 4: SEO 인프라

```
1. 사이트맵 자동 생성 (sitemap.xml)
2. robots.txt 설정
3. OG 이미지 동적 생성
4. 내부 링크 그래프 (고립 페이지 방지)
5. 정규 URL (canonical)
```

---

## Step 5: 성능 최적화

```
Core Web Vitals 기준:
- LCP < 2.5초: SSG + edge caching
- CLS < 0.1: 고정 크기 레이아웃
- FID < 100ms: 최소 JS

이미지: WebP + next/image
폰트: WOFF2 + font-display: swap
```

---

## Step 6: 검증

```
1. Google Search Console에서 인덱싱 확인
2. Lighthouse 점수 확인 (90+ 목표)
3. 내부 링크 크롤링 테스트
4. 모바일 호환성 체크
```

---

**관리자**: @Growth-Hacker
**마지막 업데이트**: 2026-02-13
