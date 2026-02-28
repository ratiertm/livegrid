# F-930 Row Move - Design

## Step 1: Grid.move_row/3 (grid.ex)
```elixir
@spec move_row(t(), any(), any()) :: t()
def move_row(grid, from_row_id, to_row_id)
```
- data 리스트에서 from_row_id 행을 제거 → to_row_id 위치 앞에 삽입

## Step 2: JS Hook (assets/js/hooks/row-reorder.js)
- `.lv-grid__row-drag-handle` 요소에 mousedown 바인딩
- 드래그 시 고스트 행 생성 + 인디케이터 라인 표시
- 드롭 시 `grid_move_row` 이벤트 push

## Step 3: Event Handler (event_handlers.ex)
- `handle_grid_move_row(params, socket)` 함수
- from_id, to_id 파싱 → Grid.move_row 호출

## Step 4: CSS (body.css)
```css
.lv-grid__row-drag-handle { ... }
.lv-grid__row--drag-over { ... }
.lv-grid__row--dragging { ... }
```

## Step 5: HEEx 수정 (grid_component.ex)
- row_reorder 옵션 true일 때 각 행에 드래그 핸들 추가
- 행에 data-row-id, phx-hook 추가

## Step 6: app.js에 Hook 등록

## Step 7: 데모에 row_reorder: true 옵션 추가

## Step 8: 테스트
- move_row/3 순서 변경 확인
- 유효하지 않은 row_id 처리
