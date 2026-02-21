defmodule LiveViewGrid.Filter do
  @moduledoc """
  Grid 데이터 필터링

  ## 기본 필터 (v0.1)
  - 텍스트: 대소문자 무관 부분 일치
  - 숫자: 연산자 지원 (>, <, >=, <=, =)

  ## 고급 필터 (v0.6 - F-310)
  - 다중 조건: AND/OR 논리 연산자 조합
  - 텍스트 연산자: contains, equals, starts_with, ends_with, is_empty, is_not_empty
  - 숫자 연산자: eq, neq, gt, lt, gte, lte
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

  # ── Advanced Filter (F-310) ──

  @doc """
  다중 조건 고급 필터 적용.

  ## Parameters
    - data: 행 데이터 리스트
    - advanced_filters: `%{logic: :and | :or, conditions: [condition]}`
      - condition: `%{field: :atom, operator: :atom, value: any}`
    - columns: 컬럼 정의 리스트

  ## Examples

      iex> conditions = [
      ...>   %{field: :name, operator: :contains, value: "Ali"},
      ...>   %{field: :age, operator: :gt, value: "25"}
      ...> ]
      iex> Filter.apply_advanced(data, %{logic: :and, conditions: conditions}, columns)
  """
  def apply_advanced(data, %{logic: logic, conditions: conditions}, columns)
      when is_list(data) and is_list(conditions) do
    # 유효한 조건만 필터 (field가 nil이거나 value가 비어있으면 무시)
    active = Enum.filter(conditions, fn c ->
      c[:field] != nil and c[:value] != nil and c[:value] != ""
    end)

    if Enum.empty?(active) do
      data
    else
      column_map = Map.new(columns, fn col -> {col.field, col} end)

      Enum.filter(data, fn row ->
        results = Enum.map(active, fn condition ->
          match_condition?(row, condition, column_map)
        end)

        case logic do
          :and -> Enum.all?(results)
          :or -> Enum.any?(results)
          _ -> Enum.all?(results)
        end
      end)
    end
  end

  # 빈 조건 목록이면 데이터 그대로 반환
  def apply_advanced(data, _, _columns), do: data

  @doc """
  단일 조건 매칭.
  """
  def match_condition?(row, %{field: field, operator: operator, value: value}, column_map) do
    cell_value = Map.get(row, field)
    col = Map.get(column_map, field, %{filter_type: :text})
    filter_type = Map.get(col, :filter_type, :text)

    case filter_type do
      :number -> match_number_op?(cell_value, operator, value)
      _ -> match_text_op?(cell_value, operator, value)
    end
  end

  # ── Text operator matching ──

  defp match_text_op?(nil, :is_empty, _), do: true
  defp match_text_op?("", :is_empty, _), do: true
  defp match_text_op?(_, :is_empty, _), do: false

  defp match_text_op?(nil, :is_not_empty, _), do: false
  defp match_text_op?("", :is_not_empty, _), do: false
  defp match_text_op?(_, :is_not_empty, _), do: true

  defp match_text_op?(nil, _, _), do: false

  defp match_text_op?(cell, :contains, value) do
    cell_str = cell |> to_string() |> String.downcase()
    query_str = value |> to_string() |> String.downcase() |> String.trim()
    String.contains?(cell_str, query_str)
  end

  defp match_text_op?(cell, :equals, value) do
    cell_str = cell |> to_string() |> String.downcase()
    query_str = value |> to_string() |> String.downcase() |> String.trim()
    cell_str == query_str
  end

  defp match_text_op?(cell, :starts_with, value) do
    cell_str = cell |> to_string() |> String.downcase()
    query_str = value |> to_string() |> String.downcase() |> String.trim()
    String.starts_with?(cell_str, query_str)
  end

  defp match_text_op?(cell, :ends_with, value) do
    cell_str = cell |> to_string() |> String.downcase()
    query_str = value |> to_string() |> String.downcase() |> String.trim()
    String.ends_with?(cell_str, query_str)
  end

  # 알 수 없는 텍스트 연산자는 contains로 fallback
  defp match_text_op?(cell, _unknown, value), do: match_text_op?(cell, :contains, value)

  # ── Number operator matching ──

  defp match_number_op?(nil, _, _), do: false

  defp match_number_op?(cell, operator, value) do
    cell_num = to_number(cell)
    val_num = to_number(value)

    if is_nil(cell_num) or is_nil(val_num) do
      false
    else
      case operator do
        :eq -> cell_num == val_num
        :neq -> cell_num != val_num
        :gt -> cell_num > val_num
        :lt -> cell_num < val_num
        :gte -> cell_num >= val_num
        :lte -> cell_num <= val_num
        _ -> cell_num == val_num
      end
    end
  end

  # ── Legacy: Basic filter matching ──

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
