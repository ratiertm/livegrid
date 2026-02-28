# Implementation Guide - Grid Configuration UI Phase 1

**Feature:** grid-config
**Phase:** 1 (Column Configuration MVP)
**Status:** Do Phase (Implementation)
**Estimated Duration:** 3-5 days
**Start Date:** 2026-02-26

---

## 1. Pre-Implementation Checklist

Before starting, verify:

- ✅ Plan document exists: `docs/01-plan/features/grid-config.plan.md`
- ✅ Design document exists: `docs/02-design/features/grid-config.design.md`
- ✅ All dependencies available (Phoenix LiveView, TailwindCSS, etc.)
- ✅ Local development server can run (`mix phx.server`)
- ✅ Test server can run (`mix test`)

---

## 2. Implementation Order (Step-by-Step)

### Step 1: Create Grid.apply_config_changes/2 Function
**Duration:** 1-2 hours
**Files:**
- `lib/liveview_grid/grid.ex`

**Tasks:**
1. [ ] Add function signature with type specs
2. [ ] Implement config_changes validation
3. [ ] Implement column update logic
4. [ ] Implement column visibility & order logic
5. [ ] Add helper functions (normalize_config, validate_columns, etc.)
6. [ ] Test with basic config changes

**Code Template:**
```elixir
# In lib/liveview_grid/grid.ex

@doc """
Apply configuration changes to grid (from modal form)

Changes structure:
  - columns: updated column definitions
  - column_order: reordered column fields
  - hidden_columns: list of hidden column fields
"""
def apply_config_changes(grid, config_changes) do
  # Implement here
end

# Helper functions
defp normalize_config_changes(config_changes), do: ...
defp validate_columns!(config_changes, grid), do: ...
defp update_columns(columns, config_changes), do: ...
defp apply_column_visibility_and_order(columns, config_changes), do: ...
```

**Test Example:**
```elixir
# Test basic column update
config = %{
  "columns" => [
    %{
      "field" => :name,
      "label" => "이름 (Updated)",
      "width" => 200
    }
  ]
}

new_grid = Grid.apply_config_changes(grid, config)
assert Enum.find(new_grid.columns, &(&1.field == :name)).label == "이름 (Updated)"
```

---

### Step 2: Create ConfigModal LiveComponent
**Duration:** 2-3 hours
**Files:**
- `lib/liveview_grid_web/components/grid_config/config_modal.ex`

**Tasks:**
1. [ ] Create directory structure
   ```bash
   mkdir -p lib/liveview_grid_web/components/grid_config/tabs
   ```

2. [ ] Create ConfigModal component
   - Define attributes: `grid`, `show`
   - Define internal state (current_tab, form_state, backups)
   - Implement event handlers:
     - `tab_select` - switch tabs
     - `config_apply` - send to parent
     - `config_cancel` - close modal
     - `config_reset` - restore original values

3. [ ] Create modal structure (HTML):
   - Modal overlay
   - Header with close button
   - Tab navigation (3 tabs)
   - Content area (dynamic per tab)
   - Action buttons (Cancel, Reset, Apply)

4. [ ] Implement form state management
   - Store original columns backup on mount
   - Update form_state on input changes
   - Persist data between tab switches

**Component Structure:**
```elixir
# lib/liveview_grid_web/components/grid_config/config_modal.ex

defmodule LiveviewGridWeb.Components.GridConfig.ConfigModal do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <!-- Modal structure -->
    <div class="fixed inset-0 bg-black bg-opacity-50">
      <div class="bg-white rounded-lg shadow-lg">
        <!-- Header -->
        <div class="flex justify-between">
          <h2>⚙ Grid Configuration</h2>
          <button phx-click="config_cancel">✕</button>
        </div>

        <!-- Tabs -->
        <div class="border-b">
          <!-- Tab buttons -->
        </div>

        <!-- Content -->
        <div>
          <%= case @current_tab do %>
            <% :visibility -> %><.column_visibility_tab ... />
            <% :properties -> %><.column_properties_tab ... />
            <% :formatters -> %><.column_formatters_tab ... />
          <% end %>
        </div>

        <!-- Actions -->
        <div class="flex justify-end space-x-2">
          <button phx-click="config_cancel">Cancel</button>
          <button phx-click="config_reset">Reset</button>
          <button phx-click="config_apply">Apply</button>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("tab_select", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :current_tab, String.to_atom(tab))}
  end

  def handle_event("config_apply", _params, socket) do
    # Send config to parent
    {:noreply, socket}
  end

  def handle_event("config_cancel", _params, socket) do
    # Close modal
    {:noreply, socket}
  end

  def handle_event("config_reset", _params, socket) do
    # Restore backups
    {:noreply, socket}
  end
end
```

