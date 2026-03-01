defmodule LiveViewGrid.StatePersistence do
  @moduledoc """
  FA-002: Grid State Save/Restore

  Grid 상태를 JSON 직렬화/역직렬화합니다.
  persistable(영속 가능) 상태와 transient(일시적) 상태를 분리합니다.
  """

  @persistable_keys [
    :sort,
    :filters,
    :global_search,
    :show_filter_row,
    :advanced_filters,
    :column_widths,
    :column_order,
    :hidden_columns,
    :group_by,
    :group_aggregates,
    :pinned_top_ids,
    :pinned_bottom_ids,
    :show_status_column,
    :pagination
  ]

  @doc """
  Persistable 상태 키 목록을 반환합니다.
  """
  @spec persistable_keys() :: list(atom())
  def persistable_keys, do: @persistable_keys

  @doc """
  Grid 상태에서 persistable 키만 추출합니다.

  ## Examples

      iex> StatePersistence.export_state(grid)
      %{sort: %{field: :name, direction: :asc}, filters: %{}, ...}
  """
  @spec export_state(grid :: map()) :: map()
  def export_state(%{state: state}) do
    state
    |> Map.take(@persistable_keys)
    |> convert_atoms_to_strings()
  end

  @doc """
  직렬화된 상태를 Grid에 복원합니다.
  존재하는 컬럼 필드만 적용합니다.

  ## Parameters
    - grid: 대상 Grid
    - state_map: `export_state/1`에서 반환된 맵 또는 JSON 역직렬화 결과
  """
  @spec import_state(grid :: map(), state_map :: map()) :: map()
  def import_state(grid, state_map) when is_map(state_map) do
    valid_fields = MapSet.new(Enum.map(grid.columns, & &1.field))

    restored = state_map
      |> convert_strings_to_atoms()
      |> validate_state(valid_fields)

    # 기존 state에 persistable 키만 덮어쓰기
    merged_state = Map.merge(grid.state, restored)
    %{grid | state: merged_state}
  end

  @doc """
  상태 맵을 JSON 문자열로 직렬화합니다.
  """
  @spec serialize(state_map :: map()) :: {:ok, String.t()} | {:error, term()}
  def serialize(state_map) do
    Jason.encode(state_map)
  end

  @doc """
  JSON 문자열을 상태 맵으로 역직렬화합니다.
  """
  @spec deserialize(json :: String.t()) :: {:ok, map()} | {:error, term()}
  def deserialize(json) when is_binary(json) do
    Jason.decode(json)
  end

  # ── Private Helpers ──

  # atom 값을 문자열로 변환 (JSON 호환)
  defp convert_atoms_to_strings(state) do
    Enum.reduce(state, %{}, fn {key, value}, acc ->
      string_key = Atom.to_string(key)
      converted_value = convert_value_to_string(key, value)
      Map.put(acc, string_key, converted_value)
    end)
  end

  defp convert_value_to_string(:sort, nil), do: nil
  defp convert_value_to_string(:sort, %{field: field, direction: dir}) do
    %{"field" => Atom.to_string(field), "direction" => Atom.to_string(dir)}
  end

  defp convert_value_to_string(:filters, filters) when is_map(filters) do
    Enum.reduce(filters, %{}, fn {field, value}, acc ->
      Map.put(acc, Atom.to_string(field), value)
    end)
  end

  defp convert_value_to_string(:column_widths, widths) when is_map(widths) do
    Enum.reduce(widths, %{}, fn {field, w}, acc ->
      Map.put(acc, Atom.to_string(field), w)
    end)
  end

  defp convert_value_to_string(:column_order, nil), do: nil
  defp convert_value_to_string(:column_order, order) when is_list(order) do
    Enum.map(order, &Atom.to_string/1)
  end

  defp convert_value_to_string(:hidden_columns, list) when is_list(list) do
    Enum.map(list, &Atom.to_string/1)
  end

  defp convert_value_to_string(:group_by, list) when is_list(list) do
    Enum.map(list, &Atom.to_string/1)
  end

  defp convert_value_to_string(:group_aggregates, aggs) when is_map(aggs) do
    Enum.reduce(aggs, %{}, fn {field, agg}, acc ->
      Map.put(acc, Atom.to_string(field), Atom.to_string(agg))
    end)
  end

  defp convert_value_to_string(:advanced_filters, %{logic: logic, conditions: conditions}) do
    %{
      "logic" => Atom.to_string(logic),
      "conditions" => Enum.map(conditions, fn cond_map ->
        Enum.reduce(cond_map, %{}, fn {k, v}, acc ->
          sk = if is_atom(k), do: Atom.to_string(k), else: k
          sv = if is_atom(v), do: Atom.to_string(v), else: v
          Map.put(acc, sk, sv)
        end)
      end)
    }
  end

  defp convert_value_to_string(_key, value), do: value

  # 문자열 키를 atom으로 변환 (역직렬화 후)
  defp convert_strings_to_atoms(state) do
    Enum.reduce(state, %{}, fn {key, value}, acc ->
      atom_key = safe_to_atom(key)
      if atom_key in @persistable_keys do
        converted_value = convert_value_to_atom(atom_key, value)
        Map.put(acc, atom_key, converted_value)
      else
        acc
      end
    end)
  end

  defp convert_value_to_atom(:sort, nil), do: nil
  defp convert_value_to_atom(:sort, %{"field" => field, "direction" => dir}) do
    %{field: safe_to_atom(field), direction: safe_to_atom(dir)}
  end

  defp convert_value_to_atom(:filters, filters) when is_map(filters) do
    Enum.reduce(filters, %{}, fn {field, value}, acc ->
      Map.put(acc, safe_to_atom(field), value)
    end)
  end

  defp convert_value_to_atom(:column_widths, widths) when is_map(widths) do
    Enum.reduce(widths, %{}, fn {field, w}, acc ->
      Map.put(acc, safe_to_atom(field), w)
    end)
  end

  defp convert_value_to_atom(:column_order, nil), do: nil
  defp convert_value_to_atom(:column_order, order) when is_list(order) do
    Enum.map(order, &safe_to_atom/1)
  end

  defp convert_value_to_atom(:hidden_columns, list) when is_list(list) do
    Enum.map(list, &safe_to_atom/1)
  end

  defp convert_value_to_atom(:group_by, list) when is_list(list) do
    Enum.map(list, &safe_to_atom/1)
  end

  defp convert_value_to_atom(:group_aggregates, aggs) when is_map(aggs) do
    Enum.reduce(aggs, %{}, fn {field, agg}, acc ->
      Map.put(acc, safe_to_atom(field), safe_to_atom(agg))
    end)
  end

  defp convert_value_to_atom(:advanced_filters, %{"logic" => logic, "conditions" => conditions}) do
    %{
      logic: safe_to_atom(logic),
      conditions: Enum.map(conditions, fn cond_map ->
        Enum.reduce(cond_map, %{}, fn {k, v}, acc ->
          Map.put(acc, safe_to_atom(k), v)
        end)
      end)
    }
  end

  defp convert_value_to_atom(:pagination, %{"current_page" => page, "total_rows" => total}) do
    %{current_page: page, total_rows: total}
  end
  defp convert_value_to_atom(:pagination, %{current_page: _, total_rows: _} = p), do: p

  defp convert_value_to_atom(_key, value), do: value

  # 유효성 검증: 존재하는 컬럼만 허용
  defp validate_state(state, valid_fields) do
    state
    |> maybe_validate(:column_widths, fn widths ->
      widths
      |> Enum.filter(fn {field, _} -> MapSet.member?(valid_fields, field) end)
      |> Map.new()
    end)
    |> maybe_validate(:column_order, fn
      nil -> nil
      order ->
        filtered = Enum.filter(order, &MapSet.member?(valid_fields, &1))
        if filtered == [], do: nil, else: filtered
    end)
    |> maybe_validate(:hidden_columns, fn hidden ->
      Enum.filter(hidden, &MapSet.member?(valid_fields, &1))
    end)
    |> maybe_validate(:filters, fn filters ->
      filters
      |> Enum.filter(fn {field, _} -> MapSet.member?(valid_fields, field) end)
      |> Map.new()
    end)
    |> maybe_validate(:group_by, fn groups ->
      Enum.filter(groups, &MapSet.member?(valid_fields, &1))
    end)
    |> maybe_validate(:group_aggregates, fn aggs ->
      aggs
      |> Enum.filter(fn {field, _} -> MapSet.member?(valid_fields, field) end)
      |> Map.new()
    end)
  end

  defp maybe_validate(state, key, validator) do
    case Map.get(state, key) do
      nil -> state
      value -> Map.put(state, key, validator.(value))
    end
  end

  defp safe_to_atom(value) when is_atom(value), do: value
  defp safe_to_atom(value) when is_binary(value), do: String.to_atom(value)
end
