# Do Phase - Grid Configuration Phase 2 (Grid Settings Tab Implementation)

**Status:** Do Phase (Implementation)
**Feature:** grid-config-phase2
**Version:** 1.0
**Last Updated:** 2026-02-26

---

## 📋 Implementation Overview

This guide provides step-by-step instructions to implement **Phase 2: Grid Settings Configuration** - adding Tab 4 to the existing ConfigModal component.

**Target:** Add a comprehensive Grid Settings form with 5 configuration sections
- ✅ Pagination Settings (page size)
- ✅ Display Settings (row numbers, header, footer toggles)
- ✅ Theme Settings (light/dark theme selector)
- ✅ Scroll & Row Settings (virtual scroll, row height)
- ✅ Column Freezing (frozen columns count)

**Timeline Estimate:** 4-5 hours
**Difficulty:** Medium
**Dependencies:** Phase 1 (Column Configuration) ✅ Complete

---

## 🎯 Phase 2 Implementation Checklist

### Phase 2A: Backend Functions (Grid.apply_grid_settings/2)

**File:** `lib/liveview_grid/grid.ex`

#### Step 1: Add Grid.apply_grid_settings/2 Function

```elixir
# Location: lib/liveview_grid/grid.ex (after apply_config_changes/2 function)

@doc """
Apply grid-level settings to the grid struct.

Validates and applies options like page_size, theme, row_height, frozen_columns, etc.
"""
@spec apply_grid_settings(Grid.t(), map()) :: {:ok, Grid.t()} | {:error, String.t()}
def apply_grid_settings(grid, options_changes) when is_map(options_changes) do
  # 1. Normalize option keys (string -> atom)
  options_changes = normalize_option_keys(options_changes)

  # 2. Validate each option
  case validate_grid_options(options_changes, grid) do
    :ok ->
      # 3. Merge with existing options
      new_options = Map.merge(grid.options, options_changes)
      {:ok, %{grid | options: new_options}}

    {:error, reason} ->
      {:error, reason}
  end
end

# Helper: Normalize option keys from strings to atoms
defp normalize_option_keys(options) when is_map(options) do
  Map.new(options, fn {k, v} ->
    key = if is_binary(k), do: String.to_atom(k), else: k
    {key, v}
  end)
end

# Helper: Validate grid options
defp validate_grid_options(options, grid) do
  try do
    Enum.each(options, fn {key, value} ->
      case key do
        :page_size ->
          unless is_integer(value) and value > 0 and value <= 1000 do
            raise "Invalid page_size: must be between 1 and 1000"
          end

        :theme ->
          unless is_binary(value) and value in ["light", "dark", "custom"] do
            raise "Invalid theme: must be 'light', 'dark', or 'custom'"
          end

        :virtual_scroll ->
          unless is_boolean(value) do
            raise "Invalid virtual_scroll: must be boolean"
          end

        :row_height ->
          unless is_integer(value) and value >= 32 and value <= 80 do
            raise "Invalid row_height: must be between 32 and 80 pixels"
          end

        :frozen_columns ->
          max_cols = length(grid.columns)
          unless is_integer(value) and value >= 0 and value <= max_cols do
            raise "Invalid frozen_columns: must be between 0 and #{max_cols}"
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

        :debug_mode ->
          unless is_boolean(value) do
            raise "Invalid debug_mode: must be boolean"
          end

        _ ->
          # Allow unknown keys to be safely ignored
          :ok
      end
    end)

    :ok
  rescue
    e in RuntimeError ->
      {:error, e.message}
  end
end
```

