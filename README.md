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
- **Grid Demo**: http://localhost:5001/demo
- **Homepage**: http://localhost:5001

### Development Setup

```bash
# Install dependencies
mix deps.get

# Build assets
mix assets.setup

# Run tests
mix test
```

## ✨ Implemented Features (v0.1-alpha)

### Core
- [x] Table rendering (LiveComponent-based)
- [x] Column sorting (asc/desc toggle with sort icons)
- [x] Row selection (checkbox, select all/none)
- [x] Frozen columns
- [x] Column resize (drag handle)

### Search & Filter
- [x] Global text search (300ms debounce)
- [x] Per-column filters (text/number types)
- [x] Filter toggle button (in header)
- [x] Filter clear button

### Large Dataset
- [x] Virtual scrolling - renders only visible rows
- [x] Infinite scroll - loads more on scroll
- [x] Dynamic data count (50~10,000 rows)
- [x] Pagination (when virtual scroll is OFF)

### Editing
- [x] Inline cell editing (double-click to enter)
- [x] Text/number editor (input)
- [x] Dropdown editor (select) - for fixed-choice columns
- [x] Add row (top/bottom)
- [x] Delete rows (select & delete, :deleted marking)
- [x] Change tracking (N=New, U=Updated, D=Deleted badges)
- [x] Batch save / discard (Save & Discard)

### Export
- [x] CSV download (full data)

## 🗺️ Roadmap

### v0.2 - Validation & Themes
- [ ] Cell validation - required fields, number ranges, format checks
- [ ] Validation error UI (cell highlight, tooltip messages)
- [ ] Theme system (dark mode, custom themes)

### v0.3 - DBMS Integration
- [ ] Ecto/Repo integration - adapter-based multi-DB support
  - PostgreSQL, MySQL/MariaDB (Ecto built-in)
  - MSSQL (`ecto_sql` + `tds`)
  - Oracle (`ecto_oracle`)
  - SQLite (`ecto_sqlite3`)
- [ ] Server-side sort/filter/paging (DB queries)
- [ ] Persist changes to DB (INSERT/UPDATE/DELETE)
- [ ] Large dataset streaming (Repo.stream)

### v0.4 - Advanced Data Processing
- [ ] Grouping
- [ ] Pivot table
- [ ] Tree grid

### v0.5 - Collaboration & Real-time
- [ ] Real-time sync (multi-user concurrent editing)
- [ ] Change history (Undo/Redo)
- [ ] Cell locking

### v1.0 - Enterprise
- [ ] Excel Export/Import
- [ ] Column drag reorder
- [ ] Context menu
- [ ] Keyboard navigation
- [ ] API documentation (HexDocs)

## 📁 Project Structure

```
lib/
├── liveview_grid/              # Business logic
│   ├── grid.ex                 # Grid core module (data/state management)
│   └── application.ex
└── liveview_grid_web/          # Web layer
    ├── live/
    │   └── demo_live.ex        # Demo page (LiveView)
    ├── components/
    │   └── grid_component.ex   # Grid LiveComponent (rendering/events)
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
