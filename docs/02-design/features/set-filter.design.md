# FA-012 Set Filter — 기술 설계서

> **Feature ID**: FA-012
> **Version**: v0.13.0
> **Created**: 2026-03-05

---

## Step 1: Filter.ex에 `:set` 필터 타입 추가

**파일**: `lib/liveview_grid/operations/filter.ex`

```elixir
# match_filter?에 :set 패턴 추가
defp match_filter?(row, field, value, :set) when is_list(value) do
  cell_value = Map.get(row, field)
  if value == [] do
    true  # 빈 리스트 = 필터 없음
  else
    to_string(cell_value) in Enum.map(value, &to_string/1)
  end
end

defp match_filter?(row, field, value, :set) when is_binary(value) do
  # 문자열로 저장된 경우 쉼표 구분 파싱
  selected = value |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  if selected == [] do
    true
  else
    cell_value = Map.get(row, field) |> to_string()
    cell_value in selected
  end
end
```

## Step 2: Grid.ex에 Set Filter 헬퍼 함수

**파일**: `lib/liveview_grid/grid.ex`

```elixir
@doc "컬럼의 고유값 목록 추출 (Set Filter용)"
@spec unique_values(t(), atom()) :: list(String.t())
def unique_values(grid, field) do
  grid.data
  |> Enum.map(fn row -> Map.get(row, field) end)
  |> Enum.reject(&is_nil/1)
  |> Enum.map(&to_string/1)
  |> Enum.uniq()
  |> Enum.sort()
end

@doc "Set 필터 적용"
@spec apply_set_filter(t(), atom(), list(String.t())) :: t()
def apply_set_filter(grid, field, selected_values) do
  put_in(grid.state.filters[field], selected_values)
end

@doc "Set 필터 해제"
@spec clear_set_filter(t(), atom()) :: t()
def clear_set_filter(grid, field) do
  filters = Map.delete(grid.state.filters, field)
  put_in(grid.state.filters, filters)
end
```

## Step 3: GridComponent HEEx — Set Filter 드롭다운

**파일**: `lib/liveview_grid_web/components/grid_component.ex`

filter-row 내부에서 `filter_type == :set`일 때 드롭다운 렌더링:

```heex
<%= if column.filter_type == :set do %>
  <div class="lv-grid__set-filter">
    <button
      class={"lv-grid__set-filter-btn #{if has_set_filter?(@grid, column.field), do: "lv-grid__set-filter-btn--active"}"}
      phx-click="toggle_set_filter"
      phx-value-field={column.field}
      phx-target={@myself}
    >
      ▼ <%= if has_set_filter?(@grid, column.field), do: "(#{count_set_filter(@grid, column.field)})" %>
    </button>

    <%= if @set_filter_open == column.field do %>
      <div class="lv-grid__set-filter-dropdown" phx-click-away="close_set_filter" phx-target={@myself}>
        <!-- 검색 입력 -->
        <input
          type="text"
          class="lv-grid__set-filter-search"
          placeholder="검색..."
          phx-keyup="set_filter_search"
          phx-value-field={column.field}
          phx-debounce="200"
          phx-target={@myself}
        />
        <!-- 전체 선택/해제 -->
        <div class="lv-grid__set-filter-actions">
          <button phx-click="set_filter_select_all" phx-value-field={column.field} phx-target={@myself}>전체 선택</button>
          <button phx-click="set_filter_clear_all" phx-value-field={column.field} phx-target={@myself}>전체 해제</button>
        </div>
        <!-- 체크박스 목록 -->
        <div class="lv-grid__set-filter-list">
          <%= for val <- filtered_unique_values(@grid, column.field, @set_filter_query) do %>
            <label class="lv-grid__set-filter-item">
              <input
                type="checkbox"
                checked={val in get_set_filter_selected(@grid, column.field)}
                phx-click="toggle_set_filter_value"
                phx-value-field={column.field}
                phx-value-val={val}
                phx-target={@myself}
              />
              <span><%= val %></span>
            </label>
          <% end %>
        </div>
        <!-- 적용 버튼 -->
        <button class="lv-grid__set-filter-apply" phx-click="apply_set_filter" phx-value-field={column.field} phx-target={@myself}>
          적용
        </button>
      </div>
    <% end %>
  </div>
<% end %>
```

## Step 4: EventHandlers — Set Filter 이벤트

**파일**: `lib/liveview_grid_web/components/grid_component/event_handlers.ex`

