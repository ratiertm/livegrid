defmodule LiveViewGrid.DataSource.InMemory do
  @moduledoc """
  In-memory data source adapter.

  Wraps existing Filter, Sorting, Pagination modules.
  This is the default adapter used when `data_source` is not explicitly set,
  preserving full backward compatibility with v0.1/v0.2 behavior.
  """

  @behaviour LiveViewGrid.DataSource

  alias LiveViewGrid.{Filter, Sorting, Pagination}

  @impl true
  def fetch_data(%{data: data}, state, options, columns) do
    # Apply the same pipeline as Grid.visible_data/1
    searched = apply_global_search(data, state.global_search, columns)
    filtered = apply_filters(searched, state.filters, columns)
    advanced = apply_advanced_filters(filtered, state.advanced_filters, columns)
    sorted = apply_sort(advanced, state.sort)

    total_count = length(data)
    filtered_count = length(sorted)

    rows =
      if options.virtual_scroll do
        apply_virtual_scroll(sorted, state.scroll_offset, options)
      else
        apply_pagination(sorted, state.pagination, options.page_size)
      end

    {rows, total_count, filtered_count}
  end

  @impl true
  def insert_row(%{data: _data}, row_data) do
    # In-memory: just return the row as-is (ID management is handled by Grid)
    {:ok, row_data}
  end

  @impl true
  def update_row(%{data: _data}, _row_id, changes) do
    # In-memory: return changes (actual data update is handled by Grid)
    {:ok, changes}
  end

  @impl true
  def delete_row(%{data: _data}, _row_id) do
    # In-memory: just acknowledge (actual removal is handled by Grid)
    :ok
  end

  # ── Private: reuses existing operation modules ──

  defp apply_global_search(data, "", _columns), do: data
  defp apply_global_search(data, nil, _columns), do: data
  defp apply_global_search(data, query, columns) do
    Filter.global_search(data, query, columns)
  end

  defp apply_filters(data, filters, _columns) when map_size(filters) == 0, do: data
  defp apply_filters(data, filters, columns) do
    Filter.apply(data, filters, columns)
  end

  defp apply_advanced_filters(data, %{conditions: conditions} = adv, columns)
       when is_list(conditions) and length(conditions) > 0 do
    Filter.apply_advanced(data, adv, columns)
  end
  defp apply_advanced_filters(data, _, _columns), do: data

  defp apply_sort(data, nil), do: data
  defp apply_sort(data, %{field: field, direction: direction}) do
    Sorting.sort(data, field, direction)
  end

  defp apply_pagination(data, pagination, page_size) do
    Pagination.paginate(data, pagination.current_page, page_size)
  end

  defp apply_virtual_scroll([], _scroll_offset, _options), do: []
  defp apply_virtual_scroll(data, scroll_offset, options) do
    total_rows = length(data)
    row_height = options.row_height
    buffer = options.virtual_buffer

    viewport_height = Map.get(options, :viewport_height, 600)
    visible_rows = div(viewport_height, row_height)

    start_index = max(0, scroll_offset - buffer)
    end_index = min(total_rows - 1, scroll_offset + visible_rows + buffer)

    if start_index >= total_rows or end_index < start_index do
      []
    else
      data
      |> Enum.slice(start_index..end_index//1)
      |> Enum.with_index(start_index)
      |> Enum.map(fn {row, idx} -> Map.put(row, :_virtual_index, idx) end)
    end
  end
end