**Testing:** Create unit tests for this function
```elixir
# In test/liveview_grid/grid_test.exs, add tests:

describe "apply_grid_settings/2" do
  test "applies valid page_size" do
    grid = Grid.new(data: @data, columns: @columns)
    {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"page_size" => 50})
    assert new_grid.options.page_size == 50
  end

  test "applies valid theme" do
    grid = Grid.new(data: @data, columns: @columns)
    {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"theme" => "dark"})
    assert new_grid.options.theme == "dark"
  end

  test "validates page_size range" do
    grid = Grid.new(data: @data, columns: @columns)
    {:error, reason} = Grid.apply_grid_settings(grid, %{"page_size" => 2000})
    assert String.contains?(reason, "page_size")
  end

  test "validates row_height range" do
    grid = Grid.new(data: @data, columns: @columns)
    {:error, reason} = Grid.apply_grid_settings(grid, %{"row_height" => 100})
    assert String.contains?(reason, "row_height")
  end

  test "applies multiple options at once" do
    grid = Grid.new(data: @data, columns: @columns)
    changes = %{
      "page_size" => 25,
      "theme" => "dark",
      "row_height" => 50,
      "virtual_scroll" => true
    }
    {:ok, new_grid} = Grid.apply_grid_settings(grid, changes)
    assert new_grid.options.page_size == 25
    assert new_grid.options.theme == "dark"
    assert new_grid.options.row_height == 50
    assert new_grid.options.virtual_scroll == true
  end
end
```

#### Step 2: Add @spec Typespec
- [ ] Add `@spec apply_grid_settings/2` before the function
- [ ] Include return type: `{:ok, Grid.t()} | {:error, String.t()}`

---

### Phase 2B: ConfigModal Component Extension

**File:** `lib/liveview_grid_web/components/grid_config/config_modal.ex`

#### Step 3: Extend ConfigModal State

In the `mount/1` function, add grid settings state:

```elixir
def mount(assigns, socket) do
  # Existing Phase 1 initialization...

  # NEW Phase 2: Initialize grid options state
  options = assigns.grid.options || %{
    page_size: 10,
    theme: "light",
    virtual_scroll: false,
    row_height: 40,
    frozen_columns: 0,
    show_row_number: true,
    show_header: true,
    show_footer: false
  }

  {:ok,
    socket
    |> assign(:current_tab, :visibility)
    |> assign(:form_state, %{
      # Phase 1 fields
      columns_visible: build_columns_visible(assigns.grid.columns),
      columns_order: Enum.map(assigns.grid.columns, & &1.field),
      selected_column: nil,
      column_updates: %{},
      formatters: %{},
      validators: %{},
      # Phase 2 fields (NEW)
      options: options
    })
    |> assign(:columns_backup, assigns.grid.columns)
    |> assign(:options_backup, options)  # NEW backup for reset
  }
end
```

#### Step 4: Update handle_event for form_update

Extend the `handle_event("form_update", ...)` to handle grid settings:

```elixir
def handle_event("form_update", params, socket) do
  current_tab = socket.assigns.current_tab
  form_state = socket.assigns.form_state

  case current_tab do
    # Phase 1 handlers (keep existing)
    :visibility -> handle_visibility_update(params, socket)
    :properties -> handle_properties_update(params, socket)
    :formatters -> handle_formatters_update(params, socket)
    # Phase 2 handler (NEW)
    :grid_settings -> handle_grid_settings_update(params, socket)
  end
end

# NEW handler for grid settings updates
defp handle_grid_settings_update(params, socket) do
  form_state = socket.assigns.form_state
  option_key = params["option"]
  value = params["value"]

  # Type coercion based on option_key
  coerced_value = coerce_option_value(option_key, value)

  # Update form_state.options
  new_options = Map.put(form_state.options, String.to_atom(option_key), coerced_value)
  new_form_state = %{form_state | options: new_options}

  {:noreply, assign(socket, :form_state, new_form_state)}
end

# Helper to coerce string values to correct types
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
```

#### Step 5: Update Tab Navigation

In the `render/1` function, add Tab 4 button:

