defmodule LiveViewGrid.DataSource.Ecto.QueryBuilder do
  @moduledoc """
  Converts Grid filter/sort/pagination state into Ecto.Query expressions.

  Supports all LiveViewGrid filter operators:
  - Text: contains, equals, starts_with, ends_with, is_empty, is_not_empty
  - Number: eq, neq, gt, lt, gte, lte
  - Advanced filters with AND/OR logic
  - Global search (LIKE across all columns)
  """

  import Ecto.Query

  @doc "Apply global search across all searchable columns using LIKE"
  def apply_global_search(query, "", _columns), do: query
  def apply_global_search(query, nil, _columns), do: query
  def apply_global_search(query, search_term, columns) do
    term = "%#{escape_like(search_term)}%"
    fields = Enum.map(columns, & &1.field)

    conditions =
      Enum.reduce(fields, dynamic(false), fn field, acc ->
        dynamic([r], ^acc or like(fragment("CAST(? AS TEXT)", field(r, ^field)), ^term))
      end)

    from(r in query, where: ^conditions)
  end

  @doc "Apply column filters"
  def apply_filters(query, filters, columns) when is_map(filters) do
    Enum.reduce(filters, query, fn {field_str, filter_value}, acc ->
      field = if is_atom(field_str), do: field_str, else: String.to_existing_atom(field_str)
      column = Enum.find(columns, fn c -> c.field == field end)
      filter_type = if column, do: Map.get(column, :filter_type, :text), else: :text

      apply_column_filter(acc, field, filter_value, filter_type)
    end)
  end

  @doc "Apply advanced filters (AND/OR conditions)"
  def apply_advanced_filters(query, %{conditions: []}), do: query
  def apply_advanced_filters(query, %{logic: logic, conditions: conditions}) do
    dynamic_conditions =
      conditions
      |> Enum.filter(fn c -> c.value != nil and c.value != "" end)
      |> Enum.map(&build_condition_dynamic/1)

    case {logic, dynamic_conditions} do
      {_, []} -> query
      {:and, conds} ->
        combined = Enum.reduce(conds, dynamic(true), fn cond, acc ->
          dynamic(^acc and ^cond)
        end)
        from(r in query, where: ^combined)
      {:or, conds} ->
        combined = Enum.reduce(conds, dynamic(false), fn cond, acc ->
          dynamic(^acc or ^cond)
        end)
        from(r in query, where: ^combined)
    end
  end

  @doc "Apply sort"
  def apply_sort(query, nil), do: query
  def apply_sort(query, %{field: field, direction: :asc}) do
    from(r in query, order_by: [asc: field(r, ^field)])
  end
  def apply_sort(query, %{field: field, direction: :desc}) do
    from(r in query, order_by: [desc: field(r, ^field)])
  end

  @doc "Apply pagination (limit/offset)"
  def apply_pagination(query, pagination, page_size) do
    page = pagination.current_page
    offset_val = (page - 1) * page_size

    from(r in query, limit: ^page_size, offset: ^offset_val)
  end

  # ── Private ──

  defp apply_column_filter(query, field, value, :text) when is_binary(value) do
    if value == "" do
      query
    else
      term = "%#{escape_like(value)}%"
      from(r in query, where: like(fragment("CAST(? AS TEXT)", field(r, ^field)), ^term))
    end
  end

  defp apply_column_filter(query, field, value, :number) when is_binary(value) do
    case parse_number_filter(value) do
      {:ok, op, num} -> apply_number_op(query, field, op, num)
      :error -> query
    end
  end

  defp apply_column_filter(query, _field, _value, _type), do: query

  defp apply_number_op(query, field, :gt, num),
    do: from(r in query, where: field(r, ^field) > ^num)
  defp apply_number_op(query, field, :lt, num),
    do: from(r in query, where: field(r, ^field) < ^num)
  defp apply_number_op(query, field, :gte, num),
    do: from(r in query, where: field(r, ^field) >= ^num)
  defp apply_number_op(query, field, :lte, num),
    do: from(r in query, where: field(r, ^field) <= ^num)
  defp apply_number_op(query, field, :eq, num),
    do: from(r in query, where: field(r, ^field) == ^num)
  defp apply_number_op(query, field, :neq, num),
    do: from(r in query, where: field(r, ^field) != ^num)

  defp parse_number_filter(value) do
    cond do
      String.starts_with?(value, ">=") ->
        parse_num_with_op(value, ">=", :gte)
      String.starts_with?(value, "<=") ->
        parse_num_with_op(value, "<=", :lte)
      String.starts_with?(value, "!=") ->
        parse_num_with_op(value, "!=", :neq)
      String.starts_with?(value, ">") ->
        parse_num_with_op(value, ">", :gt)
      String.starts_with?(value, "<") ->
        parse_num_with_op(value, "<", :lt)
      String.starts_with?(value, "=") ->
        parse_num_with_op(value, "=", :eq)
      true ->
        case parse_number(value) do
          {:ok, num} -> {:ok, :eq, num}
          :error -> :error
        end
    end
  end

  defp parse_num_with_op(value, prefix, op) do
    num_str = String.trim_leading(value, prefix) |> String.trim()
    case parse_number(num_str) do
      {:ok, num} -> {:ok, op, num}
      :error -> :error
    end
  end

  # Parse as integer first, fall back to float (Ecto type casting requirement)
  defp parse_number(str) do
    case Integer.parse(str) do
      {num, ""} -> {:ok, num}
      {_num, _rest} ->
        case Float.parse(str) do
          {num, _} -> {:ok, num}
          :error -> :error
        end
      :error ->
        case Float.parse(str) do
          {num, _} -> {:ok, num}
          :error -> :error
        end
    end
  end

  defp build_condition_dynamic(%{field: field_str, operator: operator, value: value}) do
    field = if is_atom(field_str), do: field_str, else: String.to_existing_atom(field_str)

    case operator do
      "contains" ->
        term = "%#{escape_like(value)}%"
        dynamic([r], like(fragment("CAST(? AS TEXT)", field(r, ^field)), ^term))

      "equals" ->
        dynamic([r], fragment("CAST(? AS TEXT)", field(r, ^field)) == ^value)

      "starts_with" ->
        term = "#{escape_like(value)}%"
        dynamic([r], like(fragment("CAST(? AS TEXT)", field(r, ^field)), ^term))

      "ends_with" ->
        term = "%#{escape_like(value)}"
        dynamic([r], like(fragment("CAST(? AS TEXT)", field(r, ^field)), ^term))

      "is_empty" ->
        dynamic([r], is_nil(field(r, ^field)) or fragment("CAST(? AS TEXT)", field(r, ^field)) == "")

      "is_not_empty" ->
        dynamic([r], not is_nil(field(r, ^field)) and fragment("CAST(? AS TEXT)", field(r, ^field)) != "")

      "eq" ->
        {:ok, num} = parse_number(value)
        dynamic([r], field(r, ^field) == ^num)

      "neq" ->
        {:ok, num} = parse_number(value)
        dynamic([r], field(r, ^field) != ^num)

      "gt" ->
        {:ok, num} = parse_number(value)
        dynamic([r], field(r, ^field) > ^num)

      "lt" ->
        {:ok, num} = parse_number(value)
        dynamic([r], field(r, ^field) < ^num)

      "gte" ->
        {:ok, num} = parse_number(value)
        dynamic([r], field(r, ^field) >= ^num)

      "lte" ->
        {:ok, num} = parse_number(value)
        dynamic([r], field(r, ^field) <= ^num)

      _ ->
        dynamic(true)
    end
  end

  defp escape_like(term) do
    term
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end
end
