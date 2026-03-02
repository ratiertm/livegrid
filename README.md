# LiveView Grid

**Enterprise-grade Grid Library for Phoenix LiveView**

[한국어](README.ko.md) | English

## 🎯 Project Goal

The first enterprise grid solution built on Elixir/Phoenix for the Korean market.

### Key Differentiators
- ⚡ **Real-time Sync**: WebSocket-based multi-user concurrent editing
- 🚀 **High-volume Processing**: Leveraging Elixir concurrency (1M+ rows)
- 🎨 **Server Rendering**: Minimal JavaScript, fast initial load
- 🔒 **Reliability**: Non-stop operation on Erlang VM

## 🏃 Quick Start

### Run Server

```bash
cd liveview_grid
mix phx.server
```

Open in browser:
- **Dashboard**: http://localhost:5001 (redirects to /demo)
- **DBMS Demo**: http://localhost:5001/dbms-demo
- **API Demo**: http://localhost:5001/api-demo
- **Advanced Demo**: http://localhost:5001/advanced-demo (Grouping/Tree/Pivot)
- **Grid Config Demo**: http://localhost:5001/grid-config-demo
- **Grid Builder**: http://localhost:5001/builder
- **API Docs**: http://localhost:5001/api-docs

### Development Setup

```bash
# Install dependencies
mix deps.get

# Build assets
mix assets.setup

# Run tests
mix test

# Generate API docs
mix docs
open doc/index.html
```

## ✨ Implemented Features (v0.1 ~ v0.10)

### v0.1 - Core Grid
- [x] Table rendering (LiveComponent-based)
- [x] Column sorting (asc/desc toggle with sort icons)
- [x] Row selection (checkbox, select all/none)
- [x] Frozen columns
- [x] Column resize (drag handle with min/max width)
- [x] Column drag reorder
- [x] Global text search (300ms debounce)
- [x] Per-column filters (text/number types)
- [x] Virtual scrolling - renders only visible rows
- [x] Infinite scroll - loads more on scroll
- [x] Pagination (when virtual scroll is OFF)
- [x] Inline cell editing (double-click to enter)
- [x] Text/number/dropdown editors
- [x] Add row / Delete rows / Change tracking (N/U/D badges)
- [x] Batch save & discard
- [x] CSV download

### v0.2 - Validation & Themes
- [x] Cell validation - required fields, number ranges, format checks
- [x] Validation error UI (cell highlight, tooltip messages)
- [x] Advanced multi-condition filter (AND/OR combinator, text/number operators)
- [x] Theme system (dark mode, custom themes, CSS variable customizer)

### v0.3 - DBMS Integration
- [x] Ecto/Repo integration - DataSource behaviour adapter pattern
- [x] SQLite support (`ecto_sqlite3`)
- [x] Server-side sort/filter/paging (SQL ORDER BY, WHERE, LIMIT/OFFSET)
- [x] Persist changes to DB (INSERT/UPDATE/DELETE via Ecto Changeset)

### v0.4 - REST API & Export
- [x] REST DataSource adapter (configurable base_url, endpoint, headers)
- [x] Async data fetching with loading states & response time tracking
- [x] API-based CRUD (POST create, PUT update, PATCH partial, DELETE remove)
- [x] Offset-based pagination via API (page/page_size)
- [x] Authentication header support (Bearer token, custom headers)
- [x] Error handling & retry logic (exponential backoff)
- [x] Mock REST API server (MockApiController)
- [x] API Key management & authentication (RequireApiKey plug)
- [x] Excel (.xlsx) / CSV Export (Elixlsx-based)
- [x] Custom cell renderers (badge, link, progress built-in presets)
- [x] API Documentation page
- [x] Dashboard layout with sidebar navigation

### v0.5 - Advanced Data Processing
- [x] Grouping (multi-level field grouping with expand/collapse, aggregate functions)
- [x] Pivot table (row/column dimensions, dynamic columns, sum/avg/count/min/max)
- [x] Tree grid (parent-child hierarchy, depth-based indentation, expand/collapse)
- [x] Formatter (16 types: number, currency, percent, date, datetime, time, boolean, mask, phone, email, url, uppercase, lowercase, capitalize, truncate, custom)
- [x] ExDoc API documentation (bilingual guides in Korean/English)

