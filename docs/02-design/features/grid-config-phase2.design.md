# Design Document - Grid Configuration UI (Phase 2: Grid Settings)

**Status:** Design Phase
**Feature:** grid-config-phase2
**Version:** 1.0 (Phase 2 MVP)
**Last Updated:** 2026-02-26

---

## 1. Executive Summary

This document specifies the detailed design for **Phase 2: Grid Settings Configuration** - an extension of the existing Grid Configuration Modal that allows dynamic configuration of Grid-level options (page size, theme, virtual scroll, row height, frozen columns, and display toggles) without code changes.

**Phase 2 Scope:** Add Tab 4 to the existing ConfigModal with controls for all Grid-level options, building on the successful Phase 1 (Column Configuration) architecture.

**Design Goal:** Create an intuitive form-based interface for Grid settings that integrates seamlessly with the existing ConfigModal component and applies configuration changes live without page reload.

---

## 2. Architecture Overview

### 2.1 High-Level Component Structure

```
GridConfigModal (existing from Phase 1)
├── Tab 1: Column Visibility & Order (Phase 1)
├── Tab 2: Column Properties (Phase 1)
├── Tab 3: Formatters & Validators (Phase 1)
└── [NEW] Tab 4: Grid Settings (Phase 2)
    ├── [Section 1] Pagination Settings
    │   └── Page Size (number input)
    ├── [Section 2] Display Settings
    │   ├── Show Row Numbers (checkbox)
    │   ├── Show Header (checkbox)
    │   └── Show Footer (checkbox)
    ├── [Section 3] Theme Settings
    │   └── Theme (select: light, dark, custom)
    ├── [Section 4] Scroll & Row Settings
    │   ├── Virtual Scroll (checkbox)
    │   └── Row Height (slider)
    └── [Section 5] Column Freezing
        └── Frozen Columns (number input)
```

### 2.2 Data Flow Architecture (Phase 2 Extension)

```
┌─────────────────────────────────────────────────┐
│ GridComponent (Parent LiveView)                 │
├─────────────────────────────────────────────────┤
│                                                 │
│  socket.assigns                                 │
│  ├── :grid (Grid struct with .options)          │
│  ├── :show_config_modal (boolean)               │
│  └── :config_form_state (form data)             │
│                                                 │
│  Event Handlers:                                │
│  └── "config_apply" ← from ConfigModal          │
│      ├── Apply Column changes (Phase 1)         │
│      ├── Apply Grid options changes (Phase 2)   │
│      │   ├── Grid.apply_config_changes/2        │
│      │   └── Grid.apply_grid_settings/2         │
│      └── Update socket.assigns[:grid]           │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │ GridConfigModal (LiveComponent)           │  │
│  │                                           │  │
│  │ State Management:                         │  │
│  │ ├── :current_tab (atom)                   │  │
│  │ │   (:visibility | :properties |          │  │
│  │ │    :formatters | :grid_settings)        │  │
│  │ ├── :form_state (map with Phase 2 data)   │  │
│  │ │   ├── columns_* (Phase 1 fields)        │  │
│  │ │   └── options (Phase 2 new fields)      │  │
│  │ ├── :options_backup (map)                 │  │
│  │ └── :original_options (map)               │  │
│  │                                           │  │
│  │ Event Handlers:                           │  │
│  │ ├── "tab_select" (all tabs)               │  │
│  │ ├── "form_update" (all tabs)              │  │
│  │ ├── "config_apply"                        │  │
│  │ │   └── Send columns + options to parent  │  │
│  │ ├── "config_cancel"                       │  │
│  │ └── "config_reset"                        │  │
│  │                                           │  │
│  │ Sub-Components:                           │  │
│  │ ├── GridSettingsTab (NEW - Tab 4)         │  │
│  │ ├── ColumnVisibilityTab (Phase 1)         │  │
│  │ ├── ColumnPropertiesTab (Phase 1)         │  │
│  │ └── ColumnFormattersTab (Phase 1)         │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

---

## 3. ConfigModal Component Updates

### 3.1 ConfigModal State Extension

The existing ConfigModal state will be extended to include Phase 2 data:

```elixir
%{
  # From Phase 1
  current_tab: :visibility | :properties | :formatters | :grid_settings,
  form_state: %{
    # Phase 1 fields (unchanged)
    columns_visible: %{...},
    columns_order: [...],
    selected_column: atom,
    column_updates: %{...},
    formatters: %{...},
    validators: %{...},

    # NEW Phase 2 fields
    options: %{
      page_size: integer,              # e.g., 10, 25, 50
      theme: string,                   # "light" | "dark" | "custom"
      virtual_scroll: boolean,          # true | false
      row_height: integer,              # pixels (40-60 typical)
      frozen_columns: integer,          # 0, 1, 2, etc.
      show_row_number: boolean,         # true | false
      show_header: boolean,             # true | false
      show_footer: boolean,             # true | false
      debug_mode: boolean               # (optional, for dev)
    }
  },

  # Backup for reset functionality
  columns_backup: [...],
  options_backup: %{...},              # Backup of original options
  original_options: %{...}             # For comparison
}
```

### 3.2 Tab Navigation Update

The existing Tab Navigation in ConfigModal will add Tab 4:

```heex
<!-- Tab Navigation (in config_modal.ex render) -->
<div class="config-modal__tabs">
  <button
    class={["tab", active_class(:visibility)]}
    phx-click="tab_select"
    phx-value-tab="visibility">
    📋 Column Visibility
  </button>
  <button
    class={["tab", active_class(:properties)]}
    phx-click="tab_select"
    phx-value-tab="properties">
    ⚙ Column Properties
  </button>
  <button
    class={["tab", active_class(:formatters)]}
    phx-click="tab_select"
    phx-value-tab="formatters">
    🎨 Formatters & Validators
  </button>
  <button
    class={["tab", active_class(:grid_settings)]}
    phx-click="tab_select"
    phx-value-tab="grid_settings">
    ⚙️ Grid Settings
  </button>
