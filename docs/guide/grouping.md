# Grouping

다중 레벨 그룹핑으로 데이터를 계층적으로 분류하고, 그룹별 집계(합계, 평균 등)를 표시합니다.

## Overview

그룹핑은 하나 이상의 필드를 기준으로 행을 그룹화합니다. 각 그룹은 접기/펼치기가 가능하며, 집계 함수를 통해 그룹별 통계를 표시합니다.

## Enabling Grouping

```elixir
# 단일 필드 그룹핑
grid = Grid.set_group_by(grid, [:department])

# 다중 레벨 그룹핑
grid = Grid.set_group_by(grid, [:department, :team])
```

## Aggregates

그룹별 집계 함수를 설정합니다:

```elixir
grid = Grid.set_group_aggregates(grid, %{
  salary: :sum,
  age: :avg,
  employees: :count
})
```

### Supported Functions

| Function | 설명 | 예시 |
|----------|------|------|
| `:sum` | 합계 | 급여 합계 |
| `:avg` | 평균 | 나이 평균 |
| `:count` | 건수 | 직원 수 |
| `:min` | 최소값 | 최저 급여 |
| `:max` | 최대값 | 최고 급여 |

## Expand / Collapse

```elixir
# 그룹 접기/펼치기
grid = Grid.toggle_group(grid, "개발팀")
```

- 헤더 행의 ▶ / ▼ 아이콘 클릭
- 기본: 모든 그룹 펼침 상태

## Visual Structure

```
▼ 개발팀 (3명)                    Sum: 15,300,000  Avg: 31
  Alice  | Dev  | 5,000,000 | 28
  Bob    | Dev  | 4,200,000 | 35
  Carol  | Dev  | 6,100,000 | 31
▶ 영업팀 (2명)                    Sum: 8,500,000   Avg: 33
  (collapsed)
```

## Related

- [Summary Row](./summary-row.md) — 전체 데이터 집계 행
- [Tree Grid](./tree-grid.md) — 계층 데이터 표현
- [Pivot Table](./pivot-table.md) — 피벗 변환
