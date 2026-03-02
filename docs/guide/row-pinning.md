# Row Pinning

특정 행을 그리드 상단 또는 하단에 고정합니다. 스크롤해도 항상 보이는 행을 만들 수 있습니다.

## API

```elixir
# 행을 상단에 고정 (기본값)
grid = Grid.pin_row(grid, row_id)

# 행을 하단에 고정
grid = Grid.pin_row(grid, row_id, :bottom)

# 고정 해제
grid = Grid.unpin_row(grid, row_id)

# 고정된 행 조회
top_rows = Grid.pinned_rows(grid, :top)
bottom_rows = Grid.pinned_rows(grid, :bottom)
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `row_id` | any | 고정할 행의 ID |
| `position` | `:top` \| `:bottom` | 고정 위치 (기본값: `:top`) |

## Behavior

- 고정된 행은 스크롤 시에도 상단/하단에 항상 표시
- 정렬/필터 변경 시에도 고정 위치 유지
- 같은 행을 중복 고정하면 무시
- CSS 클래스: `.lv-grid__row--pinned-top`, `.lv-grid__row--pinned-bottom`
- z-index: `var(--lv-grid-z-pinned)` (10)

## Example

```elixir
# 합계 행을 하단에 고정
grid = grid
  |> Grid.pin_row("total-row", :bottom)

# 헤더 요약 행을 상단에 고정
grid = grid
  |> Grid.pin_row("summary-row", :top)
```