</div>

<!-- Content Area (case statement) -->
<div class="config-modal__content">
  <%= case @current_tab do %>
    <% :visibility -> %>
      <.column_visibility_tab ... />
    <% :properties -> %>
      <.column_properties_tab ... />
    <% :formatters -> %>
      <.column_formatters_tab ... />
    <% :grid_settings -> %>
      <.grid_settings_tab ...  />
  <% end %>
</div>
```

### 3.3 Event Handler Updates

Add new event handler to ConfigModal for tab switching and grid settings form updates:

```elixir
# In ConfigModal handle_event

def handle_event("tab_select", %{"tab" => tab}, socket) do
  # Support new :grid_settings tab
  new_tab = String.to_atom(tab)
  {:noreply, assign(socket, :current_tab, new_tab)}
end

def handle_event("form_update", params, socket) do
  # Extended to handle grid options updates
  current_tab = socket.assigns.current_tab

  case current_tab do
    # Phase 1 handlers (unchanged)
    :visibility -> handle_visibility_update(params, socket)
    :properties -> handle_properties_update(params, socket)
    :formatters -> handle_formatters_update(params, socket)
    # Phase 2 handler (NEW)
    :grid_settings -> handle_grid_settings_update(params, socket)
  end
end

# NEW handler for grid settings
defp handle_grid_settings_update(params, socket) do
  form_state = socket.assigns.form_state

  # Extract option key and value
  {option_key, _} = Map.pop(params, "option")
  value = params["value"]

  # Type coercion based on option_key
  coerced_value = coerce_option_value(option_key, value)

  # Update form_state.options
  new_options = Map.put(form_state.options, option_key, coerced_value)
  new_form_state = %{form_state | options: new_options}

  {:noreply, assign(socket, :form_state, new_form_state)}
end

# Helper to coerce string input values to correct types
defp coerce_option_value(key, value) when is_binary(value) do
  case key do
    "page_size" -> String.to_integer(value)
    "row_height" -> String.to_integer(value)
    "frozen_columns" -> String.to_integer(value)
    "virtual_scroll" -> value == "true"
    "show_row_number" -> value == "true"
    "show_header" -> value == "true"
    "show_footer" -> value == "true"
    "debug_mode" -> value == "true"
    "theme" -> value
    _ -> value
  end
end

# Update config_apply handler to include options
def handle_event("config_apply", _params, socket) do
  form_state = socket.assigns.form_state
  config_changes = %{
    "columns" => build_column_changes(form_state),
    "column_order" => form_state.columns_order,
    "hidden_columns" => build_hidden_columns(form_state),
    "options" => form_state.options  # NEW: Include grid options
  }

  {:noreply, push_event(socket, "config_apply", config_changes)}