```heex
<!-- Tab Navigation (extend existing) -->
<div class="config-modal__tabs">
  <button
    class={["tab", if(@current_tab == :visibility, do: "tab--active")]}
    phx-click="tab_select"
    phx-value-tab="visibility">
    📋 Column Visibility
  </button>
  <button
    class={["tab", if(@current_tab == :properties, do: "tab--active")]}
    phx-click="tab_select"
    phx-value-tab="properties">
    ⚙ Column Properties
  </button>
  <button
    class={["tab", if(@current_tab == :formatters, do: "tab--active")]}
    phx-click="tab_select"
    phx-value-tab="formatters">
    🎨 Formatters & Validators
  </button>
  <!-- NEW Phase 2 Tab -->
  <button
    class={["tab", if(@current_tab == :grid_settings, do: "tab--active")]}
    phx-click="tab_select"
    phx-value-tab="grid_settings">
    ⚙️ Grid Settings
  </button>
</div>
```

#### Step 6: Update Content Area Case Statement

```heex
<!-- Content Area (extend existing case) -->
<div class="config-modal__content">
  <%= case @current_tab do %>
    <% :visibility -> %>
      <.column_visibility_tab ... />
    <% :properties -> %>
      <.column_properties_tab ... />
    <% :formatters -> %>
      <.column_formatters_tab ... />
    <!-- NEW Phase 2 Tab -->
    <% :grid_settings -> %>
      <.grid_settings_tab
        options={@form_state.options}
        form_state={@form_state}
        target={@myself}
      />
  <% end %>
</div>
```

#### Step 7: Update config_apply Handler

```elixir
def handle_event("config_apply", _params, socket) do
  form_state = socket.assigns.form_state
  config_changes = %{
    # Phase 1 data
    "columns" => build_column_changes(form_state),
    "column_order" => form_state.columns_order,
    "hidden_columns" => build_hidden_columns(form_state),
    # Phase 2 data (NEW)
    "options" => form_state.options
  }

  {:noreply, push_event(socket, "config_apply", config_changes)}
end
```

#### Step 8: Update config_reset Handler

```elixir
def handle_event("config_reset", _params, socket) do
  {:noreply,
    socket
    |> assign(:form_state, %{
      # Reset to backups
      columns_visible: build_columns_visible(socket.assigns.columns_backup),
      columns_order: Enum.map(socket.assigns.columns_backup, & &1.field),
      selected_column: nil,
      column_updates: %{},
      formatters: %{},
      validators: %{},
      options: socket.assigns.options_backup  # Phase 2 reset
    })
    |> assign(:current_tab, :visibility)
  }
end
```

---

### Phase 2C: Create GridSettingsTab Component

**File:** `lib/liveview_grid_web/components/grid_config/tabs/grid_settings_tab.ex` (NEW)

#### Step 9: Create GridSettingsTab Component

