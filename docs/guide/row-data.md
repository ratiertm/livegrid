# Row Data

이 섹션에서는 Grid에 데이터를 제공하는 방법과 Row ID 관리를 설명합니다.

## Overview

Grid는 리스트-of-맵 형태의 데이터를 받습니다. 각 행(row)은 `id` 필드를 가져야 하며, 이 값으로 행을 고유하게 식별합니다.

## Providing Row Data

`data` 속성에 맵 리스트를 전달합니다:

```elixir
data = [
  %{id: 1, name: "Alice", email: "alice@example.com"},
  %{id: 2, name: "Bob", email: "bob@example.com"},
  %{id: 3, name: "Carol", email: "carol@example.com"}
]

<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="my-grid"
  data={data}
  columns={columns}
  options={%{}}
/>
```

## Row IDs

모든 행은 고유한 `id` 필드를 가져야 합니다. Grid는 이 ID를 기반으로:

- 행 선택(selection) 상태 추적
- 편집(editing) 대상 식별
- CRUD 작업 시 행 매핑
- Virtual Scroll에서 DOM 재사용

```elixir
# 권장: 데이터베이스 PK 또는 고유 식별자
%{id: 1, name: "Alice"}
%{id: "uuid-abc-123", name: "Bob"}
```

### Temporary IDs

새 행을 추가할 때 Grid는 자동으로 임시 ID를 생성합니다:

```elixir
grid = Grid.add_row(grid, %{name: "", email: ""})
# 임시 ID: "temp_1", "temp_2", ...
```

임시 ID는 서버에 저장할 때 실제 ID로 대체됩니다.

## Updating Data

데이터가 변경되면 LiveView의 `assign`을 통해 Grid에 반영됩니다. Grid는 `update/2` 콜백에서 기존 상태(정렬, 필터, 페이지)를 보존하면서 데이터만 갱신합니다:

```elixir
# LiveView에서 데이터 갱신
def handle_info(:refresh, socket) do
  users = fetch_users()
  {:noreply, assign(socket, users: users)}
end
```

## Data Size Considerations

| Data Size | Recommended Mode | 설명 |
|-----------|-----------------|------|
| ~ 1,000행 | Pagination | 기본 모드, 페이지 단위 렌더링 |
| ~ 10,000행 | Virtual Scroll | viewport 영역만 DOM 생성 |
| 10,000행+ | DataSource (Ecto/REST) | 서버사이드 처리 위임 |

```elixir
# Virtual Scroll 활성화
options = %{virtual_scroll: true, row_height: 40}
```

## Row Status Tracking

Grid는 각 행의 변경 상태를 추적합니다:

| Status | 설명 | 시각적 표시 |
|--------|------|-------------|
| `:normal` | 변경 없음 | - |
| `:new` | 새로 추가된 행 | 초록색 좌측 바 |
| `:updated` | 수정된 행 | 주황색 좌측 바 |
| `:deleted` | 삭제 대기 행 | 빨간색 취소선 |

```elixir
# 변경된 행 조회
Grid.changed_rows(grid)
# => [%{row: %{id: 1, ...}, status: :updated}, ...]

# 미저장 변경 확인
Grid.has_changes?(grid)
# => true
```

## Related

- [Column Definitions](./column-definitions.md) — 컬럼 속성 설정
- [Data Sources](./data-sources.md) — Ecto/REST 외부 데이터
- [CRUD Operations](./crud-operations.md) — 행 추가/수정/삭제
