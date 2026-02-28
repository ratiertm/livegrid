defmodule LiveViewGrid.DataSource.RawTable do
  @moduledoc """
  Raw SQL data source adapter for schema-less database tables.

  Uses parameterized SQL queries to provide full CRUD without requiring
  an Ecto schema. Designed for Grid Builder's "Table Browse" mode.

  ## Config

      %{
        repo: MyApp.Repo,
        table: "demo_users",
        primary_key: "id"
      }

  ## Safety

  Table and column names are validated against `[a-zA-Z0-9_]` pattern.
  All values are parameterized to prevent SQL injection.
  """

  @behaviour LiveViewGrid.DataSource

  alias LiveViewGrid.TableInspector

  @doc """
  Raw SQL로 테이블 데이터를 조회한다. 스키마 없이 파라미터화된 SQL로 필터/정렬/페이지네이션을 처리한다.
  """
  @impl true
  def fetch_data(config, state, options, columns) do
    repo = config.repo
    table = config.table
    pk = Map.get(config, :primary_key, "id")

    unless valid_identifier?(table) do
      {[], 0, 0}
    else
      # Validate column names
      valid_fields = valid_column_names(repo, table)

      # Total count
      total_count = count_rows(repo, table)

      # Build WHERE clause from filters
      {where_clause, where_params} = build_where(state, columns, valid_fields)

      # Filtered count
      filtered_count = count_rows(repo, table, where_clause, where_params)

      # ORDER BY
      order_clause = build_order_by(state, valid_fields, pk)

      # LIMIT / OFFSET
      page_size = Map.get(options, :page_size, 20)
      page = get_in(state, [:pagination, :current_page]) || 1
      offset = (page - 1) * page_size

      sql = "SELECT * FROM #{table}#{where_clause}#{order_clause} LIMIT ? OFFSET ?"
      params = where_params ++ [page_size, offset]

      rows =
        case safe_query(repo, sql, params) do
          {:ok, result} -> result_to_maps(result)
          {:error, _} -> []
        end

      {rows, total_count, filtered_count}
    end
  end

  @doc """
  Raw SQL INSERT로 새 행을 추가한다. 유효한 컬럼만 필터링하고 PK는 자동 제외한다.
  """
  @impl true
  def insert_row(config, row_data) do
    repo = config.repo
    table = config.table
    pk = Map.get(config, :primary_key, "id")
    valid_fields = valid_column_names(repo, table)

    # Filter to only valid columns, exclude primary key
    fields =
      row_data
      |> Enum.filter(fn {k, _v} -> to_string(k) in valid_fields and to_string(k) != pk end)
      |> Enum.map(fn {k, v} -> {to_string(k), v} end)

    if fields == [] do
      {:error, :no_valid_fields}
    else
      col_names = Enum.map(fields, &elem(&1, 0))
      values = Enum.map(fields, &elem(&1, 1))
      placeholders = Enum.map_join(1..length(fields), ", ", fn _ -> "?" end)
      cols_str = Enum.join(col_names, ", ")

      sql = "INSERT INTO #{table} (#{cols_str}) VALUES (#{placeholders})"

      case safe_query(repo, sql, values) do
        {:ok, %{last_insert_id: insert_id}} when not is_nil(insert_id) ->
          fetch_row(repo, table, pk, insert_id)

        {:ok, _} ->
          {:ok, Map.new(fields)}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Raw SQL UPDATE로 행을 수정한다. 유효한 컬럼만 SET 절에 포함한다.
  """
  @impl true
  def update_row(config, row_id, changes) do
    repo = config.repo
    table = config.table
    pk = Map.get(config, :primary_key, "id")
    valid_fields = valid_column_names(repo, table)

    fields =
      changes
      |> Enum.filter(fn {k, _v} -> to_string(k) in valid_fields and to_string(k) != pk end)
      |> Enum.map(fn {k, v} -> {to_string(k), v} end)

    if fields == [] do
      {:error, :no_valid_fields}
    else
      set_clause = Enum.map_join(fields, ", ", fn {col, _} -> "#{col} = ?" end)
      values = Enum.map(fields, &elem(&1, 1)) ++ [row_id]

      sql = "UPDATE #{table} SET #{set_clause} WHERE #{pk} = ?"

      case safe_query(repo, sql, values) do
        {:ok, _} -> fetch_row(repo, table, pk, row_id)
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Raw SQL DELETE로 행을 삭제한다. 삭제된 행이 없으면 `:not_found` 에러를 반환한다.
  """
  @impl true
  def delete_row(config, row_id) do
    repo = config.repo
    table = config.table
    pk = Map.get(config, :primary_key, "id")

    sql = "DELETE FROM #{table} WHERE #{pk} = ?"

    case safe_query(repo, sql, [row_id]) do
      {:ok, %{num_rows: n}} when n > 0 -> :ok
      {:ok, _} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  # ── Private Helpers ──

  defp fetch_row(repo, table, pk, row_id) do
    sql = "SELECT * FROM #{table} WHERE #{pk} = ? LIMIT 1"

    case safe_query(repo, sql, [row_id]) do
      {:ok, %{rows: [row | _]} = result} ->
        {:ok, row_to_map(result.columns, row)}

      _ ->
        {:error, :not_found}
    end
  end

  defp count_rows(repo, table) do
    case safe_query(repo, "SELECT COUNT(*) FROM #{table}") do
      {:ok, %{rows: [[count]]}} -> count
      _ -> 0
    end
  end

  defp count_rows(repo, table, where_clause, where_params) do
    sql = "SELECT COUNT(*) FROM #{table}#{where_clause}"

    case safe_query(repo, sql, where_params) do
      {:ok, %{rows: [[count]]}} -> count
      _ -> 0
    end
  end

  defp build_where(state, columns, valid_fields) do
    conditions = []
    params = []

    # Global search
    {conditions, params} =
      case Map.get(state, :global_search) do
        nil ->
          {conditions, params}

        "" ->
          {conditions, params}

        search_term ->
          searchable =
            columns
            |> Enum.filter(fn col ->
              field = to_string(Map.get(col, :field, ""))
              field in valid_fields and Map.get(col, :type) in [:string, "string"]
            end)
            |> Enum.map(fn col -> to_string(Map.get(col, :field, "")) end)

          if searchable == [] do
            {conditions, params}
          else
            or_clauses = Enum.map_join(searchable, " OR ", fn f -> "#{f} LIKE ?" end)
            like_params = Enum.map(searchable, fn _ -> "%#{search_term}%" end)
            {conditions ++ ["(#{or_clauses})"], params ++ like_params}
          end
      end

    # Column filters
    {conditions, params} =
      case Map.get(state, :filters) do
        nil ->
          {conditions, params}

        filters when is_map(filters) ->
          Enum.reduce(filters, {conditions, params}, fn {field, value}, {conds, pars} ->
            field_str = to_string(field)

            if field_str in valid_fields and value != "" and not is_nil(value) do
              {conds ++ ["#{field_str} LIKE ?"], pars ++ ["%#{value}%"]}
            else
              {conds, pars}
            end
          end)

        _ ->
          {conditions, params}
      end

    if conditions == [] do
      {"", []}
    else
      {" WHERE " <> Enum.join(conditions, " AND "), params}
    end
  end

  defp build_order_by(state, valid_fields, default_pk) do
    case Map.get(state, :sort) do
      %{field: field, direction: dir} when not is_nil(field) ->
        field_str = to_string(field)

        if field_str in valid_fields do
          direction = if dir == :desc, do: "DESC", else: "ASC"
          " ORDER BY #{field_str} #{direction}"
        else
          " ORDER BY #{default_pk} ASC"
        end

      _ ->
        " ORDER BY #{default_pk} ASC"
    end
  end

  defp valid_column_names(repo, table) do
    case TableInspector.table_columns(repo, table) do
      {:ok, cols} -> Enum.map(cols, & &1.name)
      _ -> []
    end
  end

  defp valid_identifier?(name), do: Regex.match?(~r/\A[a-zA-Z_][a-zA-Z0-9_]*\z/, name)

  defp safe_query(repo, sql, params \\ []) do
    try do
      {:ok, Ecto.Adapters.SQL.query!(repo, sql, params)}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp result_to_maps(%{columns: columns, rows: rows}) do
    Enum.map(rows, fn row -> row_to_map(columns, row) end)
  end

  defp row_to_map(columns, row) do
    columns
    |> Enum.zip(row)
    |> Map.new(fn {col, val} -> {String.to_atom(col), val} end)
  end
end
