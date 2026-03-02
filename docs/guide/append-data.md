# Append Data (Dataset Merge)

외부 데이터를 현재 Grid 데이터에 병합(추가)합니다.

## Overview

`Grid.append_data/2`를 사용하면 기존 데이터 뒤에 새 행들을 추가할 수 있습니다. 무한 스크롤, 데이터 로드 추가, 외부 데이터 병합 등에 활용됩니다.

## Usage

```elixir
# 새 데이터 추가
new_rows = [
  %{id: 101, name: "New User 1", email: "new1@example.com"},
  %{id: 102, name: "New User 2", email: "new2@example.com"}
]

grid = Grid.append_data(grid, new_rows)
```

## Behavior

- 새 행들이 기존 데이터의 **끝**에 추가됩니다
- 빈 리스트를 전달하면 데이터가 변경되지 않습니다
- ID 중복 검사는 수행되지 않습니다 (호출자 책임)
- 추가 후 정렬/필터가 적용 중이면 자동 재계산됩니다

## Use Cases

### 무한 스크롤

```elixir
def handle_event("load_more", _params, socket) do
  next_page = fetch_next_page(socket.assigns.page + 1)
  grid = Grid.append_data(socket.assigns.grid, next_page)
  {:noreply, assign(socket, grid: grid, page: socket.assigns.page + 1)}
end
```

### 외부 데이터 병합

```elixir
# API에서 가져온 데이터 병합
api_data = MyApp.ExternalApi.fetch_users()
grid = Grid.append_data(grid, api_data)
```

## Related

- [Row Data](./row-data.md) — 데이터 제공 방식
- [Data Sources](./data-sources.md) — InMemory, Ecto, REST
- [CRUD Operations](./crud-operations.md) — 행 추가/수정/삭제
