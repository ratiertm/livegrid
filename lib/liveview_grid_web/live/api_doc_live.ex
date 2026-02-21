defmodule LiveviewGridWeb.ApiDocLive do
  @moduledoc """
  API Documentation 페이지 - Mock REST API 명세
  """
  use Phoenix.LiveView

  @endpoints [
    %{
      id: "list_users",
      method: "GET",
      path: "/api/users",
      title: "사용자 목록 조회",
      description: "페이지네이션, 정렬, 필터링을 지원하는 사용자 목록을 반환합니다.",
      params: [
        %{name: "page", type: "integer", default: "1", desc: "페이지 번호"},
        %{name: "page_size", type: "integer", default: "20", desc: "페이지당 항목 수 (최대 500)"},
        %{name: "sort", type: "string", default: "id", desc: "정렬 필드 (id, name, email, department, age, salary, status, join_date)"},
        %{name: "order", type: "string", default: "asc", desc: "정렬 방향 (asc, desc)"},
        %{name: "q", type: "string", default: "-", desc: "글로벌 검색어 (name, email, department, status에서 검색)"},
        %{name: "filters", type: "JSON", default: "-", desc: "필드별 필터 (예: {\"age\":\">30\", \"department\":\"Engineering\"})"}
      ],
      request_body: nil,
      response_example: """
      {
        "data": [
          {
            "id": 1,
            "name": "홍길동",
            "email": "hong@example.com",
            "department": "Engineering",
            "age": 32,
            "salary": 85000,
            "status": "활성",
            "join_date": "2024-03-15"
          }
        ],
        "total": 1000,
        "filtered": 1000,
        "page": 1,
        "page_size": 20,
        "total_pages": 50,
        "query_time_ms": 5
      }
      """
    },
    %{
      id: "get_user",
      method: "GET",
      path: "/api/users/:id",
      title: "사용자 단건 조회",
      description: "ID로 특정 사용자를 조회합니다.",
      params: [
        %{name: "id", type: "integer", default: "-", desc: "사용자 ID (path parameter)"}
      ],
      request_body: nil,
      response_example: """
      {
        "data": {
          "id": 1,
          "name": "홍길동",
          "email": "hong@example.com",
          "department": "Engineering",
          "age": 32,
          "salary": 85000,
          "status": "활성",
          "join_date": "2024-03-15"
        }
      }
      """
    },
    %{
      id: "create_user",
      method: "POST",
      path: "/api/users",
      title: "사용자 생성",
      description: "새로운 사용자를 생성합니다.",
      params: [],
      request_body: """
      {
        "name": "김철수",
        "email": "kim@example.com",
        "department": "Marketing",
        "age": 28,
        "salary": 65000,
        "status": "활성",
        "join_date": "2026-01-15"
      }
      """,
      response_example: """
      {
        "data": {
          "id": 1001,
          "name": "김철수",
          "email": "kim@example.com",
          "department": "Marketing",
          "age": 28,
          "salary": 65000,
          "status": "활성",
          "join_date": "2026-01-15"
        }
      }
      """
    },
    %{
      id: "update_user",
      method: "PUT",
      path: "/api/users/:id",
      title: "사용자 수정",
      description: "기존 사용자의 정보를 수정합니다. 변경할 필드만 전송합니다.",
      params: [
        %{name: "id", type: "integer", default: "-", desc: "사용자 ID (path parameter)"}
      ],
      request_body: """
      {
        "name": "김철수(수정)",
        "salary": 70000
      }
      """,
      response_example: """
      {
        "data": {
          "id": 1001,
          "name": "김철수(수정)",
          "email": "kim@example.com",
          "department": "Marketing",
          "age": 28,
          "salary": 70000,
          "status": "활성",
          "join_date": "2026-01-15"
        }
      }
      """
    },
    %{
      id: "delete_user",
      method: "DELETE",
      path: "/api/users/:id",
      title: "사용자 삭제",
      description: "사용자를 삭제합니다.",
      params: [
        %{name: "id", type: "integer", default: "-", desc: "사용자 ID (path parameter)"}
      ],
      request_body: nil,
      response_example: """
      {
        "message": "User deleted successfully"
      }
      """
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, active_endpoint: "list_users", endpoints: @endpoints)}
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
      <div style="margin-bottom: 24px;">
        <h1 style="margin: 0; font-size: 24px; font-weight: 700; color: #1a1a1a;">API Documentation</h1>
        <p style="margin: 4px 0 0; color: #666; font-size: 14px;">
          LiveView Grid Mock REST API 명세서 &mdash; Base URL: <code style="background: #f1f5f9; padding: 2px 6px; border-radius: 3px; font-size: 13px;">http://localhost:5001</code>
        </p>
      </div>

      <div style="display: flex; gap: 20px;">
        <!-- Endpoint List (left) -->
        <div style="width: 280px; flex-shrink: 0;">
          <div style="background: white; border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden; position: sticky; top: 24px;">
            <div style="padding: 12px 16px; border-bottom: 1px solid #e2e8f0; font-weight: 600; font-size: 13px; color: #475569; background: #f8fafc;">
              Endpoints
            </div>
            <%= for ep <- @endpoints do %>
              <button
                phx-click="select_endpoint"
                phx-value-id={ep.id}
                style={"display: flex; align-items: center; gap: 8px; width: 100%; padding: 10px 16px; border: none; border-bottom: 1px solid #f1f5f9; cursor: pointer; text-align: left; font-size: 13px; #{if @active_endpoint == ep.id, do: "background: #eff6ff; color: #1d4ed8;", else: "background: white; color: #334155;"}"}
              >
                <span style={"padding: 2px 6px; border-radius: 4px; font-size: 10px; font-weight: 700; font-family: monospace; #{method_style(ep.method)}"}>
                  <%= ep.method %>
                </span>
                <span style="font-weight: 500;"><%= ep.title %></span>
              </button>
            <% end %>
          </div>
        </div>

        <!-- Endpoint Detail (right) -->
        <div style="flex: 1; min-width: 0;">
          <%= for ep <- @endpoints, ep.id == @active_endpoint do %>
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
                          <td style="padding: 8px 12px;">
                            <code style="color: #7c3aed; font-weight: 500;"><%= p.name %></code>
                          </td>
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
          API 요청 시 다음 헤더를 포함해야 합니다:
        </p>
        <pre style="margin: 0; padding: 12px; background: #fef3c7; border-radius: 6px; font-size: 13px; color: #78350f; font-family: monospace;">Authorization: Bearer YOUR_API_KEY&#10;Content-Type: application/json</pre>
      </div>

      <!-- Error Codes -->
      <div style="margin-top: 16px; padding: 20px; background: white; border: 1px solid #e2e8f0; border-radius: 10px;">
        <h3 style="margin: 0 0 12px; font-size: 14px; font-weight: 600; color: #334155;">Error Codes</h3>
        <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
          <thead>
            <tr style="border-bottom: 1px solid #e2e8f0;">
              <th style="padding: 8px 12px; text-align: left; font-weight: 600; color: #64748b;">Code</th>
              <th style="padding: 8px 12px; text-align: left; font-weight: 600; color: #64748b;">Description</th>
            </tr>
          </thead>
          <tbody>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 8px 12px;"><code style="color: #15803d;">200</code></td>
              <td style="padding: 8px 12px; color: #475569;">성공</td>
            </tr>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 8px 12px;"><code style="color: #15803d;">201</code></td>
              <td style="padding: 8px 12px; color: #475569;">생성 성공 (POST)</td>
            </tr>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 8px 12px;"><code style="color: #dc2626;">404</code></td>
              <td style="padding: 8px 12px; color: #475569;">리소스를 찾을 수 없음</td>
            </tr>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 8px 12px;"><code style="color: #dc2626;">422</code></td>
              <td style="padding: 8px 12px; color: #475569;">유효성 검사 실패</td>
            </tr>
            <tr>
              <td style="padding: 8px 12px;"><code style="color: #dc2626;">500</code></td>
              <td style="padding: 8px 12px; color: #475569;">서버 내부 오류</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp method_style("GET"), do: "background: #dbeafe; color: #1d4ed8;"
  defp method_style("POST"), do: "background: #dcfce7; color: #15803d;"
  defp method_style("PUT"), do: "background: #fef3c7; color: #92400e;"
  defp method_style("DELETE"), do: "background: #fee2e2; color: #dc2626;"
  defp method_style(_), do: "background: #f1f5f9; color: #475569;"
end
