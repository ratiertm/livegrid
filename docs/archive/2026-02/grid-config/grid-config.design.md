# Design Document - Grid Configuration UI (Phase 1: Column Configuration)

**Status:** Design Phase
**Feature:** grid-config
**Version:** 1.0 (Phase 1 MVP)
**Last Updated:** 2026-02-26

---

## 1. Executive Summary

This document specifies the detailed design for **Phase 1: Column Configuration Modal** - a user interface that allows dynamic configuration of Grid columns without code changes.

**Phase 1 Scope:** Column visibility, properties, formatters, and validators configuration through a modal dialog with 3 tabs.

**Design Goal:** Create an intuitive, responsive modal UI that integrates seamlessly with the existing Grid component and applies configuration changes live without page reload.

---

## 2. Architecture Overview

### 2.1 High-Level Component Structure

```
GridComponent (existing)
├── Grid Toolbar
│   ├── [Existing Controls]
│   └── [NEW] ⚙ Configure Button
│       └── (triggers config_show_modal event)
└── [NEW] GridConfigModal (LiveComponent)
    ├── Tab Navigation (3 tabs for Phase 1)
    │   ├── [Tab 1] Column Visibility & Order
    │   ├── [Tab 2] Column Properties
    │   └── [Tab 3] Formatters & Validators
    ├── Content Area (changes per tab)
    └── Action Buttons: [Cancel] [Apply] [Reset]
```

### 2.2 Data Flow Architecture

```
┌─────────────────────────────────────────────────┐
│ GridComponent (Parent LiveView)                 │
├─────────────────────────────────────────────────┤
│                                                 │
│  socket.assigns                                 │
│  ├── :grid (Grid struct)                        │
│  ├── :show_config_modal (boolean)               │
│  └── :config_form_state (form data)             │
│                                                 │
│  Event Handlers:                                │
│  ├── "config_show" → set show_config_modal=true │
│  ├── "config_hide" → set show_config_modal=false│
│  └── "config_apply" ← from ConfigModal          │
│      └── Grid.apply_config_changes(grid, data)  │
│          └── Update socket.assigns[:grid]       │
│                                                 │
│  ┌───────────────────────────────────────┐      │
│  │ GridConfigModal (LiveComponent)       │      │
│  │                                       │      │
│  │ State Management:                     │      │
│  │ ├── :current_tab (atom)               │      │
│  │ ├── :form_state (map)                 │      │
│  │ ├── :columns_backup (list)            │      │
│  │ └── :options_backup (map)             │      │
│  │                                       │      │
│  │ Event Handlers:                       │      │
│  │ ├── "tab_select" → update :current_tab│      │
│  │ ├── "form_update" → update form_state │      │
│  │ ├── "config_apply" → send to parent   │      │
│  │ ├── "config_cancel" → close modal     │      │
│  │ └── "config_reset" → restore backup   │      │
│  │                                       │      │
│  │ Renders:                              │      │
│  │ ├── Tab Navigation                    │      │
│  │ ├── Column Visibility Tab             │      │
│  │ ├── Column Properties Tab             │      │
│  │ ├── Formatters & Validators Tab       │      │
│  │ └── Action Buttons                    │      │
│  └───────────────────────────────────────┘      │
└─────────────────────────────────────────────────┘
```

---

## 3. Component Specifications

### 3.1 GridConfigModal Component

**File:** `lib/liveview_grid_web/components/grid_config/config_modal.ex`

**Type:** LiveComponent
**Attributes:**
```elixir
attr :grid, :any, required: true          # Grid struct
attr :show, :boolean, default: false      # Modal visibility
```

**State (assigns):**
```elixir
%{
  current_tab: :visibility,                # :visibility | :properties | :formatters
  form_state: %{
    # Tab 1 data
    columns_visible: %{
      field_name => boolean                # e.g., :name => true (visible)
    },
    columns_order: [atom],                 # reordered field list

    # Tab 2 data
    selected_column: atom,                 # currently editing column
    column_updates: %{
      field_name => %{
        label: string,
        width: integer | :auto,
        align: :left | :center | :right,
        sortable: boolean,
        filterable: boolean,
        editable: boolean,
        ...
      }
    },

    # Tab 3 data
    formatters: %{
      field_name => %{
        type: :currency | :number | :date | ...,
        options: %{...}
      }
    },
    validators: %{
      field_name => [
        %{type: :required, message: string},
        %{type: :pattern, pattern: string, message: string},
        ...
      ]
    }
  },

  # Backup for reset functionality
  columns_backup: [original columns],
  options_backup: %{original options}
}
```