---

### Step 3: Create Column Visibility Tab Component
**Duration:** 2 hours
**Files:**
- `lib/liveview_grid_web/components/grid_config/tabs/column_visibility_tab.ex`

**Tasks:**
1. [ ] Create component that receives:
   - `columns` - list of all columns
   - `columns_visible` - map of field => visible (boolean)
   - `columns_order` - reordered field list

2. [ ] Render draggable list:
   - Checkbox for each column (show/hide)
   - Drag handle (:::)
   - Column label

3. [ ] Implement events:
   - `toggle_column` - toggle show/hide checkbox
   - `reorder_columns` - from JS hook (drag-drop)

4. [ ] Connect to JS hook for drag-drop

**Component Template:**
```elixir
# lib/liveview_grid_web/components/grid_config/tabs/column_visibility_tab.ex

def render(assigns) do
  ~H"""
  <div class="column-visibility-tab">
    <h3>📋 Column Visibility & Order</h3>

    <div class="column-list" phx-hook="ColumnReorder">
      <%= for column <- @columns do %>
        <div class="column-list__item" draggable="true">
          <input
            type="checkbox"
            checked={Map.get(@columns_visible, column.field, true)}
            phx-click="toggle_column"
            phx-value-field={column.field}
          />
          <span class="drag-handle">:::</span>
          <span><%= column.label %></span>
        </div>
      <% end %>
    </div>
  </div>
  """
end
```

---

### Step 4: Create Column Properties Tab Component
**Duration:** 2-3 hours
**Files:**
- `lib/liveview_grid_web/components/grid_config/tabs/column_properties_tab.ex`

**Tasks:**
1. [ ] Create component with state:
   - `selected_column` - currently editing column
   - `column_updates` - changes for each column

2. [ ] Render form fields:
   - Column selector (select dropdown)
   - Label input
   - Width input (number) + slider
   - Alignment select (left, center, right)
   - Sortable checkbox
   - Filterable checkbox
   - Editable checkbox

3. [ ] Implement events:
   - `select_column` - switch column in form
   - `update_property` - update single field
   - Form state persists when switching columns

4. [ ] Add validation:
   - Width must be positive integer
   - Label must not be empty

**Component Sketch:**
```elixir
def render(assigns) do
  ~H"""
  <div class="column-properties-tab">
    <h3>⚙ Column Properties</h3>

    <!-- Column Selector -->
    <select phx-change="select_column">
      <%= for col <- @columns do %>
        <option value={col.field} selected={col.field == @selected_column}>
          <%= col.label %>
        </option>
      <% end %>
    </select>

    <!-- Property Form -->
    <%= if @selected_column do %>
      <div class="form-group">
        <label>Label</label>
        <input
          type="text"
          value={get_column_value(@selected_column, :label)}
          phx-change="update_property"
          phx-value-field={@selected_column}
          phx-value-property="label"
        />
      </div>
      <!-- More form fields... -->
    <% end %>
  </div>
  """
end
```

---

### Step 5: Create Column Formatters & Validators Tab Component
**Duration:** 3 hours
**Files:**
- `lib/liveview_grid_web/components/grid_config/tabs/column_formatters_tab.ex`

**Tasks:**
1. [ ] Create component sections:
   - Formatter selection & configuration
   - Validator builder

2. [ ] Formatter section:
   - Type selector (dropdown with all formatter types)
   - Options form (context-sensitive based on type)
   - Preview of formatted output
   - Example: Currency formatter shows symbol, precision options

3. [ ] Validator section:
   - List of validators
   - Add validator button
   - For each validator:
     - Type selector
     - Validator-specific fields
     - Remove button

4. [ ] Implement events:
   - `select_formatter` - change formatter type
   - `update_formatter_option` - update formatter config
   - `add_validator` - add new validator
   - `remove_validator` - remove validator
   - `toggle_validator` - enable/disable

