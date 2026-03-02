defmodule LiveviewGridWeb.GridComponent.EventHandlers do
  @moduledoc """
  GridComponent 이벤트 핸들러 비즈니스 로직 모듈.

  GridComponent의 `handle_event/3`에서 위임받아 실행됩니다.
  모든 함수는 `{:noreply, socket}` 튜플을 반환합니다.
  """

  import Phoenix.LiveView, only: [push_event: 3]
  import Phoenix.Component, only: [assign: 2]

  alias LiveViewGrid.{Grid, Export}
  alias LiveviewGridWeb.GridComponent.RenderHelpers

  # ── Sorting ──

  @doc """
  컬럼 정렬을 처리한다. 지정된 필드와 방향(asc/desc)으로 그리드를 정렬하고 스크롤을 초기화한다.
  """
  @spec handle_sort(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_sort(%{"field" => field, "direction" => direction}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)
    direction_atom = String.to_atom(direction)

    updated_grid = grid
      |> put_in([:state, :sort], %{field: field_atom, direction: direction_atom})
      |> put_in([:state, :scroll_offset], 0)

    {:noreply,
      socket
      |> assign(grid: updated_grid)
      |> push_event("reset_virtual_scroll", %{})
    }
  end

  # ── Pagination ──

  @doc """
  페이지 변경을 처리한다. 지정된 페이지 번호로 현재 페이지를 이동한다.
  """
  @spec handle_page_change(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_page_change(%{"page" => page}, socket) do
    grid = socket.assigns.grid
    page_num = String.to_integer(page)
    updated_grid = put_in(grid.state.pagination.current_page, page_num)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  페이지 크기 변경을 처리한다. 새 페이지 크기 적용 후 1페이지로 리셋한다.
  """
  @spec handle_page_size_change(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_page_size_change(%{"page_size" => page_size}, socket) do
    grid = socket.assigns.grid
    new_size = String.to_integer(page_size)

    updated_grid = grid
    |> put_in([:options, :page_size], new_size)
    |> put_in([:state, :pagination, :current_page], 1)

    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Column Operations ──

  @doc """
  컬럼 너비 변경을 처리한다. 최소 50px을 보장한다.
  """
  @spec handle_column_resize(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_column_resize(%{"field" => field, "width" => width}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_existing_atom(field)
    width_int = String.to_integer(width)

    updated_grid = Grid.resize_column(grid, field_atom, max(width_int, 50))
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  컬럼 순서 변경을 처리한다. 드래그 앤 드롭으로 재배치된 컬럼 순서를 적용한다.
  """
  @spec handle_column_reorder(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_column_reorder(%{"order" => order}, socket) do
    grid = socket.assigns.grid
    field_atoms = Enum.map(order, &String.to_existing_atom/1)

    updated_grid = Grid.reorder_columns(grid, field_atoms)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Row Selection ──

  @doc """
  개별 행 선택/해제를 토글한다. 이미 선택된 행이면 해제, 아니면 선택 목록에 추가한다.
  """
  @spec handle_row_select(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_row_select(%{"row-id" => row_id}, socket) do
    grid = socket.assigns.grid
    id = String.to_integer(row_id)

    selected_ids = grid.state.selection.selected_ids
    updated_ids = if id in selected_ids do
      List.delete(selected_ids, id)
    else
      [id | selected_ids]
    end

    updated_grid = put_in(grid.state.selection.selected_ids, updated_ids)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  전체 선택/해제를 토글한다. 이미 전체 선택 상태이면 해제, 아니면 모든 행을 선택한다.
  """
  @spec handle_select_all(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_select_all(_params, socket) do
    grid = socket.assigns.grid

    if grid.state.selection.select_all do
      updated_grid = put_in(grid.state.selection, %{selected_ids: [], select_all: false})
      {:noreply, assign(socket, grid: updated_grid)}
    else
      all_ids = Enum.map(grid.data, & &1.id)
      updated_grid = put_in(grid.state.selection, %{selected_ids: all_ids, select_all: true})
      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  # ── Filter Toggle / Status ──

  @doc """
  필터 행 표시/숨김을 토글한다. 숨길 때 모든 필터 조건을 초기화하고 스크롤을 리셋한다.
  """
  @spec handle_toggle_filter(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_toggle_filter(_params, socket) do
    grid = socket.assigns.grid
    show = !grid.state.show_filter_row

    updated_grid = if show do
      put_in(grid.state.show_filter_row, true)
    else
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

  @doc """
  상태(status) 컬럼 표시/숨김을 토글한다.
  """
  @spec handle_toggle_status_column(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_toggle_status_column(_params, socket) do
    grid = socket.assigns.grid
    updated_grid = put_in(grid.state.show_status_column, !grid.state.show_status_column)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Filtering ──

  @doc """
  컬럼별 필터를 적용한다. 빈 값이면 해당 필터를 제거하고, 값이 있으면 필터를 설정한다.
  필터 변경 시 1페이지로 이동하고 스크롤을 초기화한다.
  """
  @spec handle_filter(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_filter(%{"field" => field, "value" => value}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)

    updated_filters = if value == "" do
      Map.delete(grid.state.filters, field_atom)
    else
      Map.put(grid.state.filters, field_atom, value)
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

  @doc """
  날짜 범위 필터를 처리한다. from/to 부분을 `~`로 결합하여 날짜 범위 필터를 구성한다.
  """
  @spec handle_filter_date(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_filter_date(%{"field" => field, "part" => part, "value" => value}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)

    current = Map.get(grid.state.filters, field_atom, "~")
    [current_from, current_to] = case String.split(current, "~", parts: 2) do
      [f, t] -> [f, t]
      _ -> ["", ""]
    end

    {new_from, new_to} = case part do
      "from" -> {value, current_to}
      "to" -> {current_from, value}
      _ -> {current_from, current_to}
    end

    combined = "#{new_from}~#{new_to}"

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

  @doc """
  모든 컬럼 필터를 초기화한다. 1페이지로 이동하고 스크롤을 리셋한다.
  """
  @spec handle_clear_filters(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_clear_filters(_params, socket) do
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

  # ── FA-003: Date Filter Presets ──

  @doc """
  날짜 필터 프리셋을 적용한다. 선택된 프리셋에 따라 from~to 범위를 자동 설정한다.
  """
  @spec handle_date_filter_preset(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_date_filter_preset(%{"preset" => preset, "_target" => [_ | _]} = params, socket) do
    field = params["field"] || List.last(params["_target"] || [])
    handle_date_filter_preset_apply(field, preset, socket)
  end
  def handle_date_filter_preset(%{"preset" => preset, "field" => field}, socket) do
    handle_date_filter_preset_apply(field, preset, socket)
  end
  def handle_date_filter_preset(_params, socket), do: {:noreply, socket}

  defp handle_date_filter_preset_apply(_field, "", socket), do: {:noreply, socket}
  defp handle_date_filter_preset_apply(field, preset, socket) do
    grid = socket.assigns.grid
    field_atom = if is_atom(field), do: field, else: String.to_atom(field)
    today = Date.utc_today()

    {from_date, to_date} = case preset do
      "today" ->
        {today, today}
      "last_7_days" ->
        {Date.add(today, -6), today}
      "this_month" ->
        {Date.beginning_of_month(today), Date.end_of_month(today)}
      "last_month" ->
        last = today |> Date.beginning_of_month() |> Date.add(-1)
        {Date.beginning_of_month(last), last}
      "this_year" ->
        {Date.new!(today.year, 1, 1), Date.new!(today.year, 12, 31)}
      _ ->
        {nil, nil}
    end

    case {from_date, to_date} do
      {nil, nil} -> {:noreply, socket}
      {from, to} ->
        combined = "#{Date.to_iso8601(from)}~#{Date.to_iso8601(to)}"
        updated_filters = Map.put(grid.state.filters, field_atom, combined)

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
  end

  @doc """
  특정 컬럼의 필터만 초기화한다.
  """
  @spec handle_clear_column_filter(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_clear_column_filter(%{"field" => field}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)

    updated_filters = Map.delete(grid.state.filters, field_atom)

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

  # ── FA-012: Set Filter ──

  @doc "Set Filter 패널 토글"
  def handle_toggle_set_filter(%{"field" => field}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)
    current = grid.state.set_filter_open

    new_open = if current == field_atom, do: nil, else: field_atom
    updated_grid = put_in(grid.state.set_filter_open, new_open)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc "Set Filter 내 검색"
  def handle_set_filter_search(%{"field" => field, "value" => value}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)
    search = Map.put(grid.state.set_filter_search, field_atom, value)
    updated_grid = put_in(grid.state.set_filter_search, search)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc "Set Filter 전체 선택"
  def handle_set_filter_select_all(%{"field" => field}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)

    # 전체 선택 = 필터 해제
    updated_filters = Map.delete(grid.state.filters, field_atom)

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

  @doc "Set Filter 전체 해제"
  def handle_set_filter_deselect_all(%{"field" => field}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)

    updated_filters = Map.put(grid.state.filters, field_atom, {:set, []})

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

  @doc "Set Filter 개별 값 토글"
  def handle_set_filter_toggle_value(%{"field" => field, "val" => val}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)

    all_values = RenderHelpers.unique_column_values(grid, field_atom)

    current_values = case Map.get(grid.state.filters, field_atom) do
      {:set, vals} -> vals
      _ -> all_values  # 필터 없음 = 전체 선택
    end

    new_values = if val in current_values do
      List.delete(current_values, val)
    else
      current_values ++ [val]
    end

    # 모든 값이 선택되면 필터 해제
    updated_filters = if length(new_values) >= length(all_values) do
      Map.delete(grid.state.filters, field_atom)
    else
      Map.put(grid.state.filters, field_atom, {:set, new_values})
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

  # ── FA-010: Column Menu ──

  @doc "Column Menu 패널 토글"
  @spec handle_toggle_column_menu(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_toggle_column_menu(%{"field" => field}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)
    current = grid.state.column_menu_open

    new_open = if current == field_atom, do: nil, else: field_atom
    updated_grid = put_in(grid.state.column_menu_open, new_open)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc "Column Menu 액션 실행"
  @spec handle_column_menu_action(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_column_menu_action(%{"field" => field, "action" => action}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)

    # 메뉴 닫기
    grid = put_in(grid.state.column_menu_open, nil)

    case action do
      "sort_asc" ->
        updated_grid = grid
          |> put_in([:state, :sort], %{field: field_atom, direction: :asc})
          |> put_in([:state, :scroll_offset], 0)

        {:noreply,
          socket
          |> assign(grid: updated_grid)
          |> push_event("reset_virtual_scroll", %{})
        }

      "sort_desc" ->
        updated_grid = grid
          |> put_in([:state, :sort], %{field: field_atom, direction: :desc})
          |> put_in([:state, :scroll_offset], 0)

        {:noreply,
          socket
          |> assign(grid: updated_grid)
          |> push_event("reset_virtual_scroll", %{})
        }

      "hide_column" ->
        hidden = Map.get(grid.state, :hidden_columns, [])
        new_hidden = if field_atom in hidden, do: hidden, else: hidden ++ [field_atom]

        # columns에서 해당 컬럼 제거
        visible_columns = Enum.reject(grid.columns, fn col -> col.field in new_hidden end)

        updated_grid = grid
          |> Map.put(:columns, visible_columns)
          |> put_in([:state, :hidden_columns], new_hidden)

        {:noreply, assign(socket, grid: updated_grid)}

      "autofit" ->
        # JS Hook으로 자동 너비 맞춤 이벤트 전달
        {:noreply,
          socket
          |> assign(grid: grid)
          |> push_event("autofit_column", %{field: to_string(field_atom)})
        }

      "clear_filter" ->
        updated_filters = Map.delete(grid.state.filters, field_atom)

        updated_grid = grid
          |> put_in([:state, :filters], updated_filters)
          |> put_in([:state, :pagination, :current_page], 1)
          |> put_in([:state, :scroll_offset], 0)

        {:noreply,
          socket
          |> assign(grid: updated_grid)
          |> push_event("reset_virtual_scroll", %{})
        }

      _ ->
        {:noreply, assign(socket, grid: grid)}
    end
  end

  # ── FA-002: Grid State Save/Restore ──

  @doc "현재 그리드 상태를 localStorage에 저장하도록 JS Hook에 이벤트 전달"
  @spec handle_save_state(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_save_state(_params, socket) do
    grid = socket.assigns.grid
    state_map = Grid.get_state(grid)

    {:noreply, push_event(socket, "save_grid_state", %{state: state_map})}
  end

  @doc "JS Hook으로부터 받은 상태 맵으로 그리드 상태 복원"
  @spec handle_restore_state(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_restore_state(%{"state" => state_map}, socket) do
    grid = socket.assigns.grid
    restored = Grid.restore_state(grid, state_map)
    {:noreply, assign(socket, grid: restored)}
  end

  @doc """
  전체 검색(글로벌 서치)을 처리한다. 모든 컬럼에 걸쳐 검색어를 적용한다.
  """
  @spec handle_global_search(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_global_search(%{"value" => value}, socket) do
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

  # ── Scroll ──

  @doc """
  가상 스크롤 이벤트를 처리한다. scroll_top 값으로 현재 표시 오프셋을 계산한다.
  """
  @spec handle_scroll(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_scroll(%{"scroll_top" => scroll_top}, socket) do
    grid = socket.assigns.grid
    row_height = grid.options.row_height

    scroll_top_num = case Integer.parse(to_string(scroll_top)) do
      {num, _} -> num
      :error -> 0
    end

    scroll_offset = max(0, div(scroll_top_num, row_height))
    updated_grid = put_in(grid.state.scroll_offset, scroll_offset)

    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Cell Editing ──

  @doc """
  셀 편집을 시작한다. 해당 행이 이미 행 편집 모드이면 무시한다.
  """
  @spec handle_cell_edit_start(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_cell_edit_start(%{"row-id" => row_id, "field" => field}, socket) do
    grid = socket.assigns.grid
    row_id_int = String.to_integer(row_id)
    field_atom = String.to_atom(field)

    if grid.state.editing_row == row_id_int do
      {:noreply, socket}
    else
      updated_grid = put_in(grid.state.editing, %{row_id: row_id_int, field: field_atom})
      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  @doc """
  편집 상태가 nil일 때 저장 요청을 무시한다.
  """
  @spec handle_cell_edit_save_nil_editing(socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_cell_edit_save_nil_editing(socket) do
    {:noreply, socket}
  end

  @doc """
  셀 편집 값을 저장한다. 타입에 따라 값을 파싱하고, data_source가 있으면 DB에 직접 업데이트한다.
  InMemory 모드에서는 Undo 히스토리에 기록한다.
  """
  @spec handle_cell_edit_save(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_cell_edit_save(%{"row-id" => row_id, "field" => field, "value" => value}, socket) do
    grid = socket.assigns.grid
    row_id_int = String.to_integer(row_id)
    field_atom = String.to_atom(field)

    column = Enum.find(grid.columns, fn c -> c.field == field_atom end)
    parsed_value = cond do
      column && column.editor_type == :number ->
        case Float.parse(value) do
          {num, ""} -> if num == trunc(num), do: trunc(num), else: num
          {num, _} -> if num == trunc(num), do: trunc(num), else: num
          :error -> value
        end
      column && (column.editor_type == :date || column.filter_type == :date) ->
        RenderHelpers.parse_date_value(value)
      true ->
        value
    end

    row = Enum.find(grid.data, fn r -> r.id == row_id_int end)
    original_value = if row, do: Map.get(row, field_atom), else: nil

    if original_value == parsed_value do
      updated_grid = put_in(grid.state.editing, nil)
      {:noreply, assign(socket, grid: updated_grid)}
    else
      # data_source가 있으면 DB에 직접 업데이트
      case Map.get(grid, :data_source) do
        {module, config} ->
          changes = %{field_atom => parsed_value}

          case module.update_row(config, row_id_int, changes) do
            {:ok, _updated_row} ->
              updated_grid = grid
                |> Grid.refresh_from_source()
                |> put_in([:state, :editing], nil)

              send(self(), {:grid_cell_updated, row_id_int, field_atom, parsed_value})
              {:noreply, assign(socket, grid: updated_grid)}

            {:error, _reason} ->
              updated_grid = put_in(grid.state.editing, nil)
              {:noreply, assign(socket, grid: updated_grid)}
          end

        _ ->
          updated_grid = grid
            |> Grid.update_cell(row_id_int, field_atom, parsed_value)
            |> Grid.validate_cell(row_id_int, field_atom)
            |> Grid.push_edit_history({:update_cell, row_id_int, field_atom, original_value, parsed_value})
            |> put_in([:state, :editing], nil)

          send(self(), {:grid_cell_updated, row_id_int, field_atom, parsed_value})
          {:noreply, assign(socket, grid: updated_grid)}
      end
    end
  end

  @doc """
  셀 편집을 취소하고 편집 상태를 초기화한다.
  """
  @spec handle_cell_edit_cancel(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_cell_edit_cancel(_params, socket) do
    grid = socket.assigns.grid
    updated_grid = put_in(grid.state.editing, nil)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  셀 편집 중 Enter 키 입력을 처리한다. 값을 저장하고 편집 모드를 종료한다.
  """
  @spec handle_cell_keydown_enter(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_cell_keydown_enter(%{"value" => _value} = params, socket) do
    {:noreply, socket} = handle_cell_edit_save(params, socket)
    {:noreply, push_event(socket, "grid_edit_ended", %{direction: "stay"})}
  end

  @doc """
  셀 편집 중 Escape 키 입력을 처리한다. 편집을 취소하고 모드를 종료한다.
  """
  @spec handle_cell_keydown_escape(socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_cell_keydown_escape(socket) do
    {:noreply, socket} = handle_cell_edit_cancel(%{}, socket)
    {:noreply, push_event(socket, "grid_edit_ended", %{direction: "stay"})}
  end

  @doc """
  셀 편집 중 기타 키 입력을 무시한다.
  """
  @spec handle_cell_keydown_other(socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_cell_keydown_other(socket) do
    {:noreply, socket}
  end

  @doc """
  셀 편집 값을 저장하고 지정 방향(Tab/Shift+Tab)으로 포커스를 이동한다.
  """
  @spec handle_cell_edit_save_and_move(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_cell_edit_save_and_move(%{"direction" => direction} = params, socket) do
    save_params = Map.take(params, ["row-id", "field", "value"])
    {:noreply, socket} = handle_cell_edit_save(save_params, socket)
    {:noreply, push_event(socket, "grid_edit_ended", %{direction: direction})}
  end

  @doc """
  날짜 셀 편집을 처리한다. date input 변경 시 호출되며 내부적으로 `handle_cell_edit_save/2`에 위임한다.
  """
  @spec handle_cell_edit_date(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_cell_edit_date(%{"field" => field, "row-id" => row_id, "value" => value}, socket) do
    handle_cell_edit_save(%{"row-id" => row_id, "field" => field, "value" => value}, socket)
  end

  # ── Checkbox (F-905) ──

  @doc """
  체크박스 셀의 값을 토글한다. 현재 boolean 값을 반전시키고 Undo 히스토리에 기록한다.
  """
  @spec handle_checkbox_toggle(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_checkbox_toggle(%{"row-id" => row_id, "field" => field}, socket) do
    grid = socket.assigns.grid
    row_id_int = String.to_integer(row_id)
    field_atom = String.to_atom(field)

    row = Enum.find(grid.data, fn r -> r.id == row_id_int end)
    current_value = if row, do: Map.get(row, field_atom) == true, else: false
    new_value = !current_value

    updated_grid = grid
      |> Grid.update_cell(row_id_int, field_atom, new_value)
      |> Grid.validate_cell(row_id_int, field_atom)
      |> Grid.push_edit_history({:update_cell, row_id_int, field_atom, current_value, new_value})

    send(self(), {:grid_cell_updated, row_id_int, field_atom, new_value})
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Select Change ──

  @doc """
  셀렉트(드롭다운) 셀의 값 변경을 처리한다. 기존 값과 동일하면 편집만 종료한다.
  """
  @spec handle_cell_select_change(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_cell_select_change(%{"select_value" => value, "row-id" => row_id, "field" => field}, socket) do
    grid = socket.assigns.grid
    row_id_int = String.to_integer(row_id)
    field_atom = String.to_atom(field)

    row = Enum.find(grid.data, fn r -> r.id == row_id_int end)
    original_value = if row, do: Map.get(row, field_atom), else: nil

    if to_string(original_value) == value do
      updated_grid = put_in(grid.state.editing, nil)
      {:noreply, assign(socket, grid: updated_grid)}
    else
      updated_grid = grid
        |> Grid.update_cell(row_id_int, field_atom, value)
        |> Grid.validate_cell(row_id_int, field_atom)
        |> put_in([:state, :editing], nil)

      send(self(), {:grid_cell_updated, row_id_int, field_atom, value})
      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  # ── Row Editing (F-920) ──

  @doc """
  행 편집 모드를 시작한다. 해당 행의 모든 편집 가능 컬럼이 입력 모드로 전환된다.
  """
  @spec handle_row_edit_start(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_row_edit_start(%{"row-id" => row_id}, socket) do
    grid = socket.assigns.grid
    row_id_int = String.to_integer(row_id)

    updated_grid = grid
      |> put_in([:state, :editing_row], row_id_int)
      |> put_in([:state, :editing], nil)

    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  행 편집 값을 일괄 저장한다. 변경된 필드만 감지하여 Undo 히스토리에 기록한다.
  """
  @spec handle_row_edit_save(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_row_edit_save(%{"row-id" => row_id, "values" => values}, socket) do
    grid = socket.assigns.grid
    row_id_int = String.to_integer(row_id)
    row = Enum.find(grid.data, fn r -> r.id == row_id_int end)

    {changed_values, updated_grid} = Enum.reduce(values, {%{}, grid}, fn {field_str, value}, {changes, acc} ->
      field_atom = String.to_atom(field_str)
      column = Enum.find(acc.columns, fn c -> c.field == field_atom end)
      parsed_value = RenderHelpers.parse_cell_value(value, column)
      original_value = if row, do: Map.get(row, field_atom), else: nil

      if original_value == parsed_value do
        {changes, acc}
      else
        new_acc = acc
          |> Grid.update_cell(row_id_int, field_atom, parsed_value)
          |> Grid.validate_cell(row_id_int, field_atom)
        {Map.put(changes, field_atom, parsed_value), new_acc}
      end
    end)

    final_grid = if map_size(changed_values) > 0 do
      old_values = Enum.reduce(changed_values, %{}, fn {field, _new_val}, acc ->
        old_val = if row, do: Map.get(row, field), else: nil
        Map.put(acc, field, old_val)
      end)
      Grid.push_edit_history(updated_grid, {:update_row, row_id_int, old_values, changed_values})
    else
      updated_grid
    end
    |> put_in([:state, :editing_row], nil)

    if map_size(changed_values) > 0 do
      send(self(), {:grid_row_updated, row_id_int, changed_values})
    end

    {:noreply, assign(socket, grid: final_grid)}
  end

  @doc """
  행 편집을 취소하고 편집 모드를 종료한다.
  """
  @spec handle_row_edit_cancel(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_row_edit_cancel(%{"row-id" => _row_id}, socket) do
    grid = socket.assigns.grid
    updated_grid = put_in(grid.state.editing_row, nil)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Undo/Redo (F-700) ──

  @doc """
  마지막 편집을 되돌린다(Undo). 히스토리가 비어있으면 무시한다.
  """
  @spec handle_undo(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_undo(_params, socket) do
    grid = socket.assigns.grid

    case grid.state.edit_history do
      [] ->
        {:noreply, socket}

      [action | _] ->
        updated_grid = Grid.undo(grid)
        send(self(), {:grid_undo, undo_action_summary(action)})
        {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  @doc """
  되돌린 편집을 다시 적용한다(Redo). Redo 스택이 비어있으면 무시한다.
  """
  @spec handle_redo(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_redo(_params, socket) do
    grid = socket.assigns.grid

    case grid.state.redo_stack do
      [] ->
        {:noreply, socket}

      [action | _] ->
        updated_grid = Grid.redo(grid)
        send(self(), {:grid_redo, redo_action_summary(action)})
        {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  defp undo_action_summary({:update_cell, row_id, field, old_value, _new_value}) do
    %{type: :cell, row_id: row_id, field: field, value: old_value}
  end
  defp undo_action_summary({:update_row, row_id, old_values, _new_values}) do
    %{type: :row, row_id: row_id, values: old_values}
  end
  defp undo_action_summary({:insert_row, row_id, _row_data}) do
    %{type: :insert_row, row_id: row_id}
  end

  defp redo_action_summary({:update_cell, row_id, field, _old_value, new_value}) do
    %{type: :cell, row_id: row_id, field: field, value: new_value}
  end
  defp redo_action_summary({:update_row, row_id, _old_values, new_values}) do
    %{type: :row, row_id: row_id, values: new_values}
  end
  defp redo_action_summary({:insert_row, row_id, _row_data}) do
    %{type: :insert_row, row_id: row_id}
  end

  # ── CRUD ──

  @doc """
  새 행을 추가한다. data_source가 있으면 DB에 삽입, 없으면 InMemory에 추가한다.
  컬럼 타입별 기본값이 자동으로 설정된다.
  """
  @spec handle_add_row(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_add_row(_params, socket) do
    grid = socket.assigns.grid
    defaults = build_column_defaults(grid.columns)

    # data_source가 있으면 DB에 직접 삽입
    case Map.get(grid, :data_source) do
      {module, config} ->
        case module.insert_row(config, defaults) do
          {:ok, new_row} ->
            updated_grid = Grid.refresh_from_source(grid)
            send(self(), {:grid_row_added, new_row})
            {:noreply, assign(socket, grid: updated_grid)}

          {:error, reason} ->
            require Logger
            Logger.error("[GridComponent] insert_row failed: #{inspect(reason)}")
            {:noreply, socket}
        end

      _ ->
        updated_grid = Grid.add_row(grid, defaults, :top)
        send(self(), {:grid_row_added, hd(updated_grid.data)})
        {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  @doc """
  선택된 행들을 삭제한다. data_source가 있으면 DB에서 삭제, 없으면 InMemory에서 제거한다.
  선택이 비어있으면 무시한다.
  """
  @spec handle_delete_selected(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_delete_selected(_params, socket) do
    grid = socket.assigns.grid
    selected_ids = grid.state.selection.selected_ids

    if selected_ids == [] do
      {:noreply, socket}
    else
      # data_source가 있으면 DB에서 직접 삭제
      case Map.get(grid, :data_source) do
        {module, config} ->
          Enum.each(selected_ids, fn row_id ->
            module.delete_row(config, row_id)
          end)

          updated_grid = grid
            |> Grid.refresh_from_source()
            |> put_in([:state, :selection, :selected_ids], [])
            |> put_in([:state, :selection, :select_all], false)

          send(self(), {:grid_rows_deleted, selected_ids})
          {:noreply, assign(socket, grid: updated_grid)}

        _ ->
          updated_grid = grid
            |> Grid.delete_rows(selected_ids)
            |> put_in([:state, :selection, :selected_ids], [])
            |> put_in([:state, :selection, :select_all], false)

          send(self(), {:grid_rows_deleted, selected_ids})
          {:noreply, assign(socket, grid: updated_grid)}
      end
    end
  end

  @doc """
  변경 사항 저장을 요청한다. 유효성 오류가 있으면 저장을 차단하고, 없으면 부모에게 저장 이벤트를 전송한다.
  """
  @spec handle_save(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_save(_params, socket) do
    grid = socket.assigns.grid

    if Grid.has_errors?(grid) do
      send(self(), {:grid_save_blocked, Grid.error_count(grid)})
      {:noreply, socket}
    else
      changed = Grid.changed_rows(grid)
      send(self(), {:grid_save_requested, changed})
      updated_grid = Grid.clear_row_statuses(grid)
      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  @doc """
  변경 사항을 폐기한다. 행 상태와 셀 오류를 초기화하고 부모에게 폐기 이벤트를 전송한다.
  """
  @spec handle_discard(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_discard(_params, socket) do
    grid = socket.assigns.grid
    send(self(), :grid_discard_requested)

    updated_grid = grid
      |> Grid.clear_row_statuses()
      |> Grid.clear_cell_errors()
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Import (F-511) ──

  @doc """
  CSV/Excel 파일 데이터를 그리드에 임포트한다. 헤더를 컬럼에 매핑하고 각 행을 추가한다.
  """
  @spec handle_import_file(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_import_file(%{"headers" => headers, "data" => data_rows}, socket) do
    grid = socket.assigns.grid
    display_cols = Grid.display_columns(grid)

    col_mapping = Enum.map(headers, fn header ->
      Enum.find(display_cols, fn col ->
        col.label == header ||
        to_string(col.field) == header ||
        String.downcase(col.label) == String.downcase(header) ||
        String.downcase(to_string(col.field)) == String.downcase(header)
      end)
    end)

    max_id = grid.data
      |> Enum.map(& &1.id)
      |> Enum.max(fn -> 0 end)

    {updated_grid, _} = Enum.reduce(data_rows, {grid, max_id + 1}, fn row_cells, {acc_grid, next_id} ->
      row_map = Enum.zip(col_mapping, row_cells)
        |> Enum.reject(fn {col, _val} -> is_nil(col) end)
        |> Enum.reduce(%{id: next_id}, fn {col, val}, acc ->
          parsed = RenderHelpers.parse_cell_value(val, col)
          Map.put(acc, col.field, parsed)
        end)

      new_grid = Grid.add_row(acc_grid, row_map)
      {new_grid, next_id + 1}
    end)

    send(self(), {:grid_import_completed, length(data_rows)})
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Paste (F-932) ──

  @doc """
  클립보드 붙여넣기를 처리한다. 시작 셀부터 붙여넣기 데이터를 편집 가능한 셀에 적용한다.
  """
  @spec handle_paste_cells(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_paste_cells(%{"start_row_id" => start_row_id, "start_col_idx" => start_col_idx, "data" => paste_rows}, socket) do
    grid = socket.assigns.grid
    display_cols = Grid.display_columns(grid)
    visible_data = Grid.visible_data(grid)

    start_row_idx = Enum.find_index(visible_data, fn r -> r.id == start_row_id end)

    if start_row_idx do
      updated_grid = Enum.reduce(Enum.with_index(paste_rows), grid, fn {paste_cols, row_offset}, acc_grid ->
        target_row_idx = start_row_idx + row_offset
        target_row = Enum.at(visible_data, target_row_idx)

        if target_row do
          Enum.reduce(Enum.with_index(paste_cols), acc_grid, fn {cell_val, col_offset}, acc ->
            target_col_idx = start_col_idx + col_offset
            target_col = Enum.at(display_cols, target_col_idx)

            if target_col && target_col.editable do
              parsed = RenderHelpers.parse_cell_value(cell_val, target_col)
              acc
              |> Grid.update_cell(target_row.id, target_col.field, parsed)
              |> Grid.validate_cell(target_row.id, target_col.field)
            else
              acc
            end
          end)
        else
          acc_grid
        end
      end)

      send(self(), {:grid_paste_completed, length(paste_rows)})
      {:noreply, assign(socket, grid: updated_grid)}
    else
      {:noreply, socket}
    end
  end

  # ── Export ──

  @doc """
  Excel(XLSX) 형식으로 데이터를 내보낸다. type에 따라 전체/필터된/선택된 데이터를 내보낸다.
  """
  @spec handle_export_excel(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_export_excel(%{"type" => type}, socket) do
    grid = socket.assigns.grid
    {data, columns} = export_data(grid, type)

    case Export.to_xlsx(data, columns) do
      {:ok, {_filename, binary}} ->
        content = Base.encode64(binary)
        timestamp = DateTime.utc_now() |> DateTime.to_unix()
        filename = "liveview_grid_#{type}_#{timestamp}.xlsx"

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

  @doc """
  CSV 형식으로 데이터를 내보낸다. type에 따라 전체/필터된/선택된 데이터를 내보낸다.
  """
  @spec handle_export_csv(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_export_csv(%{"type" => type}, socket) do
    grid = socket.assigns.grid
    {data, columns} = export_data(grid, type)

    csv_content = Export.to_csv(data, columns)
    content = Base.encode64(csv_content)
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    filename = "liveview_grid_#{type}_#{timestamp}.csv"

    send(self(), {:grid_download_file, %{
      content: content,
      filename: filename,
      mime_type: "text/csv;charset=utf-8"
    }})

    {:noreply, assign(socket, export_menu_open: nil)}
  end

  @doc """
  내보내기 메뉴(Excel/CSV 하위 옵션)를 토글한다.
  """
  @spec handle_toggle_export_menu(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_toggle_export_menu(%{"format" => format}, socket) do
    current = socket.assigns[:export_menu_open]
    new_value = if current == format, do: nil, else: format
    {:noreply, assign(socket, export_menu_open: new_value)}
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

  # ── Advanced Filter (F-310) ──

  @doc """
  고급 필터 패널 표시/숨김을 토글한다.
  """
  @spec handle_toggle_advanced_filter(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_toggle_advanced_filter(_params, socket) do
    grid = socket.assigns.grid
    show = !Map.get(grid.state, :show_advanced_filter, false)
    updated_grid = put_in(grid.state[:show_advanced_filter], show)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  고급 필터에 새 조건을 추가한다. 기본값은 field: nil, operator: :contains, value: "".
  """
  @spec handle_add_filter_condition(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_add_filter_condition(_params, socket) do
    grid = socket.assigns.grid
    adv = Map.get(grid.state, :advanced_filters, %{logic: :and, conditions: []})
    new_condition = %{field: nil, operator: :contains, value: ""}
    updated_adv = %{adv | conditions: adv.conditions ++ [new_condition]}
    updated_grid = put_in(grid.state[:advanced_filters], updated_adv)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  고급 필터 조건의 필드/연산자/값을 변경한다.
  필드 변경 시 해당 컬럼 타입에 맞는 기본 연산자가 자동 선택된다.
  """
  @spec handle_update_filter_condition(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_update_filter_condition(params, socket) do
    grid = socket.assigns.grid
    adv = Map.get(grid.state, :advanced_filters, %{logic: :and, conditions: []})
    index = String.to_integer(params["index"])

    conditions = List.update_at(adv.conditions, index, fn condition ->
      field_str = params["field"] || ""
      operator_str = params["operator"] || ""
      value_str = params["value"] || ""
      value_to_str = params["value_to"]

      new_field = if field_str != "", do: String.to_existing_atom(field_str), else: condition.field

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

  @doc """
  고급 필터에서 지정 인덱스의 조건을 제거한다.
  """
  @spec handle_remove_filter_condition(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_remove_filter_condition(%{"index" => index}, socket) do
    grid = socket.assigns.grid
    adv = Map.get(grid.state, :advanced_filters, %{logic: :and, conditions: []})
    idx = String.to_integer(index)
    updated_conditions = List.delete_at(adv.conditions, idx)
    updated_adv = %{adv | conditions: updated_conditions}
    updated_grid = put_in(grid.state[:advanced_filters], updated_adv)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  고급 필터의 논리 연산자(AND/OR)를 변경한다.
  """
  @spec handle_change_filter_logic(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_change_filter_logic(%{"logic" => logic}, socket) do
    grid = socket.assigns.grid
    adv = Map.get(grid.state, :advanced_filters, %{logic: :and, conditions: []})
    logic_atom = String.to_existing_atom(logic)
    updated_adv = %{adv | logic: logic_atom}
    updated_grid = put_in(grid.state[:advanced_filters], updated_adv)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  모든 고급 필터 조건을 초기화한다.
  """
  @spec handle_clear_advanced_filter(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_clear_advanced_filter(_params, socket) do
    grid = socket.assigns.grid
    updated_grid = put_in(grid.state[:advanced_filters], %{logic: :and, conditions: []})
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  폼 서브밋 기본 동작을 무시한다. 실수로 발생하는 form submit 이벤트 방지용.
  """
  @spec handle_noop_submit(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_noop_submit(_params, socket) do
    {:noreply, socket}
  end

  # ── Grouping (v0.7) ──

  @doc """
  그룹핑 필드를 설정한다. 쉼표로 구분된 필드 문자열을 파싱하여 그룹핑을 적용한다.
  """
  @spec handle_group_by(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_group_by(%{"fields" => fields_str}, socket) do
    grid = socket.assigns.grid
    fields = fields_str
      |> String.split(",", trim: true)
      |> Enum.map(&String.to_atom(String.trim(&1)))

    updated_grid = Grid.set_group_by(grid, fields)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  그룹 집계 함수를 설정한다. JSON 문자열을 파싱하여 필드별 집계(sum, avg, count 등)를 적용한다.
  """
  @spec handle_group_aggregates(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_group_aggregates(%{"aggregates" => agg_str}, socket) do
    grid = socket.assigns.grid
    aggregates = agg_str
      |> Jason.decode!()
      |> Enum.map(fn {k, v} -> {String.to_atom(k), String.to_atom(v)} end)
      |> Map.new()

    updated_grid = Grid.set_group_aggregates(grid, aggregates)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  그룹의 접기/펼치기를 토글한다.
  """
  @spec handle_toggle_group(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_toggle_group(%{"group-key" => group_key}, socket) do
    grid = socket.assigns.grid
    updated_grid = Grid.toggle_group(grid, group_key)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  그룹핑을 해제하고 플랫 뷰로 전환한다.
  """
  @spec handle_clear_grouping(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_clear_grouping(_params, socket) do
    grid = socket.assigns.grid
    updated_grid = Grid.set_group_by(grid, [])
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Tree Grid (v0.7) ──

  @doc """
  트리 모드 활성화/비활성화를 토글한다.
  """
  @spec handle_toggle_tree(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_toggle_tree(%{"enabled" => enabled}, socket) do
    grid = socket.assigns.grid
    parent_field = Map.get(grid.state, :tree_parent_field, :parent_id)
    updated_grid = Grid.set_tree_mode(grid, enabled == "true", parent_field)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  트리 노드의 접기/펼치기를 토글한다.
  """
  @spec handle_toggle_tree_node(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_toggle_tree_node(%{"node-id" => node_id_str}, socket) do
    grid = socket.assigns.grid
    node_id = String.to_integer(node_id_str)
    updated_grid = Grid.toggle_tree_node(grid, node_id)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── v0.7 Options ──

  @doc """
  v0.7 옵션(그룹핑, 트리 모드)을 그리드에 적용한다. Grid 초기화 시 사용된다.
  """
  @spec apply_v07_options(grid :: map(), options :: map()) :: map()
  def apply_v07_options(grid, options) do
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

    grid = if Map.has_key?(options, :merge_regions) do
      Enum.reduce(Map.get(options, :merge_regions, []), grid, fn spec, acc ->
        case Grid.merge_cells(acc, spec) do
          {:ok, updated} -> updated
          {:error, _reason} -> acc
        end
      end)
    else
      grid
    end

    grid
  end

  # ── F-930: Row Move ──

  @doc "행 드래그 이동 이벤트를 처리합니다."
  @spec handle_move_row(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_move_row(%{"from_id" => from_id_str, "to_id" => to_id_str}, socket) do
    grid = socket.assigns.grid
    from_id = parse_row_id(from_id_str, grid)
    to_id = parse_row_id(to_id_str, grid)

    if from_id && to_id do
      updated_grid = Grid.move_row(grid, from_id, to_id)
      {:noreply, assign(socket, grid: updated_grid)}
    else
      {:noreply, socket}
    end
  end

  defp parse_row_id(id_str, grid) do
    case Integer.parse(id_str) do
      {id, ""} -> id
      _ ->
        # 문자열 ID 지원
        atom_id = String.to_existing_atom(id_str)
        if Enum.any?(grid.data, &(&1.id == atom_id)), do: atom_id, else: nil
    end
  rescue
    _ -> nil
  end

  # ── Dynamic Freeze ──

  @doc "특정 컬럼까지 고정하거나, 이미 해당 위치에 고정되어 있으면 해제한다."
  def handle_freeze_to_column(%{"col_idx" => col_idx_str}, socket) do
    col_idx = String.to_integer(col_idx_str)
    grid = socket.assigns.grid
    new_count = col_idx + 1

    updated_grid =
      if grid.options.frozen_columns == new_count do
        Grid.set_frozen_columns(grid, 0)
      else
        Grid.set_frozen_columns(grid, new_count)
      end

    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── F-800: Context Menu ──

  @doc """
  셀 우클릭 컨텍스트 메뉴를 표시한다. 클릭 좌표(x, y)와 대상 셀 정보를 저장한다.
  """
  @spec handle_show_context_menu(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_show_context_menu(params, socket) do
    menu = %{
      row_id: params["row_id"],
      col_idx: params["col_idx"],
      x: params["x"],
      y: params["y"]
    }
    {:noreply, assign(socket, context_menu: menu)}
  end

  @doc """
  컨텍스트 메뉴를 숨긴다.
  """
  @spec handle_hide_context_menu(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_hide_context_menu(_params, socket) do
    {:noreply, assign(socket, context_menu: nil)}
  end

  @doc """
  컨텍스트 메뉴 항목 클릭을 처리한다. copy_cell, copy_row, insert_row_above/below, duplicate_row, delete_row를 지원한다.
  """
  @spec handle_context_menu_action(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_context_menu_action(params, socket) do
    action = params["action"]
    row_id_str = params["row-id"] || params["row_id"]
    row_id = if is_binary(row_id_str), do: String.to_integer(row_id_str), else: row_id_str
    col_idx_str = params["col-idx"] || params["col_idx"]
    col_idx = if is_binary(col_idx_str), do: String.to_integer(col_idx_str), else: col_idx_str

    socket = assign(socket, context_menu: nil)
    grid = socket.assigns.grid

    case action do
      "copy_cell" ->
        handle_ctx_copy_cell(grid, row_id, col_idx, socket)

      "copy_row" ->
        handle_ctx_copy_row(grid, row_id, socket)

      "insert_row_above" ->
        handle_ctx_insert_row(grid, row_id, :above, socket)

      "insert_row_below" ->
        handle_ctx_insert_row(grid, row_id, :below, socket)

      "duplicate_row" ->
        handle_ctx_duplicate_row(grid, row_id, socket)

      "delete_row" ->
        handle_ctx_delete_row(grid, row_id, socket)

      # FA-001: Row Pinning
      "pin_row_top" ->
        updated_grid = Grid.pin_row(grid, row_id, :top)
        {:noreply, assign(socket, grid: updated_grid)}

      "pin_row_bottom" ->
        updated_grid = Grid.pin_row(grid, row_id, :bottom)
        {:noreply, assign(socket, grid: updated_grid)}

      "unpin_row" ->
        updated_grid = Grid.unpin_row(grid, row_id)
        {:noreply, assign(socket, grid: updated_grid)}

      _ ->
        {:noreply, socket}
    end
  end

  defp handle_ctx_copy_cell(grid, row_id, col_idx, socket) do
    # F-940: 범위 선택이 있으면 범위 복사
    if grid.state.cell_range do
      handle_copy_cell_range(%{}, socket)
    else
      row = Enum.find(grid.data, fn r -> r.id == row_id end)
      visible_cols = Grid.display_columns(grid)
      col = Enum.at(visible_cols, col_idx)

      text = if row && col do
        value = Map.get(row, col.field, "")
        to_string(value)
      else
        ""
      end

      {:noreply, push_event(socket, "clipboard_write", %{text: text})}
    end
  end

  defp handle_ctx_copy_row(grid, row_id, socket) do
    row = Enum.find(grid.data, fn r -> r.id == row_id end)

    text = if row do
      Grid.display_columns(grid)
      |> Enum.map(fn col -> to_string(Map.get(row, col.field, "")) end)
      |> Enum.join("\t")
    else
      ""
    end

    {:noreply, push_event(socket, "clipboard_write", %{text: text})}
  end

  defp handle_ctx_insert_row(grid, row_id, position, socket) do
    # 1. 컬럼 기본값
    defaults = build_column_defaults(grid.columns)

    # 2. (C) 그룹핑 활성 시 그룹 키 복사
    defaults = copy_group_keys_from_target(defaults, grid, row_id)

    # 3. 새 행 생성
    temp_id = Grid.next_temp_id(grid)
    new_row = Map.merge(defaults, %{id: temp_id})

    # 4. (A) grid.data에서 대상 행 옆에 삽입
    idx = Enum.find_index(grid.data, fn r -> r.id == row_id end) || 0
    insert_idx = if position == :below, do: idx + 1, else: idx
    updated_data = List.insert_at(grid.data, insert_idx, new_row)

    # 5. 상태 갱신 (G: total_rows 갱신)
    updated_grid = %{grid | data: updated_data}
      |> put_in([:state, :row_statuses], Map.put(grid.state.row_statuses, temp_id, :new))
      |> put_in([:state, :pagination, :total_rows], length(updated_data))

    # 6. (F) Undo 히스토리
    updated_grid = Grid.push_edit_history(updated_grid, {:insert_row, temp_id, new_row})

    # 7. 부모 알림
    send(self(), {:grid_row_added, new_row})

    # 8. (E) 첫 편집 가능 컬럼 인덱스
    first_editable_idx = find_first_editable_col_idx(grid)

    # 9. (D, E) scroll + focus push_event
    {:noreply,
      socket
      |> assign(grid: updated_grid)
      |> push_event("scroll_to_row", %{row_id: temp_id})
      |> push_event("focus_cell", %{row_id: temp_id, col_idx: first_editable_idx})}
  end

  defp handle_ctx_duplicate_row(grid, row_id, socket) do
    row = Enum.find(grid.data, fn r -> r.id == row_id end)

    if row do
      temp_id = Grid.next_temp_id(grid)
      new_row = row |> Map.put(:id, temp_id)

      idx = Enum.find_index(grid.data, fn r -> r.id == row_id end) || 0
      updated_data = List.insert_at(grid.data, idx + 1, new_row)

      updated_grid = %{grid | data: updated_data}
        |> put_in([:state, :row_statuses], Map.put(grid.state.row_statuses, temp_id, :new))
        |> put_in([:state, :pagination, :total_rows], length(updated_data))

      send(self(), {:grid_row_added, new_row})
      {:noreply, assign(socket, grid: updated_grid)}
    else
      {:noreply, socket}
    end
  end

  defp handle_ctx_delete_row(grid, row_id, socket) do
    updated_grid = Grid.delete_rows(grid, [row_id])
    send(self(), {:grid_rows_deleted, [row_id]})
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── F-940: Cell Range Selection ──

  @doc """
  셀 범위 선택을 설정한다. 앵커 셀과 확장 셀의 좌표를 저장한다.
  """
  @spec handle_set_cell_range(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_set_cell_range(params, socket) do
    grid = socket.assigns.grid

    range = %{
      anchor_row_id: params["anchor_row_id"],
      anchor_col_idx: params["anchor_col_idx"],
      extent_row_id: params["extent_row_id"],
      extent_col_idx: params["extent_col_idx"]
    }

    updated_grid = Grid.set_cell_range(grid, range)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  @doc """
  셀 범위 선택을 해제한다.
  """
  @spec handle_clear_cell_range(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_clear_cell_range(_params, socket) do
    grid = socket.assigns.grid
    updated_grid = Grid.clear_cell_range(grid)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── F-800-INSERT Helpers ──

  defp build_column_defaults(columns) do
    Enum.reduce(columns, %{}, fn col, acc ->
      default_val = case col.editor_type do
        :number -> 0
        :date -> Date.utc_today()
        :checkbox -> false
        :select ->
          if col.editor_options != [], do: elem(hd(col.editor_options), 1), else: ""
        _ ->
          if col.filter_type == :date, do: Date.utc_today(), else: ""
      end
      Map.put(acc, col.field, default_val)
    end)
  end

  defp copy_group_keys_from_target(defaults, grid, row_id) do
    group_by = grid.state.group_by

    if is_list(group_by) and length(group_by) > 0 do
      target = Enum.find(grid.data, fn r -> r.id == row_id end)

      if target do
        Enum.reduce(group_by, defaults, fn field, acc ->
          case Map.get(target, field) do
            nil -> acc
            val -> Map.put(acc, field, val)
          end
        end)
      else
        defaults
      end
    else
      defaults
    end
  end

  defp find_first_editable_col_idx(grid) do
    Grid.display_columns(grid)
    |> Enum.with_index()
    |> Enum.find_value(0, fn {col, idx} -> if col.editable, do: idx end)
  end

  @doc """
  선택된 셀 범위의 데이터를 탭/줄바꿈 구분 텍스트로 클립보드에 복사한다.
  """
  @spec handle_copy_cell_range(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_copy_cell_range(_params, socket) do
    grid = socket.assigns.grid

    case grid.state.cell_range do
      nil ->
        {:noreply, socket}

      range ->
        visible_data = Grid.visible_data(grid)
        display_cols = Grid.display_columns(grid)
        visible_row_ids = Enum.map(visible_data, &(&1.id))

        anchor_pos = Enum.find_index(visible_row_ids, &(&1 == range.anchor_row_id))
        extent_pos = Enum.find_index(visible_row_ids, &(&1 == range.extent_row_id))

        if anchor_pos && extent_pos do
          min_row = min(anchor_pos, extent_pos)
          max_row = max(anchor_pos, extent_pos)
          min_col = min(range.anchor_col_idx, range.extent_col_idx)
          max_col = max(range.anchor_col_idx, range.extent_col_idx)

          text =
            min_row..max_row
            |> Enum.map(fn row_pos ->
              row = Enum.at(visible_data, row_pos)

              min_col..max_col
              |> Enum.map(fn col_idx ->
                col = Enum.at(display_cols, col_idx)
                if row && col, do: to_string(Map.get(row, col.field, "")), else: ""
              end)
              |> Enum.join("\t")
            end)
            |> Enum.join("\n")

          {:noreply, push_event(socket, "clipboard_write", %{text: text})}
        else
          {:noreply, socket}
        end
    end
  end

  # ── FA-013: Cell Fill Handle ──

  @doc "셀 자동채움 (드래그로 값 복사)"
  @spec handle_fill_cells(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_fill_cells(%{"source_row_id" => source_id, "field" => field, "target_row_ids" => target_ids}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_atom(field)
    source_row_id = parse_row_id(source_id)
    target_row_ids = Enum.map(target_ids, &parse_row_id/1)

    updated = Grid.fill_cells(grid, source_row_id, field_atom, target_row_ids)
    {:noreply, assign(socket, grid: updated)}
  end

  # ── FA-014: Master-Detail ──

  @doc "상세 패널 토글"
  @spec handle_toggle_detail(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_toggle_detail(%{"row_id" => row_id}, socket) do
    grid = socket.assigns.grid
    updated = Grid.toggle_detail(grid, parse_row_id(row_id))
    {:noreply, assign(socket, grid: updated)}
  end

  # ── F-961: Tree Batch Expand ──

  @doc "모든 트리 노드 펼침"
  @spec handle_expand_all(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_expand_all(_params, socket) do
    grid = socket.assigns.grid
    updated = Grid.expand_all_nodes(grid)
    {:noreply, assign(socket, grid: updated)}
  end

  @doc "모든 트리 노드 접기"
  @spec handle_collapse_all(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_collapse_all(_params, socket) do
    grid = socket.assigns.grid
    updated = Grid.collapse_all_nodes(grid)
    {:noreply, assign(socket, grid: updated)}
  end

  @doc "특정 레벨까지 트리 노드 펼침"
  @spec handle_expand_to_level(params :: map(), socket :: Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_expand_to_level(%{"level" => level}, socket) do
    grid = socket.assigns.grid
    level = if is_binary(level), do: String.to_integer(level), else: level
    updated = Grid.expand_to_level(grid, level)
    {:noreply, assign(socket, grid: updated)}
  end

  # ── Phase 5 (v1.0+) Event Handlers ──

  # FA-030: Side Bar
  def handle_toggle_sidebar(_params, socket) do
    grid = socket.assigns.grid
    updated = Grid.toggle_sidebar(grid)
    {:noreply, assign(socket, grid: updated)}
  end

  def handle_sidebar_tab(%{"tab" => tab}, socket) do
    grid = socket.assigns.grid
    tab_atom = String.to_existing_atom(tab)
    updated = Grid.set_sidebar_tab(grid, tab_atom)
    {:noreply, assign(socket, grid: updated)}
  end

  @spec handle_toggle_column_visibility(map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_toggle_column_visibility(%{"field" => field_str}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_existing_atom(field_str)
    hidden = Map.get(grid.state, :hidden_columns, [])

    # 원본 컬럼 목록 보존 (최초 숨김 시 state.all_columns에 저장)
    original_columns = get_all_columns(grid)

    new_hidden =
      if field_atom in hidden do
        List.delete(hidden, field_atom)
      else
        hidden ++ [field_atom]
      end

    visible_columns =
      original_columns
      |> Enum.reject(fn col -> col.field in new_hidden end)

    updated_grid =
      grid
      |> Map.put(:columns, visible_columns)
      |> put_in([:state, :hidden_columns], new_hidden)
      |> put_in([:state, :all_columns], original_columns)

    {:noreply, assign(socket, grid: updated_grid)}
  end

  defp get_all_columns(grid) do
    case grid do
      %{definition: %{columns: cols}} when is_list(cols) -> cols
      %{state: %{all_columns: cols}} when is_list(cols) -> cols
      _ -> grid.columns
    end
  end

  # FA-034: Batch Edit
  def handle_batch_edit(%{"field" => field, "value" => value}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_existing_atom(field)
    updated = Grid.batch_update_cells(grid, field_atom, value)
    {:noreply, assign(socket, grid: updated)}
  end

  # FA-044: Find & Highlight
  def handle_toggle_find(_params, socket) do
    grid = socket.assigns.grid
    updated = Grid.toggle_find_bar(grid)
    {:noreply, assign(socket, grid: updated)}
  end

  def handle_find(%{"text" => text}, socket) do
    grid = socket.assigns.grid
    updated = Grid.find_in_grid(grid, text)
    {:noreply, assign(socket, grid: updated)}
  end

  def handle_find_next(_params, socket) do
    grid = socket.assigns.grid
    updated = Grid.find_next(grid)
    {:noreply, assign(socket, grid: updated)}
  end

  def handle_find_prev(_params, socket) do
    grid = socket.assigns.grid
    updated = Grid.find_prev(grid)
    {:noreply, assign(socket, grid: updated)}
  end

  # FA-045: Large Text Editor
  def handle_large_text_open(%{"row-id" => row_id, "field" => field}, socket) do
    grid = socket.assigns.grid
    row_id = parse_row_id(row_id)
    field_atom = String.to_existing_atom(field)
    updated = Grid.start_large_text_edit(grid, row_id, field_atom)
    {:noreply, assign(socket, grid: updated)}
  end

  def handle_large_text_save(%{"value" => value}, socket) do
    grid = socket.assigns.grid
    updated = Grid.save_large_text_edit(grid, value)
    {:noreply, assign(socket, grid: updated)}
  end

  def handle_large_text_cancel(_params, socket) do
    grid = socket.assigns.grid
    updated = Grid.cancel_large_text_edit(grid)
    {:noreply, assign(socket, grid: updated)}
  end

  # row_id 파싱 헬퍼 (이미 존재하면 skip)
  defp parse_row_id(id) when is_integer(id), do: id
  defp parse_row_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} -> int
      _ -> id
    end
  end
  defp parse_row_id(id), do: id
end