end
```

---

## 4. GridSettingsTab Component Specification

### 4.1 Component Overview

**File:** `lib/liveview_grid_web/components/grid_config/tabs/grid_settings_tab.ex`

**Type:** Function Component (functional component, not LiveComponent)

**Purpose:** Render a form for configuring Grid-level options with real-time input validation.

**Attributes:**
```elixir
attr :options, :map, required: true           # Current grid options
attr :form_state, :map, required: true        # Full form state
attr :target, :any, default: nil              # Parent LiveComponent for events
```

### 4.2 UI Structure & Layout

```
┌──────────────────────────────────────────────┐
│ ⚙️ Grid Settings                            │
├──────────────────────────────────────────────┤
│                                              │
│ [Section 1] PAGINATION SETTINGS              │
│ ─────────────────────────────────────────    │
│ Page Size:        [25 ▼]                     │
│                   Options: 10, 25, 50, 100   │
│                   (or custom number input)   │
│                                              │
│ [Section 2] DISPLAY SETTINGS                 │
│ ─────────────────────────────────────────    │
│ ☑ Show Row Numbers                           │
│ ☑ Show Header                                │
│ ☑ Show Footer                                │
│                                              │
│ [Section 3] THEME SETTINGS                   │
│ ─────────────────────────────────────────    │
│ Theme: [Light ▼]                             │
│        Options: Light, Dark, Custom          │
│                                              │
│ [Section 4] SCROLL & ROW SETTINGS            │
│ ─────────────────────────────────────────    │
│ ☑ Virtual Scroll                             │
│                                              │
│ Row Height: [45] px     [////////]           │
│             Min: 32px, Max: 80px             │
│             Hint: Adjust grid row height     │
│                                              │
│ [Section 5] COLUMN FREEZING                  │
│ ─────────────────────────────────────────    │
│ Frozen Columns: [1]                          │
│                 (0 to column count)          │
│                                              │
│ [Reset to Default] [Live Preview]            │
└──────────────────────────────────────────────┘
```

### 4.3 Form Controls Specification

#### 4.3.1 Pagination Section

```elixir
# Page Size (Dropdown + Custom Option)
<div class="form-group">
  <label for="page_size">Page Size</label>
  <select
    id="page_size"
    name="page_size"
    value={@form_state.options["page_size"]}
    phx-change="form_update"
    phx-target={@target}
  >
    <option value="10">10 rows per page</option>
    <option value="25">25 rows per page</option>
    <option value="50">50 rows per page</option>
    <option value="100">100 rows per page</option>
    <option value="custom">Custom...</option>
  </select>

  <!-- Show custom input if "custom" selected -->
  <%= if @form_state.options["page_size"] not in [10, 25, 50, 100] do %>
    <input
      type="number"
      min="1"
      max="1000"
      value={@form_state.options["page_size"]}
      phx-change="form_update"
      phx-value-option="page_size"
      phx-target={@target}
    />
  <% end %>

  <p class="help-text">Number of rows to display per page</p>
</div>
```

#### 4.3.2 Display Settings Section

```elixir
# Boolean toggles with descriptions
<div class="form-group">
  <h3>Display Settings</h3>

  <div class="form-checkbox-group">
    <label>
      <input
        type="checkbox"
        checked={@form_state.options["show_row_number"]}
        phx-value-option="show_row_number"
        phx-change="form_update"
        phx-target={@target}
      />
      Show Row Numbers
    </label>
    <p class="help-text">Display sequential row numbers in the left margin</p>
  </div>

  <div class="form-checkbox-group">
    <label>
      <input
        type="checkbox"
        checked={@form_state.options["show_header"]}
        phx-value-option="show_header"
        phx-change="form_update"
        phx-target={@target}
      />
      Show Header Row
    </label>
    <p class="help-text">Display column headers at the top of the grid</p>
  </div>

  <div class="form-checkbox-group">
    <label>
      <input
        type="checkbox"
        checked={@form_state.options["show_footer"]}
        phx-value-option="show_footer"
        phx-change="form_update"
        phx-target={@target}
      />
      Show Footer Row
    </label>
    <p class="help-text">Display aggregation/summary footer at the bottom</p>
  </div>
</div>
```

#### 4.3.3 Theme Settings Section

```elixir
# Theme selector
<div class="form-group">
  <label for="theme">Theme</label>
  <select
    id="theme"
    name="theme"
    value={@form_state.options["theme"]}
    phx-change="form_update"
    phx-value-option="theme"
    phx-target={@target}
  >
    <option value="light">Light (Default)</option>
    <option value="dark">Dark</option>
    <option value="custom">Custom (if available)</option>
  </select>

  <p class="help-text">Choose color scheme for the grid</p>

  <!-- Theme preview (optional) -->
  <div class="theme-preview">
    <div class={"preview-box preview-box--#{@form_state.options["theme"]}"}>
      Preview
    </div>
  </div>
</div>
```

#### 4.3.4 Scroll & Row Settings Section

```elixir
# Virtual scroll toggle
<div class="form-group">
  <div class="form-checkbox-group">
    <label>
      <input
        type="checkbox"
        checked={@form_state.options["virtual_scroll"]}
        phx-value-option="virtual_scroll"
        phx-change="form_update"
        phx-target={@target}
      />
      Enable Virtual Scrolling
    </label>
    <p class="help-text">
      For large datasets (1000+ rows), render only visible rows for performance
    </p>
  </div>
</div>

# Row height slider
<div class="form-group">
  <label for="row_height">
    Row Height:
    <span class="value-display"><%= @form_state.options["row_height"] %> px</span>
  </label>

  <input
    type="range"
    id="row_height"
    min="32"
    max="80"
    value={@form_state.options["row_height"]}
    phx-change="form_update"
    phx-value-option="row_height"
    phx-target={@target}
    class="form-slider"
  />

  <div class="slider-labels">
    <span class="label-min">32px (Compact)</span>
    <span class="label-max">80px (Spacious)</span>
  </div>

  <p class="help-text">Height of each row in pixels (affects vertical spacing)</p>
</div>
```

#### 4.3.5 Column Freezing Section

```elixir
# Frozen columns input
<div class="form-group">
  <label for="frozen_columns">Frozen Columns</label>

  <input
    type="number"
    id="frozen_columns"
    min="0"
    max={length(@options.columns)}
    value={@form_state.options["frozen_columns"]}
    phx-change="form_update"
    phx-value-option="frozen_columns"
    phx-target={@target}
  />

  <p class="help-text">
    Number of leftmost columns to keep visible when horizontal scrolling.
    (Max: <%= length(@options.columns) %> columns)
  </p>

  <!-- Visual indicator -->
  <div class="frozen-columns-preview">
    <%= for {col, idx} <- Enum.with_index(@options.columns) do %>
      <div class={["col-indicator", frozen?(idx, @form_state.options["frozen_columns"])]}>
        <%= col.label %>
      </div>
    <% end %>
  </div>
</div>
```

### 4.4 Form Actions

```elixir
# Action buttons (in ConfigModal, but apply to all tabs)
<div class="config-modal__actions">
  <button class="btn btn-secondary" phx-click="config_cancel">
    Cancel
  </button>
  <button class="btn btn-secondary" phx-click="config_reset">
    Reset to Default
  </button>
  <button class="btn btn-primary" phx-click="config_apply">
    Apply Changes
  </button>
</div>
```

---

## 5. Grid Settings Data Schema

### 5.1 Grid Options Map Structure

```elixir
# Grid options map (stored in grid.options)
options = %{
  "page_size" => 25,              # integer, default: 10
  "theme" => "light",              # string: "light" | "dark" | "custom"
  "virtual_scroll" => false,       # boolean, default: false
  "row_height" => 45,              # integer (pixels), default: 40
  "frozen_columns" => 1,           # integer, default: 0
  "show_row_number" => true,       # boolean, default: true
  "show_header" => true,           # boolean, default: true
  "show_footer" => false,          # boolean, default: false
  "debug_mode" => false            # boolean, default: false (optional)
}
```

### 5.2 Configuration Changes Structure (Phase 1 + Phase 2)

```elixir
# Full config_changes sent to parent on "Apply"
config_changes = %{
  # Phase 1 data (unchanged)
  "columns" => [...],              # Column updates
  "column_order" => [...],         # Reordered columns
  "hidden_columns" => [...],       # Hidden columns

  # Phase 2 data (NEW)
  "options" => %{
    "page_size" => 25,
    "theme" => "dark",
    "virtual_scroll" => true,
    "row_height" => 50,
    "frozen_columns" => 1,
    "show_row_number" => true,
    "show_header" => true,
    "show_footer" => false
  }
}
```

### 5.3 Validation Rules for Grid Settings

```elixir
# Validation constraints (enforced client-side and server-side)

page_size:
  - Type: integer
  - Range: 1 to 1000
  - Default: 10

theme:
  - Type: string
  - Allowed: ["light", "dark", "custom"]
  - Default: "light"

virtual_scroll:
  - Type: boolean
  - Default: false

row_height:
  - Type: integer
  - Range: 32 to 80 (pixels)
  - Default: 40

frozen_columns:
  - Type: integer
  - Range: 0 to column_count
  - Default: 0

show_row_number:
  - Type: boolean
  - Default: true

show_header:
  - Type: boolean
  - Default: true

show_footer:
  - Type: boolean
  - Default: false

debug_mode:
  - Type: boolean
  - Default: false
  - (Developer only)
```

---

## 6. Backend Integration: Grid.apply_grid_settings/2

### 6.1 New Function in Grid Module

**File:** `lib/liveview_grid/grid.ex`

**Function Signature:**
```elixir
@doc """
Apply grid-level settings to the grid struct.

Validates and applies options like page_size, theme, row_height, etc.

## Examples

  iex> grid = Grid.new(data: data, columns: cols, options: opts)
  iex> Grid.apply_grid_settings(grid, %{"page_size" => 50, "theme" => "dark"})
  %Grid{options: %{page_size: 50, theme: "dark", ...}, ...}

"""
@spec apply_grid_settings(Grid.t(), map()) :: Grid.t() | {:error, String.t()}
def apply_grid_settings(grid, options_changes) do
  # Normalize and validate options
  # Apply changes to grid.options
  # Return updated grid
end
```

### 6.2 Implementation Logic

```elixir
def apply_grid_settings(grid, options_changes) do
  # 1. Normalize option keys (string -> atom)
  options_changes = normalize_option_keys(options_changes)

  # 2. Validate each option
  case validate_grid_options!(options_changes, grid) do
    :ok ->
      # 3. Merge with existing options
      new_options = Map.merge(grid.options, options_changes)

      # 4. Return updated grid
      {:ok, %{grid | options: new_options}}

    {:error, reason} ->
      {:error, reason}
  end
end

# Helper: Validate grid options
defp validate_grid_options!(options, grid) do
  Enum.each(options, fn {key, value} ->
    case key do
      :page_size ->
        unless is_integer(value) and value > 0 and value <= 1000 do
          raise "Invalid page_size: must be 1-1000"
        end

      :theme ->
        unless value in ["light", "dark", "custom"] do
          raise "Invalid theme: must be light, dark, or custom"
        end

      :virtual_scroll ->
        unless is_boolean(value) do
          raise "Invalid virtual_scroll: must be boolean"
        end

      :row_height ->
        unless is_integer(value) and value >= 32 and value <= 80 do
          raise "Invalid row_height: must be 32-80"
        end

      :frozen_columns ->
        max_cols = length(grid.columns)
        unless is_integer(value) and value >= 0 and value <= max_cols do
          raise "Invalid frozen_columns: must be 0-#{max_cols}"
        end

      :show_row_number ->
        unless is_boolean(value) do
          raise "Invalid show_row_number: must be boolean"
        end

      :show_header ->
        unless is_boolean(value) do
          raise "Invalid show_header: must be boolean"
        end

      :show_footer ->
        unless is_boolean(value) do
          raise "Invalid show_footer: must be boolean"
        end

      _ ->
        :ok
    end
  end)

  :ok
end

# Helper: Normalize option keys
defp normalize_option_keys(options) when is_map(options) do
  Map.new(options, fn {k, v} ->
    key = if is_binary(k), do: String.to_atom(k), else: k
    {key, v}
  end)
end
```

### 6.3 Integration in GridComponent

The GridComponent event handler will call both functions:

```elixir
def handle_event("config_apply", config_changes, socket) do
  grid = socket.assigns.grid

  # Apply Phase 1 column changes
  grid = Grid.apply_config_changes(grid, config_changes)

  # Apply Phase 2 grid settings changes (NEW)
  grid = case Grid.apply_grid_settings(grid, config_changes["options"]) do
    {:ok, new_grid} -> new_grid
    {:error, reason} ->
      # Log error, show to user
      IO.warn("Grid settings error: #{reason}")
      grid
  end

  {:noreply,
    socket
    |> assign(:grid, grid)
    |> assign(:show_config_modal, false)
  }
end
```

---

## 7. CSS Styling & Responsive Design

### 7.1 New CSS Classes for Phase 2

**File:** `assets/css/grid/config-modal.css`

Add styles for Phase 2 components:

```css
/* Grid Settings Tab */
.grid-settings-tab {}
.form-group {}                    /* Form group container */
.form-group h3 {}                 /* Section heading */
.form-group label {}              /* Form label */

/* Sections */
.form-section {
  margin-bottom: 2rem;
  padding-bottom: 2rem;
  border-bottom: 1px solid #e0e0e0;
}
.form-section:last-child {
  border-bottom: none;
}

/* Form inputs */
.form-checkbox-group {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  margin-bottom: 1.5rem;
  padding: 0.75rem;
  background: #f9f9f9;
  border-radius: 4px;
}

.form-checkbox-group label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
}

