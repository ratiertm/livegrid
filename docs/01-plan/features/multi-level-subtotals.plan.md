# F-963 다단계 소계 - Plan

> **Feature**: F-963 Multi-Level Subtotals
> **Phase**: 4 (v0.14)
> **Priority**: P1
> **Difficulty**: ⭐⭐

## 요구사항

### FR-01: 그룹 레벨별 소계 행
- 각 그룹 하단에 소계 행 삽입
- `_row_type: :subtotal` 마커
- 레벨별 독립 집계 (sum, avg, count, min, max)

### FR-02: 소계 설정
- `show_subtotals: false` 기본 옵션
- `subtotal_position: :bottom` (bottom/top)
- 기존 group_aggregates 설정 활용

### FR-03: 소계 렌더링
- `.lv-grid__subtotal-row` CSS 클래스
- 그룹 필드명 + "소계" 라벨
- 집계 값 포맷팅 (formatter 적용)

## 구현 범위
- grouping.ex: 소계 행 삽입 로직 (`insert_subtotals/3`)
- grid.ex: `show_subtotals`, `subtotal_position` 옵션
- grid_component.ex: subtotal row 렌더링
- render_helpers.ex: subtotal 행 포맷 헬퍼
- CSS: `.lv-grid__subtotal-row` 스타일

## 테스트
- 단일/다중 그룹 소계 행 테스트
- subtotal_position top/bottom 테스트
