# Realtime Collaboration

Phoenix PubSub + Presence를 이용한 실시간 멀티유저 동기화 기능입니다.

## Overview

여러 사용자가 같은 Grid를 동시에 편집할 때, 셀 변경·행 추가·삭제가 실시간으로 동기화됩니다. 현재 접속 중인 사용자 목록과 편집 중인 셀 위치도 공유됩니다.

## Enabling Collaboration

LiveView의 `mount`에서 PubSub을 구독합니다:

```elixir
def mount(_params, _session, socket) do
  grid_id = "shared-grid"

  if connected?(socket) do
    LiveviewGrid.PubSubBridge.subscribe(grid_id)

    LiveviewGrid.GridPresence.track_user(
      self(),
      grid_id,
      socket.assigns.current_user.id,
      %{name: socket.assigns.current_user.name}
    )
  end

  {:ok, assign(socket, grid_id: grid_id)}
end
```

## PubSubBridge API

셀/행 변경을 다른 사용자에게 브로드캐스트합니다:

```elixir
# 셀 업데이트 브로드캐스트
PubSubBridge.broadcast_cell_update(grid_id, row_id, :name, "Alice", self())

# 행 추가 브로드캐스트
PubSubBridge.broadcast_row_added(grid_id, %{id: 99, name: "New"}, self())

# 행 삭제 브로드캐스트
PubSubBridge.broadcast_rows_deleted(grid_id, [1, 2, 3], self())

# 저장 완료 브로드캐스트
PubSubBridge.broadcast_rows_saved(grid_id, self())

# 편집 중 상태 브로드캐스트
PubSubBridge.broadcast_user_editing(grid_id, row_id, :email, "Alice", self())
```

## GridPresence API

접속 사용자 추적:

```elixir
# 사용자 추적 시작
GridPresence.track_user(self(), grid_id, user_id, %{name: "Alice"})

# 편집 중 상태 업데이트
GridPresence.update_editing(self(), grid_id, user_id, %{row_id: 1, field: :name})

# 접속 사용자 목록
GridPresence.list_users(grid_id)
# => [%{user_id: "u1", name: "Alice", editing: %{row_id: 1, field: :name}}, ...]

# 접속 사용자 수
GridPresence.user_count(grid_id)
# => 3
```

## Receiving Events

`handle_info`에서 다른 사용자의 변경을 수신합니다:

```elixir
def handle_info({:grid_event, %{type: :cell_updated} = event}, socket) do
  if event.sender != self() do
    grid = Grid.update_cell(socket.assigns.grid, event.row_id, event.field, event.value)
    {:noreply, assign(socket, grid: grid)}
  else
    {:noreply, socket}
  end
end

def handle_info({:grid_event, %{type: :user_editing} = event}, socket) do
  # 다른 사용자의 편집 위치 표시
  {:noreply, socket}
end
```

## Event Types

| type | 설명 | 주요 필드 |
|------|------|----------|
| `:cell_updated` | 셀 값 변경 | `row_id`, `field`, `value` |
| `:row_added` | 행 추가 | `row` (map) |
| `:rows_deleted` | 행 삭제 | `row_ids` (list) |
| `:rows_saved` | 저장 완료 | - |
| `:user_editing` | 편집 위치 | `row_id`, `field`, `user_name` |

## Related

- [Cell Editing](./cell-editing.md) — 인라인 셀 편집
- [CRUD Operations](./crud-operations.md) — 행 추가/삭제/저장
- [Grid Options](./grid-options.md) — 그리드 설정
