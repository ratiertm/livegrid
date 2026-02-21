defmodule LiveViewGrid.DataSource.Ecto do
  @moduledoc """
  Ecto-based data source adapter.

  Delegates sorting, filtering, and pagination to SQL queries via Ecto.

  ## Config

      %{
        repo: MyApp.Repo,
        schema: MyApp.User,
        base_query: from(u in MyApp.User, where: u.active == true)  # optional
      }
  """

  @behaviour LiveViewGrid.DataSource

  alias LiveViewGrid.DataSource.Ecto.QueryBuilder

  import Ecto.Query

  @impl true
  def fetch_data(config, state, options, columns) do
    repo = config.repo
    base = base_query(config)

    # Total count (unfiltered)
    total_count = repo.aggregate(base, :count)

    # Apply filters
    filtered_query =
      base
      |> QueryBuilder.apply_global_search(state.global_search, columns)
      |> QueryBuilder.apply_filters(state.filters, columns)
      |> maybe_apply_advanced_filters(state)

    # Filtered count
    filtered_count = repo.aggregate(filtered_query, :count)

    # Apply sort + pagination
    rows =
      filtered_query
      |> QueryBuilder.apply_sort(state.sort)
      |> QueryBuilder.apply_pagination(state.pagination, options.page_size)
      |> repo.all()
      |> rows_to_maps(config)

    {rows, total_count, filtered_count}
  end

  @impl true
  def insert_row(config, row_data) do
    repo = config.repo
    schema = config.schema

    changeset = schema.__struct__() |> Ecto.Changeset.cast(row_data, schema.__schema__(:fields))

    case repo.insert(changeset) do
      {:ok, record} -> {:ok, row_to_map(record, config)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @impl true
  def update_row(config, row_id, changes) do
    repo = config.repo
    schema = config.schema

    case repo.get(schema, row_id) do
      nil ->
        {:error, :not_found}

      record ->
        changeset = Ecto.Changeset.cast(record, changes, Map.keys(changes) |> Enum.filter(&is_atom/1))
        case repo.update(changeset) do
          {:ok, updated} -> {:ok, row_to_map(updated, config)}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @impl true
  def delete_row(config, row_id) do
    repo = config.repo
    schema = config.schema

    case repo.get(schema, row_id) do
      nil -> {:error, :not_found}
      record ->
        case repo.delete(record) do
          {:ok, _} -> :ok
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  # ── Private ──

  defp base_query(%{base_query: query}) when not is_nil(query), do: query
  defp base_query(%{schema: schema}), do: from(_ in schema)

  defp maybe_apply_advanced_filters(query, %{advanced_filters: %{conditions: conds} = adv})
       when is_list(conds) and length(conds) > 0 do
    QueryBuilder.apply_advanced_filters(query, adv)
  end
  defp maybe_apply_advanced_filters(query, _state), do: query

  defp rows_to_maps(records, config) do
    Enum.map(records, &row_to_map(&1, config))
  end

  defp row_to_map(record, _config) do
    record
    |> Map.from_struct()
    |> Map.delete(:__meta__)
  end
end
