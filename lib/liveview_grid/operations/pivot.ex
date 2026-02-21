defmodule LiveViewGrid.Pivot do
  @moduledoc """
  Pivot Table operation for LiveView Grid.

  Transforms flat data into a pivot table by:
  - Row dimensions: fields that become row labels
  - Column dimension: field whose unique values become dynamic columns
  - Value field: field to aggregate
  - Aggregate function: :sum, :avg, :count, :min, :max

  ## Example

      data = [
        %{department: "개발", status: "재직", salary: 50_000_000},
        %{department: "개발", status: "퇴직", salary: 40_000_000},
        %{department: "마케팅", status: "재직", salary: 45_000_000},
      ]

      config = %{
        row_fields: [:department],
        col_field: :status,
        value_field: :salary,
        aggregate: :sum
      }

      {columns, rows} = Pivot.transform(data, config)
      # columns => [
      #   %{field: :department, label: "department"},
      #   %{field: :"재직", label: "재직"},
      #   %{field: :"퇴직", label: "퇴직"},
      #   %{field: :_total, label: "합계"}
      # ]
      # rows => [
      #   %{id: 1, department: "개발", "재직": 50000000, "퇴직": 40000000, _total: 90000000},
      #   %{id: 2, department: "마케팅", "재직": 45000000, "퇴직": 0, _total: 45000000}
      # ]
  """

  @doc """
  Transform flat data into pivot table format.

  Returns `{dynamic_columns, pivot_rows}` where:
  - `dynamic_columns` - list of column definitions for the pivot view
  - `pivot_rows` - list of aggregated row maps

  ## Config
  - `:row_fields` - list of atoms for row dimensions
  - `:col_field` - atom for column dimension
  - `:value_field` - atom for the value to aggregate
  - `:aggregate` - `:sum | :avg | :count | :min | :max`
  """
  @spec transform(list(map()), map()) :: {list(map()), list(map())}
  def transform(data, config) do
    row_fields = Map.get(config, :row_fields, [])
    col_field = Map.get(config, :col_field)
    value_field = Map.get(config, :value_field)
    aggregate = Map.get(config, :aggregate, :sum)

    # Get unique column values (sorted)
    col_values = data
      |> Enum.map(&Map.get(&1, col_field))
      |> Enum.uniq()
      |> Enum.sort_by(&to_string/1)

    # Group by row dimensions
    grouped = Enum.group_by(data, fn row ->
      Enum.map(row_fields, &Map.get(row, &1))
    end)

    # Build pivot rows
    pivot_rows = grouped
      |> Enum.sort_by(fn {key, _} -> Enum.map(key, &to_string/1) end)
      |> Enum.with_index(1)
      |> Enum.map(fn {{row_key, rows}, idx} ->
        # Base row with row dimension values
        base = row_fields
          |> Enum.zip(row_key)
          |> Enum.into(%{id: idx})

        # For each column value, compute aggregate
        col_data = Map.new(col_values, fn cv ->
          matching = Enum.filter(rows, fn r -> Map.get(r, col_field) == cv end)
          {safe_field(cv), aggregate_values(matching, value_field, aggregate)}
        end)

        # Total across all column values
        all_values = Enum.map(rows, &Map.get(&1, value_field))
        total = aggregate_list(all_values, aggregate)

        base
        |> Map.merge(col_data)
        |> Map.put(:_total, total)
      end)

    # Build dynamic columns
    row_columns = Enum.map(row_fields, fn f ->
      %{field: f, label: to_string(f), sortable: true, width: 150}
    end)

    value_columns = Enum.map(col_values, fn cv ->
      %{field: safe_field(cv), label: to_string(cv), sortable: true, width: 120, align: :right, filter_type: :number}
    end)

    total_column = %{field: :_total, label: "Total", sortable: true, width: 120, align: :right, filter_type: :number}

    columns = row_columns ++ value_columns ++ [total_column]

    {columns, pivot_rows}
  end

  defp aggregate_values(rows, value_field, aggregate) do
    values = rows
      |> Enum.map(&Map.get(&1, value_field))
      |> Enum.filter(&is_number/1)

    aggregate_list(values, aggregate)
  end

  defp aggregate_list([], :count), do: 0
  defp aggregate_list([], _), do: 0
  defp aggregate_list(values, :sum), do: Enum.sum(values)
  defp aggregate_list(values, :avg) do
    nums = Enum.filter(values, &is_number/1)
    if nums == [], do: 0, else: Float.round(Enum.sum(nums) / length(nums), 2)
  end
  defp aggregate_list(values, :count), do: length(values)
  defp aggregate_list(values, :min) do
    nums = Enum.filter(values, &is_number/1)
    if nums == [], do: 0, else: Enum.min(nums)
  end
  defp aggregate_list(values, :max) do
    nums = Enum.filter(values, &is_number/1)
    if nums == [], do: 0, else: Enum.max(nums)
  end
  defp aggregate_list(_, _), do: 0

  # Convert column value to safe atom field name
  defp safe_field(value) when is_atom(value), do: value
  defp safe_field(value), do: String.to_atom(to_string(value))
end
