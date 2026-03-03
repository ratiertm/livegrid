# Undo / Redo

셀 편집, 행 추가/삭제를 50단계까지 되돌리거나 다시 실행할 수 있습니다.

## Overview

Grid는 편집 히스토리를 자동으로 기록합니다. Ctrl+Z로 되돌리고, Ctrl+Y로 다시 실행합니다.

## Keyboard Shortcuts

| 단축키 | 동작 |
|--------|------|
| `Ctrl+Z` / `Cmd+Z` | Undo (되돌리기) |
| `Ctrl+Y` / `Cmd+Y` | Redo (다시 실행) |
| `Ctrl+Shift+Z` | Redo (대체 단축키) |

## Programmatic API

```elixir
# 되돌리기
grid = Grid.undo(grid)

# 다시 실행
grid = Grid.redo(grid)

# 상태 확인
Grid.can_undo?(grid)  # => true
Grid.can_redo?(grid)  # => false
```

## Tracked Actions

히스토리에 기록되는 동작:

| 동작 | 설명 |
|------|------|
| `{:update_cell, row_id, field, old, new}` | 셀 값 변경 |
| `{:update_row, row_id, old_values, new_values}` | 행 단위 변경 |
| `{:insert_row, row_id, row_data}` | 행 추가 |

## Grid State

```elixir
%{
  edit_history: [],  # Undo 스택 (최대 50개)
  redo_stack: []     # Redo 스택
}
```

## Behavior

- 히스토리는 **최대 50단계**까지 유지됩니다
- 새로운 편집 시 redo 스택은 초기화됩니다
- 저장(`save_changes`) 후에도 히스토리는 유지됩니다

## Related

- [Cell Editing](./cell-editing.md) — 인라인 셀 편집
- [Row Editing](./row-editing.md) — 행 단위 편집
- [Keyboard Navigation](./keyboard-navigation.md) — 키보드 단축키
