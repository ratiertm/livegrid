# FA-021 Localization (i18n) - Gap Analysis

> **Feature**: FA-021 Localization (i18n)
> **Date**: 2026-03-01
> **Match Rate**: 91%

## 요구사항 매칭

| # | 요구사항 | 구현 | 상태 |
|---|---------|------|------|
| FR-01 | locale 옵션 | default_options에 locale: :ko, 지원 언어: :ko, :en, :ja | ✅ |
| FR-02 | 번역 맵 | LiveViewGrid.Locale 모듈, 25+ 키, 3개 언어 | ✅ |
| FR-03 | 커스텀 번역 | locale_texts 옵션으로 개별 텍스트 오버라이드 | ✅ |

## 코드 검증

| 항목 | 결과 |
|------|------|
| Locale.t/3 함수 | ✅ key, locale, overrides 지원 |
| grid_t/2 헬퍼 | ✅ grid 옵션에서 locale/locale_texts 자동 추출 |
| 한국어 기본값 | ✅ 25개 키 번역 |
| 영어 번역 | ✅ 25개 키 번역 |
| 일본어 번역 | ✅ 25개 키 번역 |

## Match Rate: 91%
- -5%: grid_component.ex 내 하드코딩 텍스트를 grid_t() 호출로 실제 교체 미완료 (헬퍼만 준비)
- -4%: 날짜/숫자 포맷 로케일 미지원 (번역 텍스트만)
