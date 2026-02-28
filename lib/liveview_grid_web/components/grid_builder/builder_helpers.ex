defmodule LiveViewGridWeb.Components.GridBuilder.BuilderHelpers do
  @moduledoc """
  Grid Builder의 순수 헬퍼 함수들.

  BuilderModal에서 추출한 검증, 변환, ID 생성 등의 순수 함수.
  테스트 가능하도록 public API로 제공한다.
  """

  @doc """
  Grid Builder 상태를 검증한다.

  ## Returns
  - `{:ok, definition_params}` - 유효한 경우
  - `{:error, errors}` - 에러 맵 반환
  """
  @spec validate_builder(map()) :: {:ok, map()} | {:error, map()}
  def validate_builder(assigns) do
    errors = %{}

    errors =
      if assigns.grid_name == "",
        do: Map.put(errors, :grid_name, "그리드 이름을 입력하세요"),
        else: errors

    errors =
      if assigns.columns == [],
        do: Map.put(errors, :columns, "최소 1개 컬럼이 필요합니다"),
        else: errors

    empty_fields = Enum.filter(assigns.columns, &(&1.field == ""))

    errors =
      if empty_fields != [],
        do: Map.put(errors, :field, "모든 컬럼에 Field Name이 필요합니다"),
        else: errors

    fields =
      assigns.columns
      |> Enum.map(& &1.field)
      |> Enum.filter(& &1 != "")

    errors =
      if length(fields) != length(Enum.uniq(fields)),
        do: Map.put(errors, :duplicate, "중복된 Field Name이 있습니다"),
        else: errors

    # Data source validation
    errors =
      case {Map.get(assigns, :data_source_type, "sample"),
            Map.get(assigns, :selected_schema),
            Map.get(assigns, :selected_table)} do
        {"schema", nil, _} -> Map.put(errors, :data_source, "스키마를 선택하세요")
        {"schema", "", _} -> Map.put(errors, :data_source, "스키마를 선택하세요")
        {"table", _, nil} -> Map.put(errors, :data_source, "테이블을 선택하세요")
        {"table", _, ""} -> Map.put(errors, :data_source, "테이블을 선택하세요")
        _ -> errors
      end

    if errors == %{} do
      {:ok, build_definition_params(assigns)}
    else
      {:error, errors}
    end
  end

  @doc """
  컬럼 정의 맵을 GridDefinition 파라미터로 변환한다.
  """
  @spec build_definition_params(map()) :: map()
  def build_definition_params(assigns) do
    columns =
      assigns.columns
      |> Enum.filter(&(&1.field != ""))
      |> Enum.map(fn col ->
        base = %{
          field: String.to_atom(col.field),
          label: if(col.label == "", do: col.field, else: col.label),
          type: col.type,
          width: col.width,
          align: col.align,
          sortable: col.sortable,
          filterable: col.filterable,
          filter_type: filter_type_for_col(col.type),
          editable: col.editable,
          editor_type: col.editor_type,
          editor_options: col.editor_options
        }

        base = if col.formatter, do: Map.put(base, :formatter, col.formatter), else: base

        base =
          if col.validators != [] do
            tuples = Enum.map(col.validators, &validator_map_to_tuple/1)
            Map.put(base, :validators, tuples)
          else
            base
          end

        build_renderer(base, col)
      end)

    %{
      grid_name: assigns.grid_name,
      grid_id: assigns.grid_id,
      columns: columns,
      options: assigns.grid_options,
      data_source_type: Map.get(assigns, :data_source_type, "sample"),
      selected_schema: Map.get(assigns, :selected_schema),
      selected_table: Map.get(assigns, :selected_table)
    }
  end

  @doc """
  Validator 맵을 튜플로 변환한다.

  ## Examples

      iex> validator_map_to_tuple(%{type: "required", message: "필수"})
      {:required, "필수"}

      iex> validator_map_to_tuple(%{type: "min", value: "10", message: "최소 10"})
      {:min, 10, "최소 10"}
  """
  @spec validator_map_to_tuple(map()) :: tuple()
  def validator_map_to_tuple(%{type: "required", message: msg}), do: {:required, msg}

  def validator_map_to_tuple(%{type: "min", value: v, message: msg}) do
    {:min, parse_number(v), msg}
  end

  def validator_map_to_tuple(%{type: "max", value: v, message: msg}) do
    {:max, parse_number(v), msg}
  end

  def validator_map_to_tuple(%{type: "min_length", value: v, message: msg}) do
    {:min_length, parse_number(v), msg}
  end

  def validator_map_to_tuple(%{type: "max_length", value: v, message: msg}) do
    {:max_length, parse_number(v), msg}
  end

  def validator_map_to_tuple(%{type: "pattern", value: v, message: msg}) do
    case Regex.compile(v || "") do
      {:ok, regex} -> {:pattern, regex, msg}
      _ -> {:pattern, ~r/./, msg}
    end
  end

  def validator_map_to_tuple(other), do: {:required, Map.get(other, :message, "필수 입력")}

  @doc """
  Renderer 설정을 빌드한다.
  """
  @spec build_renderer(map(), map()) :: map()
  def build_renderer(base, %{renderer: "badge", renderer_options: opts}) do
    colors_text = Map.get(opts, :colors_text, "")

    colors =
      colors_text
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(& &1 != "")
      |> Enum.reduce(%{}, fn pair, acc ->
        case String.split(pair, ":", parts: 2) do
          [k, v] -> Map.put(acc, String.trim(k), String.trim(v))
          _ -> acc
        end
      end)

    Map.put(base, :renderer, LiveViewGrid.Renderers.badge(colors: colors))
  end

  def build_renderer(base, %{renderer: "link", renderer_options: opts}) do
    Map.put(
      base,
      :renderer,
      LiveViewGrid.Renderers.link(
        prefix: Map.get(opts, :prefix, ""),
        target:
          case Map.get(opts, :target, "") do
            "" -> nil
            t -> t
          end
      )
    )
  end

  def build_renderer(base, %{renderer: "progress", renderer_options: opts}) do
    max_val =
      case Map.get(opts, :max, "100") do
        v when is_binary(v) -> String.to_integer(v)
        v when is_integer(v) -> v
        _ -> 100
      end

    Map.put(
      base,
      :renderer,
      LiveViewGrid.Renderers.progress(
        max: max_val,
        color: Map.get(opts, :color, "blue")
      )
    )
  end

  def build_renderer(base, _col), do: base

  @doc "그리드 이름에서 snake_case ID를 생성한다."
  @spec generate_grid_id(String.t()) :: String.t()
  def generate_grid_id(name) do
    english_parts =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s]/, "")
      |> String.replace(~r/\s+/, "_")
      |> String.trim("_")

    case english_parts do
      "" ->
        hash = :erlang.phash2(name, 9999)
        "grid_#{hash}"

      id ->
        id
    end
  end

  @doc "Grid ID를 정제한다 (영소문자 + 숫자 + 언더스코어만)."
  @spec sanitize_grid_id(String.t()) :: String.t()
  def sanitize_grid_id(id) do
    id
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/, "")
  end

  @doc "Field 이름을 정제한다 (영소문자 + 숫자 + 언더스코어만)."
  @spec sanitize_field_name(String.t()) :: String.t()
  def sanitize_field_name(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]/, "")
  end

  @doc "옵션 값을 적절한 타입으로 변환한다."
  @spec coerce_option(String.t(), String.t()) :: term()
  def coerce_option("page_size", v), do: String.to_integer(v)
  def coerce_option("row_height", v), do: String.to_integer(v)
  def coerce_option("frozen_columns", v), do: String.to_integer(v)
  def coerce_option(_, v), do: v

  @doc "문자열/숫자를 정수로 파싱한다."
  @spec parse_number(term()) :: integer()
  def parse_number(nil), do: 0
  def parse_number(v) when is_integer(v), do: v
  def parse_number(v) when is_float(v), do: round(v)

  def parse_number(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error -> 0
    end
  end

  def parse_number(_), do: 0

  @doc "컬럼 타입에 따른 filter_type을 반환한다."
  @spec filter_type_for_col(atom()) :: atom()
  def filter_type_for_col(:integer), do: :number
  def filter_type_for_col(:float), do: :number
  def filter_type_for_col(:date), do: :date
  def filter_type_for_col(:datetime), do: :date
  def filter_type_for_col(_), do: :text
end