**Event Handlers:**
```elixir
def handle_event("tab_select", %{"tab" => tab}, socket)
  # Switch between tabs
  # Validate form data before switching

def handle_event("form_update", %{"field" => field, "value" => value}, socket)
  # Update form_state for current field

def handle_event("config_apply", _params, socket)
  # Emit "config_apply" event to parent with form_state
  # Parent calls Grid.apply_config_changes/2

def handle_event("config_cancel", _params, socket)
  # Reset to original values
  # Close modal

def handle_event("config_reset", _params, socket)
  # Reset form_state to backup values
```

**Render Structure:**
```html
<!-- Modal Overlay -->
<div class="fixed inset-0 bg-black bg-opacity-50" phx-click="config_cancel">
  <div class="bg-white rounded-lg shadow-lg max-w-2xl mx-auto p-6">
    <!-- Header -->
    <div class="flex justify-between items-center mb-4">
      <h2 class="text-2xl font-bold">⚙ Grid Configuration</h2>
      <button phx-click="config_cancel">✕</button>
    </div>

    <!-- Tab Navigation -->
    <div class="border-b border-gray-200 mb-4">
      <div class="flex space-x-4">
        <button class="tab" phx-click="tab_select" value="visibility">
          📋 Column Visibility
        </button>
        <button class="tab" phx-click="tab_select" value="properties">
          ⚙ Column Properties
        </button>
        <button class="tab" phx-click="tab_select" value="formatters">
          🎨 Formatters & Validators
        </button>
      </div>
    </div>

    <!-- Content Area (dynamic based on current_tab) -->
    <div class="content-area mb-6">
      <%= case @current_tab do %>
        <% :visibility -> %>
          <.column_visibility_tab ... />
        <% :properties -> %>
          <.column_properties_tab ... />
        <% :formatters -> %>
          <.column_formatters_tab ... />
      <% end %>
    </div>

    <!-- Action Buttons -->
    <div class="flex justify-end space-x-2">
      <button class="btn btn-secondary" phx-click="config_cancel">Cancel</button>
      <button class="btn btn-secondary" phx-click="config_reset">Reset</button>
      <button class="btn btn-primary" phx-click="config_apply">Apply</button>
    </div>
  </div>
</div>
```

---

### 3.2 Tab Components

#### 3.2.1 Column Visibility Tab Component

**File:** `lib/liveview_grid_web/components/grid_config/tabs/column_visibility_tab.ex`

**Purpose:** Allow users to show/hide columns and reorder them via drag-drop.

**State Required:**
```elixir
columns: list(column_map)
columns_visible: %{field_name => boolean}
columns_order: [atom]
```

**UI Structure:**
```
┌─────────────────────────────────────┐
│ 📋 Column Visibility & Order        │
├─────────────────────────────────────┤
│                                     │
│ [Draggable List]                    │
│ ═════════════════════════════════   │
│ ☑ [:::] Name          (sortable)    │
│ ☑ [:::] Email         (sortable)    │
│ ☐ [:::] Phone         (sortable)    │
│ ☑ [:::] Salary        (sortable)    │
│ ═════════════════════════════════   │
│                                     │
│ Hint: Uncheck to hide, drag to      │
│ reorder columns                     │
│                                     │
│ [Apply Changes]                     │
└─────────────────────────────────────┘
```

**Features:**
- Checkbox for each column (show/hide)
- Drag-drop handle (:::) for reordering
- Live preview of column order
- Label display (not editable on this tab)

**Event Handlers:**
```elixir
def handle_event("toggle_column", %{"field" => field}, socket)
  # Toggle column visibility

def handle_event("reorder_columns", %{"new_order" => order}, socket)
  # Update columns_order via JS drag-drop hook
```

