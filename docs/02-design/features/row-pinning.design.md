# FA-001 Row Pinning — 기술 설계서

> **Feature ID**: FA-001
> **Version**: v0.12.0
> **Created**: 2026-03-05

---

## Step 1: Grid state에 pinned_rows 필드 추가

**파일**: `lib/liveview_grid/grid.ex` — `initial_state/0`

```elixir
# initial_state에 추가
pinned_top: [],      # [row_id, ...] 상단 고정 행 ID 목록
pinned_bottom: []    # [row_id, ...] 하단 고정 행 ID 목록
```

## Step 2: Grid API — pin_row/3, unpin_row/2

**파일**: `lib/liveview_grid/grid.ex`

```elixir
@spec pin_row(t(), any(), :top | :bottom) :: t()
def pin_row(grid, row_id, position) when position in [:top, :bottom] do
  # 기존 핀 제거 (중복 방지)
  grid = unpin_row(grid, row_id)
  case position do
    :top -> update_in(grid.state.pinned_top, &(&1 ++ [row_id]))
    :bottom -> update_in(grid.state.pinned_bottom, &(&1 ++ [row_id]))
  end
end

@spec unpin_row(t(), any()) :: t()
def unpin_row(grid, row_id) do
  grid
  |> update_in([:state, :pinned_top], &List.delete(&1, row_id))
  |> update_in([:state, :pinned_bottom], &List.delete(&1, row_id))
end

@spec pinned_top_rows(t()) :: list(map())
def pinned_top_rows(grid) do
  Enum.filter(grid.data, fn row -> row.id in grid.state.pinned_top end)
  |> Enum.sort_by(fn row -> Enum.find_index(grid.state.pinned_top, &(&1 == row.id)) end)
end

@spec pinned_bottom_rows(t()) :: list(map())
def pinned_bottom_rows(grid) do
  Enum.filter(grid.data, fn row -> row.id in grid.state.pinned_bottom end)
  |> Enum.sort_by(fn row -> Enum.find_index(grid.state.pinned_bottom, &(&1 == row.id)) end)
end
```

## Step 3: visible_data에서 pinned 행 제외

**파일**: `lib/liveview_grid/grid.ex` — `visible_data/1`

`visible_data`의 최종 결과에서 pinned 행을 제외:

```elixir
# visible_data 결과에서 pinned 행 제외
all_pinned = state.pinned_top ++ state.pinned_bottom
result |> Enum.reject(fn row -> row.id in all_pinned end)
```

## Step 4: HEEx — 상단/하단 고정 행 렌더링

**파일**: `lib/liveview_grid_web/components/grid_component.ex`

Body 영역 앞뒤에 pinned 영역 추가:

```heex
<!-- FA-001: Pinned Top Rows -->
<%= if length(@grid.state.pinned_top) > 0 do %>
  <div class="lv-grid__pinned lv-grid__pinned--top">
    <%= for row <- Grid.pinned_top_rows(@grid) do %>
      <!-- 기존 row 렌더링 로직과 동일, 클래스만 추가 -->
      <div class="lv-grid__row lv-grid__row--pinned" data-row-id={row.id}>
        ...cells...
      </div>
    <% end %>
  </div>
<% end %>

<!-- Body (기존) -->
...

<!-- FA-001: Pinned Bottom Rows -->
<%= if length(@grid.state.pinned_bottom) > 0 do %>
  <div class="lv-grid__pinned lv-grid__pinned--bottom">
    <%= for row <- Grid.pinned_bottom_rows(@grid) do %>
      <div class="lv-grid__row lv-grid__row--pinned" data-row-id={row.id}>
        ...cells...
      </div>
    <% end %>
  </div>
<% end %>
```

## Step 5: CSS 스타일링

**파일**: `assets/css/grid/body.css`

```css
/* FA-001: Row Pinning */
.lv-grid__pinned {
  position: sticky;
  z-index: 10;
  background: var(--lv-grid-bg, #fff);
}

.lv-grid__pinned--top {
  top: 0;
  border-bottom: 2px solid var(--lv-grid-primary, #2196f3);
}

.lv-grid__pinned--bottom {
  bottom: 0;
  border-top: 2px solid var(--lv-grid-primary, #2196f3);
}

.lv-grid__row--pinned {
  background: var(--lv-grid-pinned-bg, #f0f7ff);
}
```

## Step 6: 데모 페이지에 Pin 버튼 추가

**파일**: `lib/liveview_grid_web/live/demo_live.ex`

첫 번째 행을 상단 고정, 마지막 행을 하단 고정하는 버튼 추가.

## Step 7: 테스트

```elixir
test "pin_row/3 pins to top" do
  grid = Grid.new(columns: [...], data: [...])
  grid = Grid.pin_row(grid, 1, :top)
  assert 1 in grid.state.pinned_top
end

test "unpin_row/2 removes pin" do
  grid = Grid.new(columns: [...], data: [...])
  grid = Grid.pin_row(grid, 1, :top) |> Grid.unpin_row(1)
  assert grid.state.pinned_top == []
end

test "pinned_top_rows/1 returns pinned rows" do
  grid = Grid.new(columns: [...], data: [%{id: 1, name: "A"}, %{id: 2, name: "B"}])
  grid = Grid.pin_row(grid, 1, :top)
  assert [%{id: 1}] = Grid.pinned_top_rows(grid)
end
```

## 변경 요약

| Step | 파일 | 라인 수 |
|------|------|---------|
| 1-3 | grid.ex | +40 |
| 4 | grid_component.ex | +30 |
| 5 | body.css | +25 |
| 6 | demo_live.ex | +15 |
| 7 | grid_test.exs | +20 |
| **합계** | | **~130줄** |