### v0.6 - Editing & Input
- [x] Conditional cell styling (rule-based background color)
- [x] Multi-level headers (grouped column headers with parent-child)
- [x] Clipboard Excel paste (paste event handler for tabular data)
- [x] Excel/CSV Import (file upload with column mapping)
- [x] Cell tooltip (overflow detection with title attribute)
- [x] Null sorting (nil values first/last option per column)
- [x] Row number column (auto-increment row index display)
- [x] Checkbox column (boolean toggle with instant click edit)
- [x] Input restriction (regex-based input filtering + max length)
- [x] Row edit mode (edit all cells in a row simultaneously)
- [x] Undo/Redo (Ctrl+Z/Y edit history with 50-action stack)

### v0.7 - Grid Config & Architecture
- [x] Grid Configuration Modal (column visibility, order, width, frozen columns, formatters, validators)
- [x] Grid Settings tab (page size, virtual scroll, theme, row height)
- [x] Grid Builder (dynamic grid creation with column definition UI)
- [x] Raw Table DataSource adapter (schema-less direct DB table access)
- [x] Schema Registry & Table Inspector (DB introspection for Grid Builder)
- [x] Real-time collaboration (Phoenix Presence + PubSub bridge)
- [x] Keyboard navigation (arrow keys, Tab, Enter, Home/End, F2, Ctrl+C/Z/Y)
- [x] Context menu (right-click: copy, insert, duplicate, delete row)
- [x] Cell range selection (Shift+Click, drag, Shift+Arrow)
- [x] Cell range summary (count, sum, avg, min, max)
- [x] Date filter (date/datetime operators: eq, before, after, between)
- [x] JS Hook module split (10 separate modules)
- [x] CSS module split (9 separate stylesheets)
- [x] GridComponent refactoring (EventHandlers + RenderHelpers extraction)
- [x] ExDoc documentation (@doc/@spec across all public modules)

### v0.8 - Row Enhancement & UI Components
- [x] Row Pinning - pin rows to top/bottom (`pin_row/3`, `unpin_row/2`)
- [x] Status Bar - footer statistics display (`show_status_bar`, `status_bar_data/1`)
- [x] Overlay System - loading/no_data/error overlays (`set_overlay/2`, `clear_overlay/1`)
- [x] Column Resize Lock - per-column `resizable: false` option
- [x] Cell Text Selection - `enable_cell_text_selection` option

### v0.9 - State Management & i18n
- [x] Grid State Save/Restore - persist full grid state (`get_state/1`, `restore_state/2`, `GridStatePersist` JS Hook)
- [x] Column State Save/Restore - persist column order/width/visibility (`get_column_state/1`, `apply_column_state/2`)
- [x] Value Getters/Setters - computed columns (`value_getter`, `value_setter` column options)
- [x] Row Animation - enter/exit CSS animations (`animate_rows` option)
- [x] Localization (i18n) - `Locale` module with ko/en/ja, `grid_t/2` helper

### v0.10 - Enterprise Features (Current)
- [x] Side Bar - toggle sidebar with columns/filters tabs
- [x] Batch Edit - multi-cell range editing (`batch_update_cells/3`)
- [x] Find & Highlight - in-grid search with match navigation (`find_in_grid/2`, `find_next/prev`)
- [x] Full-Width Rows - spanning rows (`add_full_width_row/3`)
- [x] Large Text Editor - textarea modal for long text editing
- [x] Radio Button Column - single-select radio renderer
- [x] Empty Area Fill - fill empty grid space option
- [x] Column Hover Highlight - column highlight on mouse hover
- [x] Grid Builder JSON Export/Import - save/load grid configs as JSON files

## 📊 Implementation Status

| Item | Count |
|------|-------|
| Total Features | 84 |
| Completed | 84 (100%) |
| Versions Shipped | v0.1 ~ v0.10 |
| Tests | 578 |
| AG Grid Feature Coverage | ~91/200+ (~68 full match, ~13 partial) |

## 🗺️ Roadmap (Not Yet Implemented)

