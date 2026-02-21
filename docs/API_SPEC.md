# LiveView Grid API Specification

> **Version**: v0.5
> **Base URL**: `http://localhost:5001/api/v1`
> **Authentication**: Bearer Token (`Authorization: Bearer {API_KEY}`)

---

## Table of Contents

1. [Grid Setup](#1-grid-setup)
2. [CRUD Operations](#2-crud-operations)
3. [Theme](#3-theme)
4. [Sort / Paging / Virtual Scroll](#4-sort--paging--virtual-scroll)
5. [DBMS Connection](#5-dbms-connection)
6. [Custom Cell Renderers](#6-custom-cell-renderers)

---

## Authentication

All API requests require an API Key in the header:

```
Authorization: Bearer lvg_xxxxxxxxxxxxxxxxxxxx
```

API Keys are managed at `/api-keys` page. Permissions: `read`, `read_write`, `admin`.

---

## 1. Grid Setup

Grid is initialized via `LiveViewGrid.Grid.new/1` and rendered through `GridComponent`.

### 1.1 Create Grid Instance

**Elixir API**:
```elixir
grid = LiveViewGrid.Grid.new(
  id: "users-grid",
  columns: columns,
  data: data,           # optional (default [])
  options: options,      # optional (default %{})
  data_source: source    # optional (default nil)
)
```

### 1.2 GET /api/v1/grid/config

Retrieve grid configuration schema.

**Response** `200 OK`:
```json
{
  "grid": {
    "id": "string (auto-generated if omitted)",
    "columns": "array<Column>",
    "options": "GridOptions",
    "data_source": "DataSourceConfig | null"
  }
}
```

### 1.3 Column Definition

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `field` | string | Yes | - | Data key (e.g. `"name"`, `"age"`) |
| `label` | string | Yes | - | Header display text |
| `width` | integer \| "auto" | No | `"auto"` | Column width in px |
| `sortable` | boolean | No | `false` | Enable sorting |
| `filterable` | boolean | No | `false` | Enable column filter |
| `filter_type` | string | No | `"text"` | `"text"` \| `"number"` |
| `editable` | boolean | No | `false` | Enable inline editing |
| `editor_type` | string | No | `"text"` | `"text"` \| `"number"` \| `"select"` |
| `editor_options` | array | No | `[]` | `[{"label": "Seoul", "value": "Seoul"}, ...]` for select editor |
| `validators` | array | No | `[]` | Validation rules (see 1.5) |
| `renderer` | string | No | `null` | Built-in renderer name or custom (see Section 6) |
| `align` | string | No | `"left"` | `"left"` \| `"center"` \| `"right"` |
| `frozen` | boolean | No | `false` | Freeze column to left side |

**Example**:
```json
{
  "columns": [
    {
      "field": "id",
      "label": "ID",
      "width": 80,
      "sortable": true
    },
    {
      "field": "name",
      "label": "Name",
      "width": 150,
      "sortable": true,
      "filterable": true,
      "editable": true,
      "validators": [
        {"type": "required", "message": "Name is required"}
      ]
    },
    {
      "field": "status",
      "label": "Status",
      "width": 120,
      "editable": true,
      "editor_type": "select",
      "editor_options": [
        {"label": "Active", "value": "active"},
        {"label": "Inactive", "value": "inactive"}
      ],
      "renderer": "badge",
      "renderer_options": {
        "colors": {"active": "green", "inactive": "red"}
      }
    }
  ]
}
```

### 1.4 Grid Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `page_size` | integer | `20` | Rows per page (50, 100, 200, 300, 400, 500) |
| `show_header` | boolean | `true` | Show column headers |
| `show_footer` | boolean | `true` | Show footer with pagination |
| `virtual_scroll` | boolean | `false` | Enable virtual scrolling |
| `virtual_buffer` | integer | `5` | Buffer rows above/below viewport |
| `row_height` | integer | `40` | Row height in px (for virtual scroll calc) |
| `viewport_height` | integer | `600` | Viewport height in px |
| `frozen_columns` | integer | `0` | Number of frozen columns from left |
| `debug` | boolean | `false` | Show debug panel |
| `theme` | string | `"light"` | `"light"` \| `"dark"` \| `"custom"` |
| `custom_css_vars` | object | `{}` | CSS variable overrides (see Section 3) |

**Example**:
```json
{
  "options": {
    "page_size": 100,
    "virtual_scroll": true,
    "row_height": 40,
    "frozen_columns": 1,
    "theme": "dark"
  }
}
```

### 1.5 Validators

| Type | Params | Description |
|------|--------|-------------|
| `required` | `message` | Value must not be nil or empty |
| `min` | `value`, `message` | Number >= value |
| `max` | `value`, `message` | Number <= value |
| `min_length` | `value`, `message` | String length >= value |
| `max_length` | `value`, `message` | String length <= value |
| `pattern` | `regex`, `message` | String matches regex |
| `custom` | `function`, `message` | Custom function returns true/false |

```json
{
  "validators": [
    {"type": "required", "message": "Required field"},
    {"type": "min", "value": 0, "message": "Must be positive"},
    {"type": "max", "value": 150, "message": "Max 150"},
    {"type": "pattern", "regex": "^[a-zA-Z]+$", "message": "Letters only"}
  ]
}
```

---

## 2. CRUD Operations

### 2.1 GET /api/v1/grid/{grid_id}/data

Retrieve grid data with server-side filtering, sorting, and pagination.

**Query Parameters**:

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | integer | `1` | Page number |
| `page_size` | integer | `20` | Rows per page |
| `sort` | string | - | Sort field name |
| `order` | string | `"asc"` | `"asc"` \| `"desc"` |
| `q` | string | - | Global search query |
| `filters` | JSON string | - | Column filters `{"name":"Kim","age":">30"}` |

**Response** `200 OK`:
```json
{
  "data": [
    {"id": 1, "name": "Hong", "email": "hong@example.com", "age": 32},
    {"id": 2, "name": "Kim", "email": "kim@example.com", "age": 28}
  ],
  "meta": {
    "total": 1000,
    "filtered": 50,
    "page": 1,
    "page_size": 20,
    "total_pages": 3
  }
}
```

### 2.2 POST /api/v1/grid/{grid_id}/rows

Create a single row.

**Request Body**:
```json
{
  "row": {
    "name": "New User",
    "email": "new@example.com",
    "age": 25,
    "status": "active"
  }
}
```

**Response** `201 Created`:
```json
{
  "data": {
    "id": 1001,
    "name": "New User",
    "email": "new@example.com",
    "age": 25,
    "status": "active"
  },
  "message": "Row created successfully"
}
```

### 2.3 POST /api/v1/grid/{grid_id}/rows/batch

Create multiple rows at once.

**Request Body**:
```json
{
  "rows": [
    {"name": "User A", "email": "a@example.com", "age": 30},
    {"name": "User B", "email": "b@example.com", "age": 25}
  ]
}
```

**Response** `201 Created`:
```json
{
  "data": [
    {"id": 1001, "name": "User A", "email": "a@example.com", "age": 30},
    {"id": 1002, "name": "User B", "email": "b@example.com", "age": 25}
  ],
  "created": 2,
  "message": "2 rows created successfully"
}
```

### 2.4 PUT /api/v1/grid/{grid_id}/rows/{row_id}

Update a single row (full replace).

**Request Body**:
```json
{
  "row": {
    "name": "Updated Name",
    "email": "updated@example.com"
  }
}
```

**Response** `200 OK`:
```json
{
  "data": {
    "id": 1,
    "name": "Updated Name",
    "email": "updated@example.com",
    "age": 32,
    "status": "active"
  },
  "message": "Row updated successfully"
}
```

### 2.5 PATCH /api/v1/grid/{grid_id}/rows/{row_id}

Partial update (specific fields only).

**Request Body**:
```json
{
  "changes": {
    "age": 33
  }
}
```

**Response** `200 OK`:
```json
{
  "data": {
    "id": 1,
    "name": "Hong",
    "email": "hong@example.com",
    "age": 33,
    "status": "active"
  },
  "message": "Row patched successfully"
}
```

### 2.6 PUT /api/v1/grid/{grid_id}/rows/batch

Batch update multiple rows.

**Request Body**:
```json
{
  "rows": [
    {"id": 1, "changes": {"status": "inactive"}},
    {"id": 2, "changes": {"status": "inactive"}}
  ]
}
```

**Response** `200 OK`:
```json
{
  "updated": 2,
  "message": "2 rows updated successfully"
}
```

### 2.7 DELETE /api/v1/grid/{grid_id}/rows/{row_id}

Delete a single row.

**Response** `200 OK`:
```json
{
  "message": "Row deleted successfully",
  "deleted_id": 1
}
```

### 2.8 DELETE /api/v1/grid/{grid_id}/rows/batch

Delete multiple rows.

**Request Body**:
```json
{
  "row_ids": [1, 2, 3]
}
```

**Response** `200 OK`:
```json
{
  "deleted": 3,
  "message": "3 rows deleted successfully"
}
```

### 2.9 POST /api/v1/grid/{grid_id}/save

Save all pending changes (batch save). Sends all rows with N/U/D status.

**Request Body**:
```json
{
  "changes": [
    {"row": {"id": -1, "name": "New"}, "status": "new"},
    {"row": {"id": 5, "name": "Changed"}, "status": "updated"},
    {"row": {"id": 10}, "status": "deleted"}
  ]
}
```

**Response** `200 OK`:
```json
{
  "inserted": 1,
  "updated": 1,
  "deleted": 1,
  "message": "Changes saved successfully"
}
```

---

## 3. Theme

### 3.1 GET /api/v1/themes

List all available themes.

**Response** `200 OK`:
```json
{
  "themes": [
    {
      "name": "light",
      "type": "built-in",
      "description": "Default light theme"
    },
    {
      "name": "dark",
      "type": "built-in",
      "description": "Dark mode theme"
    },
    {
      "name": "ocean",
      "type": "custom",
      "description": "Blue ocean theme"
    }
  ]
}
```

### 3.2 GET /api/v1/themes/{theme_name}

Get theme details with all CSS variables.

**Response** `200 OK`:
```json
{
  "name": "light",
  "type": "built-in",
  "variables": {
    "--lv-grid-primary": "#2196f3",
    "--lv-grid-primary-dark": "#1976d2",
    "--lv-grid-primary-light": "#e3f2fd",
    "--lv-grid-bg": "#ffffff",
    "--lv-grid-bg-secondary": "#fafafa",
    "--lv-grid-text": "#333333",
    "--lv-grid-text-secondary": "#555555",
    "--lv-grid-text-muted": "#999999",
    "--lv-grid-border": "#e0e0e0",
    "--lv-grid-hover": "#f5f5f5",
    "--lv-grid-selected": "#e3f2fd",
    "--lv-grid-danger": "#f44336",
    "--lv-grid-success": "#4caf50",
    "--lv-grid-warning": "#ff9800",
    "--lv-grid-font-family": "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
    "--lv-grid-font-size-sm": "13px",
    "--lv-grid-font-size-md": "14px"
  }
}
```

### 3.3 POST /api/v1/themes

Create a custom theme.

**Request Body**:
```json
{
  "name": "corporate",
  "description": "Corporate brand theme",
  "base": "light",
  "overrides": {
    "--lv-grid-primary": "#e65100",
    "--lv-grid-primary-dark": "#bf360c",
    "--lv-grid-primary-light": "#fff3e0",
    "--lv-grid-bg": "#fffaf5",
    "--lv-grid-selected": "#fff3e0"
  }
}
```

**Response** `201 Created`:
```json
{
  "name": "corporate",
  "type": "custom",
  "variables": {
    "--lv-grid-primary": "#e65100",
    "--lv-grid-bg": "#fffaf5"
  },
  "message": "Theme created successfully"
}
```

### 3.4 PUT /api/v1/grid/{grid_id}/theme

Apply a theme to a specific grid.

**Request Body**:
```json
{
  "theme": "dark",
  "custom_css_vars": {
    "--lv-grid-primary": "#00bcd4"
  }
}
```

**Response** `200 OK`:
```json
{
  "grid_id": "users-grid",
  "theme": "dark",
  "custom_css_vars": {"--lv-grid-primary": "#00bcd4"},
  "message": "Theme applied successfully"
}
```

### 3.5 CSS Variables Reference

| Category | Variable | Light Default | Dark Default |
|----------|----------|---------------|--------------|
| **Primary** | `--lv-grid-primary` | `#2196f3` | `#64b5f6` |
| | `--lv-grid-primary-dark` | `#1976d2` | `#42a5f5` |
| | `--lv-grid-primary-light` | `#e3f2fd` | `#1a237e` |
| **Background** | `--lv-grid-bg` | `#ffffff` | `#1e1e1e` |
| | `--lv-grid-bg-secondary` | `#fafafa` | `#252525` |
| | `--lv-grid-bg-tertiary` | `#f8f9fa` | `#2d2d2d` |
| **Text** | `--lv-grid-text` | `#333333` | `#e0e0e0` |
| | `--lv-grid-text-secondary` | `#555555` | `#bdbdbd` |
| | `--lv-grid-text-muted` | `#999999` | `#757575` |
| **Border** | `--lv-grid-border` | `#e0e0e0` | `#424242` |
| **Interactive** | `--lv-grid-hover` | `#f5f5f5` | `#333333` |
| | `--lv-grid-selected` | `#e3f2fd` | `#1a237e` |
| **Semantic** | `--lv-grid-danger` | `#f44336` | `#ef5350` |
| | `--lv-grid-success` | `#4caf50` | `#66bb6a` |
| | `--lv-grid-warning` | `#ff9800` | `#ffa726` |

---

## 4. Sort / Paging / Virtual Scroll

### 4.1 PUT /api/v1/grid/{grid_id}/sort

Set sorting configuration.

**Request Body**:
```json
{
  "field": "name",
  "direction": "asc"
}
```

**Response** `200 OK`:
```json
{
  "sort": {"field": "name", "direction": "asc"},
  "message": "Sort applied"
}
```

To clear sorting:
```json
{
  "field": null,
  "direction": null
}
```

### 4.2 PUT /api/v1/grid/{grid_id}/pagination

Set pagination configuration.

**Request Body**:
```json
{
  "page": 3,
  "page_size": 50
}
```

**Response** `200 OK`:
```json
{
  "pagination": {
    "current_page": 3,
    "page_size": 50,
    "total_rows": 1000,
    "total_pages": 20
  }
}
```

### 4.3 PUT /api/v1/grid/{grid_id}/virtual-scroll

Enable/configure virtual scrolling.

**Request Body**:
```json
{
  "enabled": true,
  "row_height": 40,
  "buffer": 5,
  "viewport_height": 600
}
```

**Response** `200 OK`:
```json
{
  "virtual_scroll": {
    "enabled": true,
    "row_height": 40,
    "buffer": 5,
    "viewport_height": 600,
    "visible_rows": 15,
    "total_rows": 1000
  }
}
```

### 4.4 PUT /api/v1/grid/{grid_id}/filter

Set filters.

**Request Body**:
```json
{
  "global_search": "Kim",
  "column_filters": {
    "age": ">30",
    "status": "active"
  },
  "advanced_filters": {
    "logic": "and",
    "conditions": [
      {"field": "department", "operator": "equals", "value": "Engineering"},
      {"field": "age", "operator": "gte", "value": "25"}
    ]
  }
}
```

**Filter Operators**:

| Type | Operator | Description |
|------|----------|-------------|
| Text | `contains` | Substring match (case-insensitive) |
| Text | `equals` | Exact match |
| Text | `starts_with` | Prefix match |
| Text | `ends_with` | Suffix match |
| Text | `is_empty` | Null or empty string |
| Text | `is_not_empty` | Not null and not empty |
| Number | `eq` | Equal to |
| Number | `neq` | Not equal to |
| Number | `gt` | Greater than |
| Number | `lt` | Less than |
| Number | `gte` | Greater than or equal |
| Number | `lte` | Less than or equal |

**Response** `200 OK`:
```json
{
  "filtered_count": 42,
  "total_count": 1000,
  "message": "Filters applied"
}
```

---

## 5. DBMS Connection

### 5.1 GET /api/v1/datasources

List available DataSource adapters.

**Response** `200 OK`:
```json
{
  "adapters": [
    {
      "type": "in_memory",
      "description": "Client-side in-memory data processing",
      "config_schema": {
        "data": "array<object> (required)"
      }
    },
    {
      "type": "ecto",
      "description": "Ecto/Repo integration for SQL databases",
      "supported_databases": ["SQLite", "PostgreSQL", "MySQL", "MSSQL", "Oracle"],
      "config_schema": {
        "repo": "module (required) - Ecto Repo module",
        "schema": "module (required) - Ecto schema module",
        "base_query": "Ecto.Query (optional) - pre-filtered query"
      }
    },
    {
      "type": "rest",
      "description": "External REST API data source",
      "config_schema": {
        "base_url": "string (required)",
        "endpoint": "string (optional, default: '')",
        "headers": "object (optional)",
        "response_mapping": "object (optional)",
        "query_mapping": "object (optional)",
        "request_opts": "object (optional)"
      }
    }
  ]
}
```

### 5.2 POST /api/v1/grid/{grid_id}/datasource

Connect a DataSource to a grid.

**Request Body (Ecto)**:
```json
{
  "type": "ecto",
  "config": {
    "repo": "LiveviewGrid.Repo",
    "schema": "LiveviewGrid.DemoUser"
  }
}
```

**Request Body (REST)**:
```json
{
  "type": "rest",
  "config": {
    "base_url": "https://api.example.com",
    "endpoint": "/users",
    "headers": {
      "Authorization": "Bearer token123"
    },
    "response_mapping": {
      "data_key": "data",
      "total_key": "total",
      "filtered_key": "filtered"
    },
    "query_mapping": {
      "page": "page",
      "page_size": "per_page",
      "sort_field": "sort_by",
      "sort_direction": "sort_order",
      "search": "search",
      "filters": "filters"
    },
    "request_opts": {
      "timeout": 10000,
      "retry": 3,
      "retry_delay": 1000
    }
  }
}
```

**Response** `200 OK`:
```json
{
  "grid_id": "users-grid",
  "datasource": {
    "type": "ecto",
    "connected": true,
    "config": {
      "repo": "LiveviewGrid.Repo",
      "schema": "LiveviewGrid.DemoUser"
    }
  },
  "message": "DataSource connected successfully"
}
```

### 5.3 GET /api/v1/grid/{grid_id}/datasource

Get current DataSource configuration.

**Response** `200 OK`:
```json
{
  "type": "ecto",
  "connected": true,
  "config": {
    "repo": "LiveviewGrid.Repo",
    "schema": "LiveviewGrid.DemoUser"
  },
  "stats": {
    "total_rows": 1000,
    "last_fetched_at": "2026-02-22T10:30:00Z"
  }
}
```

### 5.4 DELETE /api/v1/grid/{grid_id}/datasource

Disconnect DataSource (revert to in-memory mode).

**Response** `200 OK`:
```json
{
  "message": "DataSource disconnected",
  "mode": "in_memory"
}
```

### 5.5 Ecto Adapter - Server-side Operations

When using the Ecto adapter, all operations are SQL-optimized:

| Operation | SQL Equivalent |
|-----------|---------------|
| Global search | `WHERE field1 LIKE '%q%' OR field2 LIKE '%q%' OR ...` |
| Column filter (text) | `WHERE field LIKE '%value%'` |
| Column filter (number) | `WHERE field > 30` (supports `>`, `<`, `>=`, `<=`, `=`, `!=`) |
| Advanced filter (AND) | `WHERE cond1 AND cond2 AND cond3` |
| Advanced filter (OR) | `WHERE cond1 OR cond2 OR cond3` |
| Sort | `ORDER BY field ASC/DESC` |
| Pagination | `LIMIT page_size OFFSET (page-1)*page_size` |

### 5.6 REST Adapter - Query Mapping

The REST adapter maps grid state to API query parameters:

| Grid State | Default Param | Customizable |
|------------|---------------|--------------|
| Page number | `page` | `query_mapping.page` |
| Page size | `page_size` | `query_mapping.page_size` |
| Sort field | `sort` | `query_mapping.sort_field` |
| Sort direction | `order` | `query_mapping.sort_direction` |
| Global search | `q` | `query_mapping.search` |
| Column filters | `filters` (JSON) | `query_mapping.filters` |

**Retry Configuration**:

| Config | Default | Description |
|--------|---------|-------------|
| `timeout` | 10,000ms | Request timeout |
| `retry` | 3 | Max retry attempts |
| `retry_delay` | 1,000ms | Base delay (exponential: `delay * (attempt+1)`) |
| Retried status codes | 408, 429, 500, 502, 503, 504 | Auto-retry on these HTTP codes |

---

## 6. Custom Cell Renderers

### 6.1 GET /api/v1/renderers

List all available cell renderers.

**Response** `200 OK`:
```json
{
  "renderers": [
    {
      "name": "badge",
      "description": "Colored badge for categorical values",
      "options": {
        "colors": "object - value-to-color mapping",
        "default_color": "string (default: 'gray')"
      },
      "available_colors": ["blue", "green", "red", "yellow", "gray", "purple"],
      "example": {
        "renderer": "badge",
        "renderer_options": {
          "colors": {"active": "green", "inactive": "red", "pending": "yellow"},
          "default_color": "gray"
        }
      }
    },
    {
      "name": "link",
      "description": "Clickable hyperlink",
      "options": {
        "prefix": "string - URL prefix (e.g. 'mailto:', 'https://')",
        "target": "string - link target (e.g. '_blank')",
        "href": "function(row, column) - custom URL builder"
      },
      "example": {
        "renderer": "link",
        "renderer_options": {
          "prefix": "mailto:",
          "target": "_blank"
        }
      }
    },
    {
      "name": "progress",
      "description": "Progress bar for numeric values",
      "options": {
        "max": "number (default: 100)",
        "color": "string (default: 'blue')",
        "show_value": "boolean (default: true)"
      },
      "available_colors": ["blue", "green", "red", "yellow"],
      "example": {
        "renderer": "progress",
        "renderer_options": {
          "max": 60,
          "color": "green",
          "show_value": true
        }
      }
    }
  ]
}
```

### 6.2 GET /api/v1/renderers/{renderer_name}

Get specific renderer details and configuration schema.

**Response** `200 OK`:
```json
{
  "name": "badge",
  "description": "Colored badge for categorical values",
  "options_schema": {
    "colors": {
      "type": "object",
      "description": "Map of data values to color names",
      "example": {"active": "green", "inactive": "red"}
    },
    "default_color": {
      "type": "string",
      "default": "gray",
      "enum": ["blue", "green", "red", "yellow", "gray", "purple"]
    }
  },
  "css_classes": [
    ".lv-grid__badge",
    ".lv-grid__badge--blue",
    ".lv-grid__badge--green",
    ".lv-grid__badge--red",
    ".lv-grid__badge--yellow",
    ".lv-grid__badge--gray",
    ".lv-grid__badge--purple"
  ]
}
```

### 6.3 PUT /api/v1/grid/{grid_id}/columns/{field}/renderer

Set renderer for a specific column.

**Request Body**:
```json
{
  "renderer": "badge",
  "renderer_options": {
    "colors": {
      "active": "green",
      "inactive": "red",
      "pending": "yellow"
    },
    "default_color": "gray"
  }
}
```

**Response** `200 OK`:
```json
{
  "field": "status",
  "renderer": "badge",
  "renderer_options": {
    "colors": {"active": "green", "inactive": "red", "pending": "yellow"},
    "default_color": "gray"
  },
  "message": "Renderer applied to column 'status'"
}
```

### 6.4 Custom Renderer (Elixir function)

For advanced use cases, define a custom renderer function:

```elixir
# In column definition
%{
  field: :email,
  label: "Email",
  renderer: fn row, column, _assigns ->
    value = Map.get(row, column.field)
    assigns = %{value: value}
    ~H"""
    <a href={"mailto:#{@value}"} class="lv-grid__link">
      <%= @value %>
    </a>
    """
  end
}
```

**Renderer Function Signature**:
```
fn(row :: map(), column :: map(), assigns :: map()) -> Phoenix.LiveView.Rendered.t()
```

If a renderer raises an exception, the grid falls back to displaying `to_string(value)`.

### 6.5 DELETE /api/v1/grid/{grid_id}/columns/{field}/renderer

Remove custom renderer (revert to plain text display).

**Response** `200 OK`:
```json
{
  "field": "status",
  "renderer": null,
  "message": "Renderer removed from column 'status'"
}
```

---

## Error Responses

All endpoints return consistent error format:

### 400 Bad Request
```json
{
  "error": "invalid_request",
  "message": "Missing required field: name",
  "details": {"field": "name"}
}
```

### 401 Unauthorized
```json
{
  "error": "unauthorized",
  "message": "Invalid or missing API key"
}
```

### 403 Forbidden
```json
{
  "error": "forbidden",
  "message": "Insufficient permissions. Required: read_write"
}
```

### 404 Not Found
```json
{
  "error": "not_found",
  "message": "Row with id 999 not found"
}
```

### 422 Unprocessable Entity
```json
{
  "error": "validation_failed",
  "message": "Validation errors",
  "details": {
    "name": ["Name is required"],
    "age": ["Must be positive"]
  }
}
```

### 500 Internal Server Error
```json
{
  "error": "internal_error",
  "message": "An unexpected error occurred"
}
```

---

## Event System (LiveView WebSocket)

For LiveView clients, the grid communicates via events instead of REST:

### Client -> Server Events

| Event | Payload | Description |
|-------|---------|-------------|
| `grid_sort` | `{field, direction}` | Sort column |
| `grid_filter` | `{field, value}` | Set column filter |
| `grid_global_search` | `{value}` | Global search |
| `grid_page_change` | `{page}` | Change page |
| `grid_page_size_change` | `{page_size}` | Change page size |
| `grid_scroll` | `{scroll_top}` | Virtual scroll position |
| `grid_column_resize` | `{field, width}` | Resize column |
| `grid_column_reorder` | `{order: [fields]}` | Reorder columns |
| `cell_edit_start` | `{row_id, field}` | Start cell edit |
| `cell_edit_save` | `{row_id, field, value}` | Save cell edit |
| `grid_add_row` | `{}` | Add new row |
| `grid_delete_selected` | `{}` | Delete selected rows |
| `grid_save` | `{}` | Save all changes |
| `grid_discard` | `{}` | Discard all changes |

### Server -> Parent LiveView Messages

| Message | Payload | Description |
|---------|---------|-------------|
| `{:grid_cell_updated, row_id, field, value}` | ids, atom, any | Cell value changed |
| `{:grid_row_added, row}` | map | New row added |
| `{:grid_rows_deleted, row_ids}` | list | Rows deleted |
| `{:grid_save_requested, changed_rows}` | list of `{row, status}` | Save requested |
| `{:grid_save_blocked, error_count}` | integer | Save blocked by errors |
| `:grid_discard_requested` | - | Discard requested |
| `{:grid_download_file, payload}` | map | File export ready |

---

## API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| **Grid Setup** | | |
| GET | `/api/v1/grid/config` | Grid config schema |
| **CRUD** | | |
| GET | `/api/v1/grid/{id}/data` | Get data (with filter/sort/page) |
| POST | `/api/v1/grid/{id}/rows` | Create row |
| POST | `/api/v1/grid/{id}/rows/batch` | Batch create |
| PUT | `/api/v1/grid/{id}/rows/{row_id}` | Full update |
| PATCH | `/api/v1/grid/{id}/rows/{row_id}` | Partial update |
| PUT | `/api/v1/grid/{id}/rows/batch` | Batch update |
| DELETE | `/api/v1/grid/{id}/rows/{row_id}` | Delete row |
| DELETE | `/api/v1/grid/{id}/rows/batch` | Batch delete |
| POST | `/api/v1/grid/{id}/save` | Save all changes |
| **Theme** | | |
| GET | `/api/v1/themes` | List themes |
| GET | `/api/v1/themes/{name}` | Get theme detail |
| POST | `/api/v1/themes` | Create custom theme |
| PUT | `/api/v1/grid/{id}/theme` | Apply theme |
| **Sort/Page/Filter** | | |
| PUT | `/api/v1/grid/{id}/sort` | Set sort |
| PUT | `/api/v1/grid/{id}/pagination` | Set pagination |
| PUT | `/api/v1/grid/{id}/virtual-scroll` | Configure virtual scroll |
| PUT | `/api/v1/grid/{id}/filter` | Set filters |
| **DataSource** | | |
| GET | `/api/v1/datasources` | List adapters |
| POST | `/api/v1/grid/{id}/datasource` | Connect DataSource |
| GET | `/api/v1/grid/{id}/datasource` | Get current DataSource |
| DELETE | `/api/v1/grid/{id}/datasource` | Disconnect DataSource |
| **Renderers** | | |
| GET | `/api/v1/renderers` | List renderers |
| GET | `/api/v1/renderers/{name}` | Get renderer detail |
| PUT | `/api/v1/grid/{id}/columns/{field}/renderer` | Set renderer |
| DELETE | `/api/v1/grid/{id}/columns/{field}/renderer` | Remove renderer |