.form-checkbox-group input[type="checkbox"] {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

/* Slider styling */
.form-slider {
  width: 100%;
  height: 6px;
  border-radius: 3px;
  background: #e0e0e0;
  outline: none;
  -webkit-appearance: none;
}

.form-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #2196f3;
  cursor: pointer;
}

.slider-labels {
  display: flex;
  justify-content: space-between;
  font-size: 0.875rem;
  color: #666;
  margin-top: 0.5rem;
}

/* Value display */
.value-display {
  font-family: monospace;
  background: #f0f0f0;
  padding: 0.25rem 0.5rem;
  border-radius: 3px;
}

/* Help text */
.help-text {
  font-size: 0.875rem;
  color: #666;
  margin-top: 0.5rem;
}

/* Theme preview */
.theme-preview {
  margin-top: 1rem;
}

.preview-box {
  width: 100%;
  padding: 2rem;
  border-radius: 4px;
  text-align: center;
  font-weight: 500;
  transition: all 0.3s ease;
}

.preview-box--light {
  background: #ffffff;
  border: 1px solid #ddd;
  color: #333;
}

.preview-box--dark {
  background: #333333;
  border: 1px solid #555;
  color: #fff;
}

.preview-box--custom {
  background: #f5f5f5;
  border: 1px solid #999;
  color: #333;
}

