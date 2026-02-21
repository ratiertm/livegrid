defmodule LiveviewGridWeb.GridComponent do
  @moduledoc """
  LiveView Grid 컴포넌트
  
  프로토타입 v0.1-alpha: 최소 기능만 구현
  """
  
  use Phoenix.LiveComponent
  
  alias LiveViewGrid.{Grid, Pagination}

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    new_options = Map.get(assigns, :options, %{})

    {grid, virtual_changed?} = if Map.has_key?(socket.assigns, :grid) do
      old_grid = socket.assigns.grid
      old_virtual = old_grid.options.virtual_scroll
      new_virtual = Map.get(new_options, :virtual_scroll, old_virtual)

      # 이후 업데이트: 기존 state(scroll_offset, sort, selection) 보존
      updated = Grid.update_data(
        old_grid,
        assigns.data,
        assigns.columns,
        new_options
      )

      # virtual_scroll 옵션이 변경되었으면 scroll_offset 리셋
      if old_virtual != new_virtual do
        {put_in(updated.state.scroll_offset, 0), true}
      else
        {updated, false}
      end
    else
      # 첫 마운트: 새 Grid 생성
      grid = Grid.new(
        data: assigns.data,
        columns: assigns.columns,
        options: new_options
      )
      {put_in(grid.state.pagination.total_rows, length(assigns.data)), false}
    end

    socket = assign(socket, grid: grid)

    # virtual scroll 전환 시 JS 스크롤 리셋
    socket = if virtual_changed? do
      push_event(socket, "reset_virtual_scroll", %{})
    else
      socket
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("grid_sort", %{"field" => field, "direction" => direction}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)
    direction_atom = String.to_atom(direction)

    # 정렬 상태 업데이트 + 스크롤 위치 리셋
    updated_grid = grid
      |> put_in([:state, :sort], %{field: field_atom, direction: direction_atom})
      |> put_in([:state, :scroll_offset], 0)

    {:noreply,
      socket
      |> assign(grid: updated_grid)
      |> push_event("reset_virtual_scroll", %{})
    }
  end

  @impl true
  def handle_event("grid_page_change", %{"page" => page}, socket) do
    grid = socket.assigns.grid
    page_num = String.to_integer(page)
    
    # 페이지 상태 업데이트
    updated_grid = put_in(grid.state.pagination.current_page, page_num)
    
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("grid_row_select", %{"row-id" => row_id}, socket) do
    grid = socket.assigns.grid
    id = String.to_integer(row_id)
    
    # 선택 토글
    selected_ids = grid.state.selection.selected_ids
    updated_ids = if id in selected_ids do
      List.delete(selected_ids, id)
    else
      [id | selected_ids]
    end
    
    updated_grid = put_in(grid.state.selection.selected_ids, updated_ids)
    
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("grid_select_all", _params, socket) do
    grid = socket.assigns.grid
    
    # 전체 선택/해제 토글
    if grid.state.selection.select_all do
      # 전체 해제
      updated_grid = put_in(grid.state.selection, %{selected_ids: [], select_all: false})
      {:noreply, assign(socket, grid: updated_grid)}
    else
      # 전체 선택
      all_ids = Enum.map(grid.data, & &1.id)
      updated_grid = put_in(grid.state.selection, %{selected_ids: all_ids, select_all: true})
      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  @impl true
  def handle_event("grid_toggle_filter", _params, socket) do
    grid = socket.assigns.grid
    show = !grid.state.show_filter_row

    updated_grid = if show do
      put_in(grid.state.show_filter_row, true)
    else
      # 숨길 때 필터 값도 초기화
      grid
      |> put_in([:state, :show_filter_row], false)
      |> put_in([:state, :filters], %{})
      |> put_in([:state, :pagination, :current_page], 1)
      |> put_in([:state, :scroll_offset], 0)
    end

    socket = assign(socket, grid: updated_grid)
    socket = if !show, do: push_event(socket, "reset_virtual_scroll", %{}), else: socket
    {:noreply, socket}
  end

  @impl true
  def handle_event("grid_toggle_status_column", _params, socket) do
    grid = socket.assigns.grid
    updated_grid = put_in(grid.state.show_status_column, !grid.state.show_status_column)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("grid_filter", %{"field" => field, "value" => value}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)

    # 필터 값 업데이트 (빈 문자열이면 해당 필터 제거)
    updated_filters = if value == "" do
      Map.delete(grid.state.filters, field_atom)
    else
      Map.put(grid.state.filters, field_atom, value)
    end

    # 필터 변경 시 페이지 1로 리셋 + 스크롤 리셋
    updated_grid = grid
      |> put_in([:state, :filters], updated_filters)
      |> put_in([:state, :pagination, :current_page], 1)
      |> put_in([:state, :scroll_offset], 0)

    {:noreply,
      socket
      |> assign(grid: updated_grid)
      |> push_event("reset_virtual_scroll", %{})
    }
  end

  @impl true
  def handle_event("grid_clear_filters", _params, socket) do
    grid = socket.assigns.grid

    updated_grid = grid
      |> put_in([:state, :filters], %{})
      |> put_in([:state, :pagination, :current_page], 1)
      |> put_in([:state, :scroll_offset], 0)

    {:noreply,
      socket
      |> assign(grid: updated_grid)
      |> push_event("reset_virtual_scroll", %{})
    }
  end

  @impl true
  def handle_event("grid_global_search", %{"value" => value}, socket) do
    grid = socket.assigns.grid

    updated_grid = grid
      |> put_in([:state, :global_search], value)
      |> put_in([:state, :pagination, :current_page], 1)
      |> put_in([:state, :scroll_offset], 0)

    {:noreply,
      socket
      |> assign(grid: updated_grid)
      |> push_event("reset_virtual_scroll", %{})
    }
  end

  @impl true
  def handle_event("grid_scroll", %{"scroll_top" => scroll_top}, socket) do
    grid = socket.assigns.grid
    row_height = grid.options.row_height

    # scroll_top 안전 파싱 (JS에서 문자열로 전송)
    scroll_top_num = case Integer.parse(to_string(scroll_top)) do
      {num, _} -> num
      :error -> 0
    end

    scroll_offset = max(0, div(scroll_top_num, row_height))
    updated_grid = put_in(grid.state.scroll_offset, scroll_offset)

    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("cell_edit_start", %{"row-id" => row_id, "field" => field}, socket) do
    grid = socket.assigns.grid
    row_id_int = String.to_integer(row_id)
    field_atom = String.to_atom(field)

    updated_grid = put_in(grid.state.editing, %{row_id: row_id_int, field: field_atom})
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("cell_edit_save", _params, %{assigns: %{grid: %{state: %{editing: nil}}}} = socket) do
    # 이미 취소된 상태 (Esc 후 blur 이벤트) → 무시
    {:noreply, socket}
  end

  @impl true
  def handle_event("cell_edit_save", %{"row-id" => row_id, "field" => field, "value" => value}, socket) do
    grid = socket.assigns.grid
    row_id_int = String.to_integer(row_id)
    field_atom = String.to_atom(field)

    # 숫자 타입이면 변환 시도
    column = Enum.find(grid.columns, fn c -> c.field == field_atom end)
    parsed_value = if column && column.editor_type == :number do
      case Float.parse(value) do
        {num, ""} -> if num == trunc(num), do: trunc(num), else: num
        {num, _} -> if num == trunc(num), do: trunc(num), else: num
        :error -> value
      end
    else
      value
    end

    # 원래 값과 비교 → 변경 없으면 편집 모드만 종료
    row = Enum.find(grid.data, fn r -> r.id == row_id_int end)
    original_value = if row, do: Map.get(row, field_atom), else: nil

    if original_value == parsed_value do
      # 값 변경 없음 → 편집 모드만 종료 (상태 마킹 안 함)
      updated_grid = put_in(grid.state.editing, nil)
      {:noreply, assign(socket, grid: updated_grid)}
    else
      # 값 변경됨 → update_cell + 부모 알림
      updated_grid = grid
        |> Grid.update_cell(row_id_int, field_atom, parsed_value)
        |> put_in([:state, :editing], nil)

      send(self(), {:grid_cell_updated, row_id_int, field_atom, parsed_value})
      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  @impl true
  def handle_event("cell_select_change", %{"select_value" => value, "row-id" => row_id, "field" => field}, socket) do
    grid = socket.assigns.grid
    row_id_int = String.to_integer(row_id)
    field_atom = String.to_atom(field)

    # 원래 값과 비교
    row = Enum.find(grid.data, fn r -> r.id == row_id_int end)
    original_value = if row, do: Map.get(row, field_atom), else: nil

    if to_string(original_value) == value do
      # 값 변경 없음 → 편집 모드만 종료
      updated_grid = put_in(grid.state.editing, nil)
      {:noreply, assign(socket, grid: updated_grid)}
    else
      # 값 변경됨 → update_cell + 부모 알림
      updated_grid = grid
        |> Grid.update_cell(row_id_int, field_atom, value)
        |> put_in([:state, :editing], nil)

      send(self(), {:grid_cell_updated, row_id_int, field_atom, value})
      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  @impl true
  def handle_event("cell_edit_cancel", _params, socket) do
    grid = socket.assigns.grid
    updated_grid = put_in(grid.state.editing, nil)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("cell_keydown", %{"key" => "Enter", "value" => value} = params, socket) do
    handle_event("cell_edit_save", Map.put(params, "value", value), socket)
  end

  @impl true
  def handle_event("cell_keydown", %{"key" => "Escape"}, socket) do
    handle_event("cell_edit_cancel", %{}, socket)
  end

  @impl true
  def handle_event("cell_keydown", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("grid_add_row", _params, socket) do
    grid = socket.assigns.grid

    # 컬럼 기본값 생성 (빈 문자열, 0, 또는 select 첫 번째 값)
    defaults = Enum.reduce(grid.columns, %{}, fn col, acc ->
      default_val = case col.editor_type do
        :number -> 0
        :select ->
          if col.editor_options != [], do: elem(hd(col.editor_options), 1), else: ""
        _ -> ""
      end
      Map.put(acc, col.field, default_val)
    end)

    updated_grid = Grid.add_row(grid, defaults, :top)

    # 부모에게 알림
    send(self(), {:grid_row_added, hd(updated_grid.data)})

    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("grid_delete_selected", _params, socket) do
    grid = socket.assigns.grid
    selected_ids = grid.state.selection.selected_ids

    if selected_ids == [] do
      {:noreply, socket}
    else
      updated_grid = grid
        |> Grid.delete_rows(selected_ids)
        |> put_in([:state, :selection, :selected_ids], [])
        |> put_in([:state, :selection, :select_all], false)

      # 부모에게 알림
      send(self(), {:grid_rows_deleted, selected_ids})

      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  @impl true
  def handle_event("grid_save", _params, socket) do
    grid = socket.assigns.grid
    changed = Grid.changed_rows(grid)

    # 부모 LiveView에 저장 요청
    send(self(), {:grid_save_requested, changed})

    # 저장 후 상태 초기화
    updated_grid = Grid.clear_row_statuses(grid)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("grid_discard", _params, socket) do
    grid = socket.assigns.grid

    # 부모에 취소 알림 (원본 데이터로 복원 요청)
    send(self(), :grid_discard_requested)

    # 상태만 초기화 (데이터는 부모가 원본으로 다시 전달해줌)
    updated_grid = Grid.clear_row_statuses(grid)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="lv-grid">
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
          <button
            class="lv-grid__add-btn"
            phx-click="grid_add_row"
            phx-target={@myself}
            title="새 행 추가"
          >
            + 추가
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

        <%= if Grid.has_changes?(@grid) do %>
          <div class="lv-grid__save-area">
            <span class="lv-grid__save-count">
              <%= map_size(@grid.state.row_statuses) %>건 변경
            </span>
            <button
              class="lv-grid__save-btn"
              phx-click="grid_save"
              phx-target={@myself}
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

      <!-- Header -->
      <%= if @grid.options.show_header do %>
        <div class="lv-grid__header">
          <!-- 체크박스 + 필터 토글 컬럼 -->
          <div class="lv-grid__header-cell" style="width: 50px; flex: 0 0 50px; justify-content: center; gap: 4px;">
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

          <!-- 상태 컬럼 헤더 -->
          <%= if @grid.state.show_status_column do %>
            <div class="lv-grid__header-cell lv-grid__header-cell--status" style="width: 60px; flex: 0 0 60px; justify-content: center;">
              상태
            </div>
          <% end %>

          <%= for {column, col_idx} <- Enum.with_index(@grid.columns) do %>
            <div
              class={"lv-grid__header-cell #{if column.sortable, do: "lv-grid__header-cell--sortable"} #{frozen_class(col_idx, @grid)}"}
              style={"#{column_width_style(column)}; #{frozen_style(col_idx, @grid)}"}
              phx-click={if column.sortable, do: "grid_sort"}
              phx-value-field={column.field}
              phx-value-direction={next_direction(@grid.state.sort, column.field)}
              phx-target={@myself}
              data-confirm={if column.sortable && Grid.has_changes?(@grid), do: "저장하지 않은 변경사항이 있습니다. 계속하시겠습니까?"}
              data-col-index={col_idx}
            >
              <%= column.label %>
              <%= if column.sortable && sort_active?(@grid.state.sort, column.field) do %>
                <span class="lv-grid__sort-icon">
                  <%= sort_icon(@grid.state.sort.direction) %>
                </span>
              <% end %>
              <span
                class="lv-grid__resize-handle"
                phx-hook="ColumnResize"
                id={"resize-#{column.field}"}
                data-col-index={col_idx}
              ></span>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Filter Row -->
      <%= if @grid.state.show_filter_row && has_filterable_columns?(@grid.columns) do %>
        <div class="lv-grid__filter-row">
          <!-- 체크박스 컬럼 빈칸 -->
          <div class="lv-grid__filter-cell" style="width: 50px; flex: 0 0 50px;">
          </div>

          <!-- 상태 컬럼 빈칸 -->
          <%= if @grid.state.show_status_column do %>
            <div class="lv-grid__filter-cell" style="width: 60px; flex: 0 0 60px;">
            </div>
          <% end %>

          <%= for {column, col_idx} <- Enum.with_index(@grid.columns) do %>
            <div class={"lv-grid__filter-cell #{frozen_class(col_idx, @grid)}"} style={"#{column_width_style(column)}; #{frozen_style(col_idx, @grid)}"} data-col-index={col_idx}>
              <%= if column.filterable do %>
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
            </div>
          <% end %>

          <!-- 필터 초기화 버튼 -->
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
          <!-- 전체 높이 스페이서 (스크롤바 크기 결정) -->
          <div style={"height: #{length(@grid.data) * @grid.options.row_height}px; position: relative;"}>
            <!-- 보이는 행만 올바른 위치에 렌더링 -->
            <div style={"position: absolute; top: #{Grid.virtual_offset_top(@grid)}px; width: 100%;"}>
              <%= for row <- Grid.visible_data(@grid) do %>
                <div class={"lv-grid__row #{if row.id in @grid.state.selection.selected_ids, do: "lv-grid__row--selected"} #{if Map.get(@grid.state.row_statuses, row.id) == :deleted, do: "lv-grid__row--deleted"}"}>
                  <div class="lv-grid__cell" style="width: 50px; flex: 0 0 50px; justify-content: center;">
                    <input
                      type="checkbox"
                      phx-click="grid_row_select"
                      phx-value-row-id={row.id}
                      phx-target={@myself}
                      checked={row.id in @grid.state.selection.selected_ids}
                      style="width: 18px; height: 18px; cursor: pointer;"
                    />
                  </div>
                  <%= if @grid.state.show_status_column do %>
                    <div class="lv-grid__cell lv-grid__cell--status" style="width: 60px; flex: 0 0 60px; justify-content: center;">
                      <%= render_status_badge(Map.get(@grid.state.row_statuses, row.id, :normal)) %>
                    </div>
                  <% end %>
                  <%= for {column, col_idx} <- Enum.with_index(@grid.columns) do %>
                    <div class={"lv-grid__cell #{frozen_class(col_idx, @grid)}"} style={"#{column_width_style(column)}; #{frozen_style(col_idx, @grid)}"} data-col-index={col_idx}>
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
        <div class="lv-grid__body">
          <%= for row <- Grid.visible_data(@grid) do %>
            <div class={"lv-grid__row #{if row.id in @grid.state.selection.selected_ids, do: "lv-grid__row--selected"} #{if Map.get(@grid.state.row_statuses, row.id) == :deleted, do: "lv-grid__row--deleted"}"}>
              <div class="lv-grid__cell" style="width: 50px; flex: 0 0 50px; justify-content: center;">
                <input
                  type="checkbox"
                  phx-click="grid_row_select"
                  phx-value-row-id={row.id}
                  phx-target={@myself}
                  checked={row.id in @grid.state.selection.selected_ids}
                  style="width: 18px; height: 18px; cursor: pointer;"
                />
              </div>
              <%= if @grid.state.show_status_column do %>
                <div class="lv-grid__cell lv-grid__cell--status" style="width: 60px; flex: 0 0 60px; justify-content: center;">
                  <%= render_status_badge(Map.get(@grid.state.row_statuses, row.id, :normal)) %>
                </div>
              <% end %>
              <%= for {column, col_idx} <- Enum.with_index(@grid.columns) do %>
                <div class={"lv-grid__cell #{frozen_class(col_idx, @grid)}"} style={"#{column_width_style(column)}; #{frozen_style(col_idx, @grid)}"} data-col-index={col_idx}>
                  <%= render_cell(assigns, row, column) %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- 디버깅: 보이는 데이터 개수 (debug 옵션으로 토글) -->
      <%= if @grid.options.debug do %>
        <div style="padding: 10px; background: #fff9c4; border: 1px solid #fbc02d; margin: 10px 0; font-size: 12px;">
          전체 데이터 <%= length(@grid.data) %>개 |
          화면 표시 <%= length(Grid.visible_data(@grid)) %>개 |
          현재 페이지 <%= @grid.state.pagination.current_page %> |
          페이지 크기 <%= @grid.options.page_size %> |
          Virtual Scroll <%= if @grid.options.virtual_scroll, do: "ON (offset: #{@grid.state.scroll_offset})", else: "OFF" %>
        </div>
      <% end %>
      
      <!-- Footer -->
      <%= if @grid.options.show_footer do %>
        <div class="lv-grid__footer">
          <%= if !@grid.options.virtual_scroll do %>
            <div class="lv-grid__pagination">
              <!-- 이전 버튼 -->
              <button
                class="lv-grid__page-btn"
                phx-click="grid_page_change"
                phx-value-page={@grid.state.pagination.current_page - 1}
                phx-target={@myself}
                disabled={@grid.state.pagination.current_page == 1}
              >
                &lt;
              </button>

              <!-- 페이지 번호 -->
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

              <!-- 다음 버튼 -->
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
          <% end %>

          <div class="lv-grid__info">
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
        </div>
      <% end %>
    </div>
    """
  end

  # Helper functions

  defp column_width_style(%{width: :auto}), do: "flex: 1"
  defp column_width_style(%{width: width}), do: "width: #{width}px; flex: 0 0 #{width}px"

  defp frozen_style(col_idx, grid) do
    frozen_count = grid.options.frozen_columns
    if frozen_count > 0 and col_idx < frozen_count do
      # 체크박스(50px) + 상태(60px if visible) + 이전 컬럼들 너비 합산
      base_offset = 50 + if(grid.state.show_status_column, do: 60, else: 0)
      prev_width = grid.columns
        |> Enum.take(col_idx)
        |> Enum.reduce(0, fn col, acc ->
          case col.width do
            :auto -> acc + 150  # auto 컬럼은 기본 150px로 계산
            w -> acc + w
          end
        end)
      left = base_offset + prev_width
      "position: sticky; left: #{left}px; z-index: 2; background: inherit;"
    else
      ""
    end
  end

  defp frozen_class(col_idx, grid) do
    frozen_count = grid.options.frozen_columns
    if frozen_count > 0 and col_idx < frozen_count do
      "lv-grid__cell--frozen"
    else
      ""
    end
  end

  defp sort_active?(nil, _field), do: false
  defp sort_active?(%{field: sort_field}, field), do: sort_field == field

  defp sort_icon(:asc), do: "▲"
  defp sort_icon(:desc), do: "▼"

  defp next_direction(nil, _field), do: "asc"
  defp next_direction(%{field: sort_field, direction: :asc}, field) when sort_field == field, do: "desc"
  defp next_direction(%{field: sort_field, direction: :desc}, field) when sort_field == field, do: "asc"
  defp next_direction(_sort, _field), do: "asc"

  defp has_filterable_columns?(columns) do
    Enum.any?(columns, & &1.filterable)
  end

  defp filter_placeholder(%{filter_type: :number}), do: "예: >30, <=25"
  defp filter_placeholder(_column), do: "검색..."

  defp editing?(nil, _row_id, _field), do: false
  defp editing?(%{row_id: rid, field: f}, row_id, field), do: rid == row_id and f == field

  defp editor_input_type(%{editor_type: :number}), do: "number"
  defp editor_input_type(_column), do: "text"

  defp render_status_badge(:normal), do: ""
  defp render_status_badge(:new) do
    Phoenix.HTML.raw(~s(<span class="lv-grid__status-badge lv-grid__status-badge--new">N</span>))
  end
  defp render_status_badge(:updated) do
    Phoenix.HTML.raw(~s(<span class="lv-grid__status-badge lv-grid__status-badge--updated">U</span>))
  end
  defp render_status_badge(:deleted) do
    Phoenix.HTML.raw(~s(<span class="lv-grid__status-badge lv-grid__status-badge--deleted">D</span>))
  end

  defp render_cell(assigns, row, column) do
    if column.editable && editing?(assigns.grid.state.editing, row.id, column.field) do
      if column.editor_type == :select do
        # SELECT 편집 모드
        assigns = assign(assigns, row: row, column: column)
        ~H"""
        <select
          phx-value-row-id={@row.id}
          phx-value-field={@column.field}
          phx-target={@myself}
          class="lv-grid__cell-editor"
          id={"editor-#{@row.id}-#{@column.field}"}
          phx-hook="CellEditor"
        >
          <%= for {label, value} <- @column.editor_options do %>
            <option value={value} selected={value == to_string(Map.get(@row, @column.field))}>
              <%= label %>
            </option>
          <% end %>
        </select>
        """
      else
        # INPUT 편집 모드 (text/number)
        assigns = assign(assigns, row: row, column: column)
        ~H"""
        <input
          type={editor_input_type(@column)}
          value={Map.get(@row, @column.field)}
          phx-blur="cell_edit_save"
          phx-keyup="cell_keydown"
          phx-value-row-id={@row.id}
          phx-value-field={@column.field}
          phx-target={@myself}
          class="lv-grid__cell-editor"
          id={"editor-#{@row.id}-#{@column.field}"}
          phx-hook="CellEditor"
        />
        """
      end
    else
      # 보기 모드
      assigns = assign(assigns, row: row, column: column)
      ~H"""
      <span
        class={"lv-grid__cell-value #{if @column.editable, do: "lv-grid__cell-value--editable"}"}
        id={if @column.editable, do: "cell-#{@row.id}-#{@column.field}"}
        phx-hook={if @column.editable, do: "CellEditable"}
        data-row-id={@row.id}
        data-field={@column.field}
        phx-target={@myself}
      >
        <%= Map.get(@row, @column.field) %>
      </span>
      """
    end
  end

  defp page_range_for(total_rows, current_page, page_size) do
    total = Pagination.total_pages(total_rows, page_size)

    if total == 0 do
      1..1
    else
      start = max(1, current_page - 2)
      finish = min(total, current_page + 2)
      start..finish
    end
  end
end
