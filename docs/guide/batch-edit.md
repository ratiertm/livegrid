# Batch Edit

셀 범위 선택 후 선택된 모든 셀의 값을 한번에 변경합니다.

## API

```elixir
# 선택된 범위의 셀을 일괄 업데이트
grid = Grid.batch_update_cells(grid, :status, "완료")
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `field` | atom | 업데이트할 컬럼 필드명 |
| `value` | any | 설정할 값 |

## Usage Flow

1. 셀 범위 선택 (Shift+Click 또는 드래그)
2. `batch_update_cells/3` 호출
3. 선택된 범위 내 해당 필드의 모든 셀이 새 값으로 변경
4. 변경된 행들은 자동으로 "U" (Updated) 상태로 마킹

## Requirements

- `grid.state.cell_range`에 선택 영역이 있어야 함
- 대상 컬럼이 `editable: true`여야 함
- 읽기 전용 컬럼은 무시됨

## Example

```elixir
# 셀 범위 선택 후, 상태를 일괄 "승인"으로 변경
grid = Grid.batch_update_cells(grid, :approval_status, "approved")

# 숫자 컬럼 일괄 초기화
grid = Grid.batch_update_cells(grid, :score, 0)
```