**JavaScript Hook:** `assets/js/hooks/column-reorder.js`
- Enables HTML5 drag-drop
- Sends "reorder_columns" event with new order
- Visual feedback during drag (opacity, highlighting)

---

#### 3.2.2 Column Properties Tab Component

**File:** `lib/liveview_grid_web/components/grid_config/tabs/column_properties_tab.ex`

**Purpose:** Edit properties for individual columns.

**UI Structure:**
```
┌──────────────────────────────────────┐
│ ⚙ Column Properties                  │
├──────────────────────────────────────┤
│                                      │
│ Select Column: [Name ▼]              │
│ ────────────────────────────────────  │
│                                      │
│ Label:        [________________]     │
│ Width:        [150] px     [///////]│ (slider)
│ Alignment:    [Left ▼]               │
│ Sortable:     ☑                      │
│ Filterable:   ☑                      │
│ Editable:     ☑                      │
│                                      │
│ [Apply to Column] [Reset to Default] │
└──────────────────────────────────────┘
```

**Features:**
- Column selector (dropdown showing all columns)
- Form fields for editing properties:
  - `label` (text input) - column header text
  - `width` (number input + slider) - column width in pixels or :auto
  - `align` (select: left, center, right)
  - `sortable` (checkbox)
  - `filterable` (checkbox)
  - `editable` (checkbox)
- Form persists data when switching between columns
- Apply/Reset buttons for current column

**Event Handlers:**
```elixir
def handle_event("select_column", %{"field" => field}, socket)
  # Change selected_column, load its current properties

def handle_event("update_property", %{"field" => field, "property" => prop, "value" => val}, socket)
  # Update form_state[column_updates][field][property]

def handle_event("apply_column", _params, socket)
  # Apply changes to selected column

def handle_event("reset_column", _params, socket)
  # Reset selected column to original values
```

---

#### 3.2.3 Column Formatters & Validators Tab Component

**File:** `lib/liveview_grid_web/components/grid_config/tabs/column_formatters_tab.ex`

**Purpose:** Configure formatters and validators for columns.

**UI Structure - Part 1: Formatter Selection**
```
┌──────────────────────────────────────┐
│ 🎨 Formatters & Validators           │
├──────────────────────────────────────┤
│                                      │
│ Column: [Name ▼]                     │
│                                      │
│ [Formatter Configuration]            │
│ ────────────────────────────────────  │
│ Formatter Type: [currency ▼]         │
│   None | Currency | Number | Date    │
│   Percent | Boolean | Filesize |...  │
│                                      │
│ [Formatter Options]                  │
│ ────────────────────────────────────  │
│ Symbol: [₩]                          │
│ Precision: [0]                       │
│ Position: [Prefix ▼]                 │
│                                      │
│ [Preview]: ₩150,000                  │
│                                      │
```

**UI Structure - Part 2: Validator Management**
```
│ [Validators]                         │
│ ────────────────────────────────────  │
│                                      │
│ ☑ Required                           │
│   Message: [필수 입력입니다]         │
│   [x]                                │
│                                      │
│ ☑ Pattern                            │
│   Pattern: [@]                       │
│   Message: [유효한 이메일]           │
│   [x]                                │
│                                      │
│ ☐ Custom                             │
│   Message: [________________]         │
│   [x]                                │
│                                      │
│ [+ Add Validator] [Reset Validators] │
└──────────────────────────────────────┘
```

**Features:**
- Column selector
- Formatter type dropdown with all available types
- Context-sensitive formatter options (change based on formatter type)
- Live preview of formatter output
- Validator list with enable/disable toggles
- Validator-specific fields (pattern, message, min/max, etc.)
- Add/Remove validator buttons

**Event Handlers:**
```elixir
def handle_event("select_column", %{"field" => field}, socket)
  # Load column's current formatter and validators

def handle_event("select_formatter", %{"type" => type}, socket)
  # Change formatter type, reset options form

def handle_event("update_formatter_option", %{"option" => opt, "value" => val}, socket)
  # Update formatter options

def handle_event("add_validator", %{"type" => type}, socket)
  # Add new validator to validators list

def handle_event("remove_validator", %{"index" => idx}, socket)
  # Remove validator from list

def handle_event("toggle_validator", %{"index" => idx}, socket)
  # Enable/disable validator
```

