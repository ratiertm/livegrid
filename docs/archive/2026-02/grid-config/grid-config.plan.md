# PDCA Plan - Grid Configuration UI (Grid Config Modal)

## Context

**User Request:** Add a comprehensive Grid Configuration UI (Modal Dialog) that allows users to dynamically configure Grid, Column, Cell, and Dataset-level settings without hardcoding in Elixir.

**Problem Statement:**
- ❌ All Grid configuration is **code-level only** (hardcoded in Elixir)
- ❌ Users cannot dynamically change settings through UI
- ❌ No column visibility toggler, column reordering UI, filter builder, or theme customizer
- ❌ Configuration changes require code modification + server restart

**Current Grid Configuration Capabilities:**
✅ 10+ Grid-level options (page_size, theme, virtual_scroll, row_height, frozen_columns, etc.)
✅ 18 Column-level options (sortable, filterable, editable, width, validators, formatter, renderer, etc.)
✅ 14+ Formatters (currency, number, date, percent, etc.)
✅ 7 Validator types (required, pattern, min/max, length, custom)
✅ 3 Built-in Renderers (badge, link, progress)
✅ 3 DataSource Adapters (InMemory, Ecto, REST)

**Solution Goal:**
Create a **Modal Dialog UI** that exposes ALL these configuration options through an intuitive tabbed interface, allowing users to:
1. Configure columns (visibility, properties, formatters, validators)
2. Configure grid-level settings (pagination, theme, scrolling, etc.)
3. Configure datasource connections (Ecto, REST, InMemory)
4. Apply changes **live without page reload**
5. (Future) Save/export/import configuration as JSON

---

## Implementation Phases

This feature will be delivered in **3 phases**, each providing value independently.

### Phase 1: Column Configuration (MVP)
**Deliverable:** Users can configure column visibility, properties, formatters, and validators through a modal dialog.

**Scope:**
- Column Visibility & Reordering (show/hide/drag-drop)
- Column Properties (label, width, align, sortable, filterable, editable)
- Column Formatters (select type + configure options)
- Column Validators (add/remove validators with messages)

**Impact:** ⭐⭐⭐⭐⭐ High - Most commonly needed feature
**Timeline:** 3-5 days
**Files:** 10-12 files (modal + 3 tabs + hooks + styles)

**Success Criteria:**
- ✅ Column show/hide works with live grid updates
- ✅ Drag-drop column reordering works
- ✅ Property changes (label, width, align, etc.) apply instantly
- ✅ Formatter selection and configuration works
- ✅ Validator management (add/remove) works
- ✅ Modal open/close/save/cancel all work correctly

---

### Phase 2: Grid Settings Configuration
**Deliverable:** Users can configure Grid-level options (page size, theme, virtual scroll, row height, etc.)

**Scope:**
- Page size selector (input or select dropdown)
- Theme selector (light/dark/custom)
- Virtual scroll toggle
- Row height adjustment (slider)
- Frozen columns configuration
- Show/hide header, footer, row numbers
- Advanced options (debug mode, virtual buffer)

**Impact:** ⭐⭐⭐⭐ Medium-High - Improves UX customization
**Timeline:** 2-3 days (after Phase 1)
**Depends on:** Phase 1 modal structure

**Success Criteria:**
- ✅ All grid options have UI controls
- ✅ Changes apply immediately to grid
- ✅ Options persist during session
- ✅ Valid value constraints enforced (min/max, etc.)

---

### Phase 3: DataSource Configuration
**Deliverable:** Users can switch and configure DataSource connections (Ecto, REST, InMemory) through UI.

**Scope:**
- DataSource type selector (InMemory, Ecto, REST)
- Configuration fields per type:
  - **InMemory:** No configuration needed
  - **Ecto:** Repo selection, base_query preview
  - **REST:** Base URL, endpoint, headers, response mapping
- Test connection button (validate before applying)
- Data reload on connection change

**Impact:** ⭐⭐⭐ Medium - Advanced feature for power users
**Timeline:** 3-4 days (after Phase 1)
**Depends on:** Phase 1 modal structure + DataSource understanding

**Success Criteria:**
- ✅ DataSource type can be switched via UI
- ✅ Configuration fields appear based on type
- ✅ Test connection validates configuration
- ✅ Data updates when datasource changes
- ✅ Error messages display for invalid configuration

---

## Architecture Overview

### Modal Dialog Structure

```
┌────────────────────────────────────────────────┐
│  ⚙ Grid Configuration                    ✕    │
├────────────────────────────────────────────────┤
│ [Tab 1] [Tab 2] [Tab 3] [Tab 4] [Tab 5]       │
├────────────────────────────────────────────────┤
│                                                │
│  [Content Area - changes per tab]              │
│                                                │
├────────────────────────────────────────────────┤
│                    [Cancel] [Apply] [Reset]    │
└────────────────────────────────────────────────┘
```

