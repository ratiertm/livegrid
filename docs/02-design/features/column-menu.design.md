# FA-010 Column Menu — Design

## 1. 데이터 모델

### Assigns 추가 (grid_component.ex)
```elixir
# column_menu: nil | %{field: atom(), x: integer(), y: integer()}
assign(socket, column_menu: nil)
```

## 2. API 설계

### grid.ex 추가 함수
```elixir
@spec hide_column(t(), atom()) :: t()
def hide_column(grid, field)
# columns에서 field 찾아 suppress: true 설정

@spec show_column(t(), atom()) :: t()
def show_column(grid, field)
# columns에서 field 찾아 suppress: false 설정

@spec clear_sort(t()) :: t()
def clear_sort(grid)
# state.sort를 nil로 리셋
```

## 3. 이벤트 설계

### 이벤트 핸들러 (event_handlers.ex)
```
toggle_column_menu(field, x, y) → column_menu assign 토글
close_column_menu() → column_menu = nil
column_menu_action(action, field) → 각 action 분기 처리
```

### Action 목록
| Action | 구현 |
|--------|------|
| sort_asc | Grid.sort(grid, field, :asc) |
| sort_desc | Grid.sort(grid, field, :desc) |
| clear_sort | Grid.clear_sort(grid) |
| pin_left | Grid.freeze_columns(grid, col_index) |
| unpin | Grid.freeze_columns(grid, 0) |
| hide_column | Grid.hide_column(grid, field) |

## 4. UI 설계

### 헤더 아이콘
```heex
<div class="lv-grid__header-cell">
  <span class="lv-grid__header-label">{column.label}</span>
  <!-- 호버 시에만 표시되는 ⋮ 아이콘 -->
  <button class="lv-grid__column-menu-trigger"
    phx-click="toggle_column_menu"
    phx-value-field={column.field}
    phx-value-x={...} phx-value-y={...}
    phx-target={@myself}>
    ⋮
  </button>
</div>
```

### 드롭다운 메뉴 (position: fixed)
```heex
<%= if @column_menu do %>
  <div class="lv-grid__column-menu"
    style={"position:fixed;left:#{@column_menu.x}px;top:#{@column_menu.y}px;"}
    phx-click-away="close_column_menu"
    phx-target={@myself}>
    <div class="lv-grid__column-menu-item" phx-click="column_menu_action"
      phx-value-action="sort_asc" phx-value-field={@column_menu.field}>
      ↑ 오름차순 정렬
    </div>
    <div class="lv-grid__column-menu-item" ...>↓ 내림차순 정렬</div>
    <div class="lv-grid__column-menu-item" ...>✕ 정렬 초기화</div>
    <div class="lv-grid__column-menu-divider"></div>
    <div class="lv-grid__column-menu-item" ...>📌 컬럼 고정</div>
    <div class="lv-grid__column-menu-item" ...>📌 고정 해제</div>
    <div class="lv-grid__column-menu-divider"></div>
    <div class="lv-grid__column-menu-item" ...>👁 컬럼 숨기기</div>
  </div>
<% end %>
```

## 5. CSS 설계

### header.css 추가
```css
.lv-grid__column-menu-trigger {
  opacity: 0;  /* 호버 시에만 표시 */
  cursor: pointer;
  padding: 2px 4px;
  border: none;
  background: transparent;
  font-size: 14px;
  transition: opacity 0.2s;
}
.lv-grid__header-cell:hover .lv-grid__column-menu-trigger {
  opacity: 0.6;
}
.lv-grid__column-menu-trigger:hover {
  opacity: 1 !important;
}

.lv-grid__column-menu {
  min-width: 180px;
  background: var(--lv-grid-bg);
  border: 1px solid var(--lv-grid-border);
  border-radius: 6px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
  z-index: 9999;
  padding: 4px 0;
}

.lv-grid__column-menu-item {
  padding: 8px 16px;
  cursor: pointer;
  font-size: 13px;
}
.lv-grid__column-menu-item:hover {
  background: var(--lv-grid-hover);
}

.lv-grid__column-menu-divider {
  height: 1px;
  background: var(--lv-grid-border);
  margin: 4px 0;
}
```

## 6. 테스트 설계

```elixir
describe "column menu functions (FA-010)" do
  test "hide_column sets suppress to true"
  test "show_column sets suppress to false"
  test "clear_sort resets sort state to nil"
  test "hide and show column roundtrip"
end
```