---

## 4. Data Schema & Config Changes

### 4.1 Configuration Changes Structure (sent to parent)

```elixir
config_changes = %{
  "columns" => [
    %{
      "field" => :name,
      "label" => "이름",
      "width" => 150,
      "align" => "left",
      "sortable" => true,
      "filterable" => true,
      "editable" => true,
      "formatter" => "none",
      "formatter_options" => %{},
      "validators" => [
        %{"type" => "required", "message" => "이름은 필수입니다"}
      ]
    },
    %{
      "field" => :email,
      "label" => "이메일",
      "width" => 200,
      "align" => "left",
      "sortable" => true,
      "filterable" => true,
      "editable" => true,
      "formatter" => "none",
      "formatter_options" => %{},
      "validators" => [
        %{"type" => "required", "message" => "이메일은 필수입니다"},
        %{"type" => "pattern", "pattern" => "@", "message" => "유효한 이메일을 입력하세요"}
      ]
    },
    ...
  ],
  "column_order" => [:id, :name, :email, :salary],
  "hidden_columns" => [:phone, :address]
}
```

### 4.2 Supported Formatter Types & Options

```elixir
# Formatter Configuration Examples

# 1. Currency Formatter
%{
  "type" => "currency",
  "options" => %{
    "symbol" => "₩",
    "precision" => 0,
    "position" => "prefix"  # prefix | suffix
  }
}

# 2. Number Formatter
%{
  "type" => "number",
  "options" => %{
    "precision" => 2,
    "separator" => ",",
    "delimiter" => "."
  }
}

# 3. Date Formatter
%{
  "type" => "date",
  "options" => %{
    "format" => "YYYY-MM-DD"
  }
}

# 4. Percent Formatter
%{
  "type" => "percent",
  "options" => %{
    "precision" => 1,
    "multiplier" => 100
  }
}

# 5. Boolean Formatter
%{
  "type" => "boolean",
  "options" => %{
    "true_label" => "예",
    "false_label" => "아니오"
  }
}

# 6. Truncate Formatter
%{
  "type" => "truncate",
  "options" => %{
    "max_length" => 50
  }
}

# (More formatters: filesize, time, datetime, relative_time, etc.)
```

### 4.3 Supported Validator Types

```elixir
# Validator Types

:required          # No additional options needed
:pattern           # Requires: pattern (regex string), message
:min               # Requires: value (integer), message
:max               # Requires: value (integer), message
:min_length        # Requires: length (integer), message
:max_length        # Requires: length (integer), message
:custom            # Requires: function (not UI configurable in Phase 1)
```

---

## 5. Integration with GridComponent

### 5.1 GridComponent Modifications

**File:** `lib/liveview_grid_web/components/grid_component.ex`

**Changes:**
1. Add state for modal visibility
2. Add "Configure" button to toolbar
3. Show/hide ConfigModal LiveComponent
4. Handle "config_apply" event from modal
5. Call `Grid.apply_config_changes/2`
6. Update socket assigns with new grid

**Code Sketch:**
```elixir
defmodule LiveviewGridWeb.Components.GridComponent do
  use Phoenix.LiveComponent

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("config_show_modal", _params, socket) do
    {:noreply, assign(socket, :show_config_modal, true)}
  end

  def handle_event("config_apply", config_changes, socket) do
    grid = socket.assigns.grid
    new_grid = Grid.apply_config_changes(grid, config_changes)

    {:noreply,
      socket
      |> assign(:grid, new_grid)
      |> assign(:show_config_modal, false)
    }
  end

  def render(assigns) do
    ~H"""
    <div>
      <!-- Toolbar with Configure button -->
      <div class="toolbar">
        ...
        <button phx-click="config_show_modal" class="btn">⚙ Configure</button>
      </div>

      <!-- Grid Content -->
      <div phx-id="grid">...</div>

      <!-- Config Modal -->
      <%= if @show_config_modal do %>
        <.live_component
          module={LiveviewGridWeb.Components.GridConfig.ConfigModal}
          id="grid-config-modal"
          grid={@grid}
          on_apply="config_apply"
        />
      <% end %>
    </div>
    """
  end
end
```

