# Dynamic Freeze Count - Plan

## 개요
사용자가 특정 컬럼을 클릭하여 해당 컬럼까지 동적으로 틀 고정/해제.

## 요구사항

### DF-01: Grid.set_frozen_columns API
- `Grid.set_frozen_columns(grid, count)` — frozen_columns 옵션 동적 변경
- count=0이면 고정 해제

### DF-02: 이벤트 핸들러
- `grid_freeze_to_column` 이벤트 — col_idx 받아서 해당 컬럼까지 고정
- 컨텍스트 메뉴 또는 헤더 우클릭에서 "여기까지 고정" 기능

### DF-03: 고정 토글
- 이미 고정된 상태에서 같은 위치 클릭 → 고정 해제

## 참조
- 넥사크로 2.11: set_fixedcol("left:N")
- 현재: options.frozen_columns 정적 설정만 지원