/* Frozen columns preview */
.frozen-columns-preview {
  display: flex;
  gap: 0.5rem;
  margin-top: 1rem;
  padding: 0.75rem;
  background: #f9f9f9;
  border-radius: 4px;
  font-size: 0.875rem;
}

.col-indicator {
  padding: 0.5rem;
  background: #e0e0e0;
  border-radius: 3px;
  transition: all 0.3s ease;
}

.col-indicator.frozen {
  background: #4caf50;
  color: white;
  font-weight: 500;
}

/* Responsive */
@media (max-width: 640px) {
  .form-group {
    margin-bottom: 1.5rem;
  }

  .form-checkbox-group {
    flex-direction: column;
  }

  .slider-labels {
    font-size: 0.75rem;
  }

  .frozen-columns-preview {
    flex-wrap: wrap;
  }
}
```

---

## 8. Event Flow Diagram

### 8.1 Complete Event Flow (Phase 1 + Phase 2)

```
User opens Grid
    ↓
Clicks "⚙ Configure" button
    ↓
GridComponent: handle_event("config_show_modal")
    ↓
Assigns show_config_modal = true
    ↓
ConfigModal mounts (LiveComponent)
    ↓
User navigates tabs (including new Tab 4: Grid Settings)
    ↓
User modifies settings in Grid Settings Tab
    ↓