---

## 6. Grid.apply_config_changes/2 Function

**File:** `lib/liveview_grid/grid.ex`

**Function Signature:**
```elixir
def apply_config_changes(grid, config_changes) do
  # Validate config_changes
  # Apply changes to grid.columns and grid.state
  # Return updated grid
end
```

**Logic Flow:**
```elixir
def apply_config_changes(grid, config_changes) do
  config_changes = normalize_config_changes(config_changes)

  # Validate columns exist
  validate_columns!(config_changes, grid)

  # Apply column updates
  new_columns = update_columns(grid.columns, config_changes)

  # Apply column visibility and order
  new_columns = apply_column_visibility_and_order(
    new_columns,
    config_changes
  )

  # Return updated grid
  %{grid | columns: new_columns}
end

# Helper functions:
# - normalize_config_changes/1 - convert strings to atoms
# - validate_columns!/2 - check all columns exist in grid
# - update_columns/2 - update each column's properties
# - apply_column_visibility_and_order/2 - reorder and hide columns
```

---

## 7. CSS Styling & Responsive Design

**File:** `assets/css/grid/config-modal.css`

**Design Requirements:**
- Modal should be max-width 900px (large enough for tab content)
- Responsive on mobile (full screen on < 640px, scale down form controls)
- Tab navigation with clear active state
- Form controls consistent with existing grid styling
- Drag-drop cursor feedback (grab, grabbing hands)
- Smooth transitions when switching tabs

**Key CSS Classes:**
```css
.config-modal {}               /* Modal wrapper */
.config-modal__header {}       /* Header section */
.config-modal__tabs {}         /* Tab navigation */
.config-modal__tab {}          /* Individual tab */
.config-modal__tab--active {}  /* Active tab state */
.config-modal__content {}      /* Content area */
.config-modal__actions {}      /* Action buttons */

.column-list {}                /* Draggable column list */
.column-list__item {}          /* Column item */
.column-list__item--dragging {}/* Dragging state */
.column-list__item--drag-over {}/* Drop target state */

.form-control {}               /* Generic form control */
.form-input {}                 /* Input field */
.form-select {}                /* Select dropdown */
.form-checkbox {}              /* Checkbox */
.form-slider {}                /* Slider (width) */

.validator-item {}             /* Validator row */
.validator-item__fields {}     /* Validator input fields */
```

---

## 8. JavaScript Hooks

### 8.1 Column Reorder Hook

**File:** `assets/js/hooks/column-reorder.js`

**Purpose:** Enable drag-drop reordering of columns in Phase 1 Column Visibility tab.

**Functionality:**
- Listen to dragstart, dragover, drop, dragend events
- Reorder items in DOM
- Send "reorder_columns" event with new order
- Provide visual feedback (cursor, opacity, highlighting)

**Event Flow:**
```javascript
const ColumnReorder = {
  mounted() {
    // Setup drag event listeners
    this.el.addEventListener('dragstart', this.dragStart.bind(this))
    this.el.addEventListener('dragover', this.dragOver.bind(this))
    this.el.addEventListener('drop', this.drop.bind(this))
    this.el.addEventListener('dragend', this.dragEnd.bind(this))
  },

  dragStart(e) {
    this.draggedElement = e.target
    e.dataTransfer.effectAllowed = 'move'
  },

  dragOver(e) {
    e.preventDefault()
    e.dataTransfer.dropEffect = 'move'
    // Highlight drop target
  },

  drop(e) {
    e.preventDefault()
    // Swap elements in DOM
    // Calculate new order
    // Send event to server
    this.pushEvent('reorder_columns', {
      new_order: [...new order]
    })
  }
}
```

---

## 9. Error Handling & Validation

### 9.1 Client-Side Validation

