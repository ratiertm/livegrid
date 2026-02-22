# Formatters

Formatters transform the **text display format** of cell values.
Unlike Renderers (which change HTML structure), Formatters only transform plain text.

## Basic Usage

Specify the `formatter` option in your column definition:

```elixir
columns = [
  %{field: :salary, label: "Salary", formatter: :currency},
  %{field: :rate, label: "Rate", formatter: :percent},
  %{field: :created_at, label: "Created", formatter: :date}
]
```

## Available Formatters

### Number / Currency

| Formatter | Input | Output | Description |
|-----------|-------|--------|-------------|
| `:number` | `75000000` | `"75,000,000"` | Thousands separator |
| `:currency` | `75000000` | `"₩75,000,000"` | Korean Won format |
| `:dollar` | `1500.5` | `"$1,500.50"` | US Dollar format |
| `:percent` | `0.856` | `"85.6%"` | Percentage (0~1 to 0~100%) |

**With options (Tuple syntax):**

```elixir
# Japanese Yen (no decimals)
%{field: :price, formatter: {:currency, symbol: "¥", precision: 0}}

# Euro
%{field: :price, formatter: {:currency, symbol: "EUR ", position: :prefix}}

# Number with 2 decimal places
%{field: :score, formatter: {:number, precision: 2}}

# Percent with 2 decimal places
%{field: :rate, formatter: {:percent, precision: 2}}
```

### Date / Time

| Formatter | Input | Output |
|-----------|-------|--------|
| `:date` | `~D[2026-02-22]` | `"2026-02-22"` |
| `:datetime` | `~N[2026-02-22 14:30:00]` | `"2026-02-22 14:30:00"` |
| `:time` | `~T[14:30:00]` | `"14:30:00"` |
| `:relative_time` | `~U[2026-02-20 00:00:00Z]` | `"2 days ago"` |

**Custom date format:**

```elixir
%{field: :date, formatter: {:date, "YYYY/MM/DD"}}
%{field: :date, formatter: {:date, "MM-DD"}}
%{field: :dt, formatter: {:datetime, "YYYY.MM.DD HH:mm"}}
```

### Text

| Formatter | Input | Output |
|-----------|-------|--------|
| `:uppercase` | `"hello"` | `"HELLO"` |
| `:lowercase` | `"HELLO"` | `"hello"` |
| `:capitalize` | `"hello world"` | `"Hello World"` |
| `:truncate` | `"A very long text..."` | `"A very long te..."` (50 chars) |

```elixir
# Truncate to 30 characters max
%{field: :desc, formatter: {:truncate, 30}}
```

### Other

| Formatter | Input | Output |
|-----------|-------|--------|
| `:boolean` | `true` / `false` | `"Yes"` / `"No"` |
| `:filesize` | `1048576` | `"1.0 MB"` |
| `:mask` | `"01012345678"` | `"010-****-5678"` |

**Masking patterns:**

```elixir
# Auto-detect (phone number, email, etc.)
%{field: :phone, formatter: :mask}

# Force phone number pattern
%{field: :phone, formatter: {:mask, :phone}}

# Email masking
%{field: :email, formatter: {:mask, :email}}

# Credit card masking
%{field: :card, formatter: {:mask, :card}}
```

**Custom boolean labels:**

```elixir
%{field: :active, formatter: {:boolean, true_label: "Active", false_label: "Inactive"}}
%{field: :active, formatter: {:boolean, true_label: "O", false_label: "X"}}
```

## Custom Function Formatter

Pass a function for fully custom formatting:

```elixir
%{field: :score, formatter: fn val ->
  cond do
    val >= 90 -> "A (#{val})"
    val >= 80 -> "B (#{val})"
    val >= 70 -> "C (#{val})"
    true -> "F (#{val})"
  end
end}
```

## Direct Usage

You can also call `LiveViewGrid.Formatter.format/2` directly:

```elixir
Formatter.format(75000000, :currency)     # => "₩75,000,000"
Formatter.format(0.856, :percent)         # => "85.6%"
Formatter.format(1500.5, {:currency, symbol: "$", precision: 2})  # => "$1,500.50"
```