### Priority 0 - Accessibility
- [ ] WCAG 2.1 AA - ARIA roles/attributes (`role="grid"`, `aria-*`)

### Priority 1 - Core Missing Features
- [ ] Column Menu (header dropdown: sort/filter/hide/pin)
- [ ] Set Filter (unique value checkbox filter)
- [ ] Cell Fill Handle (Excel auto-fill drag)
- [ ] Master-Detail (expandable row detail grid)
- [ ] Date Editor (datepicker component for date columns)
- [ ] Printing (print button + `print_data/1` API)

### Priority 2 - Enterprise Extensions
- [ ] Rich Select Editor (searchable dropdown)
- [ ] Sparklines (in-cell mini charts)
- [ ] Integrated Charts (data-driven charts)
- [ ] Cell Expressions/Formulas
- [ ] Multi-DB drivers (PostgreSQL, MySQL, MSSQL, Oracle)
- [ ] GraphQL DataSource
- [ ] RTL Support
- [ ] Touch Device Support

## 📁 Project Structure

```
lib/
├── liveview_grid/              # Business logic
│   ├── grid.ex                 # Grid core module (data/state management)
│   ├── grid_definition.ex      # Grid definition struct
│   ├── locale.ex               # i18n Localization (ko/en/ja) (v0.9)
│   ├── data_source.ex          # DataSource behaviour (adapter pattern)
│   ├── data_source/
│   │   ├── in_memory.ex        # InMemory adapter
│   │   ├── ecto.ex             # Ecto/DB adapter
│   │   ├── ecto/
│   │   │   └── query_builder.ex # SQL query builder
│   │   ├── rest.ex             # REST API adapter
│   │   └── raw_table.ex        # Raw table adapter
│   ├── operations/
│   │   ├── sorting.ex          # Sorting engine
│   │   ├── filter.ex           # Filter engine (basic + advanced)
│   │   ├── pagination.ex       # Pagination
│   │   ├── grouping.ex         # Multi-level grouping
│   │   ├── tree.ex             # Tree grid hierarchy
│   │   └── pivot.ex            # Pivot table transform
│   ├── renderers.ex            # Custom cell renderer presets
│   ├── formatter.ex            # 16 data formatters
│   ├── export.ex               # Excel/CSV Export
│   ├── sample_data.ex          # Sample data generator
│   ├── schema_registry.ex      # Schema registry for Grid Builder
│   ├── table_inspector.ex      # DB table introspection
│   ├── grid_presence.ex        # Phoenix Presence (collaboration)
│   └── pub_sub_bridge.ex       # PubSub bridge (real-time sync)
└── liveview_grid_web/          # Web layer
    ├── live/
    │   ├── demo_live.ex         # InMemory demo
    │   ├── dbms_demo_live.ex    # DBMS demo (SQLite)
    │   ├── api_demo_live.ex     # REST API demo
    │   ├── renderer_demo_live.ex # Renderer demo
    │   ├── advanced_demo_live.ex # Advanced features demo
    │   ├── builder_live.ex      # Grid Builder page
    │   └── api_doc_live.ex      # API documentation
    ├── components/
    │   ├── grid_component.ex    # Grid LiveComponent (core)
    │   ├── grid_component/
    │   │   ├── event_handlers.ex  # Event handler callbacks
    │   │   └── render_helpers.ex  # Render helper functions
    │   ├── grid_config/
    │   │   └── config_modal.ex    # Grid Configuration Modal
    │   └── grid_builder/
    │       ├── builder_modal.ex   # Grid Builder Modal
    │       ├── builder_helpers.ex # Builder helper functions
    │       └── builder_data_source.ex # Builder data source logic
    └── router.ex

assets/
├── js/
│   ├── app.js                     # JS entry point + hook registry
│   └── hooks/                     # Modular JS hooks (12 modules)
│       ├── virtual-scroll.js      # Virtual scrolling
│       ├── cell-editor.js         # Cell editing
│       ├── cell-editable.js       # Cell editable behavior
│       ├── column-resize.js       # Column resize
│       ├── column-reorder.js      # Column reorder
│       ├── grid-scroll.js         # Grid scroll sync
│       ├── keyboard-nav.js        # Keyboard navigation
│       ├── row-edit-save.js       # Row edit/save
│       ├── file-import.js         # File import
│       ├── config-sortable.js     # Config sortable drag
│       ├── grid-state-persist.js  # Grid state persistence (v0.9)
│       └── json-import.js         # JSON config import (v0.10)
└── css/
    ├── liveview_grid.css          # CSS entry point (imports)
    └── grid/                      # Modular CSS (10 files)
        ├── variables.css          # CSS variables & themes (z-index scale)
        ├── layout.css             # Grid layout + renderers
        ├── header.css             # Header styles
        ├── body.css               # Body & cell styles
        ├── toolbar.css            # Toolbar styles
        ├── interactions.css       # Interactions (selection, editing)
        ├── advanced.css           # Advanced features (grouping, tree, pivot)
        ├── config-modal.css       # Config modal styles
        ├── context-menu.css       # Context menu styles
        └── print.css              # Print media styles (v0.10)
```