**Before Sending to Server:**
- Validate column field existence
- Validate formatter type (must be in allowed list)
- Validate validator types (must be in allowed list)
- Validate input constraints (e.g., width must be positive integer)
- Show error messages in form (red border, error text below field)

### 9.2 Server-Side Validation

**In Grid.apply_config_changes/2:**
- Re-validate all changes
- Return error tuple if validation fails
- Prevent invalid changes from being applied
- Log validation errors (but don't crash)

### 9.3 User Feedback

**Modal:**
- Toast notification on successful apply
- Error dialog if validation fails
- Disabled Apply button if form invalid
- Clear error messages for each field

---

## 10. Phase 1 Implementation Checklist

### Component Files
- [ ] `lib/liveview_grid_web/components/grid_config/config_modal.ex`
- [ ] `lib/liveview_grid_web/components/grid_config/tabs/column_visibility_tab.ex`
- [ ] `lib/liveview_grid_web/components/grid_config/tabs/column_properties_tab.ex`
- [ ] `lib/liveview_grid_web/components/grid_config/tabs/column_formatters_tab.ex`

### Elixir Backend
- [ ] `Grid.apply_config_changes/2` function in `lib/liveview_grid/grid.ex`
- [ ] Config validation logic
- [ ] Error handling

### JavaScript & CSS
- [ ] `assets/js/hooks/column-reorder.js` (drag-drop hook)
- [ ] `assets/css/grid/config-modal.css` (styling)

### Integration
- [ ] Modify `lib/liveview_grid_web/components/grid_component.ex`
  - Add modal state
  - Add Configure button
  - Handle config_apply event
- [ ] Modify `lib/liveview_grid_web/live/demo_live.ex`
  - Add example with config modal enabled

### Testing
- [ ] Unit tests for `Grid.apply_config_changes/2`
- [ ] Component tests for ConfigModal
- [ ] Integration tests for end-to-end workflow

---

## 11. Success Criteria (Phase 1)

✅ **Functional Requirements:**
- User can open/close modal with Configure button
- User can toggle column visibility with checkboxes
- User can reorder columns with drag-drop
- User can edit column properties (label, width, align, sortable, filterable, editable)
- User can select formatter and configure options
- User can add/remove/configure validators
- Clicking Apply applies changes to grid **without page reload**
- Grid updates immediately with new configuration
- Clicking Cancel closes modal without applying changes
- Reset button reverts to original values

✅ **Quality Requirements:**
- No console errors or warnings
- Modal is keyboard accessible (Tab, Enter, Escape)
- Modal is responsive on desktop (900px max-width) and mobile (full-screen)
- Drag-drop feels smooth (visual feedback, 60fps)
- Form validation prevents invalid inputs
- Error messages are clear and actionable

✅ **Performance Requirements:**
- Modal opens within 500ms
- Form interactions feel responsive (< 100ms)
- Grid re-render on Apply < 1 second

---

## 12. Known Limitations & Future Enhancements

**Phase 1 Limitations:**
- No save/export configuration as JSON (Phase 4)
- No DataSource configuration (Phase 3)
- No Grid-level settings like page_size, theme (Phase 2)
- Validators use predefined types (no custom function support in UI)
- Formatters are limited to predefined types

**Future Enhancements:**
- Phase 2: Add Tab 4 for Grid settings (page_size, theme, virtual_scroll, etc.)
- Phase 3: Add Tab 5 for DataSource configuration (Ecto, REST, InMemory)
- Phase 4: Export/import configuration as JSON
- Add more formatter types (custom formatters)
- Add custom validator function support in UI
- Undo/Redo functionality in modal
- Keyboard shortcuts for common operations

---

## 13. Reference Documentation

**Related Files:**
- Plan Document: `docs/01-plan/features/grid-config.plan.md`
- Grid Core: `lib/liveview_grid/grid.ex`
- GridComponent: `lib/liveview_grid_web/components/grid_component.ex`
- Formatter Reference: `lib/liveview_grid/formatter.ex`
- Validator Reference: `lib/liveview_grid/grid.ex` (validate_cell function)

---

**Document Version:** 1.0
**Last Review:** 2026-02-26
**Status:** Ready for Phase 1 Implementation

