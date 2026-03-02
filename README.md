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

## ✨ Implemented Features (v0.1.0 ~ v0.11.0)

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

### v0.7.0 - Grid Config & Architecture
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

> **Note**: v0.8.0–v0.9.0 reorganized features from v0.6–v0.7 using PDCA methodology, adding IME support, Grid Config 3-layer architecture, and UI/UX improvements (dark mode CSS variables).

### v0.10.0 - Nexacro Reference Features
- [x] Suppress (hide identical consecutive values vertically)
- [x] Cell merge (rowspan/colspan)
- [x] Wordwrap (word/char wrap modes)
- [x] Frozen Row (fix top N rows)
- [x] Column auto-fit (double-click header to auto-size)
- [x] Multi-line header (header_wrap: true)
- [x] Row drag reorder (RowReorder Hook)
- [x] Auto row height (autofit_type: :row)
- [x] Scroll sync (ScrollSync Hook)
- [x] Summary Row (aggregate footer)
- [x] Right Freeze (freeze rightmost columns)
- [x] Dynamic Freeze (toggle column freeze at runtime)

### v0.11.0 - AG Grid Reference + Bugfix (Current)
- [x] Row Animation nil status fix
- [x] Value Getter/Setter editor integration
- [x] Find Bar keyboard shortcuts (Enter/Shift+Enter/Escape)
- [x] Master/Detail toggle UI
- [x] Chart Panel UI (SVG charts)
- [x] Infinite Scroll detection improvement

## 📊 Implementation Status

| Item | Count |
|------|-------|
| Total Features | 118 (73 implemented + 45 planned) |
| Completed | 73 (62%) |
| Versions Shipped | v0.1.0 ~ v0.11.0 |
| Tests | 698 passing |
| Feature Sources | Original roadmap + Nexacro + AG Grid v35 |

## 🗺️ Roadmap

### v0.12.0 - Core UX Enhancement
- [ ] Row Pinning (pin rows to top/bottom for summary rows)
- [ ] Overlay System (Loading/No Data/Error messages)
- [ ] Status Bar (row count, selection summary, filter status)
- [ ] Cell Text Selection (allow text drag-select in cells)
- [ ] Column resize restriction (disable resize per column)

### v0.13.0 - Filter Enhancement
- [ ] Date Filter + Date Editor (calendar picker UI)
- [ ] Floating Filters (inline filter inputs below header)
- [ ] Set Filter (unique value checkbox filter, Excel-style)
- [ ] Column Menu (header dropdown: sort/filter/hide/pin)

### v0.14.0 - State Management
- [ ] Grid State Save/Restore (persist to localStorage/DB)
- [ ] Column State Save/Restore
- [ ] Value Getters/Setters (computed columns)
- [ ] Row Animation (insert/delete animations)
- [ ] Localization (i18n support)

### v0.15.0 - Enterprise
- [ ] Cell Fill Handle (Excel-style auto-fill)
- [ ] Master-Detail (expandable sub-grids)
- [ ] Printing (@media print optimization)
- [ ] Accessibility (WCAG 2.1 AA)

### v1.0.0 - Official Release
- [ ] Side Bar, Sparklines, Integrated Charts, Formulas
- [ ] Multi-DB drivers (PostgreSQL, MySQL, MSSQL, Oracle)
- [ ] Remaining P2 features

## 📁 Project Structure

