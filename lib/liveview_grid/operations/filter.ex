defmodule LiveViewGrid.Filter do
  @moduledoc """
  Grid 데이터 필터링

  컬럼별 텍스트/숫자 필터 지원
  - 텍스트: 대소문자 무관 부분 일치
  - 숫자: 연산자 지원 (>, <, >=, <=, =)
  """

  @doc """
  전체 검색 (모든 컬럼에서 검색어 매칭)

  columns의 field 값들을 문자열로 변환하여 검색어 포함 여부 확인.
  대소문자 구분 없음.

  ## Examples

      iex> data = [%{name: "Alice", city: "Seoul"}, %{name: "Bob", city: "Busan"}]
      iex> columns = [%{field: :name}, %{field: :city}]
      iex> Filter.global_search(data, "ali", columns)
      [%{name: "Alice", city: "Seoul"}]
  """
  @spec global_search(data :: list(map()), query :: String.t(), columns :: list(map())) :: list(map())
  def global_search(data, query, columns) when is_list(data) and is_binary(query) do
    query = query |> String.trim() |> String.downcase()

    if query == "" do
      data
    else
      fields = Enum.map(columns, & &1.field)

      Enum.filter(data, fn row ->
        Enum.any?(fields, fn field ->
          value = Map.get(row, field)

          if is_nil(value) do
            false
          else
            value |> to_string() |> String.downcase() |> String.contains?(query)
          end
        end)
      end)
    end
  end

  @doc """
  필터 적용

  filters는 %{field_atom => filter_value} 형태
  빈 문자열 값은 무시

  ## Examples

      iex> data = [%{name: "Alice", age: 30}, %{name: "Bob", age: 25}]
      iex> columns = [%{field: :name, filter_type: :text}, %{field: :age, filter_type: :number}]
      iex> Filter.apply(data, %{name: "ali"}, columns)
      [%{name: "Alice", age: 30}]
  """
  @spec apply(data :: list(map()), filters :: map(), columns :: list(map())) :: list(map())
  def apply(data, filters, columns) when is_list(data) and is_map(filters) do
    # 빈 값 필터 제거
    active_filters =
      filters
      |> Enum.reject(fn {_field, value} -> value == "" or is_nil(value) end)
      |> Map.new()

    if map_size(active_filters) == 0 do
      data
    else
      column_map = Map.new(columns, fn col -> {col.field, col} end)

      Enum.filter(data, fn row ->
        Enum.all?(active_filters, fn {field, value} ->
          col = Map.get(column_map, field, %{filter_type: :text})
          filter_type = Map.get(col, :filter_type, :text)
          match_filter?(row, field, value, filter_type)
        end)
      end)
    end
  end

  defp match_filter?(row, field, value, :text) do
    cell_value = Map.get(row, field)

    if is_nil(cell_value) do
      false
    else
      cell_str = cell_value |> to_string() |> String.downcase()
      query_str = value |> to_string() |> String.downcase() |> String.trim()
      String.contains?(cell_str, query_str)
    end
  end

  defp match_filter?(row, field, value, :number) do
    cell_value = Map.get(row, field)

    if is_nil(cell_value) do
      false
    else
      cell_num = to_number(cell_value)
      parse_number_filter(cell_num, String.trim(to_string(value)))
    end
  end

  defp match_filter?(row, field, value, _unknown_type) do
    match_filter?(row, field, value, :text)
  end

  # 숫자 필터 파싱: ">30", ">=25", "<40", "<=35", "=30", "30"
  defp parse_number_filter(nil, _), do: false
  defp parse_number_filter(cell_num, ">=" <> num_str) do
    case Float.parse(String.trim(num_str)) do
      {num, _} -> cell_num >= num
      :error -> false
    end
  end
  defp parse_number_filter(cell_num, "<=" <> num_str) do
    case Float.parse(String.trim(num_str)) do
      {num, _} -> cell_num <= num
      :error -> false
    end
  end
  defp parse_number_filter(cell_num, ">" <> num_str) do
    case Float.parse(String.trim(num_str)) do
      {num, _} -> cell_num > num
      :error -> false
    end
  end
  defp parse_number_filter(cell_num, "<" <> num_str) do
    case Float.parse(String.trim(num_str)) do
      {num, _} -> cell_num < num
      :error -> false
    end
  end
  defp parse_number_filter(cell_num, "=" <> num_str) do
    case Float.parse(String.trim(num_str)) do
      {num, _} -> cell_num == num
      :error -> false
    end
  end
  defp parse_number_filter(cell_num, num_str) do
    # 연산자 없이 숫자만 입력 → 등호 비교
    case Float.parse(String.trim(num_str)) do
      {num, _} -> cell_num == num
      :error -> false
    end
  end

  defp to_number(value) when is_integer(value), do: value * 1.0
  defp to_number(value) when is_float(value), do: value
  defp to_number(value) when is_binary(value) do
    case Float.parse(value) do
      {num, _} -> num
      :error -> nil
    end
  end
  defp to_number(_), do: nil
end