Input event: phx-change="form_update"
    ↓
ConfigModal: handle_event("form_update")
    ↓
Extracts option key and value
    ↓
Coerces value to correct type
    ↓
Updates form_state.options[key] = coerced_value
    ↓
Grid Settings Tab re-renders with updated value
    ↓
User clicks "Apply" button
    ↓
ConfigModal: handle_event("config_apply")
    ↓
Builds config_changes map with:
  - Phase 1: columns, column_order, hidden_columns
  - Phase 2: options
    ↓
Sends config_changes to parent via event
    ↓
GridComponent: handle_event("config_apply", config_changes)
    ↓
Calls Grid.apply_config_changes(grid, config_changes)  # Phase 1
    ↓
Calls Grid.apply_grid_settings(grid, config_changes["options"])  # Phase 2
    ↓
Updates socket.assigns.grid with new grid
    ↓
Closes modal (show_config_modal = false)
    ↓
Grid re-renders with:
  - New columns (Phase 1)
  - New grid options (Phase 2)
    ↓
User sees live updates:
  - Column changes applied
  - Grid settings applied (page size, theme, row height, etc.)
    ↓
NO PAGE RELOAD
```

---

## 9. Integration Checklist for Phase 2

### ConfigModal Component (`config_modal.ex`)
- [ ] Add `:grid_settings` as valid tab atom
- [ ] Extend form_state to include `options` map
- [ ] Add `options_backup` to state for reset functionality
- [ ] Update tab navigation to include Tab 4 button
- [ ] Update case statement in render to handle `:grid_settings` tab
- [ ] Add `handle_grid_settings_update/2` event handler
- [ ] Add `coerce_option_value/2` helper function
- [ ] Update `config_apply` handler to include `options` in config_changes
- [ ] Update `config_reset` handler to restore options_backup
- [ ] Add imports for GridSettingsTab component

### GridSettingsTab Component (`tabs/grid_settings_tab.ex`)
- [ ] Create new file
- [ ] Define function component with attributes
- [ ] Implement all 5 form sections:
  - [ ] Pagination (page_size)
  - [ ] Display (show_row_number, show_header, show_footer)
  - [ ] Theme (theme selector with preview)
  - [ ] Scroll & Row (virtual_scroll, row_height slider)
  - [ ] Column Freezing (frozen_columns)
- [ ] Add form validation indicators
- [ ] Add help text for each option
- [ ] Ensure all inputs send phx-change events with correct values
- [ ] Add responsive styling

### Grid Module (`lib/liveview_grid/grid.ex`)
- [ ] Add `apply_grid_settings/2` function
- [ ] Implement validation logic for each option
- [ ] Add helper functions:
  - [ ] `validate_grid_options!/2`
  - [ ] `normalize_option_keys/1`
- [ ] Add unit tests for the function
- [ ] Document edge cases and constraints

### GridComponent (`lib/liveview_grid_web/components/grid_component.ex`)
- [ ] Update `config_apply` handler to call Grid.apply_grid_settings/2
- [ ] Add error handling for grid settings validation
- [ ] Add optional logging of applied settings

### CSS (`assets/css/grid/config-modal.css`)
- [ ] Add styles for GridSettingsTab
- [ ] Add slider styling for row_height
- [ ] Add theme preview styling
- [ ] Add frozen columns preview styling
- [ ] Ensure responsive design for mobile
- [ ] Add transitions for interactive elements

### Testing
- [ ] Unit tests for `Grid.apply_grid_settings/2`
  - [ ] Test each option individually
  - [ ] Test validation constraints
  - [ ] Test type coercion
  - [ ] Test error handling
- [ ] Component tests for GridSettingsTab
  - [ ] Test all form inputs render
  - [ ] Test event emission on change
- [ ] Integration tests for ConfigModal + GridComponent
  - [ ] Test full workflow (open modal → change settings → apply)
  - [ ] Test grid re-renders with new options
  - [ ] Test changes persist in assigns

### Demo Page (`lib/liveview_grid_web/live/demo_live.ex`)
- [ ] Update demo to show grid settings changes
- [ ] Add status display for current grid options
- [ ] Display page_size, theme, row_height, etc.
- [ ] Show visual feedback when options change

---

## 10. Validation & Error Handling

### 10.1 Client-Side Validation

GridSettingsTab will validate inputs before sending:

```elixir
# In GridSettingsTab component

