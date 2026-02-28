# Pivot Table

데이터를 피벗 변환하여 행/열 차원의 교차 분석 테이블을 생성합니다.

## Overview

Pivot Table은 플랫 데이터를 행 차원(row fields)과 열 차원(col field)으로 분리하고, 교차점에 집계 값을 표시합니다.

## Configuration

```elixir
grid = Grid.pivot_transform(grid, %{
  row_fields: [:region],        # 행 그룹 (다중 필드 가능)
  col_field: :quarter,          # 열 생성 기준 필드
  value_field: :revenue,        # 집계 대상 값 필드
  aggregate: :sum               # 집계 함수
})
```

### Config Options

| Option | Type | Description |
|--------|------|-------------|
| `row_fields` | `[atom]` | 행 그룹 필드 (다중 레벨) |
| `col_field` | `atom` | 열 생성 기준 필드 |
| `value_field` | `atom` | 집계 대상 값 |
| `aggregate` | `atom` | `:sum`, `:avg`, `:count`, `:min`, `:max` |

## Example

### Input Data

```elixir
data = [
  %{id: 1, region: "서울", quarter: "Q1", revenue: 1000},
  %{id: 2, region: "서울", quarter: "Q2", revenue: 1500},
  %{id: 3, region: "부산", quarter: "Q1", revenue: 800},
  %{id: 4, region: "부산", quarter: "Q2", revenue: 1200}
]
```

### Output (Pivot)

| Region | Q1 | Q2 |
|--------|------|------|
| 서울 | 1,000 | 1,500 |
| 부산 | 800 | 1,200 |

- 열은 `col_field`의 고유 값에서 동적 생성
- 교차점은 `aggregate` 함수 결과

## Related

- [Grouping](./grouping.md) — 필드 기반 그룹핑
- [Tree Grid](./tree-grid.md) — 계층 데이터
- [Summary Row](./summary-row.md) — 전체 집계
