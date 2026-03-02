# Suppress (Duplicate Value Merge)

연속된 행에서 동일한 값이 반복될 때 중복 셀을 숨겨서 가독성을 높입니다.

## Overview

Suppress는 정렬된 데이터에서 같은 값이 연속으로 나타날 때 두 번째 이후의 셀 값을 숨기는 기능입니다. 보고서나 그룹 데이터 표시에 효과적입니다.

```
| 도시  | 이름    | 나이 |        | 도시  | 이름    | 나이 |
|------|---------|------|  →     |------|---------|------|
| 서울  | Alice   |  28  |        | 서울  | Alice   |  28  |
| 서울  | Bob     |  35  |        |       | Bob     |  35  |  ← 서울 숨김
| 부산  | Carol   |  31  |        | 부산  | Carol   |  31  |
| 부산  | David   |  42  |        |       | David   |  42  |  ← 부산 숨김
```

## Enabling Suppress

컬럼 정의에 `suppress: true`를 지정합니다:

```elixir
columns = [
  %{field: :city, label: "도시", sortable: true, suppress: true},
  %{field: :name, label: "이름"},
  %{field: :age, label: "나이"}
]
```

도시 컬럼을 기준으로 정렬하면 동일한 도시명이 자동으로 숨겨집니다.

## Multiple Columns

여러 컬럼에 동시에 suppress를 적용할 수 있습니다:

```elixir
columns = [
  %{field: :department, label: "부서", suppress: true},
  %{field: :team, label: "팀", suppress: true},
  %{field: :name, label: "이름"}
]
```

## Behavior

- **첫 번째 행**: 항상 값을 표시합니다
- **이후 행**: 바로 위 행과 동일한 값이면 셀을 비웁니다
- **다른 값**: 새로운 값이 나타나면 다시 표시합니다
- **정렬 연동**: 정렬 변경 시 suppress가 자동 재계산됩니다

## CSS Classes

| 클래스 | 적용 대상 |
|--------|----------|
| `.lv-grid__cell--suppressed` | 숨겨진 셀 |

숨겨진 셀은 `border-top-color: transparent`가 적용되어 연속된 영역처럼 보입니다.

## Programmatic API

RenderHelpers에서 suppress 관련 함수를 제공합니다:

```elixir
# 특정 셀이 suppress 대상인지 확인
RenderHelpers.suppress_cell?(%{suppress: true, field: :city}, current_row, prev_row)

# 전체 suppress 맵 생성
suppress_map = RenderHelpers.build_suppress_map(rows, columns)

# 특정 셀 확인
RenderHelpers.suppressed?(suppress_map, row_id, :city)
```

## Related

- [Sorting](./sorting.md) — 정렬과 suppress 조합
- [Cell Merge](./cell-merge.md) — 셀 병합 (다른 방식의 그룹 표시)
- [Grouping](./grouping.md) — 데이터 그룹핑
