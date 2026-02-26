defmodule LiveViewGrid.Sorting do
  @moduledoc """
  Grid 데이터 정렬.

  `nil` 값 위치는 컬럼별 `nulls` 옵션으로 제어합니다.
  - `:last` (기본) — nil 값을 항상 마지막에 배치
  - `:first` — nil 값을 항상 처음에 배치

  ## Examples

      Sorting.sort(data, :name, :asc)           # nil → 마지막 (기본)
      Sorting.sort(data, :age, :desc, :first)   # nil → 처음
  """

  @doc """
  데이터 정렬. nulls_position으로 nil 값 위치 제어.

  ## Examples

      iex> data = [%{name: "Bob"}, %{name: nil}, %{name: "Alice"}]
      iex> Sorting.sort(data, :name, :asc, :last)
      [%{name: "Alice"}, %{name: "Bob"}, %{name: nil}]

      iex> data = [%{name: "Bob"}, %{name: nil}, %{name: "Alice"}]
      iex> Sorting.sort(data, :name, :asc, :first)
      [%{name: nil}, %{name: "Alice"}, %{name: "Bob"}]
  """
  @spec sort(list(map()), atom(), :asc | :desc, :first | :last) :: list(map())
  def sort(data, field, direction, nulls_position \\ :last)
      when is_list(data) and is_atom(field) do
    {nils, non_nils} = Enum.split_with(data, fn row -> Map.get(row, field) == nil end)

    sorted_non_nils =
      non_nils
      |> Enum.sort_by(&Map.get(&1, field), &compare/2)
      |> then(fn s -> if direction == :desc, do: Enum.reverse(s), else: s end)

    case nulls_position do
      :first -> nils ++ sorted_non_nils
      :last -> sorted_non_nils ++ nils
    end
  end

  # 비교 함수 (nil 제외 — split_with로 이미 분리됨)
  defp compare(a, b), do: a <= b
end
