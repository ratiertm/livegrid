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

  @doc """
  Ecto 쿼리로 데이터를 조회한다. 글로벌 검색, 컬럼 필터, 고급 필터, 정렬, 페이지네이션을 SQL 레벨에서 처리한다.
  """
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

  @doc """
  Ecto Changeset을 통해 새 행을 DB에 삽입한다. PK와 타임스탬프 필드는 자동 제외된다.
  """
  @impl true
  def insert_row(config, row_data) do
    repo = config.repo
    schema = config.schema

    # Primary key와 타임스탬프는 자동 생성되므로 cast에서 제외
    pk_fields = schema.__schema__(:primary_key)
    timestamp_fields = [:inserted_at, :updated_at]
    cast_fields = schema.__schema__(:fields) -- pk_fields -- timestamp_fields

    # row_data에서도 pk/timestamp 제거
    clean_data =
      row_data
      |> Map.drop(pk_fields)
      |> Map.drop(timestamp_fields)

    # empty_values: [] → 빈 문자열("")을 nil로 변환하지 않음 (NOT NULL 제약 방지)
    changeset =
      schema.__struct__()
      |> Ecto.Changeset.cast(clean_data, cast_fields, empty_values: [])

    try do
      case repo.insert(changeset) do
        {:ok, record} -> {:ok, row_to_map(record, config)}
        {:error, changeset} -> {:error, changeset}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Ecto Changeset을 통해 기존 행을 업데이트한다. 해당 row_id가 없으면 `:not_found` 에러를 반환한다.
  """
  @impl true
  def update_row(config, row_id, changes) do
    repo = config.repo
    schema = config.schema

    try do
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
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  DB에서 해당 행을 삭제한다. 해당 row_id가 없으면 `:not_found` 에러를 반환한다.
  """
  @impl true
  def delete_row(config, row_id) do
    repo = config.repo
    schema = config.schema

    try do
      case repo.get(schema, row_id) do
        nil -> {:error, :not_found}
        record ->
          case repo.delete(record) do
            {:ok, _} -> :ok
            {:error, changeset} -> {:error, changeset}
          end
      end
    rescue
      e -> {:error, Exception.message(e)}
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