defp validate_page_size(value) do
  case Integer.parse(value) do
    {num, ""} when num > 0 and num <= 1000 -> {:ok, num}
    _ -> {:error, "Page size must be 1-1000"}
  end
end

defp validate_row_height(value) do
  case Integer.parse(value) do
    {num, ""} when num >= 32 and num <= 80 -> {:ok, num}
    _ -> {:error, "Row height must be 32-80 pixels"}
  end
end

defp validate_frozen_columns(value, column_count) do
  case Integer.parse(value) do
    {num, ""} when num >= 0 and num <= column_count -> {:ok, num}
    _ -> {:error, "Frozen columns must be 0-#{column_count}"}
  end
end
```

### 10.2 Server-Side Validation

Grid.apply_grid_settings/2 will validate before applying:

```elixir
defp validate_grid_options!(options, grid) do
  # Comprehensive validation with clear error messages
  # Raises exception if invalid
  # Prevents invalid state from being applied
end
```

### 10.3 Error Feedback

```elixir
# ConfigModal displays errors
case Grid.apply_grid_settings(grid, options) do
  {:ok, new_grid} ->
    # Update grid successfully
    {:noreply, assign(socket, :grid, new_grid)}

  {:error, reason} ->
    # Show error to user (toast or inline message)
    {:noreply,
      socket
      |> assign(:error_message, reason)
      |> assign(:show_error, true)
    }
