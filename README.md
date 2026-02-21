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
- **API Docs**: http://localhost:5001/api-docs

### Development Setup

```bash
# Install dependencies
mix deps.get

# Build assets
mix assets.setup

# Run tests
mix test
```

## ✨ Implemented Features

### v0.1 - Core Grid
- [x] Table rendering (LiveComponent-based)
- [x] Column sorting (asc/desc toggle with sort icons)
- [x] Row selection (checkbox, select all/none)
- [x] Frozen columns
- [x] Column resize (drag handle)
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
- [x] Theme system (dark mode, custom themes, CSS variable customizer)

### v0.3 - DBMS Integration
- [x] Ecto/Repo integration - DataSource behaviour adapter pattern
- [x] SQLite support (`ecto_sqlite3`)
- [x] Server-side sort/filter/paging (SQL ORDER BY, WHERE, LIMIT/OFFSET)
- [x] Persist changes to DB (INSERT/UPDATE/DELETE via Ecto Changeset)

### v0.4 - Column Resize & Reorder
- [x] Column resize (drag handle with min/max width)
- [x] Column drag reorder
- [x] Pagination bug fixes

### v0.5 - REST API Integration
- [x] REST DataSource adapter (configurable base_url, endpoint, headers)
- [x] Async data fetching with loading states & response time tracking
- [x] API-based CRUD (POST create, PUT update, DELETE remove)
- [x] Offset-based pagination via API (page/page_size)
- [x] Authentication header support (Bearer token, custom headers)
- [x] Error handling & retry logic (exponential backoff)
- [x] Mock REST API server (MockApiController)
- [x] API Key management (generate/revoke/delete, SQLite storage)
- [x] API Documentation page
- [x] Dashboard layout with sidebar navigation

## 🗺️ Roadmap

### v0.6 - Upgrade: DBMS & API Enhancements
- [ ] Multi-DB drivers - PostgreSQL (`postgrex`), MySQL/MariaDB (`myxql`)
- [ ] Multi-DB drivers - MSSQL (`tds_ecto`), Oracle (`ecto_oracle`)
- [ ] Large dataset streaming (`Repo.stream` for memory-efficient processing)
- [ ] GraphQL data source support
- [ ] PATCH method support (partial update)
- [ ] Cursor-based pagination (in addition to offset)
- [ ] API Key authentication enforcement (validate keys on API requests)

### v0.7 - Advanced Data Processing
- [ ] Grouping
- [ ] Pivot table
- [ ] Tree grid

### v0.8 - Collaboration & Real-time
- [ ] Real-time sync (multi-user concurrent editing)
- [ ] Change history (Undo/Redo)
- [ ] Cell locking

### v1.0 - Enterprise
- [ ] Excel Export/Import
- [ ] Context menu
- [ ] Keyboard navigation
- [ ] API documentation (HexDocs)

## 📁 Project Structure

```
lib/
├── liveview_grid/              # Business logic
│   ├── grid.ex                 # Grid core module (data/state management)
│   ├── data_source.ex          # DataSource behaviour (adapter pattern)
│   ├── data_source/
│   │   ├── in_memory.ex        # InMemory adapter (v0.1)
│   │   ├── ecto.ex             # Ecto/DB adapter (v0.3)
│   │   └── rest.ex             # REST API adapter (v0.5)
│   ├── api_key.ex              # API Key schema
│   ├── api_keys.ex             # API Key context (CRUD)
│   └── application.ex
└── liveview_grid_web/          # Web layer
    ├── live/
    │   ├── demo_live.ex        # InMemory demo
    │   ├── dbms_demo_live.ex   # DBMS demo (SQLite)
    │   ├── api_demo_live.ex    # REST API demo
    │   ├── renderer_demo_live.ex # Renderer demo
    │   ├── api_key_live.ex     # API Key management
    │   └── api_doc_live.ex     # API documentation
    ├── components/
    │   ├── grid_component.ex   # Grid LiveComponent
    │   └── layouts/
    │       └── dashboard.html.heex  # Sidebar dashboard layout
    ├── controllers/
    │   └── mock_api_controller.ex   # Mock REST API
    └── router.ex

assets/
├── js/app.js                   # JS Hooks (VirtualScroll, CellEditor, etc.)
└── css/liveview_grid.css       # Grid stylesheet
```

## 🔧 Tech Stack

- **Elixir** 1.16+ / **Phoenix** 1.7+
- **LiveView** 1.0+ - Real-time UI (LiveComponent)
- **Custom CSS** - BEM methodology (`lv-grid__*`)
- **JavaScript Hooks** - Virtual scroll, cell editing, column resize

## 📝 Usage Example

```elixir
# Use GridComponent in LiveView
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="users-grid"
  data={@users}
  columns={[
    %{field: :id, label: "ID", width: 80, sortable: true},
    %{field: :name, label: "Name", width: 150, sortable: true,
      filterable: true, filter_type: :text, editable: true},
    %{field: :age, label: "Age", width: 80, sortable: true,
      editable: true, editor_type: :number},
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