### Phase 1 Tabs (Column Configuration)
- **Tab 1:** Column Visibility & Order (draggable list + checkboxes)
- **Tab 2:** Column Properties (per-column form)
- **Tab 3:** Formatters & Validators (formatter selector + validator builder)

### Phase 2 Tabs (Grid Settings)
- **Tab 4:** Grid Settings (form inputs + sliders + toggles)

### Phase 3 Tabs (DataSource)
- **Tab 5:** DataSource Configuration (type selector + conditional forms)

---

## Implementation Details

### Files to Create

**Phase 1:**
```
lib/liveview_grid_web/components/grid_config/
  ├── config_modal.ex                   # Main modal component (LiveComponent)
  ├── tabs/
  │   ├── column_visibility_tab.ex      # Tab 1: Show/hide/reorder columns
  │   ├── column_properties_tab.ex      # Tab 2: Edit column properties
  │   └── column_formatters_tab.ex      # Tab 3: Formatters & validators

assets/js/hooks/config-modal.js         # Drag-drop for column reordering
assets/css/grid/config-modal.css        # Modal styling
```

**Phase 2:**
```
lib/liveview_grid_web/components/grid_config/tabs/
  └── grid_settings_tab.ex              # Tab 4: Grid-level options
```

**Phase 3:**
```
lib/liveview_grid_web/components/grid_config/tabs/
  └── datasource_tab.ex                 # Tab 5: DataSource configuration
```

### Files to Modify

**All Phases:**
```
lib/liveview_grid/grid.ex               # Add Grid.apply_config_changes/2 function
lib/liveview_grid_web/components/grid_component.ex  # Add "⚙ Configure" button + modal integration
lib/liveview_grid_web/live/demo_live.ex # Demo example with modal enabled
```

---

## Data Flow

```
User clicks "⚙ Configure" button
    ↓
config_modal.ex opens (LiveComponent, shows current config)
    ↓
User modifies configuration in tabs (Tab 1, 2, 3)
    ↓
Form state updated in modal's assigns (local state)
    ↓
User clicks "Apply" button
    ↓
Modal sends "config_apply" event with all changes
    ↓
Demo/Page LiveView handles event:
    - Grid.apply_config_changes(grid, config_changes)
    - Validates changes
    - Updates Grid.state, Grid.columns, Grid.options
    ↓
Grid component re-renders with new configuration
    ↓
UI updates **without page reload**
```

---

## Configuration Schema

### Config Changes Structure (Phase 1)

```elixir
config_changes = %{
  "columns" => [
    %{
      "field" => :name,                    # identifies column
      "label" => "이름",                    # updated label
      "width" => 150,                       # updated width (pixels)
      "align" => "left",                    # left | center | right
      "sortable" => true,                   # boolean
      "filterable" => true,                 # boolean
      "editable" => true,                   # boolean
      "formatter" => "currency",            # formatter type
      "formatter_options" => %{...},        # formatter configuration
      "validators" => [                     # list of validators
        %{"type" => "required", "message" => "Required"},
        %{"type" => "pattern", "pattern" => "@", "message" => "Invalid email"}
      ]
    }
  ],
  "column_order" => [:id, :name, :email, :salary],  # column visibility + order
  "hidden_columns" => [:phone, :address]  # columns to hide
}
```

### Config Changes Structure (Phase 2)

```elixir
config_changes = %{
  "columns" => [...],  # Phase 1 changes
  "options" => %{      # Grid-level options
    "page_size" => 25,
    "theme" => "dark",
    "virtual_scroll" => true,
    "row_height" => 45,
    "frozen_columns" => 1,
    "show_row_number" => true,
    "show_header" => true,
    "show_footer" => true
  }
}
```

### Config Changes Structure (Phase 3)

```elixir
config_changes = %{
  "columns" => [...],          # Phase 1 changes
  "options" => %{...},         # Phase 2 changes
  "data_source" => %{          # DataSource configuration
    "type" => "ecto",          # "inmemory" | "ecto" | "rest"
    "config" => %{
      "repo" => "MyApp.Repo",
      "schema" => "MyApp.User",
      "base_query" => "from(u in MyApp.User)"
    }
  }
}
```

---

## Phase 1: Column Configuration Implementation

### Step-by-Step Implementation

**1. Create Grid.apply_config_changes/2 function**
   - Location: `lib/liveview_grid/grid.ex`
   - Input: `grid`, `config_changes` map
   - Logic:
     - Validate column field existence
     - Validate formatter types
     - Validate validator types
     - Apply changes to `grid.columns` and `grid.state`
     - Return updated grid

**2. Create ConfigModal Component**
   - Location: `lib/liveview_grid_web/components/grid_config/config_modal.ex`
   - Type: LiveComponent
   - State: tab selection, form data for each tab
   - Events:
     - `config_apply` - send changes to parent
     - `config_cancel` - close without saving
     - `config_reset` - reset to original values

