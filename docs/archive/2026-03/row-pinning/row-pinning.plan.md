# FA-001 Row Pinning

> **Feature ID**: FA-001
> **Version**: v0.12.0
> **Priority**: P0
> **Created**: 2026-03-05

## 요구사항

### FR-01: 상단 고정 (Pin Top)
- 특정 행을 그리드 상단에 고정 표시
- 스크롤 시에도 고정 행은 항상 상단에 위치
- API: `Grid.pin_row(grid, row_id, :top)`

### FR-02: 하단 고정 (Pin Bottom)
- 특정 행을 그리드 하단에 고정 표시
- 합계행 등에 활용
- API: `Grid.pin_row(grid, row_id, :bottom)`

### FR-03: 고정 해제
- 고정된 행을 원래 위치로 복원
- API: `Grid.unpin_row(grid, row_id)`

### FR-04: 고정 행 시각적 구분
- 고정 영역과 일반 영역 사이 경계선 표시
- 고정 행은 살짝 다른 배경색

## 영향 범위
- grid.ex: state 필드 (pinned_rows) + API
- grid_component.ex: pinned row 렌더링 영역
- CSS: pinned row 스타일
