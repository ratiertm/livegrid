# Frozen Columns

좌측 또는 우측 컬럼을 고정하여 가로 스크롤 시에도 항상 보이게 합니다.

## Overview

Frozen Columns(틀 고정)는 중요한 컬럼을 화면에 고정하여 다른 컬럼을 스크롤할 때도 항상 보이게 하는 기능입니다. 좌측과 우측 모두 지원합니다.

```
| ID (고정) | 이름  | 이메일      | 도시   | 가입일 (고정) |
|-----------|------|------------|--------|-------------|
| 1         | ← 스크롤 가능 영역 →       | 2025-01-05  |
| 2         |                            | 2025-02-03  |
```

## Left Freeze

좌측 N개 컬럼을 고정합니다:

```elixir
options = %{frozen_columns: 2}  # 좌측 2개 컬럼 고정
```

## Right Freeze

우측 N개 컬럼을 고정합니다:

```elixir
options = %{frozen_right_columns: 1}  # 우측 1개 컬럼 고정
```

## Both Sides

좌측과 우측을 동시에 고정할 수 있습니다:

```elixir
options = %{
  frozen_columns: 1,        # 좌측 1개
  frozen_right_columns: 1   # 우측 1개
}
```

## Dynamic Freeze

사용자 액션에 따라 고정 컬럼 수를 동적으로 변경할 수 있습니다:

```elixir
# 특정 컬럼까지 고정
grid = Grid.set_frozen_columns(grid, 3)

# 고정 해제
grid = Grid.set_frozen_columns(grid, 0)
```

### Event Handler

`grid_freeze_to_column` 이벤트로 클라이언트에서 동적 고정을 트리거할 수 있습니다:

```javascript
// col_idx까지 고정 (이미 해당 위치면 해제)
this.pushEvent("grid_freeze_to_column", {col_idx: "2"})
```

## CSS Classes

| 클래스 | 적용 대상 |
|--------|----------|
| `.lv-grid__cell--frozen` | 좌측 고정 셀 |
| `.lv-grid__cell--frozen-right` | 우측 고정 셀 |

고정 셀은 `position: sticky`로 구현되며, 자동으로 `background: inherit`과 `box-shadow`가 적용됩니다.

## Options Reference

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `frozen_columns` | integer | 0 | 좌측 고정 컬럼 수 |
| `frozen_right_columns` | integer | 0 | 우측 고정 컬럼 수 |

## Related

- [Column Definitions](./column-definitions.md) — 컬럼 순서와 너비
- [Grid Options](./grid-options.md) — frozen_columns 옵션
- [Cell Merge](./cell-merge.md) — 고정 컬럼과 병합 조합
