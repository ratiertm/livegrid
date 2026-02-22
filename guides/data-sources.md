# Data Sources

LiveView Grid는 플러거블 DataSource 패턴으로 다양한 데이터 백엔드를 지원합니다.

## InMemory (기본)

데이터를 Elixir 리스트로 직접 전달합니다. `data_source` 옵션 없이 사용하면 자동 적용됩니다.

```elixir
grid = Grid.new(
  data: [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}],
  columns: columns
)
```

정렬, 필터, 페이지네이션 모두 Elixir `Enum` 모듈로 서버 메모리에서 처리됩니다.

## Ecto (DB 연동)

Ecto 쿼리 기반으로 정렬/필터/페이지네이션을 SQL에 위임합니다.

### 설정

```elixir
grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.Ecto, %{
    repo: MyApp.Repo,
    schema: MyApp.User
  }}
)
```

### base_query 옵션

기본 쿼리에 조건을 추가할 수 있습니다:

```elixir
import Ecto.Query

grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.Ecto, %{
    repo: MyApp.Repo,
    base_query: from(u in MyApp.User, where: u.active == true)
  }}
)
```

### CRUD

Ecto adapter는 `INSERT`, `UPDATE`, `DELETE`를 자동으로 DB에 반영합니다:
- `insert_row/2` → `Repo.insert/1`
- `update_row/3` → `Repo.update/1` (Changeset 기반)
- `delete_row/2` → `Repo.delete/1`

## REST API

외부 REST API에서 데이터를 가져옵니다.

### 기본 설정

```elixir
grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.Rest, %{
    base_url: "https://api.example.com",
    endpoint: "/users"
  }}
)
```

### 인증 헤더

```elixir
data_source: {LiveViewGrid.DataSource.Rest, %{
  base_url: "https://api.example.com",
  endpoint: "/users",
  headers: %{
    "Authorization" => "Bearer eyJhbG...",
    "X-Api-Key" => "lvg_abc123..."
  }
}}
```

### 응답 매핑

API 응답 구조가 다른 경우 매핑을 커스터마이즈합니다:

```elixir
data_source: {LiveViewGrid.DataSource.Rest, %{
  base_url: "https://api.example.com",
  endpoint: "/users",
  response_mapping: %{
    data_key: "results",        # rows가 담긴 키 (기본: "data")
    total_key: "total_count",   # 전체 건수 키 (기본: "total")
    filtered_key: "filtered"    # 필터된 건수 (기본: "filtered")
  },
  query_mapping: %{
    page: "page",               # 페이지 파라미터명
    page_size: "per_page",      # 페이지 사이즈 파라미터명
    sort_field: "sort_by",      # 정렬 필드 파라미터명
    sort_direction: "order"     # 정렬 방향 파라미터명
  }
}}
```

### 에러 핸들링

REST adapter는 자동 재시도를 지원합니다:
- HTTP 408, 429, 500, 502, 503, 504 → 자동 재시도 (최대 3회)
- 지수 백오프 (1초, 2초, 3초)
- 타임아웃 기본 10초

```elixir
request_opts: %{
  timeout: 15_000,    # 15초 타임아웃
  retry: 5,           # 최대 5회 재시도
  retry_delay: 2_000  # 재시도 간격 2초
}
```

## 커스텀 DataSource 구현

`LiveViewGrid.DataSource` behaviour를 구현하면 어떤 백엔드든 연결 가능합니다:

```elixir
defmodule MyApp.GraphQLDataSource do
  @behaviour LiveViewGrid.DataSource

  @impl true
  def fetch_data(config, state, options, columns) do
    # GraphQL 쿼리 실행
    {rows, total_count, filtered_count}
  end

  @impl true
  def insert_row(config, row), do: # ...

  @impl true
  def update_row(config, row_id, changes), do: # ...

  @impl true
  def delete_row(config, row_id), do: # ...
end
```

필수 콜백:
- `fetch_data/4` → `{rows, total_count, filtered_count}`
- `insert_row/2` → `{:ok, row}` | `{:error, reason}`
- `update_row/3` → `{:ok, row}` | `{:error, reason}`
- `delete_row/2` → `:ok` | `{:error, reason}`

선택 콜백:
- `partial_update_row/3` (PATCH) → 미구현 시 `update_row/3`으로 대체
