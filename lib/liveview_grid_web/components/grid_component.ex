defmodule LiveviewGridWeb.GridComponent do
  @moduledoc """
  Phoenix LiveView Grid 컴포넌트 (LiveComponent).

  부모 LiveView에서 `<.live_component>`로 사용하며,
  Grid의 모든 UI 렌더링과 사용자 이벤트 처리를 담당합니다.

  ## 사용법

      <.live_component
        module={LiveviewGridWeb.GridComponent}
        id={@grid.id}
        grid={@grid}
      />

  ## Assigns (필수)

  - `id` - 컴포넌트 고유 ID (보통 `@grid.id`)
  - `grid` - `LiveViewGrid.Grid.new/1`로 생성한 Grid 맵 (또는 `data` + `columns` 개별 전달)

  ## 모듈 구조

  - `GridComponent` (이 파일) — mount, update, render, handle_event 디스패치
  - `GridComponent.EventHandlers` — 이벤트 핸들러 비즈니스 로직
  - `GridComponent.RenderHelpers` — 렌더링 헬퍼 함수
  """

  use Phoenix.LiveComponent

  alias LiveViewGrid.{Grid, Pagination}
  alias LiveviewGridWeb.GridComponent.EventHandlers
  import LiveviewGridWeb.GridComponent.RenderHelpers

  @doc "컴포넌트 마운트 시 Config Modal 상태를 초기화한다."
  @impl true
  def mount(socket) do
    {:ok, assign(socket, :show_config_modal, false)}
  end

  @doc "부모 LiveView에서 전달된 assigns를 Grid 상태로 변환한다. 초기 생성 또는 기존 Grid 업데이트를 처리한다."
  @impl true
  def update(assigns, socket) do
    new_options = Map.get(assigns, :options, %{})
    data_source = Map.get(assigns, :data_source, nil)

    {grid, virtual_changed?} = if Map.has_key?(socket.assigns, :grid) do
      old_grid = socket.assigns.grid
      old_virtual = old_grid.options.virtual_scroll
      new_virtual = Map.get(new_options, :virtual_scroll, old_virtual)

      updated = Grid.update_data(
        old_grid,
        assigns.data,
        assigns.columns,
        new_options
      )

      updated = if data_source do
        updated
        |> Map.put(:data_source, data_source)
        |> Grid.refresh_from_source()
      else
        updated
      end

      if old_virtual != new_virtual do
        {put_in(updated.state.scroll_offset, 0), true}
      else
        {updated, false}
      end
    else
      grid_opts = [
        data: assigns.data,
        columns: assigns.columns,
        options: new_options
      ]
      grid_opts = if data_source, do: Keyword.put(grid_opts, :data_source, data_source), else: grid_opts

      grid = Grid.new(grid_opts)

      grid = if data_source do
        grid
      else
        put_in(grid.state.pagination.total_rows, length(assigns.data))
      end

      {grid, false}
    end

    grid = EventHandlers.apply_v07_options(grid, new_options)

    socket = assign(socket, grid: grid)

    socket =
      if Map.has_key?(socket.assigns, :export_menu_open) do
        socket
      else
        assign(socket, export_menu_open: nil)
      end

    socket =
      if Map.has_key?(socket.assigns, :context_menu) do
        socket
      else
        assign(socket, context_menu: nil)
      end

    socket = if virtual_changed? do
      push_event(socket, "reset_virtual_scroll", %{})
    else
      socket
    end

    {:ok, socket}
  end

  # ── Event Handler Dispatch ──
  # 모든 비즈니스 로직은 EventHandlers 모듈에 위임

  @doc "Grid의 모든 사용자 이벤트를 EventHandlers 모듈로 디스패치한다. 정렬, 필터, 페이지네이션, 셀 편집, 행 편집, 내보내기 등을 지원한다."
  @impl true
  def handle_event("grid_sort", params, socket),
    do: EventHandlers.handle_sort(params, socket)

  @impl true
  def handle_event("grid_page_change", params, socket),
    do: EventHandlers.handle_page_change(params, socket)

  @impl true
  def handle_event("grid_page_size_change", params, socket),
    do: EventHandlers.handle_page_size_change(params, socket)

  @impl true
  def handle_event("grid_column_resize", params, socket),
    do: EventHandlers.handle_column_resize(params, socket)

  @impl true
  def handle_event("grid_column_reorder", params, socket),
    do: EventHandlers.handle_column_reorder(params, socket)

  @impl true
  def handle_event("grid_freeze_to_column", params, socket),
    do: EventHandlers.handle_freeze_to_column(params, socket)

  @impl true
  def handle_event("grid_move_row", params, socket),
    do: EventHandlers.handle_move_row(params, socket)

  @impl true
  def handle_event("grid_row_select", params, socket),
    do: EventHandlers.handle_row_select(params, socket)

  @impl true
  def handle_event("grid_select_all", params, socket),
    do: EventHandlers.handle_select_all(params, socket)

  @impl true
  def handle_event("grid_toggle_filter", params, socket),
    do: EventHandlers.handle_toggle_filter(params, socket)

  @impl true
  def handle_event("grid_toggle_status_column", params, socket),
    do: EventHandlers.handle_toggle_status_column(params, socket)

  @impl true
  def handle_event("grid_filter", params, socket),
    do: EventHandlers.handle_filter(params, socket)

  @impl true
  def handle_event("grid_filter_date", params, socket),
    do: EventHandlers.handle_filter_date(params, socket)

  # FA-003: Date Filter Preset
  @impl true
  def handle_event("grid_filter_date_preset", params, socket),
    do: EventHandlers.handle_filter_date_preset(params, socket)

  @impl true
  def handle_event("grid_clear_filters", params, socket),
    do: EventHandlers.handle_clear_filters(params, socket)

  # FA-012: Set Filter Events
  @impl true
  def handle_event("toggle_set_filter", params, socket),
    do: EventHandlers.handle_toggle_set_filter(params, socket)

  @impl true
  def handle_event("close_set_filter", _params, socket),
    do: EventHandlers.handle_close_set_filter(socket)

  @impl true
  def handle_event("set_filter_select_all", params, socket),
    do: EventHandlers.handle_set_filter_select_all(params, socket)

  @impl true
  def handle_event("set_filter_deselect_all", params, socket),
    do: EventHandlers.handle_set_filter_deselect_all(params, socket)

  @impl true
  def handle_event("set_filter_toggle", params, socket),
    do: EventHandlers.handle_set_filter_toggle(params, socket)

  @impl true
  def handle_event("grid_global_search", params, socket),
    do: EventHandlers.handle_global_search(params, socket)

  @impl true
  def handle_event("grid_scroll", params, socket),
    do: EventHandlers.handle_scroll(params, socket)

  @impl true
  def handle_event("cell_edit_start", params, socket),
    do: EventHandlers.handle_cell_edit_start(params, socket)

  @impl true
  def handle_event("row_edit_start", params, socket),
    do: EventHandlers.handle_row_edit_start(params, socket)

  @impl true
  def handle_event("row_edit_save", params, socket),
    do: EventHandlers.handle_row_edit_save(params, socket)

  @impl true
  def handle_event("row_edit_cancel", params, socket),
    do: EventHandlers.handle_row_edit_cancel(params, socket)

  @impl true
  def handle_event("grid_undo", params, socket),
    do: EventHandlers.handle_undo(params, socket)

  @impl true
  def handle_event("grid_redo", params, socket),
    do: EventHandlers.handle_redo(params, socket)

  @impl true
  def handle_event("cell_edit_save", _params, %{assigns: %{grid: %{state: %{editing: nil}}}} = socket),
    do: EventHandlers.handle_cell_edit_save_nil_editing(socket)

  @impl true
  def handle_event("cell_edit_save", params, socket),
    do: EventHandlers.handle_cell_edit_save(params, socket)

  @impl true
  def handle_event("cell_checkbox_toggle", params, socket),
    do: EventHandlers.handle_checkbox_toggle(params, socket)

  @impl true
  def handle_event("import_file", params, socket),
    do: EventHandlers.handle_import_file(params, socket)

  @impl true
  def handle_event("paste_cells", params, socket),
    do: EventHandlers.handle_paste_cells(params, socket)

  @impl true
  def handle_event("cell_select_change", params, socket),
    do: EventHandlers.handle_cell_select_change(params, socket)

  @impl true
  def handle_event("cell_edit_date", params, socket),
    do: EventHandlers.handle_cell_edit_date(params, socket)

  @impl true
  def handle_event("cell_edit_cancel", params, socket),
    do: EventHandlers.handle_cell_edit_cancel(params, socket)

  @impl true
  def handle_event("cell_keydown", %{"key" => "Enter"} = params, socket),
    do: EventHandlers.handle_cell_keydown_enter(params, socket)

  @impl true
  def handle_event("cell_keydown", %{"key" => "Escape"}, socket),
    do: EventHandlers.handle_cell_keydown_escape(socket)

  @impl true
  def handle_event("cell_keydown", _params, socket),
    do: EventHandlers.handle_cell_keydown_other(socket)

  @impl true
  def handle_event("cell_edit_save_and_move", params, socket),
    do: EventHandlers.handle_cell_edit_save_and_move(params, socket)

  @impl true
  def handle_event("grid_add_row", params, socket),
    do: EventHandlers.handle_add_row(params, socket)

  @impl true
  def handle_event("grid_delete_selected", params, socket),
    do: EventHandlers.handle_delete_selected(params, socket)

  @impl true
  def handle_event("grid_save", params, socket),
    do: EventHandlers.handle_save(params, socket)

  @impl true
  def handle_event("grid_discard", params, socket),
    do: EventHandlers.handle_discard(params, socket)

  @impl true
  def handle_event("export_excel", params, socket),
    do: EventHandlers.handle_export_excel(params, socket)

  @impl true
  def handle_event("export_csv", params, socket),
    do: EventHandlers.handle_export_csv(params, socket)

  @impl true
  def handle_event("toggle_export_menu", params, socket),
    do: EventHandlers.handle_toggle_export_menu(params, socket)

  @impl true
  def handle_event("toggle_advanced_filter", params, socket),
    do: EventHandlers.handle_toggle_advanced_filter(params, socket)

  @impl true
  def handle_event("add_filter_condition", params, socket),
    do: EventHandlers.handle_add_filter_condition(params, socket)

  @impl true
  def handle_event("update_filter_condition", params, socket),
    do: EventHandlers.handle_update_filter_condition(params, socket)

  @impl true
  def handle_event("remove_filter_condition", params, socket),
    do: EventHandlers.handle_remove_filter_condition(params, socket)

  @impl true
  def handle_event("change_filter_logic", params, socket),
    do: EventHandlers.handle_change_filter_logic(params, socket)

  @impl true
  def handle_event("clear_advanced_filter", params, socket),
    do: EventHandlers.handle_clear_advanced_filter(params, socket)

  @impl true
  def handle_event("noop_submit", params, socket),
    do: EventHandlers.handle_noop_submit(params, socket)

  @impl true
  def handle_event("grid_group_by", params, socket),
    do: EventHandlers.handle_group_by(params, socket)

  @impl true
  def handle_event("grid_group_aggregates", params, socket),
    do: EventHandlers.handle_group_aggregates(params, socket)

  @impl true
  def handle_event("grid_toggle_group", params, socket),
    do: EventHandlers.handle_toggle_group(params, socket)

  @impl true
  def handle_event("grid_clear_grouping", params, socket),
    do: EventHandlers.handle_clear_grouping(params, socket)

  @impl true
  def handle_event("grid_toggle_tree", params, socket),
    do: EventHandlers.handle_toggle_tree(params, socket)

  @impl true
  def handle_event("grid_toggle_tree_node", params, socket),
    do: EventHandlers.handle_toggle_tree_node(params, socket)

  # F-800: Context Menu
  @impl true
  def handle_event("show_context_menu", params, socket),
    do: EventHandlers.handle_show_context_menu(params, socket)

  @impl true
  def handle_event("hide_context_menu", params, socket),
    do: EventHandlers.handle_hide_context_menu(params, socket)

  @impl true
  def handle_event("context_menu_action", params, socket),
    do: EventHandlers.handle_context_menu_action(params, socket)

  # F-940: Cell Range Selection
  @impl true
  def handle_event("set_cell_range", params, socket),
    do: EventHandlers.handle_set_cell_range(params, socket)

  @impl true
  def handle_event("clear_cell_range", params, socket),
    do: EventHandlers.handle_clear_cell_range(params, socket)

  @impl true
  def handle_event("copy_cell_range", params, socket),
    do: EventHandlers.handle_copy_cell_range(params, socket)

  # ── FA-001: Row Pin/Unpin Events ──

  @impl true
  def handle_event("grid_pin_row_top", params, socket),
    do: EventHandlers.handle_pin_row(params, :top, socket)

  @impl true
  def handle_event("grid_pin_row_bottom", params, socket),
    do: EventHandlers.handle_pin_row(params, :bottom, socket)

  @impl true
  def handle_event("grid_unpin_row", params, socket),
    do: EventHandlers.handle_unpin_row(params, socket)

  # ── FA-010: Column Menu Events ──

  @impl true
  def handle_event("show_column_menu", params, socket),
    do: EventHandlers.handle_show_column_menu(params, socket)

  @impl true
  def handle_event("hide_column_menu", _params, socket),
    do: EventHandlers.handle_hide_column_menu(socket)

  @impl true
  def handle_event("column_menu_action", params, socket),
    do: EventHandlers.handle_column_menu_action(params, socket)

  # ── FA-002: Grid State Save/Restore Events ──

  @impl true
  def handle_event("save_grid_state", _params, socket),
    do: EventHandlers.handle_save_grid_state(socket)

  @impl true
  def handle_event("restore_grid_state", params, socket),
    do: EventHandlers.handle_restore_grid_state(params, socket)

  @impl true
  def handle_event("clear_grid_state", _params, socket),
    do: EventHandlers.handle_clear_grid_state(socket)

  # ── FA-044: Find & Highlight Events ──

  @impl true
  def handle_event("toggle_find_bar", _params, socket),
    do: EventHandlers.handle_toggle_find_bar(socket)

  @impl true
  def handle_event("find_text", params, socket),
    do: EventHandlers.handle_find(params, socket)

  @impl true
  def handle_event("find_keydown", %{"key" => "Enter", "shiftKey" => true}, socket),
    do: EventHandlers.handle_find_prev(socket)

  @impl true
  def handle_event("find_keydown", %{"key" => "Enter"}, socket),
    do: EventHandlers.handle_find_next(socket)

  @impl true
  def handle_event("find_keydown", %{"key" => "Escape"}, socket),
    do: EventHandlers.handle_close_find(socket)

  @impl true
  def handle_event("find_keydown", _params, socket),
    do: {:noreply, socket}

  @impl true
  def handle_event("find_next", _params, socket),
    do: EventHandlers.handle_find_next(socket)

  @impl true
  def handle_event("find_prev", _params, socket),
    do: EventHandlers.handle_find_prev(socket)

  @impl true
  def handle_event("close_find", _params, socket),
    do: EventHandlers.handle_close_find(socket)

  # ── Config Modal Events ──

  @impl true
  def handle_event("open_config_modal", _params, socket) do
    {:noreply, assign(socket, :show_config_modal, true)}
  end

  @impl true
  def handle_event("close_config_modal", _params, socket) do
    {:noreply, assign(socket, :show_config_modal, false)}
  end

  @impl true
  def handle_event("apply_grid_config", %{"config" => config_json}, socket) do
    grid = socket.assigns.grid

    try do
      # JSON 문자열 파싱
      {:ok, config_changes} = Jason.decode(config_json)



      # Phase 1: 컬럼 설정 변경 적용
      updated_grid = Grid.apply_config_changes(grid, config_changes)

      # Phase 2: Grid-level options 변경 적용
      updated_grid =
        case Map.get(config_changes, "options") do
          nil ->
            updated_grid

          options when is_map(options) ->
            case Grid.apply_grid_settings(updated_grid, options) do
              {:ok, new_grid} ->
                new_grid

              {:error, reason} ->
                IO.warn("Grid settings validation error: #{reason}")
                updated_grid
            end
        end

      socket =
        socket
        |> assign(:grid, updated_grid)
        |> assign(:show_config_modal, false)

      {:noreply, socket}
    rescue
      e ->
        # 에러 발생 시 에러 메시지 표시
        IO.puts("설정 변경 에러: #{inspect(e)}")
        {:noreply, socket}
    end
  end

  # ── Render ──

  @impl true
  @doc "Grid 컴포넌트의 전체 UI를 렌더링한다. 툴바, 헤더, 바디, 푸터, Config Modal을 포함한다."
  def render(assigns) do
    ~H"""
    <div class="lv-grid" id={"#{@grid.id}-keyboard-nav"} phx-hook="GridKeyboardNav" tabindex="0" data-theme={@grid.options[:theme] || "light"} data-column-hover-highlight={if @grid.options[:column_hover_highlight], do: "true"} style={build_custom_css_vars(@grid.options[:custom_css_vars])}>
      <!-- Toolbar: Search + Save -->
      <div class="lv-grid__toolbar">
        <div class="lv-grid__search-bar">
          <span class="lv-grid__search-icon">&#x1F50D;</span>
          <input
            type="text"
            class="lv-grid__search-input"
            placeholder="전체 검색..."
            value={@grid.state.global_search}
            phx-keyup="grid_global_search"
            phx-debounce="300"
            phx-target={@myself}
          />
          <%= if @grid.state.global_search != "" do %>
            <button
              class="lv-grid__search-clear"
              phx-click="grid_global_search"
              phx-value-value=""
              phx-target={@myself}
            >
              ✕
            </button>
          <% end %>
        </div>
        <div class="lv-grid__action-area">
          <!-- F-700: Undo/Redo 버튼 -->
          <button
            class={"lv-grid__undo-btn #{unless Grid.can_undo?(@grid), do: "lv-grid__undo-btn--disabled"}"}
            phx-click="grid_undo"
            phx-target={@myself}
            disabled={!Grid.can_undo?(@grid)}
            title="되돌리기 (Ctrl+Z)"
          >
            ↩
          </button>
          <button
            class={"lv-grid__redo-btn #{unless Grid.can_redo?(@grid), do: "lv-grid__redo-btn--disabled"}"}
            phx-click="grid_redo"
            phx-target={@myself}
            disabled={!Grid.can_redo?(@grid)}
            title="다시하기 (Ctrl+Y)"
          >
            ↪
          </button>
          <button
            class="lv-grid__add-btn"
            phx-click="grid_add_row"
            phx-target={@myself}
            title="새 행 추가"
          >
            + 추가
          </button>
          <button
            class="lv-grid__config-btn"
            phx-click="open_config_modal"
            phx-target={@myself}
            title="그리드 설정"
          >
            ⚙ 설정
          </button>
          <%= if length(@grid.state.selection.selected_ids) > 0 do %>
            <button
              class="lv-grid__delete-btn"
              phx-click="grid_delete_selected"
              phx-target={@myself}
              data-confirm={"선택된 #{length(@grid.state.selection.selected_ids)}개 행을 삭제하시겠습니까?"}
              title="선택 행 삭제"
            >
              삭제 (<%= length(@grid.state.selection.selected_ids) %>)
            </button>
          <% end %>
        </div>

        <span class="lv-grid__toolbar-separator"></span>

        <%= if Grid.has_changes?(@grid) do %>
          <div class="lv-grid__save-area">
            <span class="lv-grid__save-count">
              <%= map_size(@grid.state.row_statuses) %>건 변경
            </span>
            <%= if Grid.has_errors?(@grid) do %>
              <span class="lv-grid__error-count">⚠ <%= Grid.error_count(@grid) %>건 오류</span>
            <% end %>
            <button
              class={"lv-grid__save-btn #{if Grid.has_errors?(@grid), do: "lv-grid__save-btn--disabled"}"}
              phx-click="grid_save"
              phx-target={@myself}
              title={if Grid.has_errors?(@grid), do: "검증 오류를 수정한 후 저장하세요", else: "변경사항 저장"}
            >
              💾 저장
            </button>
            <button
              class="lv-grid__discard-btn"
              phx-click="grid_discard"
              phx-target={@myself}
            >
              ↩ 취소
            </button>
          </div>
        <% end %>
      </div>

      <%!-- FA-044: Find & Highlight Bar --%>
      <%= if @grid.state[:show_find_bar] do %>
        <div class="lv-grid__find-bar">
          <span class="lv-grid__find-icon">&#x1F50D;</span>
          <input
            type="text"
            class="lv-grid__find-input"
            placeholder="찾기..."
            value={@grid.state[:find_text]}
            phx-keyup="find_text"
            phx-keydown="find_keydown"
            phx-debounce="200"
            phx-target={@myself}
            autofocus
          />
          <span class="lv-grid__find-count">
            <%= if @grid.state[:find_matches] != [] do %>
              <%= (@grid.state[:find_current_index] || 0) + 1 %>/<%= length(@grid.state[:find_matches]) %>
            <% else %>
              <%= if @grid.state[:find_text] != "" do %>0/0<% end %>
            <% end %>
          </span>
          <button class="lv-grid__find-nav-btn" phx-click="find_prev" phx-target={@myself} title="이전 (Shift+Enter)">&#x25B2;</button>
          <button class="lv-grid__find-nav-btn" phx-click="find_next" phx-target={@myself} title="다음 (Enter)">&#x25BC;</button>
          <button class="lv-grid__find-close-btn" phx-click="close_find" phx-target={@myself} title="닫기 (Esc)">✕</button>
        </div>
      <% end %>

      <!-- Header Group Row (F-910: Multi-level Header) -->
      <%= if @grid.options.show_header && has_header_groups?(Grid.display_columns(@grid)) do %>
        <div class="lv-grid__header lv-grid__header--group">
          <div class="lv-grid__header-cell lv-grid__header-cell--group-spacer" style="width: 90px; flex: 0 0 90px;"></div>
          <%= if @grid.options.show_row_number do %>
            <div class="lv-grid__header-cell lv-grid__header-cell--group-spacer" style="width: 50px; flex: 0 0 50px;"></div>
          <% end %>
          <%= if @grid.state.show_status_column do %>
            <div class="lv-grid__header-cell lv-grid__header-cell--group-spacer" style="width: 60px; flex: 0 0 60px;"></div>
          <% end %>
          <%= for group <- build_header_groups(Grid.display_columns(@grid), @grid) do %>
            <div class={"lv-grid__header-cell lv-grid__header-cell--group #{if group.label, do: "", else: "lv-grid__header-cell--group-empty"}"} style={header_group_style(group)}>
              <%= group.label %>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Header -->
      <%= if @grid.options.show_header do %>
        <div class="lv-grid__header">
          <!-- 체크박스 + 필터 토글 컬럼 -->
          <div class="lv-grid__header-cell" style="width: 90px; flex: 0 0 90px; justify-content: center; gap: 4px;">
            <input
              type="checkbox"
              phx-click="grid_select_all"
              phx-target={@myself}
              checked={@grid.state.selection.select_all}
              style="width: 18px; height: 18px; cursor: pointer;"
            />
            <%= if has_filterable_columns?(@grid.columns) do %>
              <button
                class={"lv-grid__filter-toggle #{if @grid.state.show_filter_row, do: "lv-grid__filter-toggle--active"}"}
                phx-click="grid_toggle_filter"
                phx-target={@myself}
                title={if @grid.state.show_filter_row, do: "필터 숨기기", else: "필터 표시"}
              >
                ▼
              </button>
              <button
                class={"lv-grid__filter-toggle #{if @grid.state.show_advanced_filter, do: "lv-grid__filter-toggle--active"}"}
                phx-click="toggle_advanced_filter"
                phx-target={@myself}
                title={if @grid.state.show_advanced_filter, do: "고급 필터 숨기기", else: "고급 필터"}
                style="font-size: 9px;"
              >
                ▼S<%= if length((@grid.state.advanced_filters || %{conditions: []}).conditions) > 0 do %><span class="lv-grid__filter-badge"><%= length(@grid.state.advanced_filters.conditions) %></span><% end %>
              </button>
            <% end %>
            <button
              class={"lv-grid__status-toggle #{if @grid.state.show_status_column, do: "lv-grid__status-toggle--active"}"}
              phx-click="grid_toggle_status_column"
              phx-target={@myself}
              title={if @grid.state.show_status_column, do: "상태 컬럼 숨기기", else: "상태 컬럼 표시"}
            >
              S
            </button>
          </div>

          <!-- 행번호 컬럼 헤더 -->
          <%= if @grid.options.show_row_number do %>
            <div class="lv-grid__header-cell lv-grid__header-cell--row-number" style="width: 50px; flex: 0 0 50px; justify-content: center;">
              #
            </div>
          <% end %>

          <!-- 상태 컬럼 헤더 -->
          <%= if @grid.state.show_status_column do %>
            <div class="lv-grid__header-cell lv-grid__header-cell--status" style="width: 60px; flex: 0 0 60px; justify-content: center;">
              상태
            </div>
          <% end %>

          <%= for {column, col_idx} <- Enum.with_index(Grid.display_columns(@grid)) do %>
            <div
              class={"lv-grid__header-cell #{if column.sortable, do: "lv-grid__header-cell--sortable"} #{frozen_class(col_idx, @grid)} #{if Map.get(column, :header_wrap), do: "lv-grid__header-cell--wrap"}"}
              style={"#{column_width_style(column, @grid)}; #{frozen_style(col_idx, @grid)}"}
              phx-target={@myself}
              data-col-index={col_idx}
              data-field={column.field}
              data-sortable={if column.sortable, do: "true", else: "false"}
              data-sort-direction={next_direction(@grid.state.sort, column.field)}
              data-frozen={if(col_idx < (@grid.options[:frozen_columns] || 0), do: "true", else: "false")}
              id={"header-#{column.field}"}
              phx-hook="ColumnReorder"
            >
              <span class="lv-grid__header-label"><%= column.label %></span>
              <%= if column.sortable && sort_active?(@grid.state.sort, column.field) do %>
                <span class="lv-grid__sort-icon">
                  <%= sort_icon(@grid.state.sort.direction) %>
                </span>
              <% end %>
              <!-- FA-010: Column Menu Button -->
              <button
                class="lv-grid__column-menu-btn"
                phx-click="show_column_menu"
                phx-value-field={column.field}
                phx-value-col-idx={col_idx}
                phx-target={@myself}
                title="컬럼 메뉴"
              >≡</button>
              <%= if Map.get(column, :resizable, true) do %>
                <span
                  class="lv-grid__resize-handle"
                  phx-hook="ColumnResize"
                  id={"resize-#{column.field}"}
                  data-col-index={col_idx}
                  data-field={column.field}
                ></span>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- FA-010: Column Menu Dropdown -->
      <%= if @grid.state[:column_menu] do %>
        <div class="lv-grid__column-menu"
             style={"position:fixed;left:#{@grid.state.column_menu.x}px;top:#{@grid.state.column_menu.y}px;z-index:9999;"}
             phx-click-away="hide_column_menu"
             phx-target={@myself}>
          <% menu_field = @grid.state.column_menu.field %>
          <% menu_col = Enum.find(@grid.columns, fn c -> c.field == menu_field end) %>
          <%= if menu_col && menu_col.sortable do %>
            <div class="lv-grid__column-menu-item" phx-click="column_menu_action" phx-value-action="sort_asc" phx-value-field={menu_field} phx-target={@myself}>
              ↑ 오름차순 정렬
            </div>
            <div class="lv-grid__column-menu-item" phx-click="column_menu_action" phx-value-action="sort_desc" phx-value-field={menu_field} phx-target={@myself}>
              ↓ 내림차순 정렬
            </div>
            <%= if @grid.state.sort && @grid.state.sort.field == menu_field do %>
              <div class="lv-grid__column-menu-item" phx-click="column_menu_action" phx-value-action="clear_sort" phx-value-field={menu_field} phx-target={@myself}>
                ✕ 정렬 초기화
              </div>
            <% end %>
            <div class="lv-grid__column-menu-divider"></div>
          <% end %>
          <div class="lv-grid__column-menu-item" phx-click="column_menu_action" phx-value-action="hide_column" phx-value-field={menu_field} phx-target={@myself}>
            👁 컬럼 숨기기
          </div>
          <div class="lv-grid__column-menu-item" phx-click="column_menu_action" phx-value-action="auto_size" phx-value-field={menu_field} phx-target={@myself}>
            ↔ 자동 너비 맞춤
          </div>
          <%= if length(@grid.state[:hidden_columns] || []) > 0 do %>
            <div class="lv-grid__column-menu-divider"></div>
            <div class="lv-grid__column-menu-sub">숨겨진 컬럼:</div>
            <%= for hidden_field <- (@grid.state[:hidden_columns] || []) do %>
              <div class="lv-grid__column-menu-item lv-grid__column-menu-item--restore" phx-click="column_menu_action" phx-value-action="show_column" phx-value-field={hidden_field} phx-target={@myself}>
                + <%= hidden_field %>
              </div>
            <% end %>
          <% end %>
        </div>
      <% end %>

      <!-- Filter Row (FA-011: Floating Filter support) -->
      <%= if show_filter_row?(@grid) do %>
        <div class={"lv-grid__filter-row #{if @grid.options[:floating_filter], do: "lv-grid__filter-row--floating"}"}>
          <div class="lv-grid__filter-cell" style="width: 90px; flex: 0 0 90px;">
          </div>

          <%= if @grid.options.show_row_number do %>
            <div class="lv-grid__filter-cell" style="width: 50px; flex: 0 0 50px;">
            </div>
          <% end %>

          <%= if @grid.state.show_status_column do %>
            <div class="lv-grid__filter-cell" style="width: 60px; flex: 0 0 60px;">
            </div>
          <% end %>

          <%= for {column, col_idx} <- Enum.with_index(Grid.display_columns(@grid)) do %>
            <div class={"lv-grid__filter-cell #{frozen_class(col_idx, @grid)}"} style={"#{column_width_style(column, @grid)}; #{frozen_style(col_idx, @grid)}"} data-col-index={col_idx}>
              <%= if column.filterable && Map.get(column, :floating_filter, true) do %>
                <%= cond do %>
                  <% column.filter_type == :date -> %>
                    <div class="lv-grid__date-filter">
                      <form phx-change="grid_filter_date_preset" phx-target={@myself} style="display: contents;">
                        <input type="hidden" name="field" value={column.field} />
                        <select name="preset" class="lv-grid__filter-input lv-grid__filter-input--preset">
                          <option value="">기간 선택</option>
                          <option value="today">오늘</option>
                          <option value="yesterday">어제</option>
                          <option value="this_week">이번 주</option>
                          <option value="last_week">지난 주</option>
                          <option value="this_month">이번 달</option>
                          <option value="last_month">지난 달</option>
                          <option value="last_30_days">최근 30일</option>
                          <option value="last_90_days">최근 90일</option>
                        </select>
                      </form>
                      <form phx-change="grid_filter_date" phx-target={@myself} style="display: contents;">
                        <input type="hidden" name="field" value={column.field} />
                        <input type="hidden" name="part" value="from" />
                        <input
                          type="date"
                          name="value"
                          class="lv-grid__filter-input lv-grid__filter-input--date"
                          value={parse_date_part(Map.get(@grid.state.filters, column.field, ""), :from)}
                        />
                      </form>
                      <span class="lv-grid__date-filter-sep">~</span>
                      <form phx-change="grid_filter_date" phx-target={@myself} style="display: contents;">
                        <input type="hidden" name="field" value={column.field} />
                        <input type="hidden" name="part" value="to" />
                        <input
                          type="date"
                          name="value"
                          class="lv-grid__filter-input lv-grid__filter-input--date"
                          value={parse_date_part(Map.get(@grid.state.filters, column.field, ""), :to)}
                        />
                      </form>
                    </div>
                  <% column.filter_type == :set -> %>
                    <div class="lv-grid__set-filter">
                      <button
                        class={"lv-grid__set-filter-btn #{if Map.get(@grid.state.filters, column.field), do: "lv-grid__set-filter-btn--active"}"}
                        phx-click="toggle_set_filter"
                        phx-value-field={column.field}
                        phx-target={@myself}
                      >
                        <%= set_filter_label(column, @grid) %>
                        <span class="lv-grid__set-filter-arrow">▼</span>
                      </button>
                    </div>
                  <% column.filter_type == :number -> %>
                    <input
                      type="number"
                      class="lv-grid__filter-input lv-grid__filter-input--number"
                      placeholder={filter_placeholder(column)}
                      value={Map.get(@grid.state.filters, column.field, "")}
                      phx-keyup="grid_filter"
                      phx-value-field={column.field}
                      phx-debounce="300"
                      phx-target={@myself}
                    />
                  <% true -> %>
                    <input
                      type="text"
                      class="lv-grid__filter-input"
                      placeholder={filter_placeholder(column)}
                      value={Map.get(@grid.state.filters, column.field, "")}
                      phx-keyup="grid_filter"
                      phx-value-field={column.field}
                      phx-debounce="300"
                      phx-target={@myself}
                    />
                <% end %>
              <% end %>
            </div>
          <% end %>

          <%= if map_size(@grid.state.filters) > 0 do %>
            <button
              class="lv-grid__filter-clear"
              phx-click="grid_clear_filters"
              phx-target={@myself}
              title="필터 초기화"
            >
              ✕
            </button>
          <% end %>
        </div>
      <% end %>

      <!-- FA-012: Set Filter Dropdown -->
      <%= if @grid.state[:set_filter_open] do %>
        <% sf_field = @grid.state.set_filter_open %>
        <% unique_vals = LiveViewGrid.Filter.extract_unique_values(@grid.data, sf_field) %>
        <% selected_vals = get_set_filter_values(@grid, sf_field) %>
        <div class="lv-grid__set-filter-dropdown"
             phx-click-away="close_set_filter"
             phx-target={@myself}>
          <div class="lv-grid__set-filter-header">
            <span>필터: <%= sf_field %></span>
            <button class="lv-grid__set-filter-close" phx-click="close_set_filter" phx-target={@myself}>✕</button>
          </div>
          <div class="lv-grid__set-filter-actions">
            <button phx-click="set_filter_select_all" phx-value-field={sf_field} phx-target={@myself}>전체 선택</button>
            <button phx-click="set_filter_deselect_all" phx-value-field={sf_field} phx-target={@myself}>전체 해제</button>
          </div>
          <div class="lv-grid__set-filter-list">
            <%= for val <- unique_vals do %>
              <label class="lv-grid__set-filter-item">
                <input
                  type="checkbox"
                  checked={val in selected_vals}
                  phx-click="set_filter_toggle"
                  phx-value-field={sf_field}
                  phx-value-value={val}
                  phx-target={@myself}
                />
                <span><%= val %></span>
              </label>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Advanced Filter Panel (F-310) -->
      <%= if @grid.state.show_advanced_filter do %>
        <div class="lv-grid__advanced-filter">
          <div class="lv-grid__advanced-filter-header">
            <span>고급 필터</span>
            <div style="display: flex; align-items: center; gap: 8px;">
              <div class="lv-grid__advanced-filter-logic">
                <button
                  class={"lv-grid__advanced-filter-logic-btn #{if @grid.state.advanced_filters.logic == :and, do: "lv-grid__advanced-filter-logic-btn--active"}"}
                  phx-click="change_filter_logic"
                  phx-value-logic="and"
                  phx-target={@myself}
                >AND</button>
                <button
                  class={"lv-grid__advanced-filter-logic-btn #{if @grid.state.advanced_filters.logic == :or, do: "lv-grid__advanced-filter-logic-btn--active"}"}
                  phx-click="change_filter_logic"
                  phx-value-logic="or"
                  phx-target={@myself}
                >OR</button>
              </div>
              <button
                class="lv-grid__filter-condition-remove"
                phx-click="toggle_advanced_filter"
                phx-target={@myself}
                title="닫기"
              >✕</button>
            </div>
          </div>

          <%= for {condition, idx} <- Enum.with_index(@grid.state.advanced_filters.conditions) do %>
            <div class="lv-grid__filter-condition">
              <form phx-change="update_filter_condition" phx-submit="noop_submit" phx-target={@myself} style="display: contents;">
              <input type="hidden" name="index" value={idx} />
              <select name="field">
                <option value="">컬럼 선택</option>
                <%= for col <- @grid.columns do %>
                  <option value={col.field} selected={condition.field == col.field}><%= col.label %></option>
                <% end %>
              </select>

              <select name="operator">
                <%= if condition.field != nil do %>
                  <% filter_type = get_column_filter_type(@grid.columns, condition.field) %>
                  <%= if filter_type == :number do %>
                    <option value="eq" selected={condition.operator == :eq}>= 같음</option>
                    <option value="neq" selected={condition.operator == :neq}>≠ 다름</option>
                    <option value="gt" selected={condition.operator == :gt}>&gt; 큼</option>
                    <option value="lt" selected={condition.operator == :lt}>&lt; 작음</option>
                    <option value="gte" selected={condition.operator == :gte}>≥ 크거나같음</option>
                    <option value="lte" selected={condition.operator == :lte}>≤ 작거나같음</option>
                  <% else %>
                    <%= if filter_type == :date do %>
                      <option value="eq" selected={condition.operator == :eq}>= 같은 날</option>
                      <option value="before" selected={condition.operator == :before}>이전</option>
                      <option value="after" selected={condition.operator == :after}>이후</option>
                      <option value="between" selected={condition.operator == :between}>사이</option>
                      <option value="is_empty" selected={condition.operator == :is_empty}>비어있음</option>
                      <option value="is_not_empty" selected={condition.operator == :is_not_empty}>비어있지않음</option>
                    <% else %>
                      <option value="contains" selected={condition.operator == :contains}>포함</option>
                      <option value="equals" selected={condition.operator == :equals}>같음</option>
                      <option value="starts_with" selected={condition.operator == :starts_with}>시작</option>
                      <option value="ends_with" selected={condition.operator == :ends_with}>끝남</option>
                      <option value="is_empty" selected={condition.operator == :is_empty}>비어있음</option>
                      <option value="is_not_empty" selected={condition.operator == :is_not_empty}>비어있지않음</option>
                    <% end %>
                  <% end %>
                <% else %>
                  <option value="">연산자</option>
                <% end %>
              </select>

              <%= if condition.operator not in [:is_empty, :is_not_empty] do %>
                <% adv_filter_type = if condition.field, do: get_column_filter_type(@grid.columns, condition.field), else: :text %>
                <%= if adv_filter_type == :date and condition.operator == :between do %>
                  <div class="lv-grid__date-filter" style="flex: 1;">
                    <input
                      type="date"
                      class="lv-grid__filter-condition-value lv-grid__filter-input--date"
                      value={parse_date_part(condition.value || "", :from)}
                      name="value"
                      phx-debounce="300"
                    />
                    <span class="lv-grid__date-filter-sep">~</span>
                    <input
                      type="date"
                      class="lv-grid__filter-condition-value lv-grid__filter-input--date"
                      value={parse_date_part(condition.value || "", :to)}
                      name="value_to"
                      phx-debounce="300"
                    />
                  </div>
                <% else %>
                  <input
                    type={if adv_filter_type == :date, do: "date", else: "text"}
                    class="lv-grid__filter-condition-value"
                    placeholder={if adv_filter_type == :date, do: "날짜 선택", else: "값 입력..."}
                    value={condition.value}
                    name="value"
                    phx-debounce="300"
                  />
                <% end %>
              <% end %>
              </form>

              <button
                class="lv-grid__filter-condition-remove"
                phx-click="remove_filter_condition"
                phx-value-index={idx}
                phx-target={@myself}
                title="조건 삭제"
              >✕</button>
            </div>
          <% end %>

          <div class="lv-grid__advanced-filter-actions">
            <button
              class="lv-grid__filter-add-btn"
              phx-click="add_filter_condition"
              phx-target={@myself}
            >+ 조건 추가</button>
            <div style="display: flex; gap: 8px;">
              <button
                class="lv-grid__filter-reset-btn"
                phx-click="clear_advanced_filter"
                phx-target={@myself}
              >초기화</button>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- FA-001: Pinned Top Rows --%>
      <% pinned_top = Grid.pinned_top_rows(@grid) %>
      <%= if pinned_top != [] do %>
        <div class="lv-grid__pinned-rows lv-grid__pinned-rows--top">
          <%= for row <- pinned_top do %>
            <div class={"lv-grid__row lv-grid__row--pinned lv-grid__row--pinned-top #{if row.id in @grid.state.selection.selected_ids, do: "lv-grid__row--selected"}"} data-row-id={row.id}>
              <div class="lv-grid__cell lv-grid__cell--row-actions" style="width: 90px; flex: 0 0 90px; justify-content: center; gap: 4px;">
                <span class="lv-grid__pin-icon" title="상단 고정됨">&#x1F4CC;</span>
                <button
                  class="lv-grid__unpin-btn"
                  phx-click="grid_unpin_row"
                  phx-value-row-id={row.id}
                  phx-target={@myself}
                  title="고정 해제"
                >&#x2715;</button>
              </div>
              <%= if @grid.options.show_row_number do %>
                <div class="lv-grid__cell lv-grid__cell--row-number" style="width: 50px; flex: 0 0 50px; justify-content: center;">
                  -
                </div>
              <% end %>
              <%= if @grid.state.show_status_column do %>
                <div class="lv-grid__cell lv-grid__cell--status" style="width: 60px; flex: 0 0 60px; justify-content: center;">
                </div>
              <% end %>
              <%= for {column, col_idx} <- Enum.with_index(Grid.display_columns(@grid)) do %>
                <div
                  class={"lv-grid__cell #{if column.align == :right, do: "lv-grid__cell--right"} #{if column.align == :center, do: "lv-grid__cell--center"} #{frozen_class(col_idx, @grid)}"}
                  style={"#{column_width_style(column, @grid)}; #{frozen_style(col_idx, @grid)}"}
                  data-col-index={col_idx}
                >
                  <span class="lv-grid__cell-value"><%= Map.get(row, column.field) %></span>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>

      <%!-- FA-005: Overlay System --%>
      <%= if @grid.state.overlay do %>
        <div class={"lv-grid__overlay lv-grid__overlay--#{@grid.state.overlay.type}"}>
          <%= case @grid.state.overlay.type do %>
            <% :loading -> %>
              <div class="lv-grid__overlay-content">
                <div class="lv-grid__overlay-spinner"></div>
                <span class="lv-grid__overlay-text"><%= @grid.state.overlay.message || "데이터를 불러오는 중..." %></span>
              </div>
            <% :no_data -> %>
              <div class="lv-grid__overlay-content">
                <span class="lv-grid__overlay-icon">&#x1F4ED;</span>
                <span class="lv-grid__overlay-text"><%= @grid.state.overlay.message || "표시할 데이터가 없습니다" %></span>
              </div>
            <% :error -> %>
              <div class="lv-grid__overlay-content lv-grid__overlay-content--error">
                <span class="lv-grid__overlay-icon">&#x26A0;</span>
                <span class="lv-grid__overlay-text"><%= @grid.state.overlay.message || "오류가 발생했습니다" %></span>
              </div>
          <% end %>
        </div>
      <% end %>

      <!-- Body -->
      <%= if @grid.options.virtual_scroll do %>
        <!-- Virtual Scroll Body -->
        <div
          class="lv-grid__body lv-grid__body--virtual"
          id={"#{@grid.id}-virtual-body"}
          phx-hook="VirtualScroll"
          data-row-height={@grid.options.row_height}
          style="height: 600px;"
        >
          <div style={"height: #{length(@grid.data) * @grid.options.row_height}px; position: relative;"}>
            <div style={"position: absolute; top: #{Grid.virtual_offset_top(@grid)}px; width: 100%;"}>
              <% v_data = Grid.visible_data(@grid) %>
              <% v_row_id_to_pos = v_data |> Enum.with_index() |> Enum.map(fn {r, i} -> {r.id, i} end) |> Map.new() %>
              <%= for row <- v_data do %>
                <div class={"lv-grid__row #{if row.id in @grid.state.selection.selected_ids, do: "lv-grid__row--selected"} #{if Map.get(@grid.state.row_statuses, row.id) == :deleted, do: "lv-grid__row--deleted"} #{if @grid.state.editing_row == row.id, do: "lv-grid__row--editing"}"} data-row-id={row.id}>
                  <%= if @grid.state.editing_row == row.id do %>
                    <div class="lv-grid__cell lv-grid__cell--row-actions" style="width: 90px; flex: 0 0 90px; justify-content: center; gap: 4px;">
                      <button
                        class="lv-grid__row-edit-save"
                        id={"row-save-#{row.id}"}
                        phx-hook="RowEditSave"
                        data-row-id={row.id}
                        phx-target={@myself}
                        title="행 저장"
                      >&#10003;</button>
                      <button
                        class="lv-grid__row-edit-cancel"
                        phx-click="row_edit_cancel"
                        phx-value-row-id={row.id}
                        phx-target={@myself}
                        title="행 취소"
                      >&#10005;</button>
                    </div>
                  <% else %>
                    <div class="lv-grid__cell" style="width: 90px; flex: 0 0 90px; justify-content: center; gap: 4px;">
                      <input
                        type="checkbox"
                        phx-click="grid_row_select"
                        phx-value-row-id={row.id}
                        phx-target={@myself}
                        checked={row.id in @grid.state.selection.selected_ids}
                        style="width: 18px; height: 18px; cursor: pointer;"
                      />
                      <%= if has_editable_columns?(@grid.columns) do %>
                        <button
                          class="lv-grid__row-edit-btn"
                          phx-click="row_edit_start"
                          phx-value-row-id={row.id}
                          phx-target={@myself}
                          title="행 편집"
                        >&#9998;</button>
                      <% end %>
                    </div>
                  <% end %>
                  <%= if @grid.options.show_row_number do %>
                    <div class="lv-grid__cell lv-grid__cell--row-number" style="width: 50px; flex: 0 0 50px; justify-content: center;">
                      <%= Map.get(row, :_virtual_index, 0) + 1 %>
                    </div>
                  <% end %>
                  <%= if @grid.state.show_status_column do %>
                    <div class="lv-grid__cell lv-grid__cell--status" style="width: 60px; flex: 0 0 60px; justify-content: center;">
                      <%= render_status_badge(Map.get(@grid.state.row_statuses, row.id, :normal)) %>
                    </div>
                  <% end %>
                  <%= for {column, col_idx} <- Enum.with_index(Grid.display_columns(@grid)) do %>
                    <div class={"lv-grid__cell #{frozen_class(col_idx, @grid)} #{if cell_in_range?(@grid.state.cell_range, row.id, col_idx, v_row_id_to_pos), do: "lv-grid__cell--in-range"} #{if Map.get(column, :filter_type) == :number, do: "lv-grid__cell--numeric"}"} style={"#{column_width_style(column, @grid)}; #{frozen_style(col_idx, @grid)}"} data-col-index={col_idx}>
                      <%= render_cell(assigns, row, column) %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% else %>
        <!-- 기본 Body (페이징 방식) -->
        <div class={"lv-grid__body #{if Map.get(@grid.options, :autofit_type) == :row, do: "lv-grid__body--autofit"}"}>
          <% p_data = Grid.visible_data(@grid) %>
          <% p_row_id_to_pos = p_data |> Enum.with_index() |> Enum.map(fn {r, i} -> {Map.get(r, :id), i} end) |> Enum.reject(fn {k, _} -> is_nil(k) end) |> Map.new() %>
          <% merge_skip_map = Grid.build_merge_skip_map(@grid) %>
          <% merge_regions = @grid.state.merge_regions %>
          <% suppress_map = build_suppress_map(p_data, @grid.columns) %>
          <%= for {row, row_num} <- with_row_numbers(p_data, row_number_offset(@grid)) do %>
            <%= if Map.get(row, :_row_type) == :group_header do %>
              <!-- Group Header Row -->
              <div class={"lv-grid__row lv-grid__row--group-header lv-grid__row--group-depth-#{row._group_depth}"}>
                <div class="lv-grid__cell lv-grid__group-header-cell" style={"padding-left: #{16 + row._group_depth * 24}px;"}>
                  <button
                    class="lv-grid__tree-toggle"
                    phx-click="grid_toggle_group"
                    phx-value-group-key={row._group_key}
                    phx-target={@myself}
                  >
                    <%= if row._group_expanded, do: "▼", else: "▶" %>
                  </button>
                  <span class="lv-grid__group-label">
                    <%= row._group_value %>
                  </span>
                  <span class="lv-grid__group-count">(<%= row._group_count %>)</span>
                  <%= if map_size(row._group_aggregates) > 0 do %>
                    <span class="lv-grid__group-aggregates">
                      <%= for {field, value} <- row._group_aggregates do %>
                        <span class="lv-grid__group-agg-item">
                          <%= field %>: <%= format_agg_value(value) %>
                        </span>
                      <% end %>
                    </span>
                  <% end %>
                </div>
              </div>
            <% else %>
              <!-- Data Row (normal / tree) -->
              <% per_row_h = Map.get(@grid.state.row_heights, Map.get(row, :id)) %>
              <div
                class={"lv-grid__row #{if Map.get(row, :id) in @grid.state.selection.selected_ids, do: "lv-grid__row--selected"} #{if Map.get(@grid.state.row_statuses, Map.get(row, :id)) == :deleted, do: "lv-grid__row--deleted"} #{if @grid.state.editing_row == Map.get(row, :id), do: "lv-grid__row--editing"}"}
                style={if per_row_h, do: "min-height: #{per_row_h}px;"}
                data-row-id={Map.get(row, :id)}
                id={if Map.get(@grid.options, :row_reorder), do: "row-reorder-#{Map.get(row, :id)}"}
                phx-hook={if Map.get(@grid.options, :row_reorder), do: "RowReorder"}
                phx-target={if Map.get(@grid.options, :row_reorder), do: @myself}
              >
                <%= if @grid.state.editing_row == row.id do %>
                  <div class="lv-grid__cell lv-grid__cell--row-actions" style="width: 90px; flex: 0 0 90px; justify-content: center; gap: 4px;">
                    <button
                      class="lv-grid__row-edit-save"
                      id={"row-save-#{row.id}"}
                      phx-hook="RowEditSave"
                      data-row-id={row.id}
                      phx-target={@myself}
                      title="행 저장"
                    >&#10003;</button>
                    <button
                      class="lv-grid__row-edit-cancel"
                      phx-click="row_edit_cancel"
                      phx-value-row-id={row.id}
                      phx-target={@myself}
                      title="행 취소"
                    >&#10005;</button>
                  </div>
                <% else %>
                  <div class="lv-grid__cell" style="width: 90px; flex: 0 0 90px; justify-content: center; gap: 4px;">
                    <input
                      type="checkbox"
                      phx-click="grid_row_select"
                      phx-value-row-id={row.id}
                      phx-target={@myself}
                      checked={row.id in @grid.state.selection.selected_ids}
                      style="width: 18px; height: 18px; cursor: pointer;"
                    />
                    <%= if has_editable_columns?(@grid.columns) do %>
                      <button
                        class="lv-grid__row-edit-btn"
                        phx-click="row_edit_start"
                        phx-value-row-id={row.id}
                        phx-target={@myself}
                        title="행 편집"
                      >&#9998;</button>
                    <% end %>
                    <%= if Map.get(@grid.options, :row_reorder) do %>
                      <span class="lv-grid__row-drag-handle" title="드래그하여 행 이동">&#9776;</span>
                    <% end %>
                  </div>
                <% end %>
                <%= if @grid.options.show_row_number do %>
                  <div class="lv-grid__cell lv-grid__cell--row-number" style="width: 50px; flex: 0 0 50px; justify-content: center;">
                    <%= row_num %>
                  </div>
                <% end %>
                <%= if @grid.state.show_status_column do %>
                  <div class="lv-grid__cell lv-grid__cell--status" style="width: 60px; flex: 0 0 60px; justify-content: center;">
                    <%= render_status_badge(Map.get(@grid.state.row_statuses, row.id, :normal)) %>
                  </div>
                <% end %>
                <%= for {column, col_idx} <- Enum.with_index(Grid.display_columns(@grid)) do %>
                  <%= if not merge_skip?(merge_skip_map, row.id, column.field) do %>
                    <% span = merge_span(merge_regions, row.id, column.field) %>
                    <% {rs, cs} = if span, do: span, else: {1, 1} %>
                    <% m_width = if cs > 1, do: merged_width_style(@grid, column.field, cs), else: column_width_style(column, @grid) %>
                    <% m_height = if rs > 1, do: merged_height_style(@grid, rs), else: nil %>
                    <% is_suppressed = suppressed?(suppress_map, row.id, column.field) %>
                    <div class={"lv-grid__cell #{frozen_class(col_idx, @grid)} #{wordwrap_class(column)} #{if cell_in_range?(@grid.state.cell_range, row.id, col_idx, p_row_id_to_pos), do: "lv-grid__cell--in-range"} #{if Map.get(column, :filter_type) == :number, do: "lv-grid__cell--numeric"} #{if span, do: "lv-grid__cell--merged"} #{if is_suppressed, do: "lv-grid__cell--suppressed"}"} style={"#{m_width}; #{frozen_style(col_idx, @grid)}; #{tree_indent_style(row, col_idx)}; #{m_height || ""}"} data-col-index={col_idx}>
                      <%= if col_idx == 0 && Map.has_key?(row, :_tree_has_children) do %>
                        <%= if row._tree_has_children do %>
                          <button
                            class="lv-grid__tree-toggle"
                            phx-click="grid_toggle_tree_node"
                            phx-value-node-id={row.id}
                            phx-target={@myself}
                          >
                            <%= if row._tree_expanded, do: "▼", else: "▶" %>
                          </button>
                        <% else %>
                          <span class="lv-grid__tree-spacer"></span>
                        <% end %>
                      <% end %>
                      <%= unless is_suppressed do %><%= render_cell(assigns, row, column) %><% end %>
                    </div>
                  <% end %>
                <% end %>
              </div>
            <% end %>
          <% end %>
        </div>
      <% end %>

      <%!-- FA-001: Pinned Bottom Rows --%>
      <% pinned_bottom = Grid.pinned_bottom_rows(@grid) %>
      <%= if pinned_bottom != [] do %>
        <div class="lv-grid__pinned-rows lv-grid__pinned-rows--bottom">
          <%= for row <- pinned_bottom do %>
            <div class={"lv-grid__row lv-grid__row--pinned lv-grid__row--pinned-bottom #{if row.id in @grid.state.selection.selected_ids, do: "lv-grid__row--selected"}"} data-row-id={row.id}>
              <div class="lv-grid__cell lv-grid__cell--row-actions" style="width: 90px; flex: 0 0 90px; justify-content: center; gap: 4px;">
                <span class="lv-grid__pin-icon" title="하단 고정됨">&#x1F4CC;</span>
                <button
                  class="lv-grid__unpin-btn"
                  phx-click="grid_unpin_row"
                  phx-value-row-id={row.id}
                  phx-target={@myself}
                  title="고정 해제"
                >&#x2715;</button>
              </div>
              <%= if @grid.options.show_row_number do %>
                <div class="lv-grid__cell lv-grid__cell--row-number" style="width: 50px; flex: 0 0 50px; justify-content: center;">
                  -
                </div>
              <% end %>
              <%= if @grid.state.show_status_column do %>
                <div class="lv-grid__cell lv-grid__cell--status" style="width: 60px; flex: 0 0 60px; justify-content: center;">
                </div>
              <% end %>
              <%= for {column, col_idx} <- Enum.with_index(Grid.display_columns(@grid)) do %>
                <div
                  class={"lv-grid__cell #{if column.align == :right, do: "lv-grid__cell--right"} #{if column.align == :center, do: "lv-grid__cell--center"} #{frozen_class(col_idx, @grid)}"}
                  style={"#{column_width_style(column, @grid)}; #{frozen_style(col_idx, @grid)}"}
                  data-col-index={col_idx}
                >
                  <span class="lv-grid__cell-value"><%= Map.get(row, column.field) %></span>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- 디버깅 -->
      <%= if @grid.options.debug do %>
        <div style="padding: 10px; background: #fff9c4; border: 1px solid #fbc02d; margin: 10px 0; font-size: 12px;">
          전체 데이터 <%= length(@grid.data) %>개 |
          화면 표시 <%= length(Grid.visible_data(@grid)) %>개 |
          현재 페이지 <%= @grid.state.pagination.current_page %> |
          페이지 크기 <%= @grid.options.page_size %> |
          Virtual Scroll <%= if @grid.options.virtual_scroll, do: "ON (offset: #{@grid.state.scroll_offset})", else: "OFF" %>
        </div>
      <% end %>

      <%!-- F-950: Summary Row --%>
      <%= if has_summary?(@grid) do %>
        <div class="lv-grid__summary-row">
          <% summary = Grid.summary_data(@grid) %>
          <% display_cols = Grid.display_columns(@grid) %>

          <%!-- 행번호 컬럼 --%>
          <%= if @grid.options.show_row_number do %>
            <div class="lv-grid__cell lv-grid__cell--row-number lv-grid__summary-cell" style="width: 50px; flex: 0 0 50px;">
            </div>
          <% end %>

          <%!-- 선택 체크박스 컬럼 --%>
          <div class="lv-grid__cell lv-grid__summary-cell" style="width: 90px; flex: 0 0 90px;">
          </div>

          <%!-- 데이터 컬럼 --%>
          <%= for col <- display_cols do %>
            <% width = Map.get(@grid.state.column_widths, col.field) %>
            <% value = Map.get(summary, col.field) %>
            <div
              class={"lv-grid__cell lv-grid__summary-cell #{if col.align == :right, do: "lv-grid__cell--right"} #{if col.align == :center, do: "lv-grid__cell--center"}"}
              style={if width, do: "width: #{width}px; flex: 0 0 #{width}px;", else: "flex: 1 1 0;"}
            >
              <%= if value do %>
                <span class="lv-grid__summary-value"><%= format_summary_number(value) %></span>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>

      <%!-- FA-004: Status Bar --%>
      <%= if Map.get(@grid.options, :show_status_bar, false) do %>
        <div class="lv-grid__status-bar">
          <span class="lv-grid__status-bar-item">
            총 <strong><%= @grid.state.pagination.total_rows %></strong>행
          </span>
          <%= if length(@grid.state.selection.selected_ids) > 0 do %>
            <span class="lv-grid__status-bar-separator">|</span>
            <span class="lv-grid__status-bar-item lv-grid__status-bar-item--selected">
              <strong><%= length(@grid.state.selection.selected_ids) %></strong>개 선택
            </span>
          <% end %>
          <%= if @grid.state.global_search != "" or map_size(@grid.state.filters) > 0 do %>
            <span class="lv-grid__status-bar-separator">|</span>
            <span class="lv-grid__status-bar-item lv-grid__status-bar-item--filtered">
              &#x1F50D; <strong><%= Grid.filtered_count(@grid) %></strong>건 필터됨
            </span>
          <% end %>
          <%= if map_size(@grid.state.row_statuses) > 0 do %>
            <span class="lv-grid__status-bar-separator">|</span>
            <span class="lv-grid__status-bar-item lv-grid__status-bar-item--changed">
              &#x270F; <strong><%= map_size(@grid.state.row_statuses) %></strong>건 변경
            </span>
          <% end %>
          <%= if length(@grid.state.pinned_top_ids) + length(@grid.state.pinned_bottom_ids) > 0 do %>
            <span class="lv-grid__status-bar-separator">|</span>
            <span class="lv-grid__status-bar-item">
              &#x1F4CC; <strong><%= length(@grid.state.pinned_top_ids) + length(@grid.state.pinned_bottom_ids) %></strong>행 고정
            </span>
          <% end %>
        </div>
      <% end %>

      <!-- Footer -->
      <%= if @grid.options.show_footer do %>
        <div class="lv-grid__footer" style="flex-direction: column; align-items: center; gap: 8px;">
          <%= if !@grid.options.virtual_scroll do %>
            <div style="display: flex; align-items: center; gap: 12px; width: 100%; justify-content: center;">
              <div style="display: flex; align-items: center; gap: 4px; font-size: 12px; color: var(--lv-grid-text-secondary, #666);">
                <select
                  phx-change="grid_page_size_change"
                  phx-target={@myself}
                  name="page_size"
                  style="padding: 2px 6px; border: 1px solid var(--lv-grid-border, #ddd); border-radius: 4px; font-size: 12px; background: var(--lv-grid-bg, #fff); color: var(--lv-grid-text, #333); cursor: pointer;"
                >
                  <%= for size <- [50, 100, 200, 300, 400, 500] do %>
                    <option value={size} selected={size == @grid.options.page_size}><%= size %>개</option>
                  <% end %>
                </select>
              </div>

              <div class="lv-grid__pagination">
                <button
                  class="lv-grid__page-btn"
                  phx-click="grid_page_change"
                  phx-value-page={@grid.state.pagination.current_page - 1}
                  phx-target={@myself}
                  disabled={@grid.state.pagination.current_page == 1}
                >
                  &lt;
                </button>

                <% filtered_total = Grid.filtered_count(@grid) %>
                <%= for page <- page_range_for(filtered_total, @grid.state.pagination.current_page, @grid.options.page_size) do %>
                  <button
                    class={"lv-grid__page-btn #{if page == @grid.state.pagination.current_page, do: "lv-grid__page-btn--current"}"}
                    phx-click="grid_page_change"
                    phx-value-page={page}
                    phx-target={@myself}
                  >
                    <%= page %>
                  </button>
                <% end %>

                <button
                  class="lv-grid__page-btn"
                  phx-click="grid_page_change"
                  phx-value-page={@grid.state.pagination.current_page + 1}
                  phx-target={@myself}
                  disabled={@grid.state.pagination.current_page >= Pagination.total_pages(filtered_total, @grid.options.page_size)}
                >
                  &gt;
                </button>
              </div>
            </div>
          <% end %>

          <div class="lv-grid__info">
            <%!-- F-941: Cell Range Summary --%>
            <%= if (range_summary = Grid.cell_range_summary(@grid)) do %>
              <div class="lv-grid__range-summary">
                <span class="lv-grid__range-summary-label">선택 영역:</span>
                <span class="lv-grid__range-summary-item">
                  Count: <strong><%= range_summary.count %></strong>
                </span>
                <%= if range_summary.numeric_count > 0 do %>
                  <span class="lv-grid__range-summary-item">
                    Sum: <strong><%= format_summary_number(range_summary.sum) %></strong>
                  </span>
                  <span class="lv-grid__range-summary-item">
                    Avg: <strong><%= format_summary_number(range_summary.avg) %></strong>
                  </span>
                  <span class="lv-grid__range-summary-item">
                    Min: <strong><%= format_summary_number(range_summary.min) %></strong>
                  </span>
                  <span class="lv-grid__range-summary-item">
                    Max: <strong><%= format_summary_number(range_summary.max) %></strong>
                  </span>
                <% end %>
              </div>
              <span style="margin: 0 8px; color: #ccc;">|</span>
            <% end %>
            <%= if length(@grid.state.selection.selected_ids) > 0 do %>
              <span style="color: #2196f3; font-weight: 600;">
                <%= length(@grid.state.selection.selected_ids) %>개 선택됨
              </span>
              <span style="margin: 0 8px; color: #ccc;">|</span>
            <% end %>
            <%= if @grid.state.global_search != "" or map_size(@grid.state.filters) > 0 do %>
              <span style="color: #ff9800; font-weight: 600;">
                <%= Grid.filtered_count(@grid) %>개 검색됨
              </span>
              <span style="margin: 0 4px; color: #ccc;">/</span>
            <% end %>
            총 <%= @grid.state.pagination.total_rows %>개
            <%= if map_size(@grid.state.row_statuses) > 0 do %>
              <span style="margin: 0 8px; color: #ccc;">|</span>
              <span style="color: #ff9800; font-weight: 600;">
                <%= map_size(@grid.state.row_statuses) %>개 변경됨
              </span>
            <% end %>
          </div>

          <!-- Import 버튼 (F-511) -->
          <div class="lv-grid__export" style="margin-right: 8px;">
            <div
              class="lv-grid__export-btn lv-grid__export-btn--import"
              id={"import-btn-#{@grid.id}"}
              phx-hook="FileImport"
              style="cursor: pointer;"
            >
              📥 Import
            </div>
          </div>

          <!-- Export 버튼 -->
          <div class="lv-grid__export">
            <div style="position: relative;">
              <button
                class="lv-grid__export-btn lv-grid__export-btn--excel"
                phx-click="toggle_export_menu"
                phx-value-format="excel"
                phx-target={@myself}
              >
                📊 Excel
              </button>
              <%= if @export_menu_open == "excel" do %>
                <div class="lv-grid__export-dropdown">
                  <div class="lv-grid__export-dropdown-item" phx-click="export_excel" phx-value-type="all" phx-target={@myself}>
                    전체 데이터 (<%= @grid.state.pagination.total_rows %>개)
                  </div>
                  <%= if @grid.state.global_search != "" or map_size(@grid.state.filters) > 0 do %>
                    <div class="lv-grid__export-dropdown-item" phx-click="export_excel" phx-value-type="filtered" phx-target={@myself}>
                      필터 결과 (<%= Grid.filtered_count(@grid) %>개)
                    </div>
                  <% end %>
                  <%= if length(@grid.state.selection.selected_ids) > 0 do %>
                    <div class="lv-grid__export-dropdown-item" phx-click="export_excel" phx-value-type="selected" phx-target={@myself}>
                      선택된 행 (<%= length(@grid.state.selection.selected_ids) %>개)
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>

            <div style="position: relative;">
              <button
                class="lv-grid__export-btn lv-grid__export-btn--csv"
                phx-click="toggle_export_menu"
                phx-value-format="csv"
                phx-target={@myself}
              >
                📄 CSV
              </button>
              <%= if @export_menu_open == "csv" do %>
                <div class="lv-grid__export-dropdown">
                  <div class="lv-grid__export-dropdown-item" phx-click="export_csv" phx-value-type="all" phx-target={@myself}>
                    전체 데이터 (<%= @grid.state.pagination.total_rows %>개)
                  </div>
                  <%= if @grid.state.global_search != "" or map_size(@grid.state.filters) > 0 do %>
                    <div class="lv-grid__export-dropdown-item" phx-click="export_csv" phx-value-type="filtered" phx-target={@myself}>
                      필터 결과 (<%= Grid.filtered_count(@grid) %>개)
                    </div>
                  <% end %>
                  <%= if length(@grid.state.selection.selected_ids) > 0 do %>
                    <div class="lv-grid__export-dropdown-item" phx-click="export_csv" phx-value-type="selected" phx-target={@myself}>
                      선택된 행 (<%= length(@grid.state.selection.selected_ids) %>개)
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
      <%!-- F-800: Context Menu --%>
      <%= if @context_menu do %>
        <div
          class="lv-grid__context-menu"
          style={"position:fixed;left:#{@context_menu.x}px;top:#{@context_menu.y}px;z-index:9999;"}
          phx-click-away="hide_context_menu"
          phx-target={@myself}
        >
          <div class="lv-grid__context-menu-item" phx-click="context_menu_action" phx-value-action="copy_cell" phx-value-row-id={@context_menu.row_id} phx-value-col-idx={@context_menu.col_idx} phx-target={@myself}>
            <span>📋</span> 셀 복사
          </div>
          <div class="lv-grid__context-menu-item" phx-click="context_menu_action" phx-value-action="copy_row" phx-value-row-id={@context_menu.row_id} phx-target={@myself}>
            <span>📄</span> 행 복사
          </div>
          <div class="lv-grid__context-menu-divider"></div>
          <div class="lv-grid__context-menu-item" phx-click="context_menu_action" phx-value-action="insert_row_above" phx-value-row-id={@context_menu.row_id} phx-target={@myself}>
            <span>⬆</span> 위에 행 추가
          </div>
          <div class="lv-grid__context-menu-item" phx-click="context_menu_action" phx-value-action="insert_row_below" phx-value-row-id={@context_menu.row_id} phx-target={@myself}>
            <span>⬇</span> 아래에 행 추가
          </div>
          <div class="lv-grid__context-menu-item" phx-click="context_menu_action" phx-value-action="duplicate_row" phx-value-row-id={@context_menu.row_id} phx-target={@myself}>
            <span>⧉</span> 행 복제
          </div>
          <div class="lv-grid__context-menu-divider"></div>
          <%!-- FA-001: Row Pinning 메뉴 --%>
          <%= case Grid.pinned?(@grid, @context_menu.row_id) do %>
            <% :top -> %>
              <div class="lv-grid__context-menu-item" phx-click="context_menu_action" phx-value-action="unpin_row" phx-value-row-id={@context_menu.row_id} phx-target={@myself}>
                <span>&#x1F4CC;</span> 고정 해제
              </div>
            <% :bottom -> %>
              <div class="lv-grid__context-menu-item" phx-click="context_menu_action" phx-value-action="unpin_row" phx-value-row-id={@context_menu.row_id} phx-target={@myself}>
                <span>&#x1F4CC;</span> 고정 해제
              </div>
            <% false -> %>
              <div class="lv-grid__context-menu-item" phx-click="context_menu_action" phx-value-action="pin_row_top" phx-value-row-id={@context_menu.row_id} phx-target={@myself}>
                <span>&#x2B06;</span> 상단 고정
              </div>
              <div class="lv-grid__context-menu-item" phx-click="context_menu_action" phx-value-action="pin_row_bottom" phx-value-row-id={@context_menu.row_id} phx-target={@myself}>
                <span>&#x2B07;</span> 하단 고정
              </div>
          <% end %>
          <div class="lv-grid__context-menu-divider"></div>
          <div class="lv-grid__context-menu-item lv-grid__context-menu-item--danger" phx-click="context_menu_action" phx-value-action="delete_row" phx-value-row-id={@context_menu.row_id} phx-target={@myself}>
            <span>🗑</span> 행 삭제
          </div>
        </div>
      <% end %>

      <!-- Config Modal -->
      <%= if @show_config_modal do %>
        <.live_component
          module={LiveViewGridWeb.Components.GridConfig.ConfigModal}
          id="grid_config_modal"
          grid={@grid}
          parent_target={@myself}
        />
      <% end %>

      <%!-- FA-002: State Persistence Hook --%>
      <%= if @grid.options[:state_persistence] do %>
        <div id={"#{@grid.id}-state-persistence"}
             phx-hook="StatePersistence"
             phx-target={@myself}
             data-grid-id={@grid.id}
             style="display:none">
        </div>
      <% end %>
    </div>
    """
  end
end
