# F-300: DBMS Integration - Design

> **Feature Code**: F-300
> **Version**: v0.3
> **Created**: 2026-02-21

---

## 1. Architecture

```
┌─────────────┐     ┌──────────────────┐
│  Grid.new() │────▶│  DataSource      │
│             │     │  Behaviour       │
└─────────────┘     └──────┬───────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
       ┌──────────┐ ┌──────────┐ ┌──────────┐
       │ InMemory │ │  Ecto    │ │ Custom   │
       │ Adapter  │ │ Adapter  │ │ Adapter  │
       └──────────┘ └──────────┘ └──────────┘
            │             │
      Enum pipeline  Ecto.Query
```

## 2. DataSource Behaviour

```elixir
@callback fetch_data(config, state, options, columns) :: {rows, total, filtered}
@callback insert_row(config, row_data) :: {:ok, row} | {:error, any}
@callback update_row(config, row_id, changes) :: {:ok, row} | {:error, any}
@callback delete_row(config, row_id) :: :ok | {:error, any}
```

## 3. Grid Struct Extension

```elixir
%{
  id: "grid_xxx",
  data: [...],
  columns: [...],
  state: %{...},
  options: %{...},
  data_source: {module, config}  # NEW - nil for InMemory
}
```

## 4. InMemory Adapter

- Wraps existing `Filter`, `Sorting`, `Pagination` modules
- Config: `%{data: [list of maps]}`
- fetch_data: global_search → filters → advanced_filters → sort → pagination
- CRUD: pass-through (Grid handles data mutations)

## 5. Ecto Adapter

- Config: `%{repo: Repo, schema: Schema, base_query: optional}`
- Uses QueryBuilder to convert Grid state → Ecto.Query
- fetch_data: 3 queries (total count, filtered count, paginated rows)
- CRUD: Repo.insert/update/delete with changeset

## 6. QueryBuilder

### Supported Operators
| Category | Operators | SQL Translation |
|----------|-----------|-----------------|
| Text filter | LIKE contains | `WHERE CAST(col AS TEXT) LIKE '%term%'` |
| Number filter | >, <, >=, <=, =, != | `WHERE col > N` |
| Global search | LIKE across all columns | `WHERE col1 LIKE '%q%' OR col2 LIKE ...` |
| Advanced - text | contains, equals, starts_with, ends_with, is_empty, is_not_empty | Dynamic WHERE |
| Advanced - number | eq, neq, gt, lt, gte, lte | Dynamic WHERE |
| Sort | asc, desc | `ORDER BY col ASC/DESC` |
| Pagination | limit/offset | `LIMIT N OFFSET M` |

### Number Parsing
- Integer-first: `Integer.parse("30")` → `30` (not `30.0`)
- Fallback to Float: `Float.parse("3.14")` → `3.14`
- This prevents Ecto CastError for integer columns

## 7. Demo Application

- Database: SQLite3 (`ecto_sqlite3`)
- Schema: `demo_users` (name, email, department, age, salary, status, join_date)
- Seeds: 1000 random Korean user records
- Page: `/dbms-demo` with full Grid + CRUD controls

## 8. File Structure

```
lib/liveview_grid/
  data_source.ex           # Behaviour
  data_source/
    in_memory.ex           # InMemory adapter
    ecto.ex                # Ecto adapter
    ecto/
      query_builder.ex     # Grid state → Ecto.Query
  repo.ex                  # Demo Repo
  demo_user.ex             # Demo Schema
```

## 9. Test Scenarios

| ID | Test | Expected |
|----|------|----------|
| T-01 | InMemory fetch_data (no filters) | All rows returned |
| T-02 | InMemory global search | Filtered rows only |
| T-03 | InMemory sort + pagination | Correct order and page |
| T-04 | Ecto fetch_data (no filters) | SQL COUNT + SELECT |
| T-05 | Ecto global search | LIKE query |
| T-06 | Ecto column filter (text) | WHERE LIKE |
| T-07 | Ecto column filter (number) | WHERE >/</= |
| T-08 | Ecto advanced filters AND | Combined WHERE |
| T-09 | Ecto advanced filters OR | OR WHERE |
| T-10 | Ecto sort asc/desc | ORDER BY |
| T-11 | Ecto pagination | LIMIT OFFSET |
| T-12 | Ecto insert_row | INSERT |
| T-13 | Ecto update_row | UPDATE |
| T-14 | Ecto delete_row | DELETE |
| T-15 | Grid.new backward compat | No data_source = InMemory |
| T-16 | Grid.new with data_source | Ecto adapter activated |
