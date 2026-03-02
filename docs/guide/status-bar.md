# Status Bar

그리드 하단에 현재 상태 정보를 표시하는 바입니다.

## Enabling

Grid 옵션에서 활성화합니다:

```elixir
options = %{
  show_status_bar: true
}
```

## Status Bar Data

```elixir
Grid.status_bar_data(grid)
# => %{
#   total_rows: 1000,
#   filtered_rows: 250,
#   selected_count: 5,
#   editing: nil  # 또는 %{row_id: 1, field: :name}
# }
```

## Display Items

| Item | Description |
|------|-------------|
| `total_rows` | 전체 행 수 |
| `filtered_rows` | 필터링된 행 수 |
| `selected_count` | 선택된 행 수 |
| `editing` | 현재 편집 중인 셀 정보 |

## CSS Classes

```css
.lv-grid__status-bar           /* 컨테이너 */
.lv-grid__status-bar-left      /* 왼쪽 영역 */
.lv-grid__status-bar-right     /* 오른쪽 영역 */
.lv-grid__status-bar-item      /* 개별 항목 */
.lv-grid__status-bar-item--editing  /* 편집 중 표시 */
```

## Behavior

- 필터/검색 적용 시 실시간 업데이트
- 셀 편집 시작/종료 시 editing 상태 변경
- Footer(페이지네이션) 아래에 표시
