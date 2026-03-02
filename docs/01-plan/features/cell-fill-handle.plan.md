# FA-013 Cell Fill Handle - Plan

> **Feature**: FA-013 Cell Fill Handle
> **Phase**: 4 (v0.14)
> **Priority**: P1
> **Difficulty**: ⭐⭐⭐

## 요구사항

### FR-01: Fill Handle UI
- 편집 가능 셀 선택 시 우하단에 작은 파란색 사각형 핸들 표시
- 핸들 드래그로 방향(아래/위) 감지

### FR-02: Fill Down 로직
- 드래그 방향으로 선택 셀 값 복사 (단순 copy)
- Grid.fill_cells/4 API: source 셀 값을 target 범위에 적용
- editable: true 컬럼만 대상

### FR-03: Fill 이벤트
- `grid_fill_cells` 이벤트 — source_row_id, field, target_row_ids
- 각 target row에 update_cell 호출
- row_statuses :updated 마킹

## 구현 범위
- grid.ex: `fill_cells/4` API
- grid_component.ex: fill handle div 렌더링 (편집 가능 셀에만)
- event_handlers.ex: `handle_fill_cells/2`
- CSS: `.lv-grid__fill-handle` 스타일
- JS Hook: 드래그 범위 감지 (FillHandle Hook)

## 테스트
- fill_cells API 단위 테스트
- editable: false 컬럼 무시 테스트
