# FA-018 Printing - Plan

> **Feature**: FA-018 Printing
> **Phase**: 4 (v0.14)
> **Priority**: P1
> **Difficulty**: ⭐⭐

## 요구사항

### FR-01: Print CSS
- `@media print` 기반 인쇄 최적화 스타일
- 스크롤 해제, 전체 데이터 표시
- 불필요한 UI 숨김 (필터, 버튼, 페이지네이션, 체크박스)
- 테두리/배경색 인쇄 최적화

### FR-02: Print API
- `Grid.print_data/1` — 인쇄용 전체 데이터 (페이징 해제)
- `enable_print: false` 기본 옵션

### FR-03: Print 버튼
- Status bar 또는 헤더에 인쇄 버튼
- `window.print()` 호출

## 구현 범위
- grid.ex: `print_data/1` API, `enable_print` option
- CSS: `@media print` 섹션 (grid/print.css)
- grid_component.ex: 인쇄 버튼 렌더링

## 테스트
- print_data API 테스트 (전체 데이터 반환)
- enable_print 옵션 테스트
