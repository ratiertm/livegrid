# Row Reorder

드래그 앤 드롭으로 행의 순서를 변경합니다.

## Overview

Row Reorder를 활성화하면 각 행 왼쪽에 드래그 핸들(☰)이 표시됩니다. 핸들을 드래그하여 행을 원하는 위치로 이동할 수 있습니다.

## Enabling Row Reorder

`options`에 `row_reorder: true`를 지정합니다:

```elixir
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="my-grid"
  data={@data}
  columns={@columns}
  options={%{row_reorder: true}}
/>
```

## Interaction

1. 행의 드래그 핸들(☰) 위에 마우스를 올립니다 (hover 시 표시)
2. 마우스를 누른 채 원하는 위치로 드래그합니다
3. 파란색 드롭 인디케이터가 삽입 위치를 표시합니다
4. 마우스를 놓으면 행이 해당 위치로 이동합니다

## Programmatic API

코드에서 직접 행을 이동할 수 있습니다:

```elixir
# row_id=3인 행을 row_id=1 위치로 이동
grid = Grid.move_row(grid, 3, 1)
```

`move_row/3`는 원본 데이터 배열의 순서를 변경합니다. 같은 ID로 이동하면 변경 없이 원본을 반환합니다.

## Events

| 이벤트 | 파라미터 | 설명 |
|--------|---------|------|
| `grid_move_row` | `%{from_id, to_id}` | 행 이동 완료 시 서버로 전송 |

## CSS Classes

| 클래스 | 적용 대상 |
|--------|----------|
| `.lv-grid__row-drag-handle` | 드래그 핸들 (☰) |
| `.lv-grid__row--dragging` | 드래그 중인 원본 행 |
| `.lv-grid__row--ghost` | 드래그 시 마우스를 따라다니는 복제 행 |
| `.lv-grid__row-drop-indicator` | 삽입 위치 표시선 |

## JS Hook

Row Reorder는 `RowReorder` Phoenix LiveView Hook으로 구현됩니다. Hook은 `row_reorder: true` 옵션이 활성화된 행에만 자동 부착됩니다.

## Related

- [Row Data](./row-data.md) — 데이터 순서와 Row ID
- [Selection](./selection.md) — 행 선택과 이동 조합
- [Grid Options](./grid-options.md) — row_reorder 옵션
