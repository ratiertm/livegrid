# Selection

Grid는 행 선택과 셀 범위 선택을 지원합니다.

## Row Selection

### Single Row Select

행의 체크박스를 클릭하여 개별 선택합니다:

```elixir
# 선택된 행 ID 목록
grid.state.selection.selected_ids
# => [1, 3, 5]
```

### Select All

헤더의 체크박스로 전체 선택/해제:

```elixir
grid.state.selection.select_all
# => true
```

### Selection State

```elixir
# 선택된 행이 있는지 확인
length(grid.state.selection.selected_ids) > 0

# 선택된 행 데이터 추출
selected_data = Enum.filter(grid.data, fn row ->
  row.id in grid.state.selection.selected_ids
end)
```

## Cell Range Selection

마우스 드래그로 셀 범위를 선택합니다. Excel과 유사한 동작입니다.

### Features

- 클릭 + 드래그로 범위 지정
- 선택 영역 하이라이트 표시
- 선택 영역 통계 자동 계산 (Sum, Avg, Count, Min, Max)
- `Ctrl+C`로 클립보드 복사

### Cell Range Summary

선택된 셀 범위의 통계가 Footer에 실시간 표시됩니다:

```
선택 영역: Count: 6 | Sum: 15,300 | Avg: 2,550 | Min: 1,200 | Max: 6,100
```

## Context Menu

행을 우클릭하면 컨텍스트 메뉴가 표시됩니다:

| Action | 설명 |
|--------|------|
| Copy | 행/범위 클립보드 복사 |
| Insert Row Above | 위에 행 추가 |
| Insert Row Below | 아래에 행 추가 |
| Duplicate Row | 행 복제 |
| Delete Row | 행 삭제 표시 |

## Related

- [Export](./export.md) — 선택된 행 내보내기
- [CRUD Operations](./crud-operations.md) — 선택된 행 삭제
- [Keyboard Navigation](./keyboard-navigation.md) — Ctrl+C 복사
