defmodule LiveViewGrid.Sorting do
  @moduledoc """
  Grid 데이터 정렬
  
  프로토타입 v0.1-alpha: 기본 정렬만 구현
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
