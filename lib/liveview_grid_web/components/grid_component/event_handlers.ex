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

  def handle_page_change(%{"page" => page}, socket) do
    grid = socket.assigns.grid
    page_num = String.to_integer(page)
    updated_grid = put_in(grid.state.pagination.current_page, page_num)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_page_size_change(%{"page_size" => page_size}, socket) do
    grid = socket.assigns.grid
    new_size = String.to_integer(page_size)

    updated_grid = grid
    |> put_in([:options, :page_size], new_size)
    |> put_in([:state, :pagination, :current_page], 1)

    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Column Operations ──

  def handle_column_resize(%{"field" => field, "width" => width}, socket) do
    grid = socket.assigns.grid
    field_atom = String.to_existing_atom(field)
    width_int = String.to_integer(width)

    updated_grid = Grid.resize_column(grid, field_atom, max(width_int, 50))
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_column_reorder(%{"order" => order}, socket) do
    grid = socket.assigns.grid
    field_atoms = Enum.map(order, &String.to_existing_atom/1)

    updated_grid = Grid.reorder_columns(grid, field_atoms)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Row Selection ──

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

  def handle_toggle_status_column(_params, socket) do
    grid = socket.assigns.grid
    updated_grid = put_in(grid.state.show_status_column, !grid.state.show_status_column)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Filtering ──

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

  def handle_cell_edit_save_nil_editing(socket) do
    {:noreply, socket}
  end

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
      updated_grid = grid
        |> Grid.update_cell(row_id_int, field_atom, parsed_value)
        |> Grid.validate_cell(row_id_int, field_atom)
        |> Grid.push_edit_history({:update_cell, row_id_int, field_atom, original_value, parsed_value})
        |> put_in([:state, :editing], nil)

      send(self(), {:grid_cell_updated, row_id_int, field_atom, parsed_value})
      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

  def handle_cell_edit_cancel(_params, socket) do
    grid = socket.assigns.grid
    updated_grid = put_in(grid.state.editing, nil)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_cell_keydown_enter(%{"value" => _value} = params, socket) do
    {:noreply, socket} = handle_cell_edit_save(params, socket)
    {:noreply, push_event(socket, "grid_edit_ended", %{direction: "stay"})}
  end

  def handle_cell_keydown_escape(socket) do
    {:noreply, socket} = handle_cell_edit_cancel(%{}, socket)
    {:noreply, push_event(socket, "grid_edit_ended", %{direction: "stay"})}
  end

  def handle_cell_keydown_other(socket) do
    {:noreply, socket}
  end

  def handle_cell_edit_save_and_move(%{"direction" => direction} = params, socket) do
    save_params = Map.take(params, ["row-id", "field", "value"])
    {:noreply, socket} = handle_cell_edit_save(save_params, socket)
    {:noreply, push_event(socket, "grid_edit_ended", %{direction: direction})}
  end

  def handle_cell_edit_date(%{"field" => field, "row-id" => row_id, "value" => value}, socket) do
    handle_cell_edit_save(%{"row-id" => row_id, "field" => field, "value" => value}, socket)
  end

  # ── Checkbox (F-905) ──

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

  def handle_row_edit_start(%{"row-id" => row_id}, socket) do
    grid = socket.assigns.grid
    row_id_int = String.to_integer(row_id)

    updated_grid = grid
      |> put_in([:state, :editing_row], row_id_int)
      |> put_in([:state, :editing], nil)

    {:noreply, assign(socket, grid: updated_grid)}
  end

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

  def handle_row_edit_cancel(%{"row-id" => _row_id}, socket) do
    grid = socket.assigns.grid
    updated_grid = put_in(grid.state.editing_row, nil)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Undo/Redo (F-700) ──

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

  def handle_add_row(_params, socket) do
    grid = socket.assigns.grid
    defaults = build_column_defaults(grid.columns)

    updated_grid = Grid.add_row(grid, defaults, :top)
    send(self(), {:grid_row_added, hd(updated_grid.data)})
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_delete_selected(_params, socket) do
    grid = socket.assigns.grid
    selected_ids = grid.state.selection.selected_ids

    if selected_ids == [] do
      {:noreply, socket}
    else
      updated_grid = grid
        |> Grid.delete_rows(selected_ids)
        |> put_in([:state, :selection, :selected_ids], [])
        |> put_in([:state, :selection, :select_all], false)

      send(self(), {:grid_rows_deleted, selected_ids})
      {:noreply, assign(socket, grid: updated_grid)}
    end
  end

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

  def handle_discard(_params, socket) do
    grid = socket.assigns.grid
    send(self(), :grid_discard_requested)

    updated_grid = grid
      |> Grid.clear_row_statuses()
      |> Grid.clear_cell_errors()
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Import (F-511) ──

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

  def handle_toggle_advanced_filter(_params, socket) do
    grid = socket.assigns.grid
    show = !Map.get(grid.state, :show_advanced_filter, false)
    updated_grid = put_in(grid.state[:show_advanced_filter], show)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_add_filter_condition(_params, socket) do
    grid = socket.assigns.grid
    adv = Map.get(grid.state, :advanced_filters, %{logic: :and, conditions: []})
    new_condition = %{field: nil, operator: :contains, value: ""}
    updated_adv = %{adv | conditions: adv.conditions ++ [new_condition]}
    updated_grid = put_in(grid.state[:advanced_filters], updated_adv)
    {:noreply, assign(socket, grid: updated_grid)}
  end

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

  def handle_remove_filter_condition(%{"index" => index}, socket) do
    grid = socket.assigns.grid
    adv = Map.get(grid.state, :advanced_filters, %{logic: :and, conditions: []})
    idx = String.to_integer(index)
    updated_conditions = List.delete_at(adv.conditions, idx)
    updated_adv = %{adv | conditions: updated_conditions}
    updated_grid = put_in(grid.state[:advanced_filters], updated_adv)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_change_filter_logic(%{"logic" => logic}, socket) do
    grid = socket.assigns.grid
    adv = Map.get(grid.state, :advanced_filters, %{logic: :and, conditions: []})
    logic_atom = String.to_existing_atom(logic)
    updated_adv = %{adv | logic: logic_atom}
    updated_grid = put_in(grid.state[:advanced_filters], updated_adv)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_clear_advanced_filter(_params, socket) do
    grid = socket.assigns.grid
    updated_grid = put_in(grid.state[:advanced_filters], %{logic: :and, conditions: []})
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_noop_submit(_params, socket) do
    {:noreply, socket}
  end

  # ── Grouping (v0.7) ──

  def handle_group_by(%{"fields" => fields_str}, socket) do
    grid = socket.assigns.grid
    fields = fields_str
      |> String.split(",", trim: true)
      |> Enum.map(&String.to_atom(String.trim(&1)))

    updated_grid = Grid.set_group_by(grid, fields)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_group_aggregates(%{"aggregates" => agg_str}, socket) do
    grid = socket.assigns.grid
    aggregates = agg_str
      |> Jason.decode!()
      |> Enum.map(fn {k, v} -> {String.to_atom(k), String.to_atom(v)} end)
      |> Map.new()

    updated_grid = Grid.set_group_aggregates(grid, aggregates)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_toggle_group(%{"group-key" => group_key}, socket) do
    grid = socket.assigns.grid
    updated_grid = Grid.toggle_group(grid, group_key)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_clear_grouping(_params, socket) do
    grid = socket.assigns.grid
    updated_grid = Grid.set_group_by(grid, [])
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── Tree Grid (v0.7) ──

  def handle_toggle_tree(%{"enabled" => enabled}, socket) do
    grid = socket.assigns.grid
    parent_field = Map.get(grid.state, :tree_parent_field, :parent_id)
    updated_grid = Grid.set_tree_mode(grid, enabled == "true", parent_field)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  def handle_toggle_tree_node(%{"node-id" => node_id_str}, socket) do
    grid = socket.assigns.grid
    node_id = String.to_integer(node_id_str)
    updated_grid = Grid.toggle_tree_node(grid, node_id)
    {:noreply, assign(socket, grid: updated_grid)}
  end

  # ── v0.7 Options ──

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

    grid
  end

  # ── F-800: Context Menu ──

  def handle_show_context_menu(params, socket) do
    menu = %{
      row_id: params["row_id"],
      col_idx: params["col_idx"],
      x: params["x"],
      y: params["y"]
    }
    {:noreply, assign(socket, context_menu: menu)}
  end

  def handle_hide_context_menu(_params, socket) do
    {:noreply, assign(socket, context_menu: nil)}
  end

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
end
