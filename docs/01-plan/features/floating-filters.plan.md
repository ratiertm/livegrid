# Floating Filters (인라인 상시 필터)

> **Version**: v0.12
> **Priority**: P1
> **Status**: Plan
> **Feature ID**: FA-011

---

## 목표

헤더 아래에 항상 표시되는 인라인 필터 입력 행.
기존 toggle filter row와 달리 `floating_filter: true` 옵션 시 항상 표시.
AG Grid의 Floating Filters에 해당.

## 요구사항

### FR-01: floating_filter 옵션
- `default_options`에 `floating_filter: false` 추가
- true 시 필터 행이 항상 표시 (토글 불필요)

### FR-02: 컬럼별 floating_filter
- 컬럼 정의에 `floating_filter: true/false` 개별 설정 가능
- grid 옵션이 true여도 컬럼에서 false면 비활성

### FR-03: 기존 필터 행과 공존
- floating_filter는 show_filter_row 토글과 독립
- 두 가지 모두 활성화 가능 (하지만 floating이 있으면 toggle 숨김 권장)

## 구현 범위
1. grid.ex: default_options에 floating_filter, normalize_columns에 floating_filter
2. grid_component.ex: Header 아래 Floating Filter Row 렌더링
3. CSS: .lv-grid__floating-filter-row
4. demo_live.ex: 옵션 활성화
5. 테스트

## 난이도: ⭐⭐
