# Cell Merge

셀을 가로(colspan) 또는 세로(rowspan)로 병합하여 데이터를 시각적으로 그룹화합니다.

## Overview

Cell Merge는 인접한 셀을 하나의 큰 셀로 합쳐서 표시하는 기능입니다. 보고서 형태의 레이아웃이나 카테고리 그룹핑에 유용합니다.

```
| 이름         |  나이  | 도시 |
|-------------|--------|------|
| Alice Park  ← colspan=2 →  | 서울 |
| Bob   | 35             |      |
|       |← rowspan=2     | 부산 |
| Carol | (age 병합)      | 대구 |
```

## Enabling Cell Merge

`options`에 `merge_regions`를 지정합니다:

```elixir
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="my-grid"
  data={@data}
  columns={@columns}
  options={%{
    merge_regions: [
      %{row_id: 1, col_field: :name, colspan: 2},
      %{row_id: 3, col_field: :age, rowspan: 2}
    ]
  }}
/>
```

## Merge Spec

각 병합 영역은 다음 속성을 가집니다:

| 속성 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `row_id` | any | O | 병합 시작 행의 ID |
| `col_field` | atom | O | 병합 시작 컬럼 필드 |
| `rowspan` | integer | - | 세로 병합 행 수 (기본 1) |
| `colspan` | integer | - | 가로 병합 컬럼 수 (기본 1) |

## Programmatic API

코드에서 동적으로 병합을 제어할 수 있습니다:

```elixir
# 셀 병합
grid = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, colspan: 2})

# 셀 병합 해제
grid = Grid.unmerge_cells(grid, 1, :name)

# 모든 병합 해제
grid = Grid.clear_all_merges(grid)

# 병합 상태 조회
Grid.merged?(grid, 1, :name)
# => true

# 현재 병합 영역 목록
Grid.merge_regions(grid)
# => %{{1, :name} => %{rowspan: 1, colspan: 2}, ...}
```

## Overlap Prevention

같은 영역에 중복 병합을 시도하면 기존 병합이 유지됩니다. `Grid.merge_cells/2`는 겹침 검사를 수행하여 충돌 시 원본 Grid를 반환합니다.

## CSS Classes

| 클래스 | 적용 대상 |
|--------|----------|
| `.lv-grid__cell--merged` | 병합된 셀 (origin) |

병합된 셀은 자동으로 `overflow: visible`이 적용되어 내용이 잘리지 않습니다.

## Related

- [Column Definitions](./column-definitions.md) — 컬럼 필드 정의
- [Frozen Columns](./frozen-columns.md) — 고정 컬럼과 병합 조합
- [Grid Options](./grid-options.md) — merge_regions 옵션
