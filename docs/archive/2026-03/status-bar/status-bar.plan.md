# FA-004 Status Bar

> **Feature ID**: FA-004
> **Version**: v0.12.0
> **Priority**: P0
> **Created**: 2026-03-05

## 요구사항

### FR-01: 총 행수 표시
- 그리드 하단에 전체 데이터 행수 표시
- 필터링 시 "필터된 N행 / 전체 M행" 형식

### FR-02: 선택 합계 표시
- 셀 범위 선택 시 선택된 숫자 셀의 합계/평균/개수 표시
- 숫자 데이터가 없으면 개수만 표시

### FR-03: 필터 상태 표시
- 활성 필터가 있으면 "필터 활성" 표시
- 필터 해제 시 자동으로 사라짐

### FR-04: 커스텀 Status Bar
- 옵션으로 status bar 표시 여부 제어
- `show_status_bar: true/false`

## 영향 범위
- grid.ex: 옵션 + 헬퍼 함수
- grid_component.ex: status bar HEEx
- CSS: status bar 스타일
- demo_live.ex: 데모
