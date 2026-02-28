defmodule LiveViewGridWeb.Components.GridBuilder.BuilderDataSource do
  @moduledoc """
  Grid Builder 데이터 소스 선택 UI 컴포넌트.

  Tab 1(기본 설정)에 포함되어 Sample Data / Schema / Table 중 선택할 수 있게 한다.
  """
  use Phoenix.Component

  @doc """
  데이터 소스 선택 섹션.

  ## Assigns

  - `data_source_type` - "sample" | "schema" | "table"
  - `available_schemas` - 등록된 Ecto 스키마 목록
  - `available_tables` - DB 테이블 목록
  - `selected_schema` - 선택된 스키마 모듈 (atom 문자열)
  - `selected_table` - 선택된 테이블명
  - `table_columns_info` - 선택된 테이블의 컬럼 정보
  - `myself` - LiveComponent target
  """
  attr :data_source_type, :string, required: true
  attr :available_schemas, :list, default: []
  attr :available_tables, :list, default: []
  attr :selected_schema, :string, default: nil
  attr :selected_table, :string, default: nil
  attr :table_columns_info, :list, default: []
  attr :myself, :any, required: true

  def data_source_section(assigns) do
    ~H"""
    <div class="mt-6">
      <h4 class="text-sm font-semibold text-gray-700 mb-3 pb-2 border-b">데이터 소스</h4>

      <%!-- Radio 버튼 --%>
      <div class="flex gap-4 mb-4">
        <label class="flex items-center gap-2 cursor-pointer">
          <input
            type="radio"
            name="data_source_type"
            value="sample"
            checked={@data_source_type == "sample"}
            phx-click="select_data_source_type"
            phx-value-type="sample"
            phx-target={@myself}
            class="w-4 h-4 text-blue-600"
          />
          <span class="text-sm text-gray-700">Sample Data</span>
        </label>

        <label class="flex items-center gap-2 cursor-pointer">
          <input
            type="radio"
            name="data_source_type"
            value="schema"
            checked={@data_source_type == "schema"}
            phx-click="select_data_source_type"
            phx-value-type="schema"
            phx-target={@myself}
            class="w-4 h-4 text-blue-600"
          />
          <span class="text-sm text-gray-700">Database (Schema)</span>
        </label>

        <label class="flex items-center gap-2 cursor-pointer">
          <input
            type="radio"
            name="data_source_type"
            value="table"
            checked={@data_source_type == "table"}
            phx-click="select_data_source_type"
            phx-value-type="table"
            phx-target={@myself}
            class="w-4 h-4 text-blue-600"
          />
          <span class="text-sm text-gray-700">Database (Table)</span>
        </label>
      </div>

      <%!-- Schema 모드 --%>
      <%= if @data_source_type == "schema" do %>
        <div class="p-4 bg-blue-50 border border-blue-200 rounded-lg space-y-3">
          <div class="flex items-center gap-3">
            <form phx-change="select_schema" phx-target={@myself} class="flex-1">
              <select name="schema" class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm">
                <option value="">스키마를 선택하세요</option>
                <%= for schema <- @available_schemas do %>
                  <option
                    value={to_string(schema.module)}
                    selected={@selected_schema == to_string(schema.module)}
                  >
                    <%= schema.label %> (<%= schema.table %>)
                  </option>
                <% end %>
              </select>
            </form>

            <button
              phx-click="load_schema_columns"
              phx-target={@myself}
              disabled={is_nil(@selected_schema) or @selected_schema == ""}
              class={[
                "px-4 py-2 text-sm rounded-md font-medium whitespace-nowrap",
                if is_nil(@selected_schema) or @selected_schema == "" do
                  "bg-gray-300 text-gray-500 cursor-not-allowed"
                else
                  "bg-blue-600 text-white hover:bg-blue-700"
                end
              ]}
            >
              컬럼 자동 불러오기
            </button>
          </div>

          <%= if @selected_schema && @selected_schema != "" do %>
            <p class="text-xs text-blue-700">
              선택한 스키마의 필드를 기반으로 컬럼이 자동 생성됩니다.
              기존 컬럼 정의는 대체됩니다.
            </p>
          <% end %>
        </div>
      <% end %>

      <%!-- Table 모드 --%>
      <%= if @data_source_type == "table" do %>
        <div class="p-4 bg-green-50 border border-green-200 rounded-lg space-y-3">
          <div class="flex items-center gap-3">
            <form phx-change="select_table" phx-target={@myself} class="flex-1">
              <select name="table" class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm">
                <option value="">테이블을 선택하세요</option>
                <%= for table <- @available_tables do %>
                  <option value={table} selected={@selected_table == table}>
                    <%= table %>
                  </option>
                <% end %>
              </select>
            </form>

            <button
              phx-click="load_table_columns"
              phx-target={@myself}
              disabled={is_nil(@selected_table) or @selected_table == ""}
              class={[
                "px-4 py-2 text-sm rounded-md font-medium whitespace-nowrap",
                if is_nil(@selected_table) or @selected_table == "" do
                  "bg-gray-300 text-gray-500 cursor-not-allowed"
                else
                  "bg-green-600 text-white hover:bg-green-700"
                end
              ]}
            >
              컬럼 자동 불러오기
            </button>
          </div>

          <%!-- Table columns preview --%>
          <%= if @table_columns_info != [] do %>
            <div class="mt-2">
              <p class="text-xs text-green-700 mb-2">테이블 컬럼 (<%= length(@table_columns_info) %>개):</p>
              <div class="flex flex-wrap gap-1.5">
                <%= for col <- @table_columns_info do %>
                  <span class={[
                    "inline-flex items-center gap-1 px-2 py-0.5 text-xs rounded-full",
                    if col.pk do
                      "bg-yellow-100 text-yellow-800 border border-yellow-300"
                    else
                      "bg-gray-100 text-gray-600 border border-gray-200"
                    end
                  ]}>
                    <%= if col.pk do %><span class="text-yellow-600">🔑</span><% end %>
                    <%= col.name %>
                    <span class="text-gray-400">(<%= col.sqlite_type %>)</span>
                  </span>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
