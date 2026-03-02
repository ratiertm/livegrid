defmodule LiveViewGrid.Grouping do
  @moduledoc """
  Grouping operation for LiveView Grid.

  Groups flat data by one or more fields, producing a list of
  group header rows and data rows with expand/collapse support.

  Group rows are marked with `_row_type: :group_header` and contain:
  - `_group_key`: the group identifier (field value or tuple for multi-level)
  - `_group_field`: which field this group is for
  - `_group_value`: the display value
  - `_group_count`: number of rows in this group
  - `_group_depth`: nesting depth (0-based)
  - `_group_aggregates`: map of field => aggregate value

  Data rows within groups get `_row_type: :data` (or retain no marker).
  """

  @doc """
  Groups data by the given fields and returns a flat list
  with group header rows interleaved.

  ## Parameters
  - `data` - flat list of row maps
  - `group_by` - list of field atoms to group by (supports multi-level)
  - `expanded` - map of `{group_key} => boolean` for expand/collapse
  - `aggregates` - map of `field => :sum | :avg | :count | :min | :max`

  ## Returns
  Flat list with group headers and data rows mixed:
  ```
  [
    %{_row_type: :group_header, _group_key: "개발", _group_field: :department, ...},
    %{id: 1, name: "Alice", department: "개발", ...},
    %{id: 2, name: "Bob", department: "개발", ...},
    %{_row_type: :group_header, _group_key: "마케팅", _group_field: :department, ...},
    ...
  ]
  ```
  """
  @spec group_data(list(map()), list(atom()), map(), map()) :: list(map())
  def group_data(data, [], _expanded, _aggregates), do: data
  def group_data(data, group_by, expanded, aggregates) do
    do_group(data, group_by, expanded, aggregates, 0, [])
  end

  defp do_group(data, [], _expanded, _aggregates, _depth, _parent_keys), do: data
  defp do_group(data, [field | rest_fields], expanded, aggregates, depth, parent_keys) do
    data
    |> Enum.group_by(&Map.get(&1, field))
    |> Enum.sort_by(fn {key, _} -> to_string(key) end)
    |> Enum.flat_map(fn {value, rows} ->
      group_key = parent_keys ++ [value]
      key_string = Enum.join(Enum.map(group_key, &to_string/1), "|")
      is_expanded = Map.get(expanded, key_string, true)

      header = %{
        _row_type: :group_header,
        _group_key: key_string,
        _group_field: field,
        _group_value: value,
        _group_count: length(rows),
        _group_depth: depth,
        _group_expanded: is_expanded,
        _group_aggregates: compute_aggregates(rows, aggregates)
      }

      if is_expanded do
        child_rows = if rest_fields != [] do
          do_group(rows, rest_fields, expanded, aggregates, depth + 1, group_key)
        else
          rows
        end
        [header | child_rows]
      else
        [header]
      end
    end)
  end

  @doc """
  Compute aggregate values for a set of rows.
  """
  @spec compute_aggregates(list(map()), map()) :: map()
  def compute_aggregates(_rows, aggregates) when map_size(aggregates) == 0, do: %{}
  def compute_aggregates(rows, aggregates) do
    Map.new(aggregates, fn {field, func} ->
      values = rows
        |> Enum.map(&Map.get(&1, field))
        |> Enum.filter(&is_number/1)

      result = case func do
        :sum -> Enum.sum(values)
        :avg ->
          if values == [], do: 0, else: Enum.sum(values) / length(values)
        :count -> length(rows)
        :min -> if values == [], do: nil, else: Enum.min(values)
        :max -> if values == [], do: nil, else: Enum.max(values)
        _ -> nil
      end

      {field, result}
    end)
  end

  @doc """
  Toggle a group's expanded state.
  """
  @spec toggle_group(map(), String.t()) :: map()
  def toggle_group(expanded, group_key) do
    current = Map.get(expanded, group_key, true)
    Map.put(expanded, group_key, !current)
  end

  # ── F-963: Multi-Level Subtotals ──

  @doc """
  그룹 데이터에 소계 행을 삽입합니다.

  ## Parameters
  - `grouped_data` - group_data/4의 결과
  - `aggregates` - 집계 설정 맵 (%{field => :sum | :avg | ...})
  - `position` - 소계 위치 (:bottom | :top)
  """
  @spec insert_subtotals(list(map()), map(), atom()) :: list(map())
  def insert_subtotals(grouped_data, aggregates, position \\ :bottom)
  def insert_subtotals(grouped_data, aggregates, position) when map_size(aggregates) > 0 do
    do_insert_subtotals(grouped_data, aggregates, position, [])
    |> Enum.reverse()
  end
  def insert_subtotals(grouped_data, _aggregates, _position), do: grouped_data

  defp do_insert_subtotals([], _aggregates, _position, acc), do: acc
  defp do_insert_subtotals([%{_row_type: :group_header} = header | rest], aggregates, position, acc) do
    # Collect data rows for this group (until next group header of same or lower depth)
    {group_rows, remaining} = collect_group_rows(rest, header._group_depth)

    subtotal_row = %{
      _row_type: :subtotal,
      _group_key: header._group_key,
      _group_field: header._group_field,
      _group_value: header._group_value,
      _group_depth: header._group_depth,
      _subtotal_aggregates: compute_aggregates(data_rows_only(group_rows), aggregates)
    }

    # Recurse into group_rows first (they may contain sub-groups)
    processed_rows = do_insert_subtotals(group_rows, aggregates, position, []) |> Enum.reverse()

    new_acc = case position do
      :top ->
        [subtotal_row | processed_rows] ++ [header | acc]
      _ ->
        Enum.reverse([header | Enum.reverse(processed_rows ++ [subtotal_row])]) ++ acc
    end

    do_insert_subtotals(remaining, aggregates, position, Enum.reverse(new_acc))
  end
  defp do_insert_subtotals([row | rest], aggregates, position, acc) do
    do_insert_subtotals(rest, aggregates, position, [row | acc])
  end

  defp collect_group_rows(rows, parent_depth) do
    Enum.split_while(rows, fn row ->
      case Map.get(row, :_row_type) do
        :group_header -> row._group_depth > parent_depth
        _ -> true
      end
    end)
  end

  defp data_rows_only(rows) do
    Enum.filter(rows, fn row ->
      Map.get(row, :_row_type) not in [:group_header, :subtotal]
    end)
  end
end
