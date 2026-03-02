# Localization (i18n)

> **Version**: v0.13
> **Priority**: P1
> **Status**: Plan
> **Feature ID**: FA-021

---

## 목표

그리드 UI 텍스트(필터 placeholder, 버튼, 상태바 등) 다국어 지원.
AG Grid의 Localization에 해당.

## 요구사항

### FR-01: locale 옵션
- `default_options`에 `locale: :ko` 추가
- 지원 언어: :ko, :en, :ja

### FR-02: 번역 맵
- `LiveViewGrid.Locale` 모듈
- 기본 키: filter_placeholder, search_placeholder, no_data, loading, total_rows, selected, page_of 등

### FR-03: 커스텀 번역
- `locale_texts: %{key => text}` 옵션으로 개별 텍스트 오버라이드

## 구현 범위
1. lib/liveview_grid/locale.ex: Locale 모듈 + 번역 맵
2. grid.ex: locale, locale_texts 옵션
3. grid_component.ex, render_helpers.ex: 하드코딩 텍스트를 t/2 헬퍼로 교체
4. 테스트

## 난이도: ⭐⭐
