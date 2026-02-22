# Advanced Features

## CRUD (Add / Edit / Delete Rows)

The Grid tracks row states to manage changes.

### Row States

| State | Badge | Description |
|-------|-------|-------------|
| `:normal` | (none) | No changes |
| `:new` | N | Newly added row |
| `:updated` | U | Modified row |
| `:deleted` | D | Marked for deletion |

### Workflow

```elixir
# Add a new row (at the top)
grid = Grid.add_row(grid, %{name: "", email: ""})

# Update a cell value
grid = Grid.update_cell(grid, row_id, :name, "Alice")

# Run validation
grid = Grid.validate_cell(grid, row_id, :name)

# Mark rows for deletion
grid = Grid.delete_rows(grid, [row_id])

# Get all changes
changes = Grid.changed_rows(grid)
# => [%{row: %{id: -1, name: "Alice"}, status: :new}, ...]

# Check if there are any changes
Grid.has_changes?(grid)  # => true
```

### Validators

```elixir
validators: [
  {:required, "This field is required"},
  {:min, 0, "Must be 0 or greater"},
  {:max, 100, "Must be 100 or less"},
  {:min_length, 2, "At least 2 characters required"},
  {:max_length, 50, "Must be 50 characters or less"},
  {:pattern, ~r/@/, "Invalid email format"},
  {:custom, &MyValidator.check/1, "Validation failed"}
]
```

## Renderers (Custom Cell Renderers)

Renderers change the HTML structure of a cell (Formatters only change text).

### Progress Bar

```elixir
%{field: :progress, label: "Progress",
  renderer: LiveViewGrid.Renderers.progress(
    max: 100, color: "blue", show_value: true
  )}
```

### Badge

```elixir
%{field: :status, label: "Status",
  renderer: LiveViewGrid.Renderers.badge(
    colors: %{"active" => "green", "inactive" => "red"}
  )}
```

### Link

```elixir
%{field: :email, label: "Email",
  renderer: LiveViewGrid.Renderers.link(prefix: "mailto:", target: "_blank")}
```

### Custom Renderer (Function)

```elixir
%{field: :avatar, label: "Avatar",
  renderer: fn row, _column, _assigns ->
    assigns = %{url: row.avatar_url}
    ~H|<img src={@url} class="w-8 h-8 rounded-full" />|
  end}
```

## Export (Excel / CSV)

```elixir
# Excel
{:ok, {_filename, xlsx_binary}} = LiveViewGrid.Export.to_xlsx(data, columns)

# CSV (includes UTF-8 BOM for Excel compatibility)
csv_string = LiveViewGrid.Export.to_csv(data, columns)

# With options
{:ok, {_, binary}} = Export.to_xlsx(data, columns,
  sheet_name: "User List",
  header_style: true
)
```

The GridComponent provides an "Export" button automatically.

## Grouping

Group data by one or more fields with aggregate calculations.

```elixir
grid = grid
  |> Grid.set_group_by([:department, :team])
  |> Grid.set_group_aggregates(%{
    salary: :sum,
    age: :avg,
    id: :count
  })
```

### Aggregate Functions

| Function | Description |
|----------|-------------|
| `:sum` | Sum of values |
| `:avg` | Average |
| `:count` | Count of rows |
| `:min` | Minimum value |
| `:max` | Maximum value |

Click a group header to expand/collapse it.

## Tree Grid

Displays hierarchical data based on `parent_id` relationships.

```elixir
# Data (parent_id: nil means root node)
data = [
  %{id: 1, name: "HQ", parent_id: nil},
  %{id: 2, name: "Engineering", parent_id: 1},
  %{id: 3, name: "Frontend", parent_id: 2}
]

grid = Grid.set_tree_mode(grid, true, :parent_id)
```

Click the arrow icon on a tree node to expand/collapse it.

## Pivot Table

Cross-tabulate data by row and column dimensions.

```elixir
{columns, rows} = Grid.pivot_transform(grid, %{
  row_fields: [:department],   # Row dimension
  col_field: :quarter,         # Column dimension (unique values become dynamic columns)
  value_field: :revenue,       # Value field to aggregate
  aggregate: :sum              # Aggregate function
})
```

Example output:

| department | Q1 | Q2 | Q3 | Q4 | Total |
|-----------|-----|-----|-----|-----|-------|
| Engineering | 50M | 45M | 48M | 52M | 195M |
| Marketing | 30M | 35M | 32M | 38M | 135M |

## Virtual Scroll

Viewport-based partial rendering for large datasets (10,000+ rows):

```elixir
options: %{
  virtual_scroll: true,
  row_height: 40,          # Row height (must be exact)
  viewport_height: 600,    # Viewport height
  virtual_buffer: 5        # Buffer rows (above/below)
}
```

## Themes

```elixir
# Built-in themes
options: %{theme: "default"}  # Default light theme
options: %{theme: "dark"}     # Dark mode
options: %{theme: "compact"}  # Compact spacing
options: %{theme: "striped"}  # Striped rows
```
