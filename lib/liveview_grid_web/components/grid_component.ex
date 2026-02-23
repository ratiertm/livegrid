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

  ## 개별 Assigns (grid 대신 사용 가능)

  - `data` - 행 데이터 리스트 `[%{id: 1, name: "Alice"}, ...]`
  - `columns` - 컬럼 정의 리스트
  - `options` - Grid 옵션 맵
  - `data_source` - DataSource 튜플 (선택)

  ## 지원 이벤트

  GridComponent는 다음 이벤트를 내부적으로 처리합니다:

  - `sort` - 컬럼 헤더 클릭 정렬
  - `filter` - 컬럼 필터 입력
  - `global_search` - 전체 검색
  - `change_page` / `change_page_size` - 페이지네이션
  - `select_row` / `toggle_select_all` - 행 선택
  - `start_edit` / `save_edit` / `cancel_edit` - 인라인 셀 편집
  - `add_row` / `delete_selected` / `save_changes` / `cancel_changes` - CRUD
  - `export` - Excel/CSV 내보내기
  - `scroll` - Virtual Scroll
  - `resize_column` / `reorder_column` - 컬럼 리사이즈/리오더
  - `toggle_group` - 그룹 expand/collapse
  - `toggle_tree_node` - 트리 노드 expand/collapse

  ## 부모 LiveView로의 이벤트 전파

  CRUD 작업 시 `send(self(), {:grid_save, changes})` 등으로
  부모에게 알림을 보냅니다. 부모 LiveView에서 `handle_info/2`로 수신합니다.
  """
  
  use Phoenix.LiveComponent
  
  alias LiveViewGrid.{Grid, Export, Formatter, Pagination}

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    new_options = Map.get(assigns, :options, %{})
    data_source = Map.get(assigns, :data_source, nil)

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

      # data_source 모드: 보존 + refresh로 total_rows 재설정
      updated = if data_source do
        updated
        |> Map.put(:data_source, data_source)
        |> Grid.refresh_from_source()
      else
        updated
      end

      # virtual_scroll 옵션이 변경되었으면 scroll_offset 리셋
      if old_virtual != new_virtual do
        {put_in(updated.state.scroll_offset, 0), true}
      else
        {updated, false}
      end
    else
      # 첫 마운트: 새 Grid 생성
      grid_opts = [
        data: assigns.data,
        columns: assigns.columns,
        options: new_options
      ]
      grid_opts = if data_source, do: Keyword.put(grid_opts, :data_source, data_source), else: grid_opts

      grid = Grid.new(grid_opts)

      # InMemory일 때는 data 기반 total_rows, DataSource일 때는 fetch가 이미 설정
      grid = if data_source do
        grid
      else
        put_in(grid.state.pagination.total_rows, length(assigns.data))
      end

      {grid, false}
    end

    # v0.7: options에서 group_by, tree_mode 등을 state에 반영
    grid = apply_v07_options(grid, new_options)

    socket = assign(socket, grid: grid)

    # export_menu_open 초기화 (첫 마운트 시)
    socket =
      if Map.has_key?(socket.assigns, :export_menu_open) do
        socket
      else
        assign(socket, export_menu_open: nil)
      end

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
  def handle_event("grid_page_size_change", %{"page_size" => page_size}, socket) do
    grid = socket.assigns.grid
    new_size = String.to_integer(page_size)

    # page_size 변경 + 1페이지로 리셋
    updated_grid = grid
    |> put_in([:options, :page_size], new_size)
    |> put_in([:state, :pagination, :current_page], 1)

    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("grid_column_resize", %{"field" => field, "width" => width}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_existing_atom(field)
    width_int = String.to_integer(width)

    updated_grid = Grid.resize_column(grid, field_atom, max(width_int, 50))
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("grid_column_reorder", %{"order" => order}, socket) do
    grid = socket.assigns.grid
    field_atoms = Enum.map(order, &String.to_existing_atom/1)

    updated_grid = Grid.reorder_columns(grid, field_atoms)
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
  def handle_event("grid_filter_date", %{"field" => field, "part" => part, "value" => value}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)

    # 기존 필터값에서 from/to 파싱
    current = Map.get(grid.state.filters, field_atom, "~")
    [current_from, current_to] = case String.split(current, "~", parts: 2) do
      [f, t] -> [f, t]
      _ -> ["", ""]
    end

    # 해당 part만 업데이트
    {new_from, new_to} = case part do
      "from" -> {value, current_to}
      "to" -> {current_from, value}
      _ -> {current_from, current_to}
    end

    # 날짜 범위 문자열 재조합
    combined = "#{new_from}~#{new_to}"

    # 둘 다 비어있으면 필터 제거
    updated_filters = if new_from == "" and new_to == "" do
      Map.delete(grid.state.filters, field_atom)
    else
      Map.put(grid.state.filters, field_atom, combined)
    end

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

    # 타입별 값 변환
    column = Enum.find(grid.columns, fn c -> c.field == field_atom end)
    parsed_value = cond do
      column && column.editor_type == :number ->
        case Float.parse(value) do
          {num, ""} -> if num == trunc(num), do: trunc(num), else: num
          {num, _} -> if num == trunc(num), do: trunc(num), else: num
          :error -> value
        end
      column && (column.editor_type == :date || column.filter_type == :date) ->
        parse_date_value(value)
      true ->
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
      # 값 변경됨 → update_cell + validate_cell + 부모 알림
      updated_grid = grid
        |> Grid.update_cell(row_id_int, field_atom, parsed_value)
        |> Grid.validate_cell(row_id_int, field_atom)
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
      # 값 변경됨 → update_cell + validate_cell + 부모 알림
      updated_grid = grid
        |> Grid.update_cell(row_id_int, field_atom, value)
        |> Grid.validate_cell(row_id_int, field_atom)
        |> put_in([:state, :editing], nil)

      send(self(), {:grid_cell_updated, row_id_int, field_atom, value})
      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  @impl true
  def handle_event("cell_edit_date", %{"field" => field, "row-id" => row_id, "value" => value}, socket) do
    # date picker에서 값이 변경되면 바로 저장
    handle_event("cell_edit_save", %{"row-id" => row_id, "field" => field, "value" => value}, socket)
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
        :date -> Date.utc_today()
        :select ->
          if col.editor_options != [], do: elem(hd(col.editor_options), 1), else: ""
        _ ->
          if col.filter_type == :date, do: Date.utc_today(), else: ""
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

    # 검증 에러가 있으면 저장 차단
    if Grid.has_errors?(grid) do
      send(self(), {:grid_save_blocked, Grid.error_count(grid)})
      {:noreply, socket}
    else
      changed = Grid.changed_rows(grid)

      # 부모 LiveView에 저장 요청
      send(self(), {:grid_save_requested, changed})

      # 저장 후 상태 초기화
      updated_grid = Grid.clear_row_statuses(grid)
      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  @impl true
  def handle_event("grid_discard", _params, socket) do
    grid = socket.assigns.grid

    # 부모에 취소 알림 (원본 데이터로 복원 요청)
    send(self(), :grid_discard_requested)

    # 상태만 초기화 (데이터는 부모가 원본으로 다시 전달해줌)
    updated_grid = grid
      |> Grid.clear_row_statuses()
      |> Grid.clear_cell_errors()
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Export 이벤트 ──

  @impl true
  def handle_event("export_excel", %{"type" => type}, socket) do
    grid = socket.assigns.grid
    {data, columns} = export_data(grid, type)

    case Export.to_xlsx(data, columns) do
      {:ok, {_filename, binary}} ->
        content = Base.encode64(binary)
        timestamp = DateTime.utc_now() |> DateTime.to_unix()
        filename = "liveview_grid_#{type}_#{timestamp}.xlsx"

        # 부모 LiveView에 다운로드 요청 (LiveComponent의 push_event는 window에 도달하지 않음)
        send(self(), {:grid_download_file, %{
          content: content,
          filename: filename,
          mime_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        }})

        {:noreply, assign(socket, export_menu_open: nil)}

      {:error, reason} ->
        require Logger
        Logger.error("Excel export failed: #{inspect(reason)}")
        {:noreply, assign(socket, export_menu_open: nil)}
    end
  end

  @impl true
  def handle_event("export_csv", %{"type" => type}, socket) do
    grid = socket.assigns.grid
    {data, columns} = export_data(grid, type)

    csv_content = Export.to_csv(data, columns)
    content = Base.encode64(csv_content)
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    filename = "liveview_grid_#{type}_#{timestamp}.csv"

    # 부모 LiveView에 다운로드 요청
    send(self(), {:grid_download_file, %{
      content: content,
      filename: filename,
      mime_type: "text/csv;charset=utf-8"
    }})

    {:noreply, assign(socket, export_menu_open: nil)}
  end

  @impl true
  def handle_event("toggle_export_menu", %{"format" => format}, socket) do
    current = socket.assigns[:export_menu_open]
    new_value = if current == format, do: nil, else: format
    {:noreply, assign(socket, export_menu_open: new_value)}
  end

  # ── Advanced Filter 이벤트 (F-310) ──

  @impl true
  def handle_event("toggle_advanced_filter", _params, socket) do
    grid = socket.assigns.grid
    show = !Map.get(grid.state, :show_advanced_filter, false)
    updated_grid = put_in(grid.state[:show_advanced_filter], show)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("add_filter_condition", _params, socket) do
    grid = socket.assigns.grid
    adv = Map.get(grid.state, :advanced_filters, %{logic: :and, conditions: []})
    new_condition = %{field: nil, operator: :contains, value: ""}
    updated_adv = %{adv | conditions: adv.conditions ++ [new_condition]}
    updated_grid = put_in(grid.state[:advanced_filters], updated_adv)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("update_filter_condition", params, socket) do
    grid = socket.assigns.grid
    adv = Map.get(grid.state, :advanced_filters, %{logic: :and, conditions: []})
    index = String.to_integer(params["index"])

    conditions = List.update_at(adv.conditions, index, fn condition ->
      # Form phx-change: 모든 필드가 함께 전송됨
      field_str = params["field"] || ""
      operator_str = params["operator"] || ""
      value_str = params["value"] || ""
      value_to_str = params["value_to"]

      new_field = if field_str != "", do: String.to_existing_atom(field_str), else: condition.field

      # 필드가 변경되면 컬럼의 filter_type에 맞는 기본 연산자 설정
      new_operator = cond do
        field_str != "" && new_field != condition.field ->
          col = Enum.find(grid.columns, fn c -> c.field == new_field end)
          case Map.get(col, :filter_type) do
            :number -> :eq
            :date -> :eq
            _ -> :contains
          end
        operator_str != "" ->
          String.to_existing_atom(operator_str)
        true ->
          condition.operator
      end

      # between 연산자: value_to가 있으면 "from~to" 형식으로 결합
      final_value = if new_operator == :between && value_to_str do
        "#{value_str}~#{value_to_str}"
      else
        value_str
      end

      %{condition | field: new_field, operator: new_operator, value: final_value}
    end)

    updated_adv = %{adv | conditions: conditions}
    updated_grid = put_in(grid.state[:advanced_filters], updated_adv)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("remove_filter_condition", %{"index" => index}, socket) do
    grid = socket.assigns.grid
    adv = Map.get(grid.state, :advanced_filters, %{logic: :and, conditions: []})
    idx = String.to_integer(index)
    updated_conditions = List.delete_at(adv.conditions, idx)
    updated_adv = %{adv | conditions: updated_conditions}
    updated_grid = put_in(grid.state[:advanced_filters], updated_adv)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("change_filter_logic", %{"logic" => logic}, socket) do
    grid = socket.assigns.grid
    adv = Map.get(grid.state, :advanced_filters, %{logic: :and, conditions: []})
    logic_atom = String.to_existing_atom(logic)
    updated_adv = %{adv | logic: logic_atom}
    updated_grid = put_in(grid.state[:advanced_filters], updated_adv)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("clear_advanced_filter", _params, socket) do
    grid = socket.assigns.grid
    updated_grid = put_in(grid.state[:advanced_filters], %{logic: :and, conditions: []})
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # 고급 필터 form에서 엔터 키 입력 시 submit 방지
  @impl true
  def handle_event("noop_submit", _params, socket) do
    {:noreply, socket}
  end

  # ── v0.7: Grouping 이벤트 ──

  @impl true
  def handle_event("grid_group_by", %{"fields" => fields_str}, socket) do
    grid = socket.assigns.grid
    fields = fields_str
      |> String.split(",", trim: true)
      |> Enum.map(&String.to_atom(String.trim(&1)))

    updated_grid = Grid.set_group_by(grid, fields)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("grid_group_aggregates", %{"aggregates" => agg_str}, socket) do
    grid = socket.assigns.grid
    aggregates = agg_str
      |> Jason.decode!()
      |> Enum.map(fn {k, v} -> {String.to_atom(k), String.to_atom(v)} end)
      |> Map.new()

    updated_grid = Grid.set_group_aggregates(grid, aggregates)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("grid_toggle_group", %{"group-key" => group_key}, socket) do
    grid = socket.assigns.grid
    updated_grid = Grid.toggle_group(grid, group_key)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("grid_clear_grouping", _params, socket) do
    grid = socket.assigns.grid
    updated_grid = Grid.set_group_by(grid, [])
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── v0.7: Tree Grid 이벤트 ──

  @impl true
  def handle_event("grid_toggle_tree", %{"enabled" => enabled}, socket) do
    grid = socket.assigns.grid
    parent_field = Map.get(grid.state, :tree_parent_field, :parent_id)
    updated_grid = Grid.set_tree_mode(grid, enabled == "true", parent_field)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @impl true
  def handle_event("grid_toggle_tree_node", %{"node-id" => node_id_str}, socket) do
    grid = socket.assigns.grid
    node_id = String.to_integer(node_id_str)
    updated_grid = Grid.toggle_tree_node(grid, node_id)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # v0.7: options에서 전달된 group_by, tree_mode 등을 Grid state에 반영
  defp apply_v07_options(grid, options) do
    grid = if Map.has_key?(options, :group_by) do
      group_by = Map.get(options, :group_by, [])
      aggregates = Map.get(options, :group_aggregates, %{})
      grid
      |> put_in([:state, :group_by], group_by)
      |> put_in([:state, :group_aggregates], aggregates)
    else
      grid
    end

    grid = if Map.has_key?(options, :tree_mode) do
      tree_mode = Map.get(options, :tree_mode, false)
      parent_field = Map.get(options, :tree_parent_field, :parent_id)
      grid
      |> put_in([:state, :tree_mode], tree_mode)
      |> put_in([:state, :tree_parent_field], parent_field)
    else
      grid
    end

    grid
  end

  defp export_data(grid, type) do
    data =
      case type do
        "all" -> grid.data
        "filtered" -> Grid.sorted_data(grid)
        "selected" ->
          selected_ids = grid.state.selection.selected_ids
          Enum.filter(grid.data, fn row -> row.id in selected_ids end)
        _ -> grid.data
      end

    columns = grid.columns
    {data, columns}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="lv-grid" data-theme={@grid.options[:theme] || "light"} style={build_custom_css_vars(@grid.options[:custom_css_vars])}>
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

          <!-- 상태 컬럼 헤더 -->
          <%= if @grid.state.show_status_column do %>
            <div class="lv-grid__header-cell lv-grid__header-cell--status" style="width: 60px; flex: 0 0 60px; justify-content: center;">
              상태
            </div>
          <% end %>

          <%= for {column, col_idx} <- Enum.with_index(Grid.display_columns(@grid)) do %>
            <div
              class={"lv-grid__header-cell #{if column.sortable, do: "lv-grid__header-cell--sortable"} #{frozen_class(col_idx, @grid)}"}
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
                data-field={column.field}
              ></span>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Filter Row -->
      <%= if @grid.state.show_filter_row && has_filterable_columns?(@grid.columns) do %>
        <div class="lv-grid__filter-row">
          <!-- 체크박스 컬럼 빈칸 -->
          <div class="lv-grid__filter-cell" style="width: 90px; flex: 0 0 90px;">
          </div>

          <!-- 상태 컬럼 빈칸 -->
          <%= if @grid.state.show_status_column do %>
            <div class="lv-grid__filter-cell" style="width: 60px; flex: 0 0 60px;">
            </div>
          <% end %>

          <%= for {column, col_idx} <- Enum.with_index(Grid.display_columns(@grid)) do %>
            <div class={"lv-grid__filter-cell #{frozen_class(col_idx, @grid)}"} style={"#{column_width_style(column, @grid)}; #{frozen_style(col_idx, @grid)}"} data-col-index={col_idx}>
              <%= if column.filterable do %>
                <%= if column.filter_type == :date do %>
                  <div class="lv-grid__date-filter">
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
                <% else %>
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

          <!-- 조건 목록 -->
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

          <!-- 하단 액션 -->
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
                  <div class="lv-grid__cell" style="width: 90px; flex: 0 0 90px; justify-content: center;">
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
                  <%= for {column, col_idx} <- Enum.with_index(Grid.display_columns(@grid)) do %>
                    <div class={"lv-grid__cell #{frozen_class(col_idx, @grid)}"} style={"#{column_width_style(column, @grid)}; #{frozen_style(col_idx, @grid)}"} data-col-index={col_idx}>
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
              <div class={"lv-grid__row #{if Map.get(row, :id) in @grid.state.selection.selected_ids, do: "lv-grid__row--selected"} #{if Map.get(@grid.state.row_statuses, Map.get(row, :id)) == :deleted, do: "lv-grid__row--deleted"}"}>
                <div class="lv-grid__cell" style="width: 90px; flex: 0 0 90px; justify-content: center;">
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
                <%= for {column, col_idx} <- Enum.with_index(Grid.display_columns(@grid)) do %>
                  <div class={"lv-grid__cell #{frozen_class(col_idx, @grid)}"} style={"#{column_width_style(column, @grid)}; #{frozen_style(col_idx, @grid)}; #{tree_indent_style(row, col_idx)}"} data-col-index={col_idx}>
                    <%= if col_idx == 0 && Map.has_key?(row, :_tree_has_children) do %>
                      <!-- Tree toggle for first column -->
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
                    <%= render_cell(assigns, row, column) %>
                  </div>
                <% end %>
              </div>
            <% end %>
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
        <div class="lv-grid__footer" style="flex-direction: column; align-items: center; gap: 8px;">
          <%= if !@grid.options.virtual_scroll do %>
            <!-- 페이지네이션 (센터) -->
            <div style="display: flex; align-items: center; gap: 12px; width: 100%; justify-content: center;">
              <!-- 페이지 사이즈 선택 -->
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
    </div>
    """
  end

  # Helper functions

  defp column_width_style(%{width: :auto}), do: "flex: 1"
  defp column_width_style(%{width: width}), do: "width: #{width}px; flex: 0 0 #{width}px"

  # column_widths state에서 리사이즈된 너비 우선 적용
  defp column_width_style(column, grid) do
    case Map.get(grid.state.column_widths, column.field) do
      nil -> column_width_style(column)
      w -> "width: #{w}px; flex: 0 0 #{w}px"
    end
  end

  defp frozen_style(col_idx, grid) do
    frozen_count = grid.options.frozen_columns
    if frozen_count > 0 and col_idx < frozen_count do
      # 체크박스(90px) + 상태(60px if visible) + 이전 컬럼들 너비 합산
      base_offset = 90 + if(grid.state.show_status_column, do: 60, else: 0)
      display_cols = Grid.display_columns(grid)
      prev_width = display_cols
        |> Enum.take(col_idx)
        |> Enum.reduce(0, fn col, acc ->
          # column_widths에서 리사이즈된 값 우선 사용
          w = Map.get(grid.state.column_widths, col.field) || col.width
          case w do
            :auto -> acc + 150
            w when is_integer(w) -> acc + w
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
  defp filter_placeholder(%{filter_type: :date}), do: "날짜 선택"
  defp filter_placeholder(_column), do: "검색..."

  # 날짜 범위 필터값에서 from/to 파트 추출
  defp parse_date_part(nil, _part), do: ""
  defp parse_date_part("", _part), do: ""
  defp parse_date_part(value, part) when is_binary(value) do
    case String.split(value, "~", parts: 2) do
      [from, to] -> if part == :from, do: from, else: to
      _ -> ""
    end
  end
  defp parse_date_part(_, _), do: ""

  defp get_column_filter_type(columns, field) do
    case Enum.find(columns, fn c -> c.field == field end) do
      nil -> :text
      col -> Map.get(col, :filter_type, :text)
    end
  end

  # v0.7: Tree indent style (첫 번째 컬럼에 depth 기반 padding-left)
  defp tree_indent_style(%{_tree_depth: depth}, 0) when depth > 0 do
    "padding-left: #{16 + depth * 24}px;"
  end
  defp tree_indent_style(_row, _col_idx), do: ""

  # v0.7: Aggregate value 포맷
  defp format_agg_value(nil), do: "-"
  defp format_agg_value(value) when is_number(value), do: Formatter.format(value, :number)
  defp format_agg_value(value), do: to_string(value)

  defp editing?(nil, _row_id, _field), do: false
  defp editing?(%{row_id: rid, field: f}, row_id, field), do: rid == row_id and f == field

  defp editor_input_type(%{editor_type: :number}), do: "number"
  defp editor_input_type(%{editor_type: :date}), do: "date"
  defp editor_input_type(%{filter_type: :date}), do: "date"
  defp editor_input_type(_column), do: "text"

  # Date 값을 <input type="date">의 value 형식(YYYY-MM-DD)으로 변환
  defp format_date_for_input(%Date{} = d), do: Date.to_iso8601(d)
  defp format_date_for_input(%DateTime{} = dt), do: dt |> DateTime.to_date() |> Date.to_iso8601()
  defp format_date_for_input(%NaiveDateTime{} = dt), do: dt |> NaiveDateTime.to_date() |> Date.to_iso8601()
  defp format_date_for_input(val) when is_binary(val), do: val
  defp format_date_for_input(nil), do: ""
  defp format_date_for_input(_), do: ""

  # 날짜 문자열을 Date 타입으로 파싱
  defp parse_date_value(""), do: nil
  defp parse_date_value(nil), do: nil
  defp parse_date_value(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> value
    end
  end
  defp parse_date_value(value), do: value

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
        input_type = editor_input_type(column)

        if input_type == "date" do
          # DATE 편집 모드 - date picker
          cell_val = Map.get(row, column.field)
          date_str = format_date_for_input(cell_val)
          assigns = assign(assigns, row: row, column: column, date_value: date_str)
          ~H"""
          <form phx-change="cell_edit_date" phx-target={@myself} style="display: contents;">
            <input type="hidden" name="row-id" value={@row.id} />
            <input type="hidden" name="field" value={@column.field} />
            <input
              type="date"
              name="value"
              value={@date_value}
              phx-blur="cell_edit_save"
              phx-value-row-id={@row.id}
              phx-value-field={@column.field}
              phx-target={@myself}
              class="lv-grid__cell-editor"
              id={"editor-#{@row.id}-#{@column.field}"}
              phx-hook="CellEditor"
            />
          </form>
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
      end
    else
      # 보기 모드
      cell_error = Grid.cell_error(assigns.grid, row.id, column.field)

      if column.renderer do
        # 커스텀 렌더러
        render_with_renderer(assigns, row, column, cell_error)
      else
        # 기존 plain text
        render_plain(assigns, row, column, cell_error)
      end
    end
  end

  defp render_with_renderer(assigns, row, column, cell_error) do
    rendered_content =
      try do
        column.renderer.(row, column, assigns)
      rescue
        _ -> Phoenix.HTML.raw(to_string(Map.get(row, column.field)))
      end

    assigns = assign(assigns, row: row, column: column, cell_error: cell_error, rendered_content: rendered_content)

    ~H"""
    <div class={"lv-grid__cell-wrapper #{if @cell_error, do: "lv-grid__cell-wrapper--error"}"}>
      <span
        class={"lv-grid__cell-value #{if @column.editable, do: "lv-grid__cell-value--editable"} #{if @cell_error, do: "lv-grid__cell-value--error"}"}
        id={if @column.editable, do: "cell-#{@row.id}-#{@column.field}"}
        phx-hook={if @column.editable, do: "CellEditable"}
        data-row-id={@row.id}
        data-field={@column.field}
        phx-target={@myself}
        title={@cell_error}
      >
        <%= @rendered_content %>
        <%= if @cell_error do %>
          <span class="lv-grid__cell-error-icon">!</span>
        <% end %>
      </span>
      <%= if @cell_error do %>
        <span class="lv-grid__cell-error-msg"><%= @cell_error %></span>
      <% end %>
    </div>
    """
  end

  defp render_plain(assigns, row, column, cell_error) do
    raw_value = Map.get(row, column.field)
    formatted_value = Formatter.format(raw_value, column.formatter)
    assigns = assign(assigns, row: row, column: column, cell_error: cell_error, formatted_value: formatted_value)

    ~H"""
    <div class={"lv-grid__cell-wrapper #{if @cell_error, do: "lv-grid__cell-wrapper--error"}"}>
      <span
        class={"lv-grid__cell-value #{if @column.editable, do: "lv-grid__cell-value--editable"} #{if @cell_error, do: "lv-grid__cell-value--error"}"}
        id={if @column.editable, do: "cell-#{@row.id}-#{@column.field}"}
        phx-hook={if @column.editable, do: "CellEditable"}
        data-row-id={@row.id}
        data-field={@column.field}
        phx-target={@myself}
        title={@cell_error}
      >
        <%= @formatted_value %>
        <%= if @cell_error do %>
          <span class="lv-grid__cell-error-icon">!</span>
        <% end %>
      </span>
      <%= if @cell_error do %>
        <span class="lv-grid__cell-error-msg"><%= @cell_error %></span>
      <% end %>
    </div>
    """
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

  # 커스텀 CSS 변수를 인라인 style 문자열로 변환
  defp build_custom_css_vars(nil), do: nil
  defp build_custom_css_vars(vars) when is_map(vars) and map_size(vars) == 0, do: nil
  defp build_custom_css_vars(vars) when is_map(vars) do
    vars
    |> Enum.map(fn {key, value} -> "#{key}: #{value}" end)
    |> Enum.join("; ")
  end
end
