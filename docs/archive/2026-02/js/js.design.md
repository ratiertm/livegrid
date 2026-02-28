# JS Hooks & Frontend Interactions - Design (F-810, F-940)

**Reference Plan:** `docs/01-plan/features/js.plan.md`

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    app.js (Entry Point)                 │
│  - Imports all hooks                                    │
│  - Registers with LiveSocket                           │
│  - Exposes for debugging                               │
└──────────────────────┬──────────────────────────────────┘
                       │ (registers hooks)
                       ↓
┌─────────────────────────────────────────────────────────┐
│              LiveSocket Hooks Registry                   │
│  {VirtualScroll, FileImport, CellEditable, ..., etc}   │
└──────────────────────────┬───────────────────────────────┘
                           │ (attached to DOM elements)
                           ↓
┌─────────────────────────────────────────────────────────┐
│          Phoenix LiveView Grid Component                │
│   (grid_component.ex) with data-phx-hook attributes    │
└─────────────────────────────────────────────────────────┘
```

---

## Module Structure

### 1. Entry Point: `app.js`

**Responsibility:** Initialize and register hooks with LiveSocket

**Current Implementation:**
```javascript
- Import Phoenix dependencies (Socket, LiveSocket)
- Import all 9 hooks
- Assemble Hooks object
- Configure topbar progress bar
- Create LiveSocket instance
- Attach hooks to LiveSocket
- Connect and expose for debugging
```

**Key Points:**
- Single responsibility (initialization only)
- Clean module imports
- Progress bar integration

---

### 2. Hook Modules (9 Total)

Each hook should follow the pattern:
```javascript
export const HookName = {
  mounted() { /* init */ },
  updated() { /* on LiveView updates */ },
  destroyed() { /* cleanup */ },
  // Event handlers, helper methods
}
```

#### **Hook 1: VirtualScroll** (1.8 KB)
- **Purpose:** Optimize rendering with virtual scrolling
- **Responsibilities:**
  - Track visible viewport
  - Show/hide rows outside viewport
  - Manage DOM recycling
- **Dependencies:** GridScroll (coordinates with scroll)
- **DOM Target:** Grid rows container

#### **Hook 3: FileImport** (1.6 KB)
- **Purpose:** Handle file uploads and imports
- **Responsibilities:**
  - Listen to file input changes
  - Parse file content (CSV, Excel, JSON)
  - Push data to server via `push_event`
- **DOM Target:** File input element
- **Events to Server:** `"import_file"` event

#### **Hook 4: CellEditable** (419 B)
- **Purpose:** Mark cells as editable
- **Responsibilities:**
  - Add/remove editable CSS classes
  - Prevent editing in read-only cells
- **DOM Target:** Individual cells (`.lv-grid__cell`)
- **Lightweight:** Minimal logic, mostly CSS-driven

#### **Hook 5: ColumnResize** (2.2 KB)
- **Purpose:** Allow dynamic column width adjustment
- **Responsibilities:**
  - Attach resize handles to column headers
  - Track mouse drag movements
  - Update column width in DOM
  - Persist width to server (optional)
- **DOM Target:** Column header elements
- **Events to Server:** `"grid_column_resize"` event

#### **Hook 6: ColumnReorder** (5.9 KB)
- **Purpose:** Support drag-drop column reordering
- **Responsibilities:**
  - Attach drag listeners to column headers
  - Track drag start/over/drop
  - Reorder DOM elements
  - Push new order to server
- **DOM Target:** Column header elements
- **Events to Server:** `"grid_column_reorder"` event with new order
- **Largest non-nav hook:** May benefit from refactoring

#### **Hook 7: CellEditor** (3.4 KB)
- **Purpose:** Inline cell editing UI
- **Responsibilities:**
  - Show/hide edit input on cell focus
  - Handle Enter/Escape key events
  - Trigger save on blur
  - Manage input focus
- **DOM Target:** Individual cells with editing enabled
- **Dependencies:** CellEditable (determines editability)
- **Events to Server:** `"cell_edit_start"` event with new value

#### **Hook 8: RowEditSave** (631 B)
- **Purpose:** Save entire row changes
- **Responsibilities:**
  - Aggregate cell changes
  - Trigger row-level validation
  - Push changes to server
- **DOM Target:** Row container (`.lv-grid__row`)
- **Events to Server:** `"row_edit_save"` event
- **Lightweight:** Coordinates with CellEditor

#### **Hook 9: GridKeyboardNav** (20.5 KB) -- Active Development
- **Purpose:** Keyboard navigation + cell range selection
- **Responsibilities:**

  **F-810 (Keyboard Navigation):**
  - Arrow key navigation (up/down/left/right)
  - Home/End keys for row navigation
  - Ctrl+Home/Ctrl+End for grid start/end
  - Focus state management
  - Scroll to focus cell in viewport

  **F-940 (Cell Range Selection):**
  - Single cell selection with click
  - Shift+Click for range selection
  - Drag selection (mousedown -> mousemove -> mouseup)
  - Visual feedback (selected cell highlight)
  - Push range to server

- **DOM Target:** Grid container (`.lv-grid`)
- **Events to Server:**
  - `"focus_cell"` event (on navigation)
  - `"set_cell_range"` event (on range selection)
  - `"clear_cell_range"` event (on range clear)
- **State Management:**
  - `focusedRowId`, `focusedColIdx` -- Current focus
  - `cellRange` -- {anchorRowId, anchorColIdx, extentRowId, extentColIdx}
  - `isDragging` -- Drag state tracking
- **Complexity:** Largest hook (20.5 KB), handles multiple interaction patterns

---

### 3. Utilities: `utils/download.js` (1.3 KB)

**Purpose:** Handle file downloads (CSV, Excel exports)

**Responsibilities:**
- Listen to download events from server
- Generate blob from grid data
- Trigger browser download dialog
- Set filename with timestamp/format

**Integration Pattern:**
- Side-effect module (no export, just registration)
- Registers window-level event listeners
- Imported in app.js for automatic initialization

---

## Data Flow & Event Patterns

### Server <-> Client Communication

**Client -> Server (Push Events):**
```
GridKeyboardNav -> "focus_cell" -> Grid component handler
ColumnReorder -> "grid_column_reorder" -> Grid component handler
ColumnResize -> "grid_column_resize" -> Grid component handler
CellEditor -> "cell_edit_start" -> Grid component handler
RowEditSave -> "row_edit_save" -> Grid component handler
FileImport -> "import_file" -> Grid component handler
GridKeyboardNav -> "set_cell_range" -> Grid component handler
```

**Server -> Client (LiveView Updates):**
```
Grid component re-renders (phx:update)
  ↓
