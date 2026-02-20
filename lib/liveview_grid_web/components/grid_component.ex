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
  def render(assigns) do
    ~H"""
    <div class="lv-grid">
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
          </div>
          
          <%= for column <- @grid.columns do %>
            <div 
              class={"lv-grid__header-cell #{if column.sortable, do: "lv-grid__header-cell--sortable"}"}
              style={column_width_style(column)}
              phx-click={if column.sortable, do: "grid_sort"}
              phx-value-field={column.field}
              phx-value-direction={next_direction(@grid.state.sort, column.field)}
              phx-target={@myself}
            >
              <%= column.label %>
              <%= if column.sortable && sort_active?(@grid.state.sort, column.field) do %>
                <span class="lv-grid__sort-icon">
                  <%= sort_icon(@grid.state.sort.direction) %>
                </span>
              <% end %>
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

          <%= for column <- @grid.columns do %>
            <div class="lv-grid__filter-cell" style={column_width_style(column)}>
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
                <div class={"lv-grid__row #{if row.id in @grid.state.selection.selected_ids, do: "lv-grid__row--selected"}"}>
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
                  <%= for column <- @grid.columns do %>
                    <div class="lv-grid__cell" style={column_width_style(column)}>
                      <%= Map.get(row, column.field) %>
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
            <div class={"lv-grid__row #{if row.id in @grid.state.selection.selected_ids, do: "lv-grid__row--selected"}"}>
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
              <%= for column <- @grid.columns do %>
                <div class="lv-grid__cell" style={column_width_style(column)}>
                  <%= Map.get(row, column.field) %>
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
            <%= if map_size(@grid.state.filters) > 0 do %>
              <span style="color: #ff9800; font-weight: 600;">
                <%= Grid.filtered_count(@grid) %>개 필터됨
              </span>
              <span style="margin: 0 4px; color: #ccc;">/</span>
            <% end %>
            총 <%= @grid.state.pagination.total_rows %>개
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper functions

  defp column_width_style(%{width: :auto}), do: "flex: 1"
  defp column_width_style(%{width: width}), do: "width: #{width}px; flex: 0 0 #{width}px"

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