end
```

---

## 11. Performance Considerations

### 11.1 Virtual Scrolling

When `virtual_scroll: true`:
- Only render visible rows
- Reduces DOM size for large datasets
- Improves initial render time and scrolling performance
- Combined with row_height option for optimal spacing

### 11.2 Lazy Re-renders

- GridSettingsTab only re-renders on form changes
- Form state changes don't trigger full grid re-render
- Only apply changes when user clicks "Apply"

### 11.3 Theme Switching

- Minimal CSS class changes for theme switching
- No full page reload
- Smooth transition between light/dark

---

## 12. Known Limitations & Future Enhancements

**Phase 2 Limitations:**
- Theme switching only supports predefined themes (light/dark)
- Row height has fixed range (32-80px, may need adjustment for specific UX)
- No save/export of grid settings as JSON (Phase 4)
- No custom validators or formatters UI (Phase 3)

**Future Enhancements:**
- Custom theme builder (Phase 4)
- Save/restore named configuration profiles
- Keyboard shortcuts for common operations
- Grid state export/import as JSON
- Configuration templates for common use cases
- Live preview of settings (show grid with applied settings)

---

## 13. Success Criteria (Phase 2)

✅ **Functional Requirements:**
- User can open Tab 4: Grid Settings in ConfigModal
- All form controls render correctly with current values
- Page size can be changed via dropdown or custom input
- Theme can be switched between light/dark
- Virtual scroll can be toggled on/off
- Row height can be adjusted via slider (32-80px)
- Frozen columns can be set via number input (0 to column count)
- Display toggles (row numbers, header, footer) work via checkboxes
- Clicking Apply applies all changes to grid **without page reload**
- Grid re-renders immediately with new options:
  - Page size affects pagination
  - Theme changes visual appearance (light/dark)
  - Row height changes row spacing
  - Virtual scroll improves performance for large data
  - Frozen columns keep leftmost columns visible when scrolling
  - Display toggles show/hide UI elements

✅ **Quality Requirements:**
- No console errors or warnings
- Form inputs are keyboard accessible (Tab, Enter, Space)
- Validation prevents invalid inputs (client-side)
- Server-side validation catches any edge cases
- Error messages are clear and actionable
- Modal is responsive on desktop and mobile
- Form controls feel responsive (< 100ms feedback)
- Reset button restores original values
- Cancel button closes without applying changes

✅ **Performance Requirements:**
- Modal Tab 4 loads within 300ms
- Form interactions feel responsive (< 100ms)
- Grid re-render with new options < 1 second
- Virtual scroll significantly improves performance for 1000+ rows

✅ **Integration Requirements:**
- Phase 1 + Phase 2 changes can be applied together
- Column changes and grid settings work independently
- Reset affects all tabs' changes
- Cancel discards all unsaved changes

---

## 14. Reference Documentation

**Related Files:**
- Plan Document: `docs/01-plan/features/grid-config-phase2.plan.md`
- Phase 1 Design: `docs/02-design/features/grid-config.design.md`
- Grid Core: `lib/liveview_grid/grid.ex`
- GridComponent: `lib/liveview_grid_web/components/grid_component.ex`
- Grid Options Reference: `lib/liveview_grid/grid.ex` (lines 757-800)

**External References:**
- Phoenix LiveComponent: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html
- Phoenix Form Components: https://hexdocs.pm/phoenix/Phoenix.HTML.Form.html
- HTML5 Input Types: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input

---

**Document Version:** 1.0
**Last Review:** 2026-02-26
**Status:** Ready for Phase 2 Implementation

**Next Steps:**
1. ✅ Design Phase Complete
2. → Run `/pdca do grid-config-phase2` for implementation guide
3. → Implement Tab 4 and Grid.apply_grid_settings/2
4. → Run `/pdca analyze grid-config-phase2` for gap analysis
5. → If matchRate < 90%, run `/pdca iterate grid-config-phase2` for auto-improvements
6. → Run `/pdca report grid-config-phase2` for completion report