Updated HTML
  ↓
Hooks' updated() method fires (if needed)
  ↓
Internal state refresh (focus position, ranges, etc)
```

---

## DOM Structure Requirements

```html
<div class="lv-grid" data-phx-hook="GridKeyboardNav">
  <div class="lv-grid__header">
    <div class="lv-grid__column-header" data-col-index="0">...</div>
  </div>
  <div class="lv-grid__body">
    <div class="lv-grid__row" data-row-id="1">
      <div class="lv-grid__cell" data-col-index="0">...</div>
    </div>
  </div>
</div>
```

**Required Attributes:**
- `data-phx-hook="HookName"` -- Hook attachment
- `data-row-id` -- Row identifier (integer)
- `data-col-index` -- Column index (0-based integer)
- `data-row-id` + `data-col-index` -- Cell location

---

## CSS Classes Convention

| Class | Purpose | Managed By |
|-------|---------|-----------|
| `.lv-grid--selecting` | Active selection mode | GridKeyboardNav |
| `.lv-grid__cell--focused` | Cell has focus | GridKeyboardNav |
| `.lv-grid__cell--in-range` | Cell in range selection | GridKeyboardNav |

---

## State Management Strategy

**Local Hook State** (not shared):
```javascript
// GridKeyboardNav maintains:
- focusedRowId, focusedColIdx
- cellRange, isDragging
- dragAnchorRowId, dragAnchorColIdx

// CellEditor maintains:
- editingRowId, editingColIdx
- originalValue, currentValue
- isEditing flag

