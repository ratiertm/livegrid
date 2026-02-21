defmodule LiveviewGridWeb.ApiDocLive do
  @moduledoc """
  API Documentation 페이지 - LiveView Grid REST API 명세
  6개 카테고리: Grid Setup, CRUD, Theme, Sort/Page/Scroll, DBMS, Renderers
  """
  use Phoenix.LiveView

  @categories [
    %{id: "setup", label: "Grid Setup", icon: "cog"},
    %{id: "crud", label: "CRUD", icon: "database"},
    %{id: "theme", label: "Theme", icon: "palette"},
    %{id: "sort_page", label: "Sort / Page / Scroll", icon: "sort"},
    %{id: "dbms", label: "DBMS Connection", icon: "server"},
    %{id: "renderer", label: "Renderers", icon: "brush"}
  ]

  @endpoints %{
    "setup" => [
      %{
        id: "get_config",
        method: "GET",
        path: "/api/v1/grid/config",
        title: "Grid 설정 스키마 조회",
        description: "Grid 초기화에 필요한 설정 스키마(컬럼, 옵션, 데이터소스)를 반환합니다.",
        params: [],
        request_body: nil,
        response_example: """
        {
          "grid": {
            "id": "string",
            "columns": "array<Column>",
            "options": "GridOptions",
            "data_source": "DataSourceConfig | null"
          },
          "column_schema": {
            "field": "string (required)",
            "label": "string (required)",
            "width": "integer | 'auto'",
            "sortable": "boolean",
            "filterable": "boolean",
            "filter_type": "'text' | 'number'",
            "editable": "boolean",
            "editor_type": "'text' | 'number' | 'select'",
            "editor_options": "[{label, value}]",
            "validators": "array<Validator>",
            "renderer": "string | null",
            "align": "'left' | 'center' | 'right'"
          },
          "options_schema": {
            "page_size": "integer (default: 20)",
            "virtual_scroll": "boolean (default: false)",
            "row_height": "integer (default: 40)",
            "frozen_columns": "integer (default: 0)",
            "theme": "'light' | 'dark' | 'custom'",
            "debug": "boolean (default: false)"
          }
        }
        """
      }
    ],
    "crud" => [
      %{
        id: "get_data",
        method: "GET",
        path: "/api/v1/grid/{grid_id}/data",
        title: "데이터 조회",
        description: "서버사이드 필터링, 정렬, 페이지네이션을 적용하여 Grid 데이터를 반환합니다.",
        params: [
          %{name: "page", type: "integer", default: "1", desc: "페이지 번호"},
          %{name: "page_size", type: "integer", default: "20", desc: "페이지당 행 수"},
          %{name: "sort", type: "string", default: "-", desc: "정렬 필드명"},
          %{name: "order", type: "string", default: "asc", desc: "정렬 방향 (asc, desc)"},
          %{name: "q", type: "string", default: "-", desc: "글로벌 검색어"},
          %{name: "filters", type: "JSON", default: "-", desc: "컬럼 필터 {\"name\":\"Kim\",\"age\":\">30\"}"}
        ],
        request_body: nil,
        response_example: """
        {
          "data": [
            {"id": 1, "name": "홍길동", "email": "hong@example.com", "age": 32}
          ],
          "meta": {
            "total": 1000,
            "filtered": 50,
            "page": 1,
            "page_size": 20,
            "total_pages": 3
          }
        }
        """
      },
      %{
        id: "create_row",
        method: "POST",
        path: "/api/v1/grid/{grid_id}/rows",
        title: "행 생성 (단건)",
        description: "새로운 행을 추가합니다.",
        params: [],
        request_body: """
        {
          "row": {
            "name": "김철수",
            "email": "kim@example.com",
            "age": 28,
            "status": "active"
          }
        }
        """,
        response_example: """
        {
          "data": {
            "id": 1001,
            "name": "김철수",
            "email": "kim@example.com",
            "age": 28,
            "status": "active"
          },
          "message": "Row created successfully"
        }
        """
      },
      %{
        id: "create_batch",
        method: "POST",
        path: "/api/v1/grid/{grid_id}/rows/batch",
        title: "행 생성 (멀티)",
        description: "여러 행을 한 번에 생성합니다.",
        params: [],
        request_body: """
        {
          "rows": [
            {"name": "User A", "email": "a@ex.com", "age": 30},
            {"name": "User B", "email": "b@ex.com", "age": 25}
          ]
        }
        """,
        response_example: """
        {
          "data": [
            {"id": 1001, "name": "User A", ...},
            {"id": 1002, "name": "User B", ...}
          ],
          "created": 2,
          "message": "2 rows created successfully"
        }
        """
      },
      %{
        id: "update_row",
        method: "PUT",
        path: "/api/v1/grid/{grid_id}/rows/{row_id}",
        title: "행 수정 (전체)",
        description: "기존 행의 데이터를 전체 교체합니다.",
        params: [
          %{name: "row_id", type: "integer", default: "-", desc: "행 ID (path parameter)"}
        ],
        request_body: """
        {
          "row": {
            "name": "수정된 이름",
            "email": "updated@example.com"
          }
        }
        """,
        response_example: """
        {
          "data": {
            "id": 1,
            "name": "수정된 이름",
            "email": "updated@example.com",
            "age": 32,
            "status": "active"
          },
          "message": "Row updated successfully"
        }
        """
      },
      %{
        id: "patch_row",
        method: "PATCH",
        path: "/api/v1/grid/{grid_id}/rows/{row_id}",
        title: "행 수정 (부분)",
        description: "특정 필드만 부분 수정합니다.",
        params: [
          %{name: "row_id", type: "integer", default: "-", desc: "행 ID (path parameter)"}
        ],
        request_body: """
        {
          "changes": {
            "age": 33
          }
        }
        """,
        response_example: """
        {
          "data": {
            "id": 1,
            "name": "홍길동",
            "age": 33,
            "status": "active"
          },
          "message": "Row patched successfully"
        }
        """
      },
      %{
        id: "update_batch",
        method: "PUT",
        path: "/api/v1/grid/{grid_id}/rows/batch",
        title: "행 수정 (멀티)",
        description: "여러 행을 한 번에 수정합니다.",
        params: [],
        request_body: """
        {
          "rows": [
            {"id": 1, "changes": {"status": "inactive"}},
            {"id": 2, "changes": {"status": "inactive"}}
          ]
        }
        """,
        response_example: """
        {
          "updated": 2,
          "message": "2 rows updated successfully"
        }
        """
      },
      %{
        id: "delete_row",
        method: "DELETE",
        path: "/api/v1/grid/{grid_id}/rows/{row_id}",
        title: "행 삭제 (단건)",
        description: "행을 삭제합니다.",
        params: [
          %{name: "row_id", type: "integer", default: "-", desc: "행 ID (path parameter)"}
        ],
        request_body: nil,
        response_example: """
        {
          "message": "Row deleted successfully",
          "deleted_id": 1
        }
        """
      },
      %{
        id: "delete_batch",
        method: "DELETE",
        path: "/api/v1/grid/{grid_id}/rows/batch",
        title: "행 삭제 (멀티)",
        description: "여러 행을 한 번에 삭제합니다.",
        params: [],
        request_body: """
        {
          "row_ids": [1, 2, 3]
        }
        """,
        response_example: """
        {
          "deleted": 3,
          "message": "3 rows deleted successfully"
        }
        """
      },
      %{
        id: "save_changes",
        method: "POST",
        path: "/api/v1/grid/{grid_id}/save",
        title: "변경사항 일괄 저장",
        description: "N(신규)/U(수정)/D(삭제) 상태의 모든 변경사항을 한 번에 저장합니다.",
        params: [],
        request_body: """
        {
          "changes": [
            {"row": {"id": -1, "name": "New"}, "status": "new"},
            {"row": {"id": 5, "name": "Changed"}, "status": "updated"},
            {"row": {"id": 10}, "status": "deleted"}
          ]
        }
        """,
        response_example: """
        {
          "inserted": 1,
          "updated": 1,
          "deleted": 1,
          "message": "Changes saved successfully"
        }
        """
      }
    ],
    "theme" => [
      %{
        id: "list_themes",
        method: "GET",
        path: "/api/v1/themes",
        title: "테마 목록 조회",
        description: "사용 가능한 모든 테마(내장 + 커스텀)를 조회합니다.",
        params: [],
        request_body: nil,
        response_example: """
        {
          "themes": [
            {"name": "light", "type": "built-in", "description": "Default light theme"},
            {"name": "dark", "type": "built-in", "description": "Dark mode theme"},
            {"name": "corporate", "type": "custom", "description": "Corporate brand"}
          ]
        }
        """
      },
      %{
        id: "get_theme",
        method: "GET",
        path: "/api/v1/themes/{theme_name}",
        title: "테마 상세 조회",
        description: "특정 테마의 전체 CSS 변수 값을 반환합니다.",
        params: [
          %{name: "theme_name", type: "string", default: "-", desc: "테마명 (light, dark, custom...)"}
        ],
        request_body: nil,
        response_example: """
        {
          "name": "light",
          "type": "built-in",
          "variables": {
            "--lv-grid-primary": "#2196f3",
            "--lv-grid-bg": "#ffffff",
            "--lv-grid-text": "#333333",
            "--lv-grid-border": "#e0e0e0",
            "--lv-grid-hover": "#f5f5f5",
            "--lv-grid-selected": "#e3f2fd",
            "--lv-grid-danger": "#f44336",
            "--lv-grid-success": "#4caf50"
          }
        }
        """
      },
      %{
        id: "create_theme",
        method: "POST",
        path: "/api/v1/themes",
        title: "커스텀 테마 생성",
        description: "기존 테마를 기반으로 커스텀 테마를 생성합니다.",
        params: [],
        request_body: """
        {
          "name": "corporate",
          "description": "Corporate brand theme",
          "base": "light",
          "overrides": {
            "--lv-grid-primary": "#e65100",
            "--lv-grid-bg": "#fffaf5",
            "--lv-grid-selected": "#fff3e0"
          }
        }
        """,
        response_example: """
        {
          "name": "corporate",
          "type": "custom",
          "variables": {"--lv-grid-primary": "#e65100", ...},
          "message": "Theme created successfully"
        }
        """
      },
      %{
        id: "apply_theme",
        method: "PUT",
        path: "/api/v1/grid/{grid_id}/theme",
        title: "테마 적용",
        description: "Grid에 테마를 적용합니다. custom_css_vars로 개별 변수 오버라이드 가능합니다.",
        params: [],
        request_body: """
        {
          "theme": "dark",
          "custom_css_vars": {
            "--lv-grid-primary": "#00bcd4"
          }
        }
        """,
        response_example: """
        {
          "grid_id": "users-grid",
          "theme": "dark",
          "custom_css_vars": {"--lv-grid-primary": "#00bcd4"},
          "message": "Theme applied successfully"
        }
        """
      }
    ],
    "sort_page" => [
      %{
        id: "set_sort",
        method: "PUT",
        path: "/api/v1/grid/{grid_id}/sort",
        title: "정렬 설정",
        description: "Grid 정렬 설정을 변경합니다. field를 null로 설정하면 정렬을 해제합니다.",
        params: [],
        request_body: """
        {
          "field": "name",
          "direction": "asc"
        }
        """,
        response_example: """
        {
          "sort": {"field": "name", "direction": "asc"},
          "message": "Sort applied"
        }
        """
      },
      %{
        id: "set_pagination",
        method: "PUT",
        path: "/api/v1/grid/{grid_id}/pagination",
        title: "페이지네이션 설정",
        description: "페이지 번호와 페이지 크기를 변경합니다.",
        params: [],
        request_body: """
        {
          "page": 3,
          "page_size": 50
        }
        """,
        response_example: """
        {
          "pagination": {
            "current_page": 3,
            "page_size": 50,
            "total_rows": 1000,
            "total_pages": 20
          }
        }
        """
      },
      %{
        id: "set_virtual_scroll",
        method: "PUT",
        path: "/api/v1/grid/{grid_id}/virtual-scroll",
        title: "Virtual Scroll 설정",
        description: "Virtual Scrolling을 활성화/비활성화하고 관련 파라미터를 설정합니다.",
        params: [],
        request_body: """
        {
          "enabled": true,
          "row_height": 40,
          "buffer": 5,
          "viewport_height": 600
        }
        """,
        response_example: """
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
        """
      },
      %{
        id: "set_filter",
        method: "PUT",
        path: "/api/v1/grid/{grid_id}/filter",
        title: "필터 설정",
        description: "글로벌 검색, 컬럼 필터, 고급 필터를 설정합니다.",
        params: [],
        request_body: """
        {
          "global_search": "Kim",
          "column_filters": {
            "age": ">30",
            "status": "active"
          },
          "advanced_filters": {
            "logic": "and",
            "conditions": [
              {"field": "dept", "operator": "equals", "value": "Eng"},
              {"field": "age", "operator": "gte", "value": "25"}
            ]
          }
        }
        """,
        response_example: """
        {
          "filtered_count": 42,
          "total_count": 1000,
          "message": "Filters applied"
        }
        """
      }
    ],
    "dbms" => [
      %{
        id: "list_adapters",
        method: "GET",
        path: "/api/v1/datasources",
        title: "DataSource 어댑터 목록",
        description: "사용 가능한 DataSource 어댑터(InMemory, Ecto, REST)와 설정 스키마를 조회합니다.",
        params: [],
        request_body: nil,
        response_example: """
        {
          "adapters": [
            {
              "type": "in_memory",
              "description": "Client-side in-memory processing"
            },
            {
              "type": "ecto",
              "description": "Ecto/Repo SQL database integration",
              "supported_databases": [
                "SQLite", "PostgreSQL", "MySQL", "MSSQL", "Oracle"
              ],
              "config_schema": {
                "repo": "module (required)",
                "schema": "module (required)",
                "base_query": "Ecto.Query (optional)"
              }
            },
            {
              "type": "rest",
              "description": "External REST API data source",
              "config_schema": {
                "base_url": "string (required)",
                "endpoint": "string (optional)",
                "headers": "object (optional)",
                "request_opts": "object (optional)"
              }
            }
          ]
        }
        """
      },
      %{
        id: "connect_datasource",
        method: "POST",
        path: "/api/v1/grid/{grid_id}/datasource",
        title: "DataSource 연결",
        description: "Grid에 DataSource를 연결합니다. Ecto(SQL) 또는 REST API를 선택할 수 있습니다.",
        params: [],
        request_body: """
        {
          "type": "ecto",
          "config": {
            "repo": "LiveviewGrid.Repo",
            "schema": "LiveviewGrid.DemoUser"
          }
        }
        """,
        response_example: """
        {
          "grid_id": "users-grid",
          "datasource": {
            "type": "ecto",
            "connected": true
          },
          "message": "DataSource connected successfully"
        }
        """
      },
      %{
        id: "get_datasource",
        method: "GET",
        path: "/api/v1/grid/{grid_id}/datasource",
        title: "DataSource 설정 조회",
        description: "현재 연결된 DataSource의 설정과 상태를 조회합니다.",
        params: [],
        request_body: nil,
        response_example: """
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
        """
      },
      %{
        id: "disconnect_datasource",
        method: "DELETE",
        path: "/api/v1/grid/{grid_id}/datasource",
        title: "DataSource 연결 해제",
        description: "DataSource 연결을 해제하고 InMemory 모드로 전환합니다.",
        params: [],
        request_body: nil,
        response_example: """
        {
          "message": "DataSource disconnected",
          "mode": "in_memory"
        }
        """
      }
    ],
    "renderer" => [
      %{
        id: "list_renderers",
        method: "GET",
        path: "/api/v1/renderers",
        title: "렌더러 목록 조회",
        description: "사용 가능한 모든 셀 렌더러(badge, link, progress)와 설정 옵션을 조회합니다.",
        params: [],
        request_body: nil,
        response_example: """
        {
          "renderers": [
            {
              "name": "badge",
              "description": "Colored badge for categorical values",
              "options": {
                "colors": "object (value -> color mapping)",
                "default_color": "string (default: gray)"
              },
              "available_colors": [
                "blue", "green", "red", "yellow", "gray", "purple"
              ]
            },
            {
              "name": "link",
              "description": "Clickable hyperlink",
              "options": {
                "prefix": "URL prefix (e.g. mailto:)",
                "target": "link target (e.g. _blank)"
              }
            },
            {
              "name": "progress",
              "description": "Progress bar for numeric values",
              "options": {
                "max": "number (default: 100)",
                "color": "string (default: blue)",
                "show_value": "boolean (default: true)"
              }
            }
          ]
        }
        """
      },
      %{
        id: "get_renderer",
        method: "GET",
        path: "/api/v1/renderers/{renderer_name}",
        title: "렌더러 상세 조회",
        description: "특정 렌더러의 상세 설정 스키마와 CSS 클래스 목록을 조회합니다.",
        params: [
          %{name: "renderer_name", type: "string", default: "-", desc: "렌더러명 (badge, link, progress)"}
        ],
        request_body: nil,
        response_example: """
        {
          "name": "badge",
          "options_schema": {
            "colors": {
              "type": "object",
              "example": {"active": "green", "inactive": "red"}
            },
            "default_color": {
              "type": "string",
              "default": "gray",
              "enum": ["blue","green","red","yellow","gray","purple"]
            }
          },
          "css_classes": [
            ".lv-grid__badge",
            ".lv-grid__badge--blue",
            ".lv-grid__badge--green"
          ]
        }
        """
      },
      %{
        id: "set_renderer",
        method: "PUT",
        path: "/api/v1/grid/{grid_id}/columns/{field}/renderer",
        title: "렌더러 적용",
        description: "특정 컬럼에 셀 렌더러를 적용합니다.",
        params: [
          %{name: "field", type: "string", default: "-", desc: "컬럼 필드명 (path parameter)"}
        ],
        request_body: """
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
        """,
        response_example: """
        {
          "field": "status",
          "renderer": "badge",
          "renderer_options": {
            "colors": {"active":"green","inactive":"red","pending":"yellow"},
            "default_color": "gray"
          },
          "message": "Renderer applied to column 'status'"
        }
        """
      },
      %{
        id: "remove_renderer",
        method: "DELETE",
        path: "/api/v1/grid/{grid_id}/columns/{field}/renderer",
        title: "렌더러 제거",
        description: "컬럼의 커스텀 렌더러를 제거하고 기본 텍스트 표시로 되돌립니다.",
        params: [
          %{name: "field", type: "string", default: "-", desc: "컬럼 필드명 (path parameter)"}
        ],
        request_body: nil,
        response_example: """
        {
          "field": "status",
          "renderer": null,
          "message": "Renderer removed from column 'status'"
        }
        """
      }
    ]
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       categories: @categories,
       endpoints: @endpoints,
       active_category: "setup",
       active_endpoint: "get_config"
     )}
  end

  @impl true
  def handle_event("select_category", %{"id" => id}, socket) do
    first_ep = List.first(@endpoints[id])
    {:noreply, assign(socket, active_category: id, active_endpoint: first_ep.id)}
  end

  @impl true
  def handle_event("select_endpoint", %{"id" => id}, socket) do
    {:noreply, assign(socket, active_endpoint: id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="padding: 24px; max-width: 1400px; margin: 0 auto;">
      <!-- Header -->
      <div style="margin-bottom: 20px;">
        <h1 style="margin: 0; font-size: 24px; font-weight: 700; color: #1a1a1a;">API Documentation</h1>
        <p style="margin: 4px 0 0; color: #666; font-size: 14px;">
          LiveView Grid REST API &mdash; Base URL: <code style="background: #f1f5f9; padding: 2px 6px; border-radius: 3px; font-size: 13px;">/api/v1</code>
        </p>
      </div>

      <!-- Category Tabs -->
      <div style="display: flex; gap: 4px; margin-bottom: 20px; overflow-x: auto; border-bottom: 2px solid #e2e8f0; padding-bottom: 0;">
        <%= for cat <- @categories do %>
          <button
            phx-click="select_category"
            phx-value-id={cat.id}
            style={"padding: 10px 18px; border: none; cursor: pointer; font-size: 13px; font-weight: 600; border-bottom: 3px solid transparent; margin-bottom: -2px; transition: all 0.15s; #{if @active_category == cat.id, do: "background: #eff6ff; color: #1d4ed8; border-bottom-color: #3b82f6; border-radius: 6px 6px 0 0;", else: "background: transparent; color: #64748b; border-radius: 6px 6px 0 0;"}"}
          >
            <%= cat.label %>
          </button>
        <% end %>
      </div>

      <div style="display: flex; gap: 20px;">
        <!-- Endpoint List (left) -->
        <div style="width: 300px; flex-shrink: 0;">
          <div style="background: white; border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden; position: sticky; top: 24px;">
            <div style="padding: 12px 16px; border-bottom: 1px solid #e2e8f0; font-weight: 600; font-size: 12px; color: #475569; background: #f8fafc; text-transform: uppercase; letter-spacing: 0.5px;">
              <%= Enum.find(@categories, & &1.id == @active_category).label %> Endpoints
            </div>
            <%= for ep <- @endpoints[@active_category] do %>
              <button
                phx-click="select_endpoint"
                phx-value-id={ep.id}
                style={"display: flex; align-items: center; gap: 8px; width: 100%; padding: 10px 16px; border: none; border-bottom: 1px solid #f1f5f9; cursor: pointer; text-align: left; font-size: 13px; #{if @active_endpoint == ep.id, do: "background: #eff6ff; color: #1d4ed8;", else: "background: white; color: #334155;"}"}
              >
                <span style={"padding: 2px 6px; border-radius: 4px; font-size: 10px; font-weight: 700; font-family: monospace; #{method_style(ep.method)}"}>
                  <%= ep.method %>
                </span>
                <span style="font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"><%= ep.title %></span>
              </button>
            <% end %>
          </div>
        </div>

        <!-- Endpoint Detail (right) -->
        <div style="flex: 1; min-width: 0;">
          <%= for ep <- @endpoints[@active_category], ep.id == @active_endpoint do %>
            <div style="background: white; border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden;">
              <!-- Title bar -->
              <div style="padding: 20px 24px; border-bottom: 1px solid #e2e8f0;">
                <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 8px;">
                  <span style={"padding: 4px 10px; border-radius: 6px; font-size: 13px; font-weight: 700; font-family: monospace; #{method_style(ep.method)}"}>
                    <%= ep.method %>
                  </span>
                  <code style="font-size: 15px; color: #1e293b; font-weight: 600;"><%= ep.path %></code>
                </div>
                <p style="margin: 0; color: #64748b; font-size: 14px;"><%= ep.description %></p>
              </div>

              <!-- Parameters -->
              <%= if ep.params != [] do %>
                <div style="padding: 20px 24px; border-bottom: 1px solid #e2e8f0;">
                  <h3 style="margin: 0 0 12px; font-size: 14px; font-weight: 600; color: #334155;">Parameters</h3>
                  <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
                    <thead>
                      <tr style="border-bottom: 1px solid #e2e8f0;">
                        <th style="padding: 8px 12px; text-align: left; font-weight: 600; color: #64748b;">Name</th>
                        <th style="padding: 8px 12px; text-align: left; font-weight: 600; color: #64748b;">Type</th>
                        <th style="padding: 8px 12px; text-align: left; font-weight: 600; color: #64748b;">Default</th>
                        <th style="padding: 8px 12px; text-align: left; font-weight: 600; color: #64748b;">Description</th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for p <- ep.params do %>
                        <tr style="border-bottom: 1px solid #f1f5f9;">
                          <td style="padding: 8px 12px;"><code style="color: #7c3aed; font-weight: 500;"><%= p.name %></code></td>
                          <td style="padding: 8px 12px; color: #64748b;"><%= p.type %></td>
                          <td style="padding: 8px 12px; color: #94a3b8; font-family: monospace; font-size: 12px;"><%= p.default %></td>
                          <td style="padding: 8px 12px; color: #475569;"><%= p.desc %></td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>

              <!-- Request Body -->
              <%= if ep.request_body do %>
                <div style="padding: 20px 24px; border-bottom: 1px solid #e2e8f0;">
                  <h3 style="margin: 0 0 12px; font-size: 14px; font-weight: 600; color: #334155;">Request Body</h3>
                  <pre style="margin: 0; padding: 16px; background: #1e293b; color: #e2e8f0; border-radius: 8px; font-size: 13px; line-height: 1.5; overflow-x: auto; font-family: 'SF Mono', Monaco, monospace;"><%= String.trim(ep.request_body) %></pre>
                </div>
              <% end %>

              <!-- Response -->
              <div style="padding: 20px 24px;">
                <h3 style="margin: 0 0 12px; font-size: 14px; font-weight: 600; color: #334155;">Response Example</h3>
                <pre style="margin: 0; padding: 16px; background: #1e293b; color: #e2e8f0; border-radius: 8px; font-size: 13px; line-height: 1.5; overflow-x: auto; font-family: 'SF Mono', Monaco, monospace;"><%= String.trim(ep.response_example) %></pre>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Auth Info -->
      <div style="margin-top: 24px; padding: 20px; background: #fffbeb; border: 1px solid #fde68a; border-radius: 10px;">
        <h3 style="margin: 0 0 8px; font-size: 14px; font-weight: 600; color: #92400e;">Authentication</h3>
        <p style="margin: 0 0 8px; font-size: 13px; color: #a16207; line-height: 1.6;">
          모든 API 요청에는 API Key가 필요합니다. <a href="/api-keys" style="color: #1d4ed8; text-decoration: underline;">API Keys</a> 페이지에서 키를 생성하세요.
        </p>
        <pre style="margin: 0; padding: 12px; background: #fef3c7; border-radius: 6px; font-size: 13px; color: #78350f; font-family: monospace;">Authorization: Bearer lvg_xxxxxxxxxxxx&#10;Content-Type: application/json</pre>
      </div>

      <!-- Error Codes -->
      <div style="margin-top: 16px; padding: 20px; background: white; border: 1px solid #e2e8f0; border-radius: 10px;">
        <h3 style="margin: 0 0 12px; font-size: 14px; font-weight: 600; color: #334155;">Error Codes</h3>
        <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
          <thead>
            <tr style="border-bottom: 1px solid #e2e8f0;">
              <th style="padding: 8px 12px; text-align: left; font-weight: 600; color: #64748b;">Code</th>
              <th style="padding: 8px 12px; text-align: left; font-weight: 600; color: #64748b;">Description</th>
              <th style="padding: 8px 12px; text-align: left; font-weight: 600; color: #64748b;">Example</th>
            </tr>
          </thead>
          <tbody>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 8px 12px;"><code style="color: #15803d;">200</code></td>
              <td style="padding: 8px 12px; color: #475569;">Success</td>
              <td style="padding: 8px 12px; color: #94a3b8; font-size: 12px;">정상 응답</td>
            </tr>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 8px 12px;"><code style="color: #15803d;">201</code></td>
              <td style="padding: 8px 12px; color: #475569;">Created</td>
              <td style="padding: 8px 12px; color: #94a3b8; font-size: 12px;">POST 생성 성공</td>
            </tr>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 8px 12px;"><code style="color: #dc2626;">400</code></td>
              <td style="padding: 8px 12px; color: #475569;">Bad Request</td>
              <td style="padding: 8px 12px; color: #94a3b8; font-size: 12px;">필수 필드 누락</td>
            </tr>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 8px 12px;"><code style="color: #dc2626;">401</code></td>
              <td style="padding: 8px 12px; color: #475569;">Unauthorized</td>
              <td style="padding: 8px 12px; color: #94a3b8; font-size: 12px;">API Key 없음/유효하지 않음</td>
            </tr>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 8px 12px;"><code style="color: #dc2626;">403</code></td>
              <td style="padding: 8px 12px; color: #475569;">Forbidden</td>
              <td style="padding: 8px 12px; color: #94a3b8; font-size: 12px;">권한 부족 (read_write 필요)</td>
            </tr>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 8px 12px;"><code style="color: #dc2626;">404</code></td>
              <td style="padding: 8px 12px; color: #475569;">Not Found</td>
              <td style="padding: 8px 12px; color: #94a3b8; font-size: 12px;">해당 ID의 행이 없음</td>
            </tr>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 8px 12px;"><code style="color: #dc2626;">422</code></td>
              <td style="padding: 8px 12px; color: #475569;">Unprocessable Entity</td>
              <td style="padding: 8px 12px; color: #94a3b8; font-size: 12px;">Validation 실패</td>
            </tr>
            <tr>
              <td style="padding: 8px 12px;"><code style="color: #dc2626;">500</code></td>
              <td style="padding: 8px 12px; color: #475569;">Internal Server Error</td>
              <td style="padding: 8px 12px; color: #94a3b8; font-size: 12px;">서버 내부 오류</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Filter Operators Reference -->
      <div style="margin-top: 16px; padding: 20px; background: white; border: 1px solid #e2e8f0; border-radius: 10px;">
        <h3 style="margin: 0 0 12px; font-size: 14px; font-weight: 600; color: #334155;">Filter Operators</h3>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
          <div>
            <h4 style="margin: 0 0 8px; font-size: 13px; color: #475569;">Text Operators</h4>
            <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
              <tbody>
                <tr style="border-bottom: 1px solid #f1f5f9;">
                  <td style="padding: 4px 8px;"><code>contains</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">부분 문자열 검색</td>
                </tr>
                <tr style="border-bottom: 1px solid #f1f5f9;">
                  <td style="padding: 4px 8px;"><code>equals</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">정확히 일치</td>
                </tr>
                <tr style="border-bottom: 1px solid #f1f5f9;">
                  <td style="padding: 4px 8px;"><code>starts_with</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">접두사 매치</td>
                </tr>
                <tr style="border-bottom: 1px solid #f1f5f9;">
                  <td style="padding: 4px 8px;"><code>ends_with</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">접미사 매치</td>
                </tr>
                <tr style="border-bottom: 1px solid #f1f5f9;">
                  <td style="padding: 4px 8px;"><code>is_empty</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">비어있음</td>
                </tr>
                <tr>
                  <td style="padding: 4px 8px;"><code>is_not_empty</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">비어있지 않음</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div>
            <h4 style="margin: 0 0 8px; font-size: 13px; color: #475569;">Number Operators</h4>
            <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
              <tbody>
                <tr style="border-bottom: 1px solid #f1f5f9;">
                  <td style="padding: 4px 8px;"><code>eq</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">같음 (=)</td>
                </tr>
                <tr style="border-bottom: 1px solid #f1f5f9;">
                  <td style="padding: 4px 8px;"><code>neq</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">같지 않음 (!=)</td>
                </tr>
                <tr style="border-bottom: 1px solid #f1f5f9;">
                  <td style="padding: 4px 8px;"><code>gt</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">초과 (&gt;)</td>
                </tr>
                <tr style="border-bottom: 1px solid #f1f5f9;">
                  <td style="padding: 4px 8px;"><code>lt</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">미만 (&lt;)</td>
                </tr>
                <tr style="border-bottom: 1px solid #f1f5f9;">
                  <td style="padding: 4px 8px;"><code>gte</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">이상 (&gt;=)</td>
                </tr>
                <tr>
                  <td style="padding: 4px 8px;"><code>lte</code></td>
                  <td style="padding: 4px 8px; color: #64748b;">이하 (&lt;=)</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp method_style("GET"), do: "background: #dbeafe; color: #1d4ed8;"
  defp method_style("POST"), do: "background: #dcfce7; color: #15803d;"
  defp method_style("PUT"), do: "background: #fef3c7; color: #92400e;"
  defp method_style("PATCH"), do: "background: #f3e8ff; color: #7c3aed;"
  defp method_style("DELETE"), do: "background: #fee2e2; color: #dc2626;"
  defp method_style(_), do: "background: #f1f5f9; color: #475569;"
end