5. [ ] Create helper functions:
   - Get formatter options form per type
   - Render formatter options dynamically
   - Validate formatter configuration

---

### Step 6: Integrate with GridComponent
**Duration:** 1.5 hours
**Files:**
- `lib/liveview_grid_web/components/grid_component.ex`

**Tasks:**
1. [ ] Add state to GridComponent:
   - `:show_config_modal` boolean

2. [ ] Add Configure button to toolbar:
   ```elixir
   <button phx-click="config_show_modal" class="btn">
     ⚙ Configure
   </button>
   ```

3. [ ] Handle events in parent LiveView:
   - `config_show_modal` - show modal
   - `config_apply` - apply config changes
     - Call `Grid.apply_config_changes/2`
     - Update grid in assigns
     - Close modal

4. [ ] Render ConfigModal component:
   ```elixir
   <%= if @show_config_modal do %>
     <.live_component
       module={LiveviewGridWeb.Components.GridConfig.ConfigModal}
       id="grid-config-modal"
       grid={@grid}
     />
   <% end %>
   ```

---

### Step 7: Create CSS Styling
**Duration:** 2 hours
**Files:**
- `assets/css/grid/config-modal.css`

**Tasks:**
1. [ ] Create CSS classes for:
   - `.config-modal` - modal container
   - `.config-modal__header` - header
   - `.config-modal__tabs` - tab navigation
   - `.config-modal__content` - content area
   - `.config-modal__actions` - action buttons

2. [ ] Style form controls:
   - Input fields
   - Select dropdowns
   - Checkboxes
   - Sliders (width)

3. [ ] Responsive design:
   - Max-width 900px on desktop
   - Full screen on mobile (< 640px)

4. [ ] Add transitions:
   - Tab switching animation
   - Modal open/close

---

### Step 8: Create JavaScript Hook (Drag-Drop)
**Duration:** 1.5 hours
**Files:**
- `assets/js/hooks/column-reorder.js`

**Tasks:**
1. [ ] Create HTML5 drag-drop hook:
   ```javascript
   export const ColumnReorder = {
     mounted() {
       // Setup event listeners
     },
     dragStart(e) { /* ... */ },
     dragOver(e) { /* ... */ },
     drop(e) { /* ... */ },
     dragEnd(e) { /* ... */ }
   }
   ```

2. [ ] Implement drag functionality:
   - Reorder items in DOM
   - Calculate new order
   - Send "reorder_columns" event

3. [ ] Add visual feedback:
   - Cursor change (grab/grabbing)
   - Opacity on drag
   - Highlight drop target

4. [ ] Export hook in `assets/js/app.js`:
   ```javascript
   import { ColumnReorder } from "./hooks/column-reorder"
   let Hooks = {
     ColumnReorder
   }
   ```

---

### Step 9: Add Demo Example
**Duration:** 1 hour
**Files:**
- `lib/liveview_grid_web/live/demo_live.ex`

**Tasks:**
1. [ ] Create new page or modify existing demo
2. [ ] Enable ConfigModal in grid render
3. [ ] Test end-to-end workflow

---

### Step 10: Testing & Verification
**Duration:** 2-3 hours

**Unit Tests:**
- [ ] Test `Grid.apply_config_changes/2`
  - Valid config changes
  - Invalid config (missing columns, etc.)
  - Column hiding/reordering
  - Formatter updates
  - Validator updates

**Component Tests:**
- [ ] ConfigModal component
  - Tab switching
  - Form state management
  - Events (apply, cancel, reset)

**Integration Tests:**
- [ ] End-to-end workflow
  - Open modal
  - Configure columns
  - Click Apply
  - Grid updates correctly
  - No page reload

**Manual Testing:**
- [ ] Open modal with Configure button
- [ ] Toggle column visibility
- [ ] Drag columns to reorder
- [ ] Edit column properties
- [ ] Change formatters
- [ ] Add/remove validators
- [ ] Verify grid updates live
- [ ] Test on mobile (responsive)

---

## 3. File Checklist (Phase 1)

### Create Files
```
lib/liveview_grid_web/components/grid_config/
├── config_modal.ex                          (NEW)
└── tabs/
    ├── column_visibility_tab.ex             (NEW)
    ├── column_properties_tab.ex             (NEW)
    └── column_formatters_tab.ex             (NEW)

assets/js/hooks/
└── column-reorder.js                        (NEW)

assets/css/grid/
└── config-modal.css                         (NEW)

test/
├── liveview_grid/grid_test.exs             (MODIFY - add apply_config_changes tests)
└── liveview_grid_web/components/...        (NEW - component tests)
```