// ColumnResize maintains:
- resizingColIdx
- startX, startWidth
```

**Shared State** (via server):
- Grid data
- Column metadata (width, order, sortable)
- Selection (pushed to server, can be restored on update)

---

## Integration Checklist

### Hook Registration
- All 9 hooks exported as ES6 modules
- Imported in app.js
- Added to Hooks object
- Passed to LiveSocket constructor

### Event Handling
- Keyboard events (arrow keys, Enter, Escape, Shift+Click)
- Mouse events (click, mousedown, mousemove, mouseup)
- Server push events (push_event to grid component)

### DOM Coordination
- Correct selectors for cells, rows, columns
- Data attributes for identification
- CSS classes for styling feedback

### Performance Considerations
- Virtual scrolling for large datasets
- Event delegation (listen on container, not per-cell)
- Minimal reflows on cell updates

---

## Undocumented Features (Beyond Initial Design)

The GridKeyboardNav hook includes 12 additional features beyond the initial F-810 + F-940 design:

| Feature | Code | Keyboard Shortcut | Description |
|---------|------|-------------------|-------------|
| Undo | F-700 | Ctrl+Z / Cmd+Z | Undo last action |
| Redo | F-700 | Ctrl+Y / Ctrl+Shift+Z / Cmd+Y | Redo last undone action |
| Copy Cell | F-932 | Ctrl+C / Cmd+C | Copy focused cell to clipboard |
| Copy Range | F-932 | Ctrl+C / Cmd+C | Copy selected range to clipboard |
| Paste Cells | F-932 | Ctrl+V / Cmd+V | Paste tabular data from clipboard |
| Context Menu | F-800 | Right-click | Show context menu with copy/cut/paste options |
| Copy Row | F-800 | Context menu | Copy entire row to clipboard |
| Cell Tooltip | F-900 | Hover | Show cell content as tooltip if overflowing |
| Clipboard Write | F-800 | Server-driven | Server can trigger client-side clipboard writes |
| Scroll to Row | F-800 | Server-driven | Server can scroll viewport to specific row |
| Focus Cell | F-800 | Server-driven | Server can set focus to specific cell (for virtual scroll) |
| Grid Edit Ended | F-800 | Server-driven | Server notifies of edit completion, triggers directional focus |

These features enhance the keyboard navigation and editing experience beyond the original specification.

---

## Known Limitations & Refactoring Needs

1. **GridKeyboardNav size (20.5 KB)**
   - Contains: focus logic, range selection, drag handlers, keyboard events
   - **Suggested split:**
     - `keyboard-nav.js` -- Arrow key navigation only
     - `cell-range-selector.js` -- Range selection + drag
     - Reduces complexity, improves testability

2. **Event handler complexity**
   - Multiple event types in single handler
   - Tight coupling of concerns (focus + selection + drag)
   - **Suggested improvement:** Extract to handler modules

3. **No unit tests**
   - Currently only tested via browser/LiveView
   - **Suggestion:** Add Jest tests for hook logic

4. **State synchronization**
   - Relies on LiveView updates to refresh state
   - **Risk:** Desync if server update fails
   - **Mitigation:** Add state validation on update()

---

## Implementation Order

### Phase 1: Core (Already Implemented)
1. GridScroll -- Basic grid scrolling
2. VirtualScroll -- Performance optimization
3. CellEditable -- Mark editable cells

### Phase 2: Editing (Already Implemented)
4. CellEditor -- Inline cell editing
5. RowEditSave -- Row save coordination

### Phase 3: Column Management (Already Implemented)
6. ColumnResize -- Dynamic column width
7. ColumnReorder -- Drag-drop reordering

### Phase 4: Navigation & Selection (Already Implemented)
8. GridKeyboardNav -- F-810 (keyboard nav) + F-940 (range selection)

### Phase 5: Data Import (Already Implemented)
9. FileImport -- File upload/import

### Phase 6: Export & Utilities (Already Implemented)
10. Download utility -- File download support

---

## Quality Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Hook count | 9 | 9 |
| Total size | < 50 KB | ~37 KB |
| Largest hook | < 10 KB | 20.5 KB |
| Module separation | Single file per hook | Yes |
| Event delegation | Minimize listeners | Yes |
| Coverage | > 80% | TBD |

---

## Design Validation Checklist

- [x] 9 hooks implemented as separate modules
- [x] app.js as single entry point
- [x] Modular architecture (single responsibility per hook)
- [x] LiveView integration (push_event patterns)
- [x] Keyboard navigation (F-810) implemented
- [x] Cell range selection (F-940) implemented
- [x] DOM structure compatibility verified
- [x] Event flow documented
- [x] State management strategy defined
- [ ] Unit tests created (not yet)
- [ ] Performance benchmarks (not yet)
- [ ] Accessibility audit (not yet)

---

## References

- **PDCA Plan:** `docs/01-plan/features/js.plan.md`
- **Frontend Skills:** `.claude/skills/liveview/INDEX.md`
- **Grid Component:** `lib/liveview_grid_web/components/grid_component.ex`
- **CSS Styles:** `assets/css/liveview_grid.css`

---

## Design Approval

**Feature Name:** js
**PDCA Phase:** Design (Phase 2/5)
**Created At:** 2026-02-26
**Status:** Archived
