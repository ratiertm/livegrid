defmodule LiveViewGridWeb.Components.GridBuilder.BuilderModal do
  @moduledoc """
  Grid Builder Modal Component

  코드 작성 없이 UI로 GridDefinition을 정의하고, 즉시 그리드를 생성하는 모달.

  ## 기능
  - Tab 1: Grid Info (이름, ID, 기본 옵션)
  - Tab 2: Column Builder (컬럼 추가/삭제/편집 + Formatter/Validator/Renderer)
  - Tab 3: Preview (샘플 데이터 미리보기 + 생성)
  """
  use Phoenix.LiveComponent

  alias LiveViewGrid.SampleData
  alias LiveViewGrid.SchemaRegistry
  alias LiveViewGrid.TableInspector
  alias LiveViewGridWeb.Components.GridBuilder.BuilderHelpers

  import LiveViewGridWeb.Components.GridBuilder.BuilderDataSource

  # ── Formatter/Validator/Renderer 선택 목록 ──

  @formatter_options [
    {"(없음)", ""},
    {"숫자 (1,000)", "number"},
    {"통화 - 원화 (₩1,000)", "currency"},
    {"통화 - 달러 ($1,000.00)", "dollar"},
    {"백분율 (85.6%)", "percent"},
    {"날짜 (2026-02-28)", "date"},
    {"날짜+시간", "datetime"},
    {"시간", "time"},
    {"상대시간 (3일 전)", "relative_time"},
    {"불리언 (예/아니오)", "boolean"},
    {"파일크기 (1.2 MB)", "filesize"},
    {"말줄임 (...)", "truncate"},
    {"대문자", "uppercase"},
    {"소문자", "lowercase"},
    {"마스킹 (***)", "mask"}
  ]

  @validator_types [
    {"필수 입력", "required"},
    {"최솟값", "min"},
    {"최댓값", "max"},
    {"최소 길이", "min_length"},
    {"최대 길이", "max_length"},
    {"패턴 (정규식)", "pattern"}
  ]

  @renderer_options [
    {"(없음)", ""},
    {"Badge (색상 라벨)", "badge"},
    {"Link (클릭 링크)", "link"},
    {"Progress Bar (진행률)", "progress"}
  ]

  @type_options [
    {"문자열", "string"},
    {"정수", "integer"},
    {"실수", "float"},
    {"불리언", "boolean"},
    {"날짜", "date"},
    {"날짜+시간", "datetime"}
  ]

  @align_options [
    {"왼쪽", "left"},
    {"가운데", "center"},
    {"오른쪽", "right"}
  ]

  @editor_type_options [
    {"텍스트", "text"},
    {"숫자", "number"},
    {"선택", "select"},
    {"체크박스", "checkbox"},
    {"날짜", "date"}
  ]

  # ══════════════════════════════════════════════════════
  # Render
  # ══════════════════════════════════════════════════════

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:formatter_options, @formatter_options)
      |> assign(:validator_types, @validator_types)
      |> assign(:renderer_options, @renderer_options)
      |> assign(:type_options, @type_options)
      |> assign(:align_options, @align_options)
      |> assign(:editor_type_options, @editor_type_options)

    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div class="bg-white rounded-lg shadow-xl w-full max-w-5xl max-h-[90vh] flex flex-col">
        <%!-- Modal Header --%>
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h2 class="text-xl font-semibold text-gray-800">Grid Builder - 새 그리드 만들기</h2>
          <button phx-click="close_builder" phx-target={@myself} class="text-gray-400 hover:text-gray-600">
            <span class="text-2xl">&times;</span>
          </button>
        </div>

        <%!-- Tabs Navigation --%>
        <div class="flex border-b border-gray-200 bg-gray-50 px-6">
          <%= for {tab_id, tab_label, tab_icon} <- [
            {"info", "기본 설정", "⚙️"},
            {"columns", "컬럼 정의", "📋"},
            {"preview", "미리보기", "👁️"}
          ] do %>
            <button
              phx-click="select_builder_tab"
              phx-value-tab={tab_id}
              phx-target={@myself}
              class={[
                "px-4 py-3 font-medium border-b-2 transition-colors flex items-center gap-1.5",
                if @active_tab == tab_id do
                  "border-blue-500 text-blue-600"
                else
                  "border-transparent text-gray-600 hover:text-gray-800"
                end
              ]}
            >
              <span><%= tab_icon %></span>
              <span><%= tab_label %></span>
            </button>
          <% end %>
        </div>

        <%!-- Tab Content --%>
        <div class="flex-1 overflow-y-auto px-6 py-4">
          <%= case @active_tab do %>
            <% "info" -> %>
              <.grid_info_tab
                myself={@myself}
                grid_name={@grid_name}
                grid_id={@grid_id}
                grid_options={@grid_options}
                data_source_type={@data_source_type}
                available_schemas={@available_schemas}
                available_tables={@available_tables}
                selected_schema={@selected_schema}
                selected_table={@selected_table}
                table_columns_info={@table_columns_info}
              />
            <% "columns" -> %>
              <.column_builder_tab
                myself={@myself}
                columns={@columns}
                selected_column_id={@selected_column_id}
                formatter_options={@formatter_options}
                validator_types={@validator_types}
                renderer_options={@renderer_options}
                type_options={@type_options}
                align_options={@align_options}
                editor_type_options={@editor_type_options}
              />
            <% "preview" -> %>
              <.preview_tab
                myself={@myself}
                columns={@columns}
                grid_name={@grid_name}
                grid_id={@grid_id}
                grid_options={@grid_options}
                preview_data={@preview_data}
                errors={@errors}
                show_code={@show_code}
              />
          <% end %>
        </div>

        <%!-- Footer --%>
        <div class="flex items-center justify-between px-6 py-4 border-t border-gray-200 bg-gray-50">
          <div class="text-sm text-gray-500">
            컬럼 <%= length(@columns) %>개 정의됨
          </div>
          <div class="flex gap-3">
            <button
              phx-click="close_builder"
              phx-target={@myself}
              class="px-4 py-2 text-gray-600 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
            >
              취소
            </button>
            <button
              phx-click="create_grid"
              phx-target={@myself}
              class="px-6 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700 font-medium"
            >
              그리드 생성
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ══════════════════════════════════════════════════════
  # Tab 1: Grid Info
  # ══════════════════════════════════════════════════════

  defp grid_info_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h3 class="text-lg font-semibold text-gray-800 mb-4">Grid 기본 설정</h3>

        <div class="grid grid-cols-2 gap-4">
          <%!-- 그리드 이름 --%>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              그리드 이름 <span class="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={@grid_name}
              phx-blur="update_grid_name"
              phx-keyup="update_grid_name"
              phx-target={@myself}
              placeholder="예: 사용자 목록"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          <%!-- 그리드 ID --%>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              그리드 ID
              <span class="text-xs text-gray-400 ml-1">(자동 생성)</span>
            </label>
            <input
              type="text"
              value={@grid_id}
              phx-blur="update_grid_id"
              phx-target={@myself}
              placeholder="자동 생성됨"
              class="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50 text-gray-600"
            />
          </div>
        </div>
      </div>

      <%!-- 표시 옵션 --%>
      <div>
        <h4 class="text-sm font-semibold text-gray-700 mb-3 pb-2 border-b">표시 옵션</h4>

        <div class="grid grid-cols-3 gap-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1">페이지 크기</label>
            <form phx-change="update_builder_option" phx-target={@myself}>
              <input type="hidden" name="key" value="page_size" />
              <select name="value" class="w-full px-3 py-2 border border-gray-300 rounded-md">
                <%= for size <- [10, 20, 50, 100] do %>
                  <option value={size} selected={@grid_options.page_size == size}><%= size %>행</option>
                <% end %>
              </select>
            </form>
          </div>

          <div>
            <label class="block text-sm text-gray-600 mb-1">테마</label>
            <form phx-change="update_builder_option" phx-target={@myself}>
              <input type="hidden" name="key" value="theme" />
              <select name="value" class="w-full px-3 py-2 border border-gray-300 rounded-md">
                <option value="light" selected={@grid_options.theme == "light"}>Light</option>
                <option value="dark" selected={@grid_options.theme == "dark"}>Dark</option>
              </select>
            </form>
          </div>

          <div>
            <label class="block text-sm text-gray-600 mb-1">행 높이 (px)</label>
            <input
              type="number"
              value={@grid_options.row_height}
              phx-blur="update_builder_option"
              phx-target={@myself}
              phx-value-key="row_height"
              min="24"
              max="80"
              class="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>

          <div>
            <label class="block text-sm text-gray-600 mb-1">고정 컬럼 수</label>
            <input
              type="number"
              value={@grid_options.frozen_columns}
              phx-blur="update_builder_option"
              phx-target={@myself}
              phx-value-key="frozen_columns"
              min="0"
              max="5"
              class="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>
        </div>

        <div class="flex gap-6 mt-4">
          <label class="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={@grid_options.show_row_number}
              phx-click="toggle_builder_option"
              phx-value-key="show_row_number"
              phx-target={@myself}
              class="w-4 h-4 text-blue-600 rounded"
            />
            <span class="text-sm text-gray-600">행번호 표시</span>
          </label>

          <label class="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={@grid_options.virtual_scroll}
              phx-click="toggle_builder_option"
              phx-value-key="virtual_scroll"
              phx-target={@myself}
              class="w-4 h-4 text-blue-600 rounded"
            />
            <span class="text-sm text-gray-600">Virtual Scroll</span>
          </label>
        </div>
      </div>

      <%!-- 데이터 소스 선택 --%>
      <.data_source_section
        data_source_type={@data_source_type}
        available_schemas={@available_schemas}
        available_tables={@available_tables}
        selected_schema={@selected_schema}
        selected_table={@selected_table}
        table_columns_info={@table_columns_info}
        myself={@myself}
      />
    </div>
    """
  end

  # ══════════════════════════════════════════════════════
  # Tab 2: Column Builder
  # ══════════════════════════════════════════════════════

  defp column_builder_tab(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <h3 class="text-lg font-semibold text-gray-800">컬럼 정의</h3>
        <button
          phx-click="add_column"
          phx-target={@myself}
          class="px-3 py-1.5 text-sm text-white bg-blue-600 rounded-md hover:bg-blue-700 flex items-center gap-1"
        >
          <span>+</span> 컬럼 추가
        </button>
      </div>

      <%!-- 컬럼 목록 --%>
      <div
        id="builder-sortable-list"
        phx-hook="ConfigSortable"
        phx-target={@myself}
        class="space-y-2"
      >
        <%= if @columns == [] do %>
          <div class="text-center py-8 text-gray-400 border-2 border-dashed border-gray-200 rounded-lg">
            <p class="text-lg mb-2">컬럼이 없습니다</p>
            <p class="text-sm">위의 [+ 컬럼 추가] 버튼으로 시작하세요</p>
          </div>
        <% else %>
          <%= for col <- @columns do %>
            <div
              data-sortable-item
              data-field={col.temp_id}
              class={[
                "border rounded-lg transition-all",
                if @selected_column_id == col.temp_id do
                  "border-blue-400 bg-blue-50 shadow-sm"
                else
                  "border-gray-200 bg-white hover:border-gray-300"
                end
              ]}
            >
              <%!-- 컬럼 요약 행 --%>
              <div class="flex items-center gap-2 p-3">
                <span class="text-gray-400 cursor-grab active:cursor-grabbing select-none">::</span>

                <%!-- Field Name --%>
                <input
                  type="text"
                  value={col.field}
                  phx-blur="update_column_field"
                  phx-target={@myself}
                  phx-value-id={col.temp_id}
                  placeholder="field_name"
                  class="w-28 px-2 py-1 text-sm border border-gray-300 rounded font-mono"
                />

                <%!-- Label --%>
                <input
                  type="text"
                  value={col.label}
                  phx-blur="update_column_label"
                  phx-target={@myself}
                  phx-value-id={col.temp_id}
                  placeholder="표시명"
                  class="w-24 px-2 py-1 text-sm border border-gray-300 rounded"
                />

                <%!-- Type --%>
                <form phx-change="update_column_type" phx-target={@myself}>
                  <input type="hidden" name="col_id" value={col.temp_id} />
                  <select
                    name="value"
                    class="w-24 px-2 py-1 text-sm border border-gray-300 rounded"
                  >
                    <%= for {label, val} <- @type_options do %>
                      <option value={val} selected={to_string(col.type) == val}><%= label %></option>
                    <% end %>
                  </select>
                </form>

                <%!-- Width --%>
                <input
                  type="number"
                  value={if col.width == :auto, do: "", else: col.width}
                  phx-blur="update_column_width"
                  phx-target={@myself}
                  phx-value-id={col.temp_id}
                  placeholder="auto"
                  min="40"
                  max="600"
                  class="w-16 px-2 py-1 text-sm border border-gray-300 rounded"
                />

                <%!-- Quick toggles --%>
                <label class="flex items-center gap-1 text-xs text-gray-500" title="Sortable">
                  <input
                    type="checkbox"
                    checked={col.sortable}
                    phx-click="toggle_column_attr"
                    phx-value-id={col.temp_id}
                    phx-value-key="sortable"
                    phx-target={@myself}
                    class="w-3.5 h-3.5"
                  />
                  Sort
                </label>

                <label class="flex items-center gap-1 text-xs text-gray-500" title="Editable">
                  <input
                    type="checkbox"
                    checked={col.editable}
                    phx-click="toggle_column_attr"
                    phx-value-id={col.temp_id}
                    phx-value-key="editable"
                    phx-target={@myself}
                    class="w-3.5 h-3.5"
                  />
                  Edit
                </label>

                <%!-- Expand/Collapse --%>
                <button
                  phx-click="select_builder_column"
                  phx-value-id={col.temp_id}
                  phx-target={@myself}
                  class="ml-auto px-2 py-1 text-xs text-gray-500 hover:text-blue-600 rounded"
                  title="상세 설정"
                >
                  <%= if @selected_column_id == col.temp_id, do: "▲", else: "▼" %>
                </button>

                <%!-- Delete --%>
                <button
                  phx-click="remove_column"
                  phx-value-id={col.temp_id}
                  phx-target={@myself}
                  class="px-2 py-1 text-xs text-red-400 hover:text-red-600 rounded"
                  title="삭제"
                >
                  &times;
                </button>
              </div>

              <%!-- 상세 설정 패널 (확장) --%>
              <%= if @selected_column_id == col.temp_id do %>
                <.column_detail_panel
                  col={col}
                  myself={@myself}
                  formatter_options={@formatter_options}
                  validator_types={@validator_types}
                  renderer_options={@renderer_options}
                  align_options={@align_options}
                  editor_type_options={@editor_type_options}
                />
              <% end %>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  # ── 컬럼 상세 설정 패널 ──

  defp column_detail_panel(assigns) do
    ~H"""
    <div class="px-4 pb-4 border-t border-gray-100 bg-gray-50 space-y-4">
      <%!-- 속성 --%>
      <div class="pt-3">
        <h5 class="text-xs font-semibold text-gray-500 uppercase mb-2">속성</h5>
        <div class="flex flex-wrap gap-4">
          <label class="flex items-center gap-1.5 text-sm">
            <input type="checkbox" checked={@col.filterable}
              phx-click="toggle_column_attr" phx-value-id={@col.temp_id} phx-value-key="filterable"
              phx-target={@myself} class="w-4 h-4" />
            Filterable
          </label>

          <div class="flex items-center gap-2">
            <label class="text-sm text-gray-600">Align:</label>
            <form phx-change="update_column_align" phx-target={@myself}>
              <input type="hidden" name="col_id" value={@col.temp_id} />
              <select name="value" class="px-2 py-1 text-sm border border-gray-300 rounded">
                <%= for {label, val} <- @align_options do %>
                  <option value={val} selected={to_string(@col.align) == val}><%= label %></option>
                <% end %>
              </select>
            </form>
          </div>

          <div class="flex items-center gap-2">
            <label class="text-sm text-gray-600">Editor:</label>
            <form phx-change="update_column_editor" phx-target={@myself}>
              <input type="hidden" name="col_id" value={@col.temp_id} />
              <select name="value" class="px-2 py-1 text-sm border border-gray-300 rounded">
                <%= for {label, val} <- @editor_type_options do %>
                  <option value={val} selected={to_string(@col.editor_type) == val}><%= label %></option>
                <% end %>
              </select>
            </form>
          </div>
        </div>
      </div>

      <%!-- Formatter --%>
      <div>
        <h5 class="text-xs font-semibold text-gray-500 uppercase mb-2">Formatter</h5>
        <form phx-change="set_column_formatter" phx-target={@myself}>
          <input type="hidden" name="col_id" value={@col.temp_id} />
          <select name="value" class="w-64 px-2 py-1.5 text-sm border border-gray-300 rounded">
            <%= for {label, val} <- @formatter_options do %>
              <option value={val} selected={to_string(@col.formatter || "") == val}><%= label %></option>
            <% end %>
          </select>
        </form>
      </div>

      <%!-- Validators --%>
      <div>
        <div class="flex items-center justify-between mb-2">
          <h5 class="text-xs font-semibold text-gray-500 uppercase">Validators</h5>
          <button
            phx-click="add_column_validator"
            phx-value-id={@col.temp_id}
            phx-target={@myself}
            class="px-2 py-0.5 text-xs text-blue-600 border border-blue-300 rounded hover:bg-blue-50"
          >
            + 추가
          </button>
        </div>

        <%= if @col.validators == [] do %>
          <p class="text-xs text-gray-400">검증 규칙 없음</p>
        <% else %>
          <div class="space-y-2">
            <%= for {v, idx} <- Enum.with_index(@col.validators) do %>
              <div class="flex items-center gap-2 text-sm">
                <form phx-change="update_column_validator" phx-target={@myself}>
                  <input type="hidden" name="col_id" value={@col.temp_id} />
                  <input type="hidden" name="index" value={idx} />
                  <input type="hidden" name="field" value="type" />
                  <select name="type" class="w-28 px-2 py-1 border border-gray-300 rounded text-sm">
                    <%= for {label, val} <- @validator_types do %>
                      <option value={val} selected={v.type == val}><%= label %></option>
                    <% end %>
                  </select>
                </form>

                <%= if v.type in ["min", "max", "min_length", "max_length"] do %>
                  <input
                    type="number"
                    value={Map.get(v, :value, "")}
                    phx-blur="update_validator_value"
                    phx-target={@myself}
                    phx-value-id={@col.temp_id}
                    phx-value-index={idx}
                    placeholder="값"
                    class="w-16 px-2 py-1 border border-gray-300 rounded text-sm"
                  />
                <% end %>

                <%= if v.type == "pattern" do %>
                  <input
                    type="text"
                    value={Map.get(v, :value, "")}
                    phx-blur="update_validator_value"
                    phx-target={@myself}
                    phx-value-id={@col.temp_id}
                    phx-value-index={idx}
                    placeholder="정규식"
                    class="w-28 px-2 py-1 border border-gray-300 rounded text-sm font-mono"
                  />
                <% end %>

                <input
                  type="text"
                  value={v.message}
                  phx-blur="update_validator_message"
                  phx-target={@myself}
                  phx-value-id={@col.temp_id}
                  phx-value-index={idx}
                  placeholder="에러 메시지"
                  class="flex-1 px-2 py-1 border border-gray-300 rounded text-sm"
                />

                <button
                  phx-click="remove_column_validator"
                  phx-value-id={@col.temp_id}
                  phx-value-index={idx}
                  phx-target={@myself}
                  class="text-red-400 hover:text-red-600"
                >&times;</button>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- Renderer --%>
      <div>
        <h5 class="text-xs font-semibold text-gray-500 uppercase mb-2">Renderer</h5>
        <form phx-change="set_column_renderer" phx-target={@myself}>
          <input type="hidden" name="col_id" value={@col.temp_id} />
          <select name="value" class="w-64 px-2 py-1.5 text-sm border border-gray-300 rounded">
            <%= for {label, val} <- @renderer_options do %>
              <option value={val} selected={to_string(@col.renderer || "") == val}><%= label %></option>
            <% end %>
          </select>
        </form>

        <%!-- Renderer별 옵션 (badge: colors, link: prefix, progress: max/color) --%>
        <%= if @col.renderer == "badge" do %>
          <div class="mt-2 p-2 bg-white border border-gray-200 rounded text-sm">
            <p class="text-xs text-gray-500 mb-1">값:색상 매핑 (콤마 구분). 색상: blue, green, red, yellow, gray, purple</p>
            <input
              type="text"
              value={Map.get(@col.renderer_options, :colors_text, "")}
              phx-blur="update_renderer_option"
              phx-target={@myself}
              phx-value-id={@col.temp_id}
              phx-value-key="colors_text"
              placeholder="서울:blue, 부산:green, 대구:red"
              class="w-full px-2 py-1 border border-gray-300 rounded text-sm"
            />
          </div>
        <% end %>

        <%= if @col.renderer == "link" do %>
          <div class="mt-2 flex gap-2">
            <div>
              <label class="text-xs text-gray-500">Prefix</label>
              <input
                type="text"
                value={Map.get(@col.renderer_options, :prefix, "")}
                phx-blur="update_renderer_option"
                phx-target={@myself}
                phx-value-id={@col.temp_id}
                phx-value-key="prefix"
                placeholder="mailto: / tel:"
                class="w-36 px-2 py-1 border border-gray-300 rounded text-sm"
              />
            </div>
            <div>
              <label class="text-xs text-gray-500">Target</label>
              <form phx-change="update_renderer_option" phx-target={@myself}>
                <input type="hidden" name="col_id" value={@col.temp_id} />
                <input type="hidden" name="key" value="target" />
                <select name="value" class="px-2 py-1 border border-gray-300 rounded text-sm">
                  <option value="">없음</option>
                  <option value="_blank" selected={Map.get(@col.renderer_options, :target) == "_blank"}>_blank</option>
                  <option value="_self" selected={Map.get(@col.renderer_options, :target) == "_self"}>_self</option>
                </select>
              </form>
            </div>
          </div>
        <% end %>

        <%= if @col.renderer == "progress" do %>
          <div class="mt-2 flex gap-2">
            <div>
              <label class="text-xs text-gray-500">Max</label>
              <input
                type="number"
                value={Map.get(@col.renderer_options, :max, 100)}
                phx-blur="update_renderer_option"
                phx-target={@myself}
                phx-value-id={@col.temp_id}
                phx-value-key="max"
                class="w-20 px-2 py-1 border border-gray-300 rounded text-sm"
              />
            </div>
            <div>
              <label class="text-xs text-gray-500">Color</label>
              <form phx-change="update_renderer_option" phx-target={@myself}>
                <input type="hidden" name="col_id" value={@col.temp_id} />
                <input type="hidden" name="key" value="color" />
                <select name="value" class="px-2 py-1 border border-gray-300 rounded text-sm">
                  <%= for c <- ["blue", "green", "red", "yellow"] do %>
                    <option value={c} selected={Map.get(@col.renderer_options, :color) == c}><%= c %></option>
                  <% end %>
                </select>
              </form>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # ══════════════════════════════════════════════════════
  # Tab 3: Preview
  # ══════════════════════════════════════════════════════

  defp preview_tab(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <h3 class="text-lg font-semibold text-gray-800">미리보기</h3>
        <button
          phx-click="refresh_preview"
          phx-target={@myself}
          class="px-3 py-1.5 text-sm text-blue-600 border border-blue-300 rounded-md hover:bg-blue-50"
        >
          🔄 새로고침
        </button>
      </div>

      <%!-- 검증 상태 --%>
      <div class={["p-3 rounded-lg border", if(@errors == %{}, do: "border-green-200 bg-green-50", else: "border-red-200 bg-red-50")]}>
        <h4 class="text-sm font-medium mb-2">
          <%= if @errors == %{}, do: "✅ 검증 통과", else: "❌ 검증 오류" %>
        </h4>
        <ul class="text-sm space-y-1">
          <li class={if @grid_name != "", do: "text-green-700", else: "text-red-600"}>
            <%= if @grid_name != "", do: "✅", else: "❌" %> 그리드 이름: "<%= @grid_name %>"
          </li>
          <li class={if length(@columns) > 0, do: "text-green-700", else: "text-red-600"}>
            <%= if length(@columns) > 0, do: "✅", else: "❌" %> 컬럼 수: <%= length(@columns) %>개
          </li>
          <% empty_fields = Enum.filter(@columns, &(&1.field == "")) %>
          <li class={if empty_fields == [], do: "text-green-700", else: "text-red-600"}>
            <%= if empty_fields == [], do: "✅", else: "❌" %> 필드명 유효성
            <%= if empty_fields != [] do %>
              <span class="text-xs">(<%= length(empty_fields) %>개 빈 필드)</span>
            <% end %>
          </li>
          <% fields = Enum.map(@columns, & &1.field) |> Enum.filter(& &1 != "") %>
          <% has_dup = length(fields) != length(Enum.uniq(fields)) %>
          <li class={if !has_dup, do: "text-green-700", else: "text-red-600"}>
            <%= if !has_dup, do: "✅", else: "❌" %> 중복 필드 없음
          </li>
        </ul>
        <%= for {key, msg} <- @errors do %>
          <p class="text-red-600 text-sm mt-1">⚠ <%= key %>: <%= msg %></p>
        <% end %>
      </div>

      <%!-- 샘플 데이터 테이블 --%>
      <%= if @preview_data != [] and length(@columns) > 0 do %>
        <div class="border border-gray-200 rounded-lg overflow-hidden">
          <div class="bg-gray-100 px-3 py-2 text-xs text-gray-500 font-medium">
            샘플 데이터 (<%= length(@preview_data) %>행)
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="bg-gray-50 border-b">
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-500">ID</th>
                  <%= for col <- @columns do %>
                    <%= if col.field != "" do %>
                      <th class="px-3 py-2 text-left text-xs font-medium text-gray-500">
                        <%= if col.label != "", do: col.label, else: col.field %>
                      </th>
                    <% end %>
                  <% end %>
                </tr>
              </thead>
              <tbody>
                <%= for row <- @preview_data do %>
                  <tr class="border-b border-gray-100 hover:bg-gray-50">
                    <td class="px-3 py-2 text-gray-400"><%= row.id %></td>
                    <%= for col <- @columns do %>
                      <%= if col.field != "" do %>
                        <td class="px-3 py-2">
                          <%= Map.get(row, String.to_atom(col.field), "-") %>
                        </td>
                      <% end %>
                    <% end %>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>

      <%!-- 코드 미리보기 --%>
      <details class="border border-gray-200 rounded-lg">
        <summary class="px-4 py-2 bg-gray-50 cursor-pointer text-sm font-medium text-gray-600 hover:bg-gray-100">
          📝 Elixir 코드 미리보기
        </summary>
        <pre class="p-4 text-xs bg-gray-900 text-green-400 overflow-x-auto rounded-b-lg"><code><%= generate_code_preview(@columns, @grid_options) %></code></pre>
      </details>
    </div>
    """
  end

  # ══════════════════════════════════════════════════════
  # Mount & Update
  # ══════════════════════════════════════════════════════

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:active_tab, "info")
     |> assign(:grid_name, "")
     |> assign(:grid_id, "")
     |> assign(:grid_options, %{
       page_size: 20,
       theme: "light",
       virtual_scroll: false,
       row_height: 40,
       frozen_columns: 0,
       show_row_number: false
     })
     |> assign(:columns, [])
     |> assign(:selected_column_id, nil)
     |> assign(:next_temp_id, 1)
     |> assign(:preview_data, [])
     |> assign(:errors, %{})
     |> assign(:show_code, false)
     |> assign(:data_source_type, "sample")
     |> assign(:selected_schema, nil)
     |> assign(:selected_table, nil)
     |> assign(:available_schemas, SchemaRegistry.list_schemas())
     |> assign(:available_tables, [])
     |> assign(:table_columns_info, [])}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  # ══════════════════════════════════════════════════════
  # Event Handlers
  # ══════════════════════════════════════════════════════

  @impl true
  def handle_event("select_builder_tab", %{"tab" => tab}, socket) do
    socket =
      if tab == "preview" do
        refresh_preview(socket)
      else
        socket
      end

    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("close_builder", _params, socket) do
    send(self(), :grid_builder_close)
    {:noreply, socket}
  end

  # ── Tab 1: Grid Info ──

  def handle_event("update_grid_name", %{"value" => name}, socket) do
    grid_id = generate_grid_id(name)
    {:noreply, socket |> assign(:grid_name, name) |> assign(:grid_id, grid_id)}
  end

  def handle_event("update_grid_id", %{"value" => id}, socket) do
    sanitized = sanitize_grid_id(id)
    {:noreply, assign(socket, :grid_id, sanitized)}
  end

  def handle_event("update_builder_option", %{"key" => key, "value" => value}, socket) do
    options = socket.assigns.grid_options
    coerced = coerce_option(key, value)
    {:noreply, assign(socket, :grid_options, Map.put(options, String.to_atom(key), coerced))}
  end

  def handle_event("toggle_builder_option", %{"key" => key}, socket) do
    key_atom = String.to_atom(key)
    options = socket.assigns.grid_options
    {:noreply, assign(socket, :grid_options, Map.update!(options, key_atom, &(!&1)))}
  end

  # ── Data Source ──

  def handle_event("select_data_source_type", %{"type" => type}, socket) do
    socket =
      socket
      |> assign(:data_source_type, type)
      |> maybe_load_tables(type)

    {:noreply, socket}
  end

  def handle_event("select_schema", %{"schema" => ""}, socket) do
    {:noreply, assign(socket, :selected_schema, nil)}
  end

  def handle_event("select_schema", %{"schema" => schema_str}, socket) do
    {:noreply, assign(socket, :selected_schema, schema_str)}
  end

  def handle_event("select_table", %{"table" => ""}, socket) do
    {:noreply, socket |> assign(:selected_table, nil) |> assign(:table_columns_info, [])}
  end

  def handle_event("select_table", %{"table" => table}, socket) do
    table_cols =
      case TableInspector.table_columns(LiveviewGrid.Repo, table) do
        {:ok, cols} -> cols
        _ -> []
      end

    {:noreply, socket |> assign(:selected_table, table) |> assign(:table_columns_info, table_cols)}
  end

  def handle_event("load_schema_columns", _params, socket) do
    case socket.assigns.selected_schema do
      nil ->
        {:noreply, socket}

      schema_str ->
        module = String.to_existing_atom(schema_str)
        grid_cols = SchemaRegistry.schema_columns(module)

        builder_cols =
          grid_cols
          |> Enum.with_index(socket.assigns.next_temp_id)
          |> Enum.map(fn {col, idx} ->
            %{
              temp_id: "col_#{idx}",
              field: col.field,
              label: col.label,
              type: col.type,
              width: :auto,
              align: :left,
              sortable: col.sortable,
              filterable: col.filterable,
              editable: col.editable,
              editor_type: col.editor_type,
              editor_options: [],
              formatter: nil,
              formatter_options: %{},
              validators: [],
              renderer: nil,
              renderer_options: %{}
            }
          end)

        {:noreply,
         socket
         |> assign(:columns, builder_cols)
         |> assign(:next_temp_id, socket.assigns.next_temp_id + length(builder_cols))
         |> assign(:selected_column_id, nil)}
    end
  end

  def handle_event("load_table_columns", _params, socket) do
    case socket.assigns.selected_table do
      nil ->
        {:noreply, socket}

      table ->
        case TableInspector.table_to_grid_columns(LiveviewGrid.Repo, table) do
          {:ok, grid_cols} ->
            builder_cols =
              grid_cols
              |> Enum.with_index(socket.assigns.next_temp_id)
              |> Enum.map(fn {col, idx} ->
                %{
                  temp_id: "col_#{idx}",
                  field: col.field,
                  label: col.label,
                  type: col.type,
                  width: :auto,
                  align: :left,
                  sortable: col.sortable,
                  filterable: col.filterable,
                  editable: col.editable,
                  editor_type: col.editor_type,
                  editor_options: [],
                  formatter: nil,
                  formatter_options: %{},
                  validators: [],
                  renderer: nil,
                  renderer_options: %{}
                }
              end)

            {:noreply,
             socket
             |> assign(:columns, builder_cols)
             |> assign(:next_temp_id, socket.assigns.next_temp_id + length(builder_cols))
             |> assign(:selected_column_id, nil)}

          _ ->
            {:noreply, socket}
        end
    end
  end

  # ── Tab 2: Column CRUD ──

  def handle_event("add_column", _params, socket) do
    next_id = socket.assigns.next_temp_id
    new_col = new_column(next_id)

    {:noreply,
     socket
     |> assign(:columns, socket.assigns.columns ++ [new_col])
     |> assign(:next_temp_id, next_id + 1)
     |> assign(:selected_column_id, new_col.temp_id)}
  end

  def handle_event("remove_column", %{"id" => temp_id}, socket) do
    updated = Enum.reject(socket.assigns.columns, &(&1.temp_id == temp_id))

    selected =
      if socket.assigns.selected_column_id == temp_id, do: nil, else: socket.assigns.selected_column_id

    {:noreply,
     socket
     |> assign(:columns, updated)
     |> assign(:selected_column_id, selected)}
  end

  def handle_event("select_builder_column", %{"id" => temp_id}, socket) do
    current = socket.assigns.selected_column_id
    new_selected = if current == temp_id, do: nil, else: temp_id
    {:noreply, assign(socket, :selected_column_id, new_selected)}
  end

  def handle_event("update_column_field", %{"id" => temp_id, "value" => value}, socket) do
    sanitized = sanitize_field_name(value)
    {:noreply, update_column(socket, temp_id, :field, sanitized)}
  end

  def handle_event("update_column_label", %{"id" => temp_id, "value" => value}, socket) do
    {:noreply, update_column(socket, temp_id, :label, value)}
  end

  def handle_event("update_column_type", %{"col_id" => temp_id, "value" => value}, socket) do
    {:noreply, update_column(socket, temp_id, :type, String.to_atom(value))}
  end

  def handle_event("update_column_width", %{"id" => temp_id, "value" => value}, socket) do
    width = if value == "" or value == "0", do: :auto, else: String.to_integer(value)
    {:noreply, update_column(socket, temp_id, :width, width)}
  end

  def handle_event("update_column_align", %{"col_id" => temp_id, "value" => value}, socket) do
    {:noreply, update_column(socket, temp_id, :align, String.to_atom(value))}
  end

  def handle_event("update_column_editor", %{"col_id" => temp_id, "value" => value}, socket) do
    {:noreply, update_column(socket, temp_id, :editor_type, String.to_atom(value))}
  end

  def handle_event("toggle_column_attr", %{"id" => temp_id, "key" => key}, socket) do
    key_atom = String.to_atom(key)

    columns =
      Enum.map(socket.assigns.columns, fn col ->
        if col.temp_id == temp_id, do: Map.update!(col, key_atom, &(!&1)), else: col
      end)

    {:noreply, assign(socket, :columns, columns)}
  end

  # Drag-to-reorder (ConfigSortable Hook)
  def handle_event("reorder_columns", %{"order" => order}, socket) do
    column_map = Map.new(socket.assigns.columns, &{&1.temp_id, &1})

    reordered =
      Enum.map(order, fn temp_id -> Map.get(column_map, temp_id) end)
      |> Enum.reject(&is_nil/1)

    {:noreply, assign(socket, :columns, reordered)}
  end

  # ── Tab 2: Formatter / Validator / Renderer ──

  def handle_event("set_column_formatter", %{"col_id" => temp_id, "value" => value}, socket) do
    formatter = if value == "", do: nil, else: String.to_atom(value)
    {:noreply, update_column(socket, temp_id, :formatter, formatter)}
  end

  def handle_event("add_column_validator", %{"id" => temp_id}, socket) do
    new_validator = %{type: "required", message: "This field is required", value: nil}

    columns =
      Enum.map(socket.assigns.columns, fn col ->
        if col.temp_id == temp_id do
          Map.update!(col, :validators, &(&1 ++ [new_validator]))
        else
          col
        end
      end)

    {:noreply, assign(socket, :columns, columns)}
  end

  def handle_event("update_column_validator", %{"col_id" => temp_id, "index" => idx_str, "type" => new_type}, socket) do
    index = String.to_integer(idx_str)

    columns =
      Enum.map(socket.assigns.columns, fn col ->
        if col.temp_id == temp_id do
          updated_validators =
            List.update_at(col.validators, index, fn v -> %{v | type: new_type} end)

          %{col | validators: updated_validators}
        else
          col
        end
      end)

    {:noreply, assign(socket, :columns, columns)}
  end

  def handle_event("update_validator_value", %{"id" => temp_id, "index" => idx_str, "value" => value}, socket) do
    index = String.to_integer(idx_str)

    columns =
      Enum.map(socket.assigns.columns, fn col ->
        if col.temp_id == temp_id do
          updated_validators =
            List.update_at(col.validators, index, fn v -> %{v | value: value} end)

          %{col | validators: updated_validators}
        else
          col
        end
      end)

    {:noreply, assign(socket, :columns, columns)}
  end

  def handle_event("update_validator_message", %{"id" => temp_id, "index" => idx_str, "value" => value}, socket) do
    index = String.to_integer(idx_str)

    columns =
      Enum.map(socket.assigns.columns, fn col ->
        if col.temp_id == temp_id do
          updated_validators =
            List.update_at(col.validators, index, fn v -> %{v | message: value} end)

          %{col | validators: updated_validators}
        else
          col
        end
      end)

    {:noreply, assign(socket, :columns, columns)}
  end

  def handle_event("remove_column_validator", %{"id" => temp_id, "index" => idx_str}, socket) do
    index = String.to_integer(idx_str)

    columns =
      Enum.map(socket.assigns.columns, fn col ->
        if col.temp_id == temp_id do
          %{col | validators: List.delete_at(col.validators, index)}
        else
          col
        end
      end)

    {:noreply, assign(socket, :columns, columns)}
  end

  def handle_event("set_column_renderer", %{"col_id" => temp_id, "value" => value}, socket) do
    renderer = if value == "", do: nil, else: value

    columns =
      Enum.map(socket.assigns.columns, fn col ->
        if col.temp_id == temp_id do
          %{col | renderer: renderer, renderer_options: %{}}
        else
          col
        end
      end)

    {:noreply, assign(socket, :columns, columns)}
  end

  # From phx-blur (phx-value-id, phx-value-key)
  def handle_event("update_renderer_option", %{"id" => temp_id, "key" => key, "value" => value}, socket) do
    do_update_renderer_option(socket, temp_id, key, value)
  end

  # From phx-change (form with hidden inputs)
  def handle_event("update_renderer_option", %{"col_id" => temp_id, "key" => key, "value" => value}, socket) do
    do_update_renderer_option(socket, temp_id, key, value)
  end

  # ── Tab 3: Preview + Create ──

  def handle_event("refresh_preview", _params, socket) do
    {:noreply, refresh_preview(socket)}
  end

  def handle_event("create_grid", _params, socket) do
    case validate_builder(socket) do
      {:ok, params} ->
        send(self(), {:grid_builder_create, params})
        {:noreply, socket}

      {:error, errors} ->
        {:noreply, socket |> assign(:errors, errors) |> assign(:active_tab, "preview")}
    end
  end

  # ══════════════════════════════════════════════════════
  # Helpers
  # ══════════════════════════════════════════════════════

  defp new_column(temp_id) do
    %{
      temp_id: "col_#{temp_id}",
      field: "",
      label: "",
      type: :string,
      width: :auto,
      align: :left,
      sortable: false,
      filterable: false,
      editable: false,
      editor_type: :text,
      editor_options: [],
      formatter: nil,
      formatter_options: %{},
      validators: [],
      renderer: nil,
      renderer_options: %{}
    }
  end

  defp do_update_renderer_option(socket, temp_id, key, value) do
    columns =
      Enum.map(socket.assigns.columns, fn col ->
        if col.temp_id == temp_id do
          opts = Map.put(col.renderer_options, String.to_atom(key), value)
          %{col | renderer_options: opts}
        else
          col
        end
      end)

    {:noreply, assign(socket, :columns, columns)}
  end

  defp update_column(socket, temp_id, key, value) do
    columns =
      Enum.map(socket.assigns.columns, fn col ->
        if col.temp_id == temp_id, do: Map.put(col, key, value), else: col
      end)

    assign(socket, :columns, columns)
  end

  defp refresh_preview(socket) do
    valid_columns =
      socket.assigns.columns
      |> Enum.filter(&(&1.field != ""))

    preview_data =
      if valid_columns != [] do
        case socket.assigns.data_source_type do
          "schema" -> fetch_schema_preview(socket.assigns.selected_schema, 5)
          "table" -> fetch_table_preview(socket.assigns.selected_table, 5)
          _ -> SampleData.generate(valid_columns, 5)
        end
      else
        []
      end

    assign(socket, :preview_data, preview_data)
  end

  defp fetch_schema_preview(nil, _limit), do: []

  defp fetch_schema_preview(schema_str, limit) do
    try do
      module = String.to_existing_atom(schema_str)
      import Ecto.Query, only: [from: 2]
      query = from(r in module, limit: ^limit)

      LiveviewGrid.Repo.all(query)
      |> Enum.map(fn r -> r |> Map.from_struct() |> Map.delete(:__meta__) end)
    rescue
      _ -> []
    end
  end

  defp fetch_table_preview(nil, _limit), do: []

  defp fetch_table_preview(table, limit) do
    sql = "SELECT * FROM #{table} LIMIT ?"

    try do
      result = Ecto.Adapters.SQL.query!(LiveviewGrid.Repo, sql, [limit])

      Enum.map(result.rows, fn row ->
        result.columns
        |> Enum.zip(row)
        |> Map.new(fn {col, val} -> {String.to_atom(col), val} end)
      end)
    rescue
      _ -> []
    end
  end

  defp maybe_load_tables(socket, "table") do
    case TableInspector.list_tables(LiveviewGrid.Repo) do
      {:ok, tables} -> assign(socket, :available_tables, tables)
      _ -> socket
    end
  end

  defp maybe_load_tables(socket, _type), do: socket

  defp validate_builder(socket), do: BuilderHelpers.validate_builder(socket.assigns)
  defp generate_grid_id(name), do: BuilderHelpers.generate_grid_id(name)
  defp sanitize_grid_id(id), do: BuilderHelpers.sanitize_grid_id(id)
  defp sanitize_field_name(name), do: BuilderHelpers.sanitize_field_name(name)
  defp coerce_option(key, v), do: BuilderHelpers.coerce_option(key, v)

  defp generate_code_preview(columns, options) do
    col_lines =
      columns
      |> Enum.filter(&(&1.field != ""))
      |> Enum.map(fn col ->
        parts = [
          "field: :#{col.field}",
          "label: \"#{if col.label == "", do: col.field, else: col.label}\"",
          "type: :#{col.type}"
        ]

        parts = if col.width != :auto, do: parts ++ ["width: #{col.width}"], else: parts
        parts = if col.sortable, do: parts ++ ["sortable: true"], else: parts
        parts = if col.editable, do: parts ++ ["editable: true"], else: parts
        parts = if col.formatter, do: parts ++ ["formatter: :#{col.formatter}"], else: parts

        "  %{#{Enum.join(parts, ", ")}}"
      end)

    opts_parts = [
      "page_size: #{options.page_size}",
      "theme: \"#{options.theme}\""
    ]

    opts_parts = if options.show_row_number, do: opts_parts ++ ["show_row_number: true"], else: opts_parts
    opts_parts = if options.frozen_columns > 0, do: opts_parts ++ ["frozen_columns: #{options.frozen_columns}"], else: opts_parts

    """
    columns = [
    #{Enum.join(col_lines, ",\n")}
    ]

    options = %{#{Enum.join(opts_parts, ", ")}}

    Grid.new(columns: columns, options: options, data: data)
    """
  end
end