```elixir
# Set Filter 드롭다운 토글
def handle_toggle_set_filter(%{"field" => field_str}, socket) do
  field = String.to_existing_atom(field_str)
  current = socket.assigns[:set_filter_open]
  new_val = if current == field, do: nil, else: field

  # 처음 열 때 모든 값 선택 상태로 초기화
  socket = if new_val && !has_set_filter_state?(socket, field) do
    all_values = Grid.unique_values(socket.assigns.grid, field)
    init_set_filter_state(socket, field, all_values)
  else
    socket
  end

  {:noreply, assign(socket, set_filter_open: new_val, set_filter_query: "")}
end

# 체크박스 토글
def handle_toggle_set_filter_value(%{"field" => field_str, "val" => val}, socket) do
  field = String.to_existing_atom(field_str)
  current = get_set_filter_selected(socket, field)
  new_selected = if val in current do
    List.delete(current, val)
  else
    [val | current]
  end
  {:noreply, update_set_filter_selected(socket, field, new_selected)}
end

# 전체 선택
def handle_set_filter_select_all(%{"field" => field_str}, socket) do
  field = String.to_existing_atom(field_str)
  all = Grid.unique_values(socket.assigns.grid, field)
  {:noreply, update_set_filter_selected(socket, field, all)}
end

# 전체 해제
def handle_set_filter_clear_all(%{"field" => field_str}, socket) do
  field = String.to_existing_atom(field_str)
  {:noreply, update_set_filter_selected(socket, field, [])}
end

# 적용
def handle_apply_set_filter(%{"field" => field_str}, socket) do
  field = String.to_existing_atom(field_str)
  selected = get_set_filter_selected(socket, field)
  grid = Grid.apply_set_filter(socket.assigns.grid, field, selected)
  {:noreply, assign(socket, grid: grid, set_filter_open: nil)}
end

# 닫기
def handle_close_set_filter(_params, socket) do
  {:noreply, assign(socket, set_filter_open: nil)}
end

# 검색
def handle_set_filter_search(%{"field" => _field_str, "value" => query}, socket) do
  {:noreply, assign(socket, set_filter_query: query)}
end
```

## Step 5: CSS 스타일링

**파일**: `assets/css/grid/body.css`

```css
/* FA-012: Set Filter */
.lv-grid__set-filter { position: relative; width: 100%; }

.lv-grid__set-filter-btn {
  width: 100%;
  padding: 2px 6px;
  font-size: 12px;
  border: 1px solid var(--lv-grid-border, #e0e0e0);
  border-radius: 3px;
  background: var(--lv-grid-bg, #fff);
  cursor: pointer;
  text-align: left;
}

.lv-grid__set-filter-btn--active {
  border-color: var(--lv-grid-primary, #2196f3);
  color: var(--lv-grid-primary, #2196f3);
}

.lv-grid__set-filter-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  min-width: 200px;
  max-height: 300px;
  background: var(--lv-grid-bg, #fff);
  border: 1px solid var(--lv-grid-border, #e0e0e0);
  border-radius: 4px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  z-index: 100;
  display: flex;
  flex-direction: column;
}

.lv-grid__set-filter-search {
  margin: 8px;
  padding: 4px 8px;
  border: 1px solid var(--lv-grid-border, #e0e0e0);
  border-radius: 3px;
  font-size: 12px;
}

.lv-grid__set-filter-actions {
  display: flex;
  gap: 8px;
  padding: 0 8px 4px;
  font-size: 11px;
}

.lv-grid__set-filter-actions button {
  background: none;
  border: none;
  color: var(--lv-grid-primary, #2196f3);
  cursor: pointer;
  padding: 0;
  font-size: 11px;
}

.lv-grid__set-filter-list {
  overflow-y: auto;
  max-height: 200px;
  padding: 0 8px;
}

.lv-grid__set-filter-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 3px 0;
  font-size: 12px;
  cursor: pointer;
}

.lv-grid__set-filter-item input[type="checkbox"] { margin: 0; }

.lv-grid__set-filter-apply {
  margin: 8px;
  padding: 4px 12px;
  background: var(--lv-grid-primary, #2196f3);
  color: #fff;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  font-size: 12px;
}

/* Dark mode */
[data-theme="dark"] .lv-grid__set-filter-dropdown {
  background: var(--lv-grid-bg, #1e1e1e);
  border-color: var(--lv-grid-border, #444);
}

[data-theme="dark"] .lv-grid__set-filter-search {
  background: var(--lv-grid-bg, #2a2a2a);
  border-color: var(--lv-grid-border, #444);
  color: var(--lv-grid-text, #e0e0e0);
}
```

## Step 6: 데모 + 테스트

**데모**: demo_live.ex에서 `city` 컬럼을 `filter_type: :set`으로 변경
**테스트**: 5개 (set filter apply, select all, clear all, 검색 필터링, visible_data 연동)

## 변경 요약

| Step | 파일 | 라인 수 |
|------|------|---------|
| 1 | filter.ex | +20 |
| 2 | grid.ex | +25 |
| 3 | grid_component.ex | +50 |
| 4 | event_handlers.ex | +60 |
| 5 | body.css | +50 |
| 6 | demo_live.ex + grid_test.exs | +30 |
| **합계** | | **~235줄** |