**3. Create Column Visibility Tab**
   - Show all columns with show/hide checkboxes
   - Draggable list for reordering
   - Live preview of column order
   - JS hook for drag-drop functionality

**4. Create Column Properties Tab**
   - Column selector (dropdown)
   - Form for:
     - label (text input)
     - width (number input or slider)
     - align (select: left, center, right)
     - sortable (checkbox)
     - filterable (checkbox)
     - editable (checkbox)
   - Form persists when switching columns

**5. Create Column Formatters & Validators Tab**
   - Formatter type selector (dropdown)
   - Formatter options form (context-sensitive)
     - Currency: symbol, precision, position
     - Number: precision, separator, delimiter
     - Date: format string
     - etc.
   - Validator builder:
     - Add validator button
     - Validator type selector
     - Validator-specific fields (pattern, min/max, message)
     - Remove validator button per row

**6. Integrate with GridComponent**
   - Add "⚙ Configure" button to grid toolbar
   - Show/hide modal with toggle state
   - Handle `config_apply` event from modal
   - Call `Grid.apply_config_changes/2`
   - Re-render grid with new configuration

**7. Add Demo Example**
   - Create new page in `demo_live.ex`
   - Enable config modal
   - Test end-to-end

**8. Test & Verify**
   - Unit tests for `Grid.apply_config_changes/2`
   - UI tests for modal
   - Integration tests for column changes

---

## Verification Checklist (Phase 1)

### Column Visibility & Order
- [ ] List all columns with show/hide checkboxes
- [ ] Drag-drop to reorder columns works smoothly
- [ ] Hide column → removed from grid
- [ ] Show column → added back in configured order
- [ ] Apply changes → grid updates immediately

### Column Properties
- [ ] Column selector shows all columns
- [ ] Edit label → updates in grid header
- [ ] Edit width → column width changes
- [ ] Edit align → column content aligns
- [ ] Toggle sortable → header becomes clickable/not
- [ ] Toggle filterable → filter row appears/disappears
- [ ] Toggle editable → cells become editable/read-only
- [ ] Changes apply immediately when switching columns

### Formatters & Validators
- [ ] Formatter selector shows all types (currency, date, number, etc.)
- [ ] Formatter options form changes based on type
- [ ] Applied formatter shows correct output in grid cells
- [ ] Add validator → new row appears
- [ ] Validator type selector shows available types
- [ ] Validator message input field works
- [ ] Remove validator → row disappears
- [ ] Validators trigger on grid updates

### Modal Behavior
- [ ] Modal opens when "⚙ Configure" button clicked
- [ ] Modal closes when "Cancel" clicked
- [ ] Modal saves when "Apply" clicked
- [ ] Configuration persists after save
- [ ] "Reset" button reverts to original values
- [ ] Multiple columns can be configured in one session
- [ ] Modal is keyboard accessible (Tab, Enter, Escape)

### Grid Integration
- [ ] Modal button appears in grid toolbar
- [ ] Configuration changes apply **without page reload**
- [ ] Grid re-renders correctly with new config
- [ ] No console errors or warnings

---

## Success Metrics

| Metric | Target |
|--------|--------|
| **Implementation Time (Phase 1)** | 3-5 days |
| **Lines of Code** | 1,500-2,000 (Phase 1) |
| **Test Coverage** | 80%+ (unit + integration) |
| **User Experience** | Smooth, no lag when applying changes |
| **Accessibility** | WCAG 2.1 AA compliant |

---

## Notes & Constraints

1. **Client-side State Management**
   - Configuration changes stored in modal's local state
   - Only applied to grid when "Apply" button clicked
   - Prevents accidental changes

2. **Validation**
   - Client-side validation for input constraints
   - Server-side validation when applying changes
   - Error messages displayed in modal

3. **Browser Compatibility**
   - Must work on modern browsers (Chrome, Firefox, Safari, Edge)
   - Drag-drop uses standard HTML5 Drag and Drop API
   - CSS Grid/Flexbox for layout

4. **Performance**
   - Modal should open < 500ms
   - Drag-drop should feel smooth (60 fps)
   - Grid re-render should be < 1s for large datasets

5. **Phase Dependencies**
   - Phase 2 can start after Phase 1 tab structure is complete
   - Phase 3 can start after Phase 1 modal is working
   - No hard dependencies, can work in parallel if needed

---

## Related Features

- **Cell Editing** (F-922, completed with IME support)
- **Grid Toolbar** (use existing structure for config button)
- **Modal Components** (create reusable modal for future features)
- **Form Controls** (use existing Phoenix core_components)

---

## Reference Documentation

- Grid Configuration Options: `lib/liveview_grid/grid.ex` (lines 757-770 for defaults)
- Column Options: `lib/liveview_grid/grid.ex` (lines 693-713)
- Formatters: `lib/liveview_grid/formatter.ex`
- Validators: `lib/liveview_grid/grid.ex` (validation functions)
- Renderers: `lib/liveview_grid/renderers.ex`

