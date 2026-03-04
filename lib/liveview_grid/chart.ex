defmodule LiveviewGrid.Chart do
  @moduledoc """
  Grid 데이터를 차트 렌더링용 데이터로 변환합니다.
  카테고리별 집계, 정규화, 색상 팔레트 관리를 담당합니다.
  """

  @palette [
    "#4285F4", "#EA4335", "#FBBC04", "#34A853",
    "#FF6D01", "#46BDC6", "#7B61FF", "#F538A0"
  ]

  @type chart_config :: %{
    chart_type: :bar | :line | :pie | :column,
    category_field: atom() | nil,
    value_fields: [atom()],
    aggregation: :sum | :avg | :count | :min | :max
  }

  @type chart_point :: %{
    category: String.t(),
    values: %{atom() => number()},
    color: String.t()
  }

  @type chart_data :: %{
    points: [chart_point()],
    max_value: number(),
    min_value: number(),
    value_fields: [atom()],
    category_field: atom()
  }

  @doc "그리드 데이터로 차트 데이터를 생성합니다."
  @spec prepare_data(list(map()), chart_config()) :: chart_data() | nil
  def prepare_data(_data, %{category_field: nil}), do: nil
  def prepare_data(_data, %{value_fields: []}), do: nil
  def prepare_data([], _config), do: nil

  def prepare_data(data, config) do
    points =
      data
      |> Enum.group_by(&to_string(Map.get(&1, config.category_field, "N/A")))
      |> Enum.map(fn {category, rows} ->
        values =
          config.value_fields
          |> Enum.map(fn field ->
            nums = rows |> Enum.map(&to_number(Map.get(&1, field, 0)))
            {field, aggregate(nums, config.aggregation)}
          end)
          |> Map.new()

        %{category: category, values: values}
      end)
      |> Enum.sort_by(& &1.category)
      |> Enum.with_index()
      |> Enum.map(fn {point, idx} ->
        Map.put(point, :color, Enum.at(@palette, rem(idx, length(@palette))))
      end)

    all_values = Enum.flat_map(points, fn p -> Map.values(p.values) end)

    %{
      points: points,
      max_value: if(all_values == [], do: 0, else: Enum.max(all_values)),
      min_value: if(all_values == [], do: 0, else: Enum.min(all_values ++ [0])),
      value_fields: config.value_fields,
      category_field: config.category_field
    }
  end

  @doc "숫자 집계 함수"
  @spec aggregate([number()], atom()) :: number()
  def aggregate([], _), do: 0
  def aggregate(nums, :sum), do: Enum.sum(nums)
  def aggregate(nums, :avg), do: Enum.sum(nums) / length(nums)
  def aggregate(nums, :count), do: length(nums)
  def aggregate(nums, :min), do: Enum.min(nums)
  def aggregate(nums, :max), do: Enum.max(nums)

  @doc "색상 팔레트를 반환합니다."
  @spec palette() :: [String.t()]
  def palette, do: @palette

  @doc "값을 숫자로 변환합니다."
  @spec to_number(any()) :: number()
  def to_number(n) when is_number(n), do: n

  def to_number(s) when is_binary(s) do
    case Float.parse(s) do
      {n, _} -> n
      :error -> 0
    end
  end

  def to_number(_), do: 0

  @doc "숫자를 읽기 좋은 형식으로 포맷합니다."
  @spec format_number(number()) :: String.t()
  def format_number(n) when is_float(n) and n == trunc(n), do: Integer.to_string(trunc(n))
  def format_number(n) when is_float(n), do: :erlang.float_to_binary(n, decimals: 1)

  def format_number(n) when is_integer(n) and n >= 10_000 do
    n
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
    |> Enum.join(",")
  end

  def format_number(n), do: to_string(n)
end