## 🔧 Tech Stack

- **Elixir** 1.16+ / **Phoenix** 1.7+
- **LiveView** 1.0+ - Real-time UI (LiveComponent)
- **Ecto** + **SQLite** (`ecto_sqlite3`) - Database integration
- **Elixlsx** - Excel Export
- **Custom CSS** - BEM methodology (`lv-grid__*`)
- **JavaScript Hooks** - Virtual scroll, cell editing, column resize

## 📝 Usage Example

### Basic Grid

```elixir
# Use GridComponent in LiveView
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="users-grid"
  data={@users}
  columns={[
    %{field: :id, label: "ID", width: 80, sortable: true},
    %{field: :name, label: "Name", width: 150, sortable: true,
      filterable: true, filter_type: :text, editable: true,
      validators: [{:required, "Required"}]},
    %{field: :salary, label: "Salary", width: 120, sortable: true,
      formatter: :currency, align: :right},
    %{field: :city, label: "City", width: 120, sortable: true,
      editable: true, editor_type: :select,
      editor_options: [{"Seoul", "Seoul"}, {"Busan", "Busan"}, {"Daegu", "Daegu"}]}
  ]}
  options={%{
    page_size: 20,
    virtual_scroll: true,
    row_height: 40,
    frozen_columns: 1
  }}
/>
```

### DataSource Integration

```elixir
# Ecto (DB) integration
grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.Ecto,
    %{repo: MyApp.Repo, query: from(u in User)}}
)

# REST API integration
grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.Rest,
    %{base_url: "https://api.example.com/users"}}
)
```

## 📖 API Documentation

- **API Specification**: [English](docs/API_SPEC.md) | [한국어](docs/API_SPEC.ko.md)
- **Live API Docs**: http://localhost:5001/api-docs (when server is running)

The API provides 26 endpoints across 6 categories:
1. **Grid Setup** - Configuration, columns, options
2. **Data CRUD** - Single/batch create, read, update, delete
3. **Theme** - Built-in themes, custom theme creation
4. **Sort & Pagination** - Sorting, paging, virtual scroll settings
5. **DBMS Connection** - Database adapter configuration
6. **Renderers** - Built-in and custom cell renderers

## 🎯 Target Market

### Primary
- Financial trading systems
- ERP/MES solutions
- Data analytics dashboards

### Secondary
- SaaS startups
- Government systems
- Global market

## 💰 License Strategy

- **Community Edition**: MIT (free, core features)
- **Professional**: Commercial license ($999/yr, advanced features)
- **Enterprise**: Custom ($negotiable, collaboration/customization)

## 📚 References

This project was independently developed for Phoenix LiveView, **inspired by** [Toast UI Grid](https://github.com/nhn/tui.grid) (MIT License).

- Toast UI Grid was referenced for learning purposes only
- All code is natively written in Elixir/Phoenix
- Details: [DEVELOPMENT.md](./DEVELOPMENT.md)

## 📞 Contact

Project inquiries: [TBD]

---

**Made with ❤️ using Phoenix LiveView**

*Inspired by Toast UI Grid • Built for Elixir/Phoenix community*
