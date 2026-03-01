# State Persistence (상태 저장/복원)

Grid 상태를 JSON으로 직렬화하여 localStorage 또는 서버에 저장하고, 페이지 새로고침 후 자동 복원합니다.

## Overview

State Persistence는 두 가지 레벨로 동작합니다:

1. **Column State** (FA-016): 컬럼 너비, 순서, 숨김 상태만 저장/복원
2. **Grid State** (FA-002): 전체 Grid 상태(정렬, 필터, 그룹핑 등) 저장/복원

## Column State Save/Restore

컬럼 관련 상태만 경량으로 저장합니다.

### 프로그래밍 API

```elixir
# 컬럼 상태 추출
column_state = Grid.export_column_state(grid)
# => %{
#   column_widths: %{name: 150, email: 250},
#   column_order: [:name, :email, :age],
#   hidden_columns: [:created_at]
# }

# 컬럼 상태 복원
grid = Grid.import_column_state(grid, column_state)
```

### 유효성 검증

`import_column_state/2`는 현재 Grid에 존재하는 컬럼 필드만 적용합니다:
- 삭제된 컬럼 필드는 자동 무시
- 새로 추가된 컬럼은 기본값 유지

## Grid State Save/Restore

전체 Grid 상태를 localStorage에 자동 저장/복원합니다.

### 사용법

```elixir
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="my-grid"
  data={@data}
  columns={@columns}
  options={%{state_persistence: true}}
/>
```

`state_persistence: true`를 설정하면:
1. Grid 상태 변경 시 자동으로 localStorage에 저장
2. 페이지 로드 시 저장된 상태가 있으면 자동 복원

### Persistable State Keys

저장되는 상태 (14개):

| Key | Description |
|-----|-------------|
| `sort` | 정렬 설정 |
| `filters` | 컬럼 필터 |
| `global_search` | 전체 검색어 |
| `show_filter_row` | 필터 행 표시 |
| `advanced_filters` | 고급 필터 |
| `column_widths` | 컬럼 너비 |
| `column_order` | 컬럼 순서 |
| `hidden_columns` | 숨겨진 컬럼 |
| `group_by` | 그룹핑 기준 |
| `group_aggregates` | 그룹 집계 |
| `pinned_top_ids` | 상단 고정 행 |
| `pinned_bottom_ids` | 하단 고정 행 |
| `show_status_column` | 상태 컬럼 표시 |
| `pagination` | 현재 페이지 |

### 저장되지 않는 상태 (Transient)

편집 중인 셀, 선택 영역, 스크롤 위치, 오버레이 등 일시적 상태는 저장하지 않습니다.

### 프로그래밍 API

```elixir
# Grid 상태 추출 (atom → string 변환 포함)
state_map = Grid.save_state(grid)

# Grid 상태 복원 (string → atom 변환 + 유효성 검증)
grid = Grid.restore_state(grid, state_map)

# JSON 직렬화/역직렬화
json = LiveViewGrid.StatePersistence.serialize(state_map)
{:ok, state_map} = LiveViewGrid.StatePersistence.deserialize(json)
```

### localStorage 키 형식

저장 키: `lv-grid-state-{grid-id}`

```javascript
// 예: lv-grid-state-my-grid
localStorage.getItem("lv-grid-state-my-grid")
```

## Related

- [Grid Options](./grid-options.md) -- state_persistence 옵션
- [Column Definitions](./column-definitions.md) -- 컬럼 속성
- [Filtering](./filtering.md) -- 필터 상태
- [Sorting](./sorting.md) -- 정렬 상태
