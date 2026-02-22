defmodule LiveViewGrid.Sorting do
  @moduledoc """
  Grid 데이터 정렬.

  `nil` 값은 항상 마지막으로 정렬됩니다 (오름차순/내림차순 무관).

  일반적으로 `Grid.visible_data/1`에서 내부적으로 호출되며,
  직접 사용할 수도 있습니다.

  ## Examples

      Sorting.sort(data, :name, :asc)   # 이름 오름차순
      Sorting.sort(data, :age, :desc)   # 나이 내림차순
  """

  @doc """
  데이터 정렬
  
  ## Examples
  
      iex> data = [%{name: "Bob"}, %{name: "Alice"}]
      iex> Sorting.sort(data, :name, :asc)
      [%{name: "Alice"}, %{name: "Bob"}]
  """
  @spec sort(data :: list(map()), field :: atom(), direction :: :asc | :desc) :: list(map())
  def sort(data, field, direction) when is_list(data) and is_atom(field) do
    sorted = Enum.sort_by(data, &get_field_value(&1, field), &compare/2)
    
    case direction do
      :asc -> sorted
      :desc -> Enum.reverse(sorted)
    end
  end

  # Private functions

  defp get_field_value(row, field) do
    Map.get(row, field)
  end

  # Null 값을 마지막으로 정렬
  defp compare(nil, _), do: false
  defp compare(_, nil), do: true
  defp compare(a, b), do: a <= b
end
