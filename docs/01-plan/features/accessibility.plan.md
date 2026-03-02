# FA-006 Accessibility (ARIA) - Plan

> **Feature**: FA-006 Accessibility
> **Phase**: 4 (v0.14)
> **Priority**: P0
> **Difficulty**: ⭐⭐

## 요구사항

### FR-01: ARIA Roles
- 그리드: `role="grid"`, `aria-label`
- 행: `role="row"`, `aria-rowindex`
- 셀: `role="gridcell"`, `aria-colindex`
- 헤더: `role="columnheader"`, `aria-sort`
- 그룹 헤더: `role="row"`, `aria-expanded`

### FR-02: ARIA 상태
- 정렬: `aria-sort="ascending|descending|none"`
- 선택: `aria-selected` 체크박스 행
- 편집: `aria-readonly` 비편집 셀
- 확장/축소: `aria-expanded` (tree, group, detail)

### FR-03: 키보드 접근성 보강
- 기존 keyboard-nav.js에 focus 관리 강화
- `aria-activedescendant` 현재 포커스 셀
- Skip nav: 그리드 앞에 "그리드로 이동" 링크

## 구현 범위
- grid_component.ex: ARIA 속성 추가 (grid, row, cell, header)
- render_helpers.ex: aria 속성 생성 헬퍼
- CSS: focus-visible 스타일 강화

## 테스트
- ARIA role 속성 존재 테스트
- aria-sort 상태 반영 테스트
