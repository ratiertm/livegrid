# Grid State Save/Restore

그리드의 전체 상태(정렬, 필터, 페이지, 컬럼 순서 등)를 저장하고 복원합니다.

## API

```elixir
# 현재 상태 추출
state = Grid.get_state(grid)

# 상태 복원
grid = Grid.restore_state(grid, state)
```

## State Contents

`get_state/1`이 반환하는 맵:

```elixir
%{
  sort: %{field: :name, direction: :asc},
  filters: %{name: "Kim"},
  global_search: "검색어",
  show_filter_row: true,
  column_order: [:id, :name, :email, :age],
  hidden_columns: [:age],
  column_widths: %{name: 200, email: 250},
  current_page: 3,
  group_by: [:department]
}
```

## Partial Restore

부분 상태만 복원할 수 있습니다:

```elixir
# 정렬과 필터만 복원
Grid.restore_state(grid, %{
  sort: %{field: :name, direction: :asc},
  filters: %{name: "Kim"}
})
```

## JS Hook - GridStatePersist

브라우저 localStorage에 자동 저장하는 JS Hook:

```javascript
// app.js에서 등록됨
hooks.GridStatePersist = GridStatePersist;
```

```html
<div id="grid" phx-hook="GridStatePersist" data-grid-id="my-grid">
```

- 상태 변경 시 자동으로 localStorage에 저장
- 페이지 로드 시 자동 복원
- `data-grid-id`로 그리드별 구분

## Column State

컬럼별 상태만 별도로 관리할 수도 있습니다:

```elixir
# 컬럼 상태 추출
col_states = Grid.get_column_state(grid)
# => [%{field: :name, width: 150, visible: true, sort: nil, order_index: 0}, ...]

# 컬럼 상태 적용
grid = Grid.apply_column_state(grid, col_states)
```
