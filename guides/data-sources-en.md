# Data Sources

LiveView Grid supports multiple data backends through a pluggable DataSource pattern.

## InMemory (Default)

Pass data directly as an Elixir list. This is the default when no `data_source` option is set.

```elixir
grid = Grid.new(
  data: [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}],
  columns: columns
)
```

Sorting, filtering, and pagination are all processed in server memory using Elixir's `Enum` module.

## Ecto (Database)

Delegates sorting, filtering, and pagination to SQL queries via Ecto.

### Setup

```elixir
grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.Ecto, %{
    repo: MyApp.Repo,
    schema: MyApp.User
  }}
)
```

### base_query Option

You can add conditions to the base query:

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

The Ecto adapter automatically persists changes to the database:
- `insert_row/2` maps to `Repo.insert/1`
- `update_row/3` maps to `Repo.update/1` (Changeset-based)
- `delete_row/2` maps to `Repo.delete/1`

## REST API

Fetches data from external REST APIs.

### Basic Setup

```elixir
grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.Rest, %{
    base_url: "https://api.example.com",
    endpoint: "/users"
  }}
)
```

### Authentication Headers

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

### Response Mapping

Customize the mapping when your API response structure differs from the default:

```elixir
data_source: {LiveViewGrid.DataSource.Rest, %{
  base_url: "https://api.example.com",
  endpoint: "/users",
  response_mapping: %{
    data_key: "results",        # Key containing rows (default: "data")
    total_key: "total_count",   # Total count key (default: "total")
    filtered_key: "filtered"    # Filtered count key (default: "filtered")
  },
  query_mapping: %{
    page: "page",               # Page parameter name
    page_size: "per_page",      # Page size parameter name
    sort_field: "sort_by",      # Sort field parameter name
    sort_direction: "order"     # Sort direction parameter name
  }
}}
```

### Error Handling

The REST adapter supports automatic retries:
- HTTP 408, 429, 500, 502, 503, 504 trigger auto-retry (up to 3 times)
- Exponential backoff (1s, 2s, 3s)
- Default timeout: 10 seconds

```elixir
request_opts: %{
  timeout: 15_000,    # 15 second timeout
  retry: 5,           # Max 5 retries
  retry_delay: 2_000  # 2 second retry interval
}
```

## Custom DataSource

Implement the `LiveViewGrid.DataSource` behaviour to connect any backend:

```elixir
defmodule MyApp.GraphQLDataSource do
  @behaviour LiveViewGrid.DataSource

  @impl true
  def fetch_data(config, state, options, columns) do
    # Execute GraphQL query
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

Required callbacks:
- `fetch_data/4` returns `{rows, total_count, filtered_count}`
- `insert_row/2` returns `{:ok, row}` | `{:error, reason}`
- `update_row/3` returns `{:ok, row}` | `{:error, reason}`
- `delete_row/2` returns `:ok` | `{:error, reason}`

Optional callbacks:
- `partial_update_row/3` (PATCH) - falls back to `update_row/3` if not implemented
