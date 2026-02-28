defmodule LiveViewGrid.SampleData do
  @moduledoc """
  컬럼 타입에 따라 샘플 데이터를 생성한다.
  Grid Builder 미리보기에서 사용.
  """

  @first_names ["Alice", "Bob", "Charlie", "David", "Eve", "Frank", "Grace", "Henry", "Iris", "Jack"]
  @last_names ["Kim", "Lee", "Park", "Choi", "Jung", "Kang", "Cho", "Yoon", "Jang", "Lim"]
  @cities ["Seoul", "Busan", "Tokyo", "New York", "London", "Paris", "Berlin", "Sydney"]

  @doc """
  컬럼 정의 리스트와 행 수를 받아 샘플 데이터를 생성한다.

  ## Examples

      iex> columns = [%{field: :name, type: :string}, %{field: :age, type: :integer}]
      iex> rows = LiveViewGrid.SampleData.generate(columns, 3)
      iex> length(rows)
      3
  """
  @spec generate(columns :: [map()], count :: pos_integer()) :: [map()]
  def generate(columns, count \\ 5) do
    for i <- 1..count do
      row = %{id: i}

      Enum.reduce(columns, row, fn col, acc ->
        field =
          cond do
            is_atom(col.field) -> col.field
            is_binary(col.field) and col.field != "" -> String.to_atom(col.field)
            true -> nil
          end

        if field do
          Map.put(acc, field, sample_value(col.type, i, col.field))
        else
          acc
        end
      end)
    end
  end

  @spec sample_value(type :: atom(), index :: pos_integer(), field :: atom() | String.t()) :: any()
  defp sample_value(:string, i, field) do
    field_str = to_string(field)

    cond do
      String.contains?(field_str, "name") ->
        "#{Enum.at(@first_names, rem(i - 1, length(@first_names)))} #{Enum.at(@last_names, rem(i - 1, length(@last_names)))}"

      String.contains?(field_str, "email") ->
        name = String.downcase(Enum.at(@first_names, rem(i - 1, length(@first_names))))
        "#{name}#{i}@example.com"

      String.contains?(field_str, "city") or String.contains?(field_str, "address") ->
        Enum.at(@cities, rem(i - 1, length(@cities)))

      String.contains?(field_str, "phone") or String.contains?(field_str, "tel") ->
        "010-#{String.pad_leading("#{1000 + i}", 4, "0")}-#{String.pad_leading("#{5000 + i}", 4, "0")}"

      true ->
        "Sample #{i}"
    end
  end

  defp sample_value(:integer, i, _field), do: i * 10 + rem(i * 7, 90)
  defp sample_value(:float, i, _field), do: Float.round(i * 10.5 + rem(i * 13, 100) / 10.0, 2)
  defp sample_value(:boolean, i, _field), do: rem(i, 2) == 0

  defp sample_value(:date, i, _field) do
    Date.add(Date.utc_today(), -i * 7)
  end

  defp sample_value(:datetime, i, _field) do
    NaiveDateTime.add(NaiveDateTime.utc_now(), -i * 86400)
    |> NaiveDateTime.truncate(:second)
  end

  defp sample_value(_, i, _field), do: "Value #{i}"
end
