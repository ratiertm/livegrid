defmodule LiveViewGrid.TableInspector do
  @moduledoc """
  Introspects SQLite database tables and columns for schema-less Grid Builder mode.

  Queries `sqlite_master` and `PRAGMA table_info` to discover
  available tables and their column metadata without requiring Ecto schemas.

  ## Usage

      {:ok, tables} = TableInspector.list_tables(MyRepo)
      {:ok, columns} = TableInspector.table_columns(MyRepo, "demo_users")
  """

  @excluded_tables ~w(schema_migrations sqlite_sequence)

  @doc """
  Lists all user-defined tables in the database.

  Excludes system tables (`schema_migrations`, `sqlite_sequence`, `sqlite_*`).
  """
  @spec list_tables(module()) :: {:ok, [String.t()]} | {:error, any()}
  def list_tables(repo) do
    sql = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"

    case safe_query(repo, sql) do
      {:ok, %{rows: rows}} ->
        tables =
          rows
          |> List.flatten()
          |> Enum.reject(&excluded_table?/1)
          |> Enum.sort()

        {:ok, tables}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Returns column metadata for a specific table.

  Each column includes: `name`, `type` (mapped to grid type), `pk` (boolean),
  `nullable`, and `sqlite_type` (raw SQLite type string).
  """
  @spec table_columns(module(), String.t()) :: {:ok, [map()]} | {:error, any()}
  def table_columns(repo, table_name) do
    unless valid_identifier?(table_name) do
      {:error, :invalid_table_name}
    else
      sql = "PRAGMA table_info(#{table_name})"

      case safe_query(repo, sql) do
        {:ok, %{rows: []}} ->
          {:error, :table_not_found}

        {:ok, %{rows: rows}} ->
          columns =
            Enum.map(rows, fn [_cid, name, type, notnull, _default, pk] ->
              %{
                name: name,
                type: sqlite_type_to_grid_type(type),
                sqlite_type: type,
                pk: pk == 1,
                nullable: notnull == 0
              }
            end)

          {:ok, columns}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Converts table columns to grid-compatible column definitions.

  Returns column maps ready for the Grid Builder column list.
  """
  @spec table_to_grid_columns(module(), String.t()) :: {:ok, [map()]} | {:error, any()}
  def table_to_grid_columns(repo, table_name) do
    case table_columns(repo, table_name) do
      {:ok, columns} ->
        grid_cols =
          Enum.map(columns, fn col ->
            %{
              field: col.name,
              label: col.name |> String.replace("_", " ") |> String.capitalize(),
              type: col.type,
              sortable: true,
              filterable: true,
              filter_type: filter_type_for(col.type),
              editable: not col.pk,
              editor_type: editor_type_for(col.type)
            }
          end)

        {:ok, grid_cols}

      error ->
        error
    end
  end

  # ── Private ──

  @spec valid_identifier?(String.t()) :: boolean()
  defp valid_identifier?(name), do: Regex.match?(~r/\A[a-zA-Z_][a-zA-Z0-9_]*\z/, name)

  defp excluded_table?(name) do
    name in @excluded_tables or String.starts_with?(name, "sqlite_")
  end

  defp safe_query(repo, sql) do
    try do
      {:ok, Ecto.Adapters.SQL.query!(repo, sql)}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @spec sqlite_type_to_grid_type(String.t()) :: atom()
  defp sqlite_type_to_grid_type(type) do
    type_upper = String.upcase(type)

    cond do
      type_upper in ~w(INTEGER INT BIGINT SMALLINT TINYINT) -> :integer
      type_upper in ~w(REAL FLOAT DOUBLE NUMERIC DECIMAL) -> :float
      type_upper in ~w(BOOLEAN BOOL) -> :boolean
      type_upper in ~w(DATE) -> :date
      String.contains?(type_upper, "DATETIME") or String.contains?(type_upper, "TIMESTAMP") -> :datetime
      true -> :string
    end
  end

  defp editor_type_for(:integer), do: :number
  defp editor_type_for(:float), do: :number
  defp editor_type_for(:boolean), do: :checkbox
  defp editor_type_for(:date), do: :date
  defp editor_type_for(:datetime), do: :date
  defp editor_type_for(_), do: :text

  defp filter_type_for(:integer), do: :number
  defp filter_type_for(:float), do: :number
  defp filter_type_for(:date), do: :date
  defp filter_type_for(:datetime), do: :date
  defp filter_type_for(_), do: :text
end
