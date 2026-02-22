# Getting Started

LiveView Grid is a full-featured data grid built on top of Phoenix LiveView.

## Installation

Add the dependency to your `mix.exs`:

```elixir
def deps do
  [
    {:liveview_grid, "~> 0.7"}
  ]
end
```

## Basic Usage

### 1. Create a Grid (in LiveView mount)

```elixir
defmodule MyAppWeb.UserLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    users = [
      %{id: 1, name: "Alice", age: 30, city: "Seoul"},
      %{id: 2, name: "Bob", age: 25, city: "Busan"},
      %{id: 3, name: "Charlie", age: 35, city: "Daegu"}
    ]

    columns = [
      %{field: :id, label: "ID", width: 60, sortable: true},
      %{field: :name, label: "Name", sortable: true, filterable: true, editable: true},
      %{field: :age, label: "Age", sortable: true, formatter: :number, align: :right},
      %{field: :city, label: "City", sortable: true,
        editable: true, editor_type: :select,
        editor_options: [{"Seoul", "Seoul"}, {"Busan", "Busan"}, {"Daegu", "Daegu"}]}
    ]

    grid = LiveViewGrid.Grid.new(
      data: users,
      columns: columns,
      options: %{page_size: 20, theme: "default"}
    )

    {:ok, assign(socket, grid: grid)}
  end
end
```

### 2. Use GridComponent in your template

```heex
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id={@grid.id}
  grid={@grid}
/>
```

That's it. Sorting, filtering, pagination, and inline cell editing all work out of the box.

## Column Definition

Each column is defined as a map with various options:

```elixir
%{
  # Required
  field: :name,           # Data field name (atom)
  label: "Name",          # Header display text

  # Layout
  width: 150,             # Column width (px or :auto)
  align: :left,           # Text alignment (:left, :center, :right)

  # Sort / Filter
  sortable: true,         # Enable sorting
  filterable: true,       # Enable filtering
  filter_type: :text,     # Filter type (:text, :number, :select, :date)

  # Editing
  editable: true,         # Enable inline cell editing
  editor_type: :text,     # Editor type (:text, :number, :select, :textarea, :date)
  editor_options: [],     # Options list for select editor

  # Validation
  validators: [
    {:required, "This field is required"},
    {:min_length, 2, "At least 2 characters"},
    {:max, 200, "Must be 200 or less"},
    {:pattern, ~r/@/, "Invalid email format"}
  ],

  # Display format
  formatter: :currency,   # Value formatter (atom, tuple, or function)
  renderer: :progress     # Custom cell renderer (atom, tuple, or function)
}
```

## Grid Options

```elixir
%{
  page_size: 20,           # Rows per page
  theme: "default",        # Theme ("default", "dark", "compact", "striped")
  virtual_scroll: false,   # Enable virtual scrolling
  row_height: 40,          # Row height in pixels
  frozen_columns: 0,       # Number of frozen columns (from left)
  show_header: true,       # Show header row
  show_footer: true        # Show footer (pagination)
}
```

## Next Steps

- `LiveViewGrid.Formatter` - Cell value formatters (number, currency, date, etc. - 16 types)
- `LiveViewGrid.Renderers` - Custom cell renderers (progress bar, badge, link)
- `LiveViewGrid.Export` - Excel/CSV export
- `LiveViewGrid.DataSource` - Data sources (InMemory, Ecto, REST API)