```
lib/
├── liveview_grid/              # Business logic
│   ├── grid.ex                 # Grid core module (data/state management)
│   ├── grid_definition.ex      # Grid definition struct (v0.7)
│   ├── data_source.ex          # DataSource behaviour (adapter pattern)
│   ├── data_source/
│   │   ├── in_memory.ex        # InMemory adapter (v0.1)
│   │   ├── ecto.ex             # Ecto/DB adapter (v0.3)
│   │   ├── ecto/
│   │   │   └── query_builder.ex # SQL query builder
│   │   ├── rest.ex             # REST API adapter (v0.5)
│   │   └── raw_table.ex        # Raw table adapter (v0.7)
│   ├── operations/
│   │   ├── sorting.ex          # Sorting engine (v0.1)
│   │   ├── filter.ex           # Filter engine - basic+advanced (v0.1/v0.2)
│   │   ├── pagination.ex       # Pagination (v0.1)
│   │   ├── grouping.ex         # Multi-level grouping (v0.7)
│   │   ├── tree.ex             # Tree grid hierarchy (v0.7)
│   │   └── pivot.ex            # Pivot table transform (v0.7)
│   ├── renderers.ex            # Custom cell renderer presets (v0.5)
│   ├── formatter.ex            # 16 data formatters (v0.7)
│   ├── export.ex               # Excel/CSV Export (v0.5)
│   ├── api_key.ex              # API Key schema
│   ├── api_keys.ex             # API Key context (CRUD)
│   ├── demo_user.ex            # Demo User schema
│   ├── sample_data.ex          # Sample data generator (v0.7)
│   ├── schema_registry.ex      # Schema registry for Grid Builder (v0.7)
│   ├── table_inspector.ex      # DB table introspection (v0.7)
│   ├── grid_presence.ex        # Phoenix Presence for collaboration (v0.7)
│   ├── pub_sub_bridge.ex       # PubSub bridge for real-time sync (v0.7)
│   ├── repo.ex                 # Ecto Repo
│   └── application.ex
└── liveview_grid_web/          # Web layer
    ├── live/
    │   ├── grid_live.ex         # Grid LiveView
    │   ├── demo_live.ex         # InMemory demo
    │   ├── dbms_demo_live.ex    # DBMS demo (SQLite)
    │   ├── api_demo_live.ex     # REST API demo
    │   ├── renderer_demo_live.ex # Renderer demo
    │   ├── advanced_demo_live.ex # Advanced features demo (v0.7)
    │   ├── grid_config_demo_live.ex # Grid Config demo (v0.7)
    │   ├── builder_live.ex      # Grid Builder page (v0.7)
    │   ├── api_key_live.ex      # API Key management
    │   └── api_doc_live.ex      # API documentation
    ├── components/
    │   ├── grid_component.ex    # Grid LiveComponent (core)
    │   ├── grid_component/
    │   │   ├── event_handlers.ex  # Event handler callbacks (v0.7)
    │   │   └── render_helpers.ex  # Render helper functions (v0.7)
    │   ├── grid_config/
    │   │   └── config_modal.ex    # Grid Configuration Modal (v0.7)
    │   ├── grid_builder/
    │   │   ├── builder_modal.ex   # Grid Builder Modal (v0.7)
    │   │   ├── builder_helpers.ex # Builder helper functions (v0.7)
    │   │   └── builder_data_source.ex # Builder data source logic (v0.7)
    │   ├── core_components.ex   # Phoenix core components
    │   └── layouts/
    │       └── dashboard.html.heex  # Sidebar dashboard layout
    ├── plugs/
    │   └── require_api_key.ex       # API Key authentication plug (v0.6)
    ├── controllers/
    │   ├── mock_api_controller.ex   # Mock REST API
    │   └── csv_controller.ex        # CSV download
    └── router.ex

assets/
├── js/
│   ├── app.js                     # JS entry point + hook registry
│   └── hooks/                     # Modular JS hooks (v0.7)
│       ├── virtual-scroll.js      # Virtual scrolling
│       ├── cell-editor.js         # Cell editing
│       ├── cell-editable.js       # Cell editable behavior
│       ├── column-resize.js       # Column resize
│       ├── column-reorder.js      # Column reorder
│       ├── grid-scroll.js         # Grid scroll sync
│       ├── keyboard-nav.js        # Keyboard navigation
│       ├── row-edit-save.js       # Row edit/save
│       ├── file-import.js         # File import
│       └── config-sortable.js     # Config sortable drag
└── css/
    ├── liveview_grid.css          # CSS entry point (imports)
    └── grid/                      # Modular CSS (v0.7)
        ├── variables.css          # CSS variables & themes
        ├── layout.css             # Grid layout
        ├── header.css             # Header styles
        ├── body.css               # Body & cell styles
        ├── toolbar.css            # Toolbar styles
        ├── interactions.css       # Interactions (selection, editing)
        ├── advanced.css           # Advanced features (grouping, tree, pivot)
        ├── config-modal.css       # Config modal styles
        └── context-menu.css       # Context menu styles

guides/                            # ex_doc guide documents
├── getting-started.md / -en.md    # Installation & basic usage
├── formatters.md / -en.md         # 16 formatter types reference
├── data-sources.md / -en.md       # InMemory, Ecto, REST adapters
└── advanced-features.md / -en.md  # CRUD, Grouping, Tree, Pivot
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
