# FA-005 Overlay System

> **Feature ID**: FA-005
> **Version**: v0.12.0
> **Priority**: P0
> **Created**: 2026-03-05

## 요구사항

### FR-01: Loading Overlay
- 데이터 로딩 중 스피너 + "데이터 로딩 중..." 메시지
- `grid.state.loading` 상태로 제어

### FR-02: No Data Overlay
- 데이터가 빈 경우 "표시할 데이터가 없습니다" 메시지
- `grid.data == []` 자동 감지

### FR-03: Error Overlay
- 에러 발생 시 에러 메시지 표시
- `grid.state.error` 상태로 제어

### FR-04: 커스텀 메시지
- 옵션으로 각 오버레이 메시지 커스터마이징 가능
- `overlay_loading_text`, `overlay_no_data_text`, `overlay_error_text`

## 영향 범위
- grid.ex: state 필드 + 옵션
- grid_component.ex: 오버레이 HEEx
- CSS: 오버레이 스타일
- demo_live.ex: 데모