```elixir
defmodule LiveviewGridWeb.Components.GridConfig.Tabs.GridSettingsTab do
  use Phoenix.Component

  attr :options, :map, required: true
  attr :form_state, :map, required: true
  attr :target, :any, default: nil

  def render(assigns) do
    ~H"""
    <div class="grid-settings-tab">
      <!-- Section 1: Pagination Settings -->
      <div class="form-section">
        <h3>Pagination Settings</h3>

        <div class="form-group">
          <label for="page_size">Page Size</label>
          <select
            id="page_size"
            name="page_size"
            value={@options["page_size"] || @options[:page_size]}
            phx-change="form_update"
            phx-value-option="page_size"
            phx-target={@target}
          >
            <option value="10">10 rows per page</option>
            <option value="25">25 rows per page</option>
            <option value="50">50 rows per page</option>
            <option value="100">100 rows per page</option>
          </select>
          <p class="help-text">Number of rows to display per page</p>
        </div>
      </div>

      <!-- Section 2: Display Settings -->
      <div class="form-section">
        <h3>Display Settings</h3>

        <div class="form-checkbox-group">
          <label>
            <input
              type="checkbox"
              checked={@options["show_row_number"] || @options[:show_row_number]}
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
              checked={@options["show_header"] || @options[:show_header]}
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
              checked={@options["show_footer"] || @options[:show_footer]}
              phx-value-option="show_footer"
              phx-change="form_update"
              phx-target={@target}
            />
            Show Footer Row
          </label>
          <p class="help-text">Display aggregation/summary footer at the bottom</p>
        </div>
      </div>

      <!-- Section 3: Theme Settings -->
      <div class="form-section">
        <h3>Theme Settings</h3>

        <div class="form-group">
          <label for="theme">Theme</label>
          <select
            id="theme"
            name="theme"
            value={@options["theme"] || @options[:theme]}
            phx-change="form_update"
            phx-value-option="theme"
            phx-target={@target}
          >
            <option value="light">Light (Default)</option>
            <option value="dark">Dark</option>
            <option value="custom">Custom</option>
          </select>
          <p class="help-text">Choose color scheme for the grid</p>

          <!-- Theme Preview -->
          <div class="theme-preview">
            <div class={["preview-box", "preview-box--#{@options["theme"] || @options[:theme]}"]}>
              Theme Preview
            </div>
          </div>
        </div>
      </div>

      <!-- Section 4: Scroll & Row Settings -->
      <div class="form-section">
        <h3>Scroll & Row Settings</h3>

        <div class="form-checkbox-group">
          <label>
            <input
              type="checkbox"
              checked={@options["virtual_scroll"] || @options[:virtual_scroll]}
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

        <div class="form-group">
          <label for="row_height">
            Row Height:
            <span class="value-display"><%= @options["row_height"] || @options[:row_height] %> px</span>
          </label>

          <input
            type="range"
            id="row_height"
            min="32"
            max="80"
            value={@options["row_height"] || @options[:row_height]}
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
      </div>

      <!-- Section 5: Column Freezing -->
      <div class="form-section">
        <h3>Column Freezing</h3>

        <div class="form-group">
          <label for="frozen_columns">Frozen Columns</label>

          <input
            type="number"
            id="frozen_columns"
            min="0"
            max="10"
            value={@options["frozen_columns"] || @options[:frozen_columns]}
            phx-change="form_update"
            phx-value-option="frozen_columns"
            phx-target={@target}
          />

          <p class="help-text">
            Number of leftmost columns to keep visible when horizontal scrolling
          </p>
        </div>
      </div>
    </div>
    """
  end
end
```

---

### Phase 2D: GridComponent Integration

**File:** `lib/liveview_grid_web/components/grid_component.ex`

#### Step 10: Update config_apply Handler

In `handle_event("config_apply", config_changes, socket)`:

```elixir
def handle_event("config_apply", config_changes, socket) do
  grid = socket.assigns.grid

  # Apply Phase 1: Column changes
  grid = Grid.apply_config_changes(grid, config_changes)

  # Apply Phase 2: Grid settings changes (NEW)
  grid = case Grid.apply_grid_settings(grid, config_changes["options"]) do
    {:ok, new_grid} ->
      new_grid

    {:error, reason} ->
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

### Phase 2E: CSS Styling

**File:** `assets/css/grid/config-modal.css`

#### Step 11: Add Phase 2 Styles

```css
/* Grid Settings Tab */
.grid-settings-tab {
  padding: 1.5rem;
  max-height: 600px;
  overflow-y: auto;
}

.form-section {
  margin-bottom: 2rem;
  padding-bottom: 2rem;
  border-bottom: 1px solid #e0e0e0;
}

.form-section:last-child {
  border-bottom: none;
}

.form-section h3 {
  font-size: 1.1rem;
  font-weight: 600;
  margin-bottom: 1rem;
  color: #333;
}

/* Form Groups */
.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #555;
}

.form-group select,
.form-group input[type="number"] {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 1rem;
}

/* Checkbox Groups */
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
  margin-bottom: 0;
  cursor: pointer;
}

