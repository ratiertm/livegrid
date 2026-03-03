# Frozen Rows

특정 행을 상단에 고정하여 스크롤해도 항상 보이게 합니다.

## Overview

Frozen Row는 합계행, 기준행 등 항상 보여야 하는 행을 Grid 상단에 고정하는 기능입니다. 수직 스크롤 시에도 고정 행은 항상 표시됩니다.

## Enabling Frozen Rows

`options`에 `frozen_rows`를 지정합니다:

```elixir
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="my-grid"
  data={@data}
  columns={@columns}
  options={%{
    frozen_rows: 2  # 상위 2행 고정
  }}
/>
```

## Behavior

- 지정된 수만큼의 **상위 행**이 고정됩니다
- 고정 행은 수직 스크롤 시에도 항상 보입니다
- 고정 행과 일반 행 사이에 시각적 구분선이 표시됩니다
- 정렬/필터 후에도 고정 행 수는 유지됩니다
- `frozen_rows: 0`이면 고정 해제됩니다

## Frozen Rows vs Frozen Columns

| 기능 | 방향 | 옵션 |
|------|------|------|
| Frozen Rows | 수평 (상단 고정) | `frozen_rows: N` |
| Frozen Columns | 수직 (좌/우측 고정) | `frozen_columns: N` |

두 기능을 동시에 사용할 수 있습니다.

## CSS Classes

| 클래스 | 적용 대상 |
|--------|----------|
| `.lv-grid__row--frozen` | 고정된 행 |

## Related

- [Frozen Columns](./frozen-columns.md) — 좌/우측 컬럼 고정
- [Summary Row](./summary-row.md) — 합계행 (하단 고정)
- [Row Data](./row-data.md) — 행 데이터 바인딩
- [Grid Options](./grid-options.md) — 그리드 옵션