### Modify Files
```
lib/liveview_grid/grid.ex                    (ADD - apply_config_changes/2)
lib/liveview_grid_web/components/grid_component.ex  (ADD - config button + modal)
lib/liveview_grid_web/live/demo_live.ex     (MODIFY - enable modal in demo)
assets/js/app.js                             (ADD - import ColumnReorder hook)
assets/css/liveview_grid.css                 (IMPORT - config-modal.css)
```

---

## 4. Implementation Tips & Best Practices

### Code Organization
- Keep components small and focused (single responsibility)
- Use slot-based components for reusability
- Extract helper functions to separate modules

### State Management
- Use LiveComponent state for modal-specific state
- Keep backup of original config for Reset functionality
- Validate form state before sending to parent

### Testing
- Test each component in isolation first
- Use Phoenix testing utilities (render_component, etc.)
- Test event handlers with various inputs
- Test error cases and validation

### Performance
- Use `phx-debounce` for form inputs if needed
- Minimize re-renders with proper assigns
- Test with large grids (100+ columns) to catch perf issues

### Accessibility
- Add `aria-` attributes for screen readers
- Ensure keyboard navigation works (Tab, Enter, Escape)
- Use semantic HTML (button, input, select, etc.)
- Add labels for form controls

### CSS
- Use TailwindCSS utility classes where possible
- Keep custom CSS minimal
- Use CSS variables for theming
- Ensure responsive design (mobile-first)

---

## 5. Debugging Guide

**Common Issues:**

1. **Modal doesn't appear**
   - Check `show_config_modal` state in GridComponent
   - Verify event handler "config_show_modal" is hooked
   - Check browser console for errors

2. **Form changes don't persist**
   - Ensure form_state is properly updated in assigns
   - Check event handler parameters
   - Verify phx-value- attributes are correct

3. **Drag-drop not working**
   - Check JS hook is properly imported in app.js
   - Verify `phx-hook="ColumnReorder"` attribute
   - Check browser console for JS errors

4. **Grid doesn't update after Apply**
   - Check `Grid.apply_config_changes/2` return value
   - Verify socket assigns are updated correctly
   - Check if grid is properly re-rendered

**Debug Commands:**
```bash
# Run tests
mix test test/liveview_grid/grid_test.exs
mix test test/liveview_grid_web/components/...

# Check build errors
mix compile

# Run in interactive mode for debugging
iex -S mix phx.server
```

---

## 6. Success Criteria

✅ **All tasks completed when:**

- [ ] All 10 steps above are completed
- [ ] `Grid.apply_config_changes/2` works correctly
- [ ] ConfigModal opens/closes without errors
- [ ] All 3 tabs display correctly
- [ ] Form changes are captured
- [ ] Clicking Apply updates grid live
- [ ] No console errors
- [ ] Responsive on mobile
- [ ] All tests pass
- [ ] Demo shows working example

**Acceptance Test Script:**
```
1. Navigate to demo page
2. Click "⚙ Configure" button
3. Modal opens (should show 3 tabs)
4. Click Tab 1 (Column Visibility):
   - All columns show with checkboxes
   - Uncheck one column
5. Click Tab 2 (Column Properties):
   - Select a column from dropdown
   - Change label to "Updated Name"
   - Change width to 200
   - Change alignment to "Center"
6. Click Tab 3 (Formatters):
   - Select a formatter (e.g., currency)
   - Configure formatter options
7. Click "Apply" button
8. Modal closes
9. Grid updates:
   - One column hidden
   - Column label changed
   - Column width updated
   - Column aligned to center
   - Formatter applied
10. NO page reload occurred
```

---

## 7. Next Steps

After Phase 1 completion:
- [ ] Run Gap Analysis: `/pdca analyze grid-config`
- [ ] Generate Completion Report: `/pdca report grid-config` (if Match Rate >= 90%)
- [ ] Plan Phase 2 (Grid Settings): `/pdca plan grid-config-p2`

---

**Last Updated:** 2026-02-26
**Implementation Ready:** Yes ✅