.form-checkbox-group input[type="checkbox"] {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

/* Slider */
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

.form-slider::-moz-range-thumb {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #2196f3;
  cursor: pointer;
  border: none;
}

.slider-labels {
  display: flex;
  justify-content: space-between;
  font-size: 0.875rem;
  color: #666;
  margin-top: 0.5rem;
}

/* Value Display */
.value-display {
  font-family: monospace;
  background: #f0f0f0;
  padding: 0.25rem 0.5rem;
  border-radius: 3px;
  margin-left: 0.5rem;
}

/* Help Text */
.help-text {
  font-size: 0.875rem;
  color: #666;
  margin-top: 0.5rem;
}

/* Theme Preview */
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

/* Responsive */
@media (max-width: 640px) {
  .grid-settings-tab {
    max-height: none;
  }

  .form-checkbox-group {
    flex-direction: column;
  }

  .slider-labels {
    font-size: 0.75rem;
  }
}
```

---

### Phase 2F: Testing

**File:** `test/liveview_grid/grid_test.exs`

#### Step 12: Create Unit Tests for Grid.apply_grid_settings/2

- [ ] Test page_size validation
- [ ] Test theme validation
- [ ] Test row_height validation
- [ ] Test frozen_columns validation
- [ ] Test virtual_scroll toggle
- [ ] Test display toggles (show_row_number, show_header, show_footer)
- [ ] Test multiple options applied together
- [ ] Test error handling for invalid inputs
- [ ] Test type coercion from strings to correct types

#### Step 13: Create Component Tests

- [ ] Test GridSettingsTab renders correctly
- [ ] Test form inputs send correct events
- [ ] Test ConfigModal Tab 4 button renders
- [ ] Test switching to Tab 4 works

#### Step 14: Create Integration Tests

- [ ] Test full workflow: open modal → go to Tab 4 → change settings → apply
- [ ] Test grid re-renders with new settings
- [ ] Test multiple sections can be configured
- [ ] Test reset reverts changes

---

### Phase 2G: Demo Integration

**File:** `lib/liveview_grid_web/live/grid_config_demo_live.ex`

#### Step 15: Update Demo Page

```elixir
defmodule LiveviewGridWeb.GridConfigDemoLive do
  use LiveviewGridWeb, :live_view

  def mount(_params, _session, socket) do
    # Existing demo setup...

    # NEW Phase 2: Initialize grid with all options
    grid = Grid.new(
      data: data,
      columns: columns,
      options: %{
        page_size: 10,
        theme: "light",
        virtual_scroll: false,
        row_height: 40,
        frozen_columns: 0,
        show_row_number: true,
        show_header: true,
        show_footer: false
      }
    )

    {:ok,
      socket
      |> assign(:grid, grid)
      |> assign(:config_apply_count, 0)
      |> assign(:current_options, grid.options)  # NEW: Track current options
    }
  end

  def handle_event("apply_grid_config", config_changes, socket) do
    grid = socket.assigns.grid
    grid = Grid.apply_config_changes(grid, config_changes)
    grid = case Grid.apply_grid_settings(grid, config_changes["options"]) do
      {:ok, new_grid} -> new_grid
      {:error, _} -> grid
    end

    {:noreply,
      socket
      |> assign(:grid, grid)
      |> assign(:current_options, grid.options)  # NEW: Update displayed options
      |> assign(:config_apply_count, socket.assigns.config_apply_count + 1)
    }
  end
end
```

#### Step 16: Update Demo Template

In the render function, add:

```heex
<!-- Display Current Grid Options (NEW) -->
<div class="config-info">
  <h3>Current Grid Settings</h3>
  <div class="settings-grid">
    <div class="setting-item">
      <span class="label">Page Size:</span>
      <span class="value"><%= @current_options.page_size %> rows</span>
    </div>
    <div class="setting-item">
      <span class="label">Theme:</span>
      <span class="value"><%= @current_options.theme %></span>
    </div>
    <div class="setting-item">
      <span class="label">Row Height:</span>
      <span class="value"><%= @current_options.row_height %>px</span>
    </div>
    <div class="setting-item">
      <span class="label">Virtual Scroll:</span>
      <span class="value"><%= if @current_options.virtual_scroll, do: "✅ On", else: "❌ Off" %></span>
    </div>
    <div class="setting-item">
      <span class="label">Frozen Columns:</span>
      <span class="value"><%= @current_options.frozen_columns %></span>
    </div>
  </div>
</div>
```

---

## ✅ Implementation Verification Checklist

### Code Quality
- [ ] No compilation errors
- [ ] No console warnings
- [ ] All type specs present
- [ ] Functions are well-documented

### Functionality
- [ ] Tab 4 renders in ConfigModal
- [ ] All form controls render correctly
- [ ] Form inputs send correct events
- [ ] Grid settings are applied to grid

### Validation
- [ ] page_size validated (1-1000)
- [ ] theme validated (light/dark/custom)
- [ ] row_height validated (32-80)
- [ ] frozen_columns validated (0-column_count)
- [ ] Boolean fields validated

### Integration
- [ ] Phase 1 and Phase 2 changes work together
- [ ] ConfigModal sends both Phase 1 + Phase 2 data
- [ ] GridComponent receives and applies both
- [ ] Demo page shows current options

### Testing
- [ ] Unit tests pass for Grid.apply_grid_settings/2
- [ ] Component tests pass for GridSettingsTab
- [ ] Integration tests pass for full workflow
- [ ] Demo page functional

---

## 🔍 Testing Commands

```bash
# Run all tests
mix test

# Run only grid tests
mix test test/liveview_grid/grid_test.exs

# Run with coverage
mix test --cover

# Watch tests for changes
mix test.watch

# Run specific test
mix test test/liveview_grid/grid_test.exs:grid_test --no-start
```

---

## 📊 Estimated Time Breakdown

| Task | Estimated Time |
|------|-----------------|
| Step 1-2: Backend functions + tests | 1.5 hours |
| Step 3-8: ConfigModal extensions | 1 hour |
| Step 9: GridSettingsTab component | 1 hour |
| Step 10: GridComponent integration | 30 minutes |
| Step 11: CSS styling | 30 minutes |
| Step 12-14: Testing | 1 hour |
| Step 15-16: Demo integration | 30 minutes |
| **Total** | **~5.5 hours** |

---

## 🚀 Quick Start

1. Start with **Step 1-2**: Implement and test `Grid.apply_grid_settings/2`
2. Then **Step 3-8**: Extend ConfigModal for Phase 2
3. Then **Step 9**: Create GridSettingsTab component
4. Then **Step 10**: Update GridComponent event handler
5. Then **Step 11**: Add CSS styling
6. Then **Step 12-14**: Run full test suite
7. Then **Step 15-16**: Update demo page
8. Finally: **Manual testing** in browser

---

## 🐛 Troubleshooting

### Tab 4 doesn't appear
- [ ] Check ConfigModal `:grid_settings` case in render is present
- [ ] Verify tab button has correct phx-value-tab="grid_settings"

### Form inputs don't send events
- [ ] Verify phx-change="form_update" is present
- [ ] Check phx-target={@target} is set correctly
- [ ] Verify phx-value-option attribute matches option name

### Settings not applied to grid
- [ ] Check Grid.apply_grid_settings/2 returns {:ok, grid}
- [ ] Verify GridComponent handles "config_apply" event
- [ ] Check config_changes["options"] is passed correctly

### Type coercion errors
- [ ] Verify coerce_option_value/2 handles all option types
- [ ] Check String to integer/boolean conversion logic
- [ ] Add debug logging to track value transformations

---

## 📝 Next Steps After Implementation

1. Run `/pdca analyze grid-config-phase2` to verify implementation against design
2. If Match Rate < 90%, run `/pdca iterate grid-config-phase2` for auto-improvements
3. Once Match Rate ≥ 90%, run `/pdca report grid-config-phase2` for completion report
4. Finally, `/pdca archive grid-config-phase2` to complete Phase 2

---

**Ready to start? Follow the checklist above in order. Good luck! 🎉**
