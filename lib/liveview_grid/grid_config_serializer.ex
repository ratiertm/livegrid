defmodule LiveViewGrid.GridConfigSerializer do
  @moduledoc """
  Grid 설정의 직렬화/역직렬화.

  Builder로 생성된 grid 설정을 JSON으로 변환(Export)하고,
  JSON에서 복원(Import)한다. 데이터(rows)는 포함하지 않는다.

  ## 사용법

      # Export
      {:ok, json} = GridConfigSerializer.serialize(grid_map)

      # Import
      {:ok, params} = GridConfigSerializer.deserialize(json)
  """

  @config_version "1.0"

  @allowed_types ~w(string integer float boolean date datetime)
  @allowed_aligns ~w(left center right)
  @allowed_editor_types ~w(text number select checkbox date)
  @allowed_formatters ~w(number currency percent date datetime phone)
  @allowed_renderer_types ~w(badge link progress)
  @field_pattern ~r/^[a-z][a-z0-9_]{0,49}$/

  # ============================================================================
  # Public API
  # ============================================================================

  @doc """
  Grid 설정 맵을 JSON 문자열로 직렬화한다.

  `grid_map`은 BuilderLive의 `dynamic_grids` 항목 형식.
  """
  @spec serialize(map()) :: {:ok, String.t()} | {:error, String.t()}
  def serialize(grid_map) do
    payload = %{
      "version" => @config_version,
      "exported_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "grid_name" => Map.get(grid_map, :name, ""),
      "grid_id" => Map.get(grid_map, :id, ""),
      "data_source_type" => Map.get(grid_map, :source_type, "sample"),
      "selected_schema" => Map.get(grid_map, :selected_schema),
      "selected_table" => Map.get(grid_map, :selected_table),
      "options" => serialize_options(Map.get(grid_map, :options, %{})),
      "columns" => Enum.map(Map.get(grid_map, :columns, []), &serialize_column/1)
    }

    {:ok, Jason.encode!(payload, pretty: true)}
  rescue
    e -> {:error, "직렬화 실패: #{Exception.message(e)}"}
  end

  @doc """
  JSON 문자열을 역직렬화하여 BuilderLive의 build_grid에 전달 가능한 params 맵을 반환한다.
  """
  @spec deserialize(String.t()) :: {:ok, map()} | {:error, list(String.t())}
  def deserialize(json_string) when is_binary(json_string) do
    with {:ok, data} <- parse_json(json_string),
         :ok <- validate_config(data) do
      params = %{
        grid_name: data["grid_name"],
        grid_id: data["grid_id"],
        columns: Enum.map(data["columns"], &deserialize_column/1),
        options: deserialize_options(data["options"] || %{}),
        data_source_type: data["data_source_type"] || "sample",
        selected_schema: data["selected_schema"],
        selected_table: data["selected_table"]
      }

      {:ok, params}
    end
  end

  def deserialize(_), do: {:error, ["유효하지 않은 입력입니다"]}

  # ============================================================================
  # Serialization (Elixir → JSON)
  # ============================================================================

  defp serialize_options(options) do
    Map.new(options, fn {k, v} ->
      key = if is_atom(k), do: Atom.to_string(k), else: k
      {key, v}
    end)
  end

  @doc false
  def serialize_column(col) do
    base = %{
      "field" => to_string_key(col, :field),
      "label" => Map.get(col, :label, ""),
      "type" => to_string_key(col, :type, "string"),
      "width" => serialize_width(Map.get(col, :width, :auto)),
      "align" => to_string_key(col, :align, "left"),
      "sortable" => Map.get(col, :sortable, false),
      "filterable" => Map.get(col, :filterable, false),
      "editable" => Map.get(col, :editable, false),
      "editor_type" => to_string_key(col, :editor_type, "text"),
      "editor_options" => Map.get(col, :editor_options, []),
      "formatter" => serialize_formatter(Map.get(col, :formatter)),
      "formatter_options" => serialize_formatter_options(Map.get(col, :formatter_options, %{})),
      "validators" => Enum.map(Map.get(col, :validators, []), &serialize_validator/1),
      "renderer" => serialize_renderer(col)
    }

    base
    |> maybe_put("header_group", Map.get(col, :header_group))
    |> maybe_put("summary", Map.get(col, :summary))
  end

  defp to_string_key(map, key, default \\ "") do
    case Map.get(map, key) do
      nil -> default
      val when is_atom(val) -> Atom.to_string(val)
      val when is_binary(val) -> val
      val -> to_string(val)
    end
  end

  defp serialize_width(:auto), do: "auto"
  defp serialize_width(w) when is_integer(w), do: w
  defp serialize_width(_), do: "auto"

  defp serialize_formatter(nil), do: nil
  defp serialize_formatter(f) when is_atom(f), do: Atom.to_string(f)
  defp serialize_formatter(f) when is_binary(f), do: f
  defp serialize_formatter(_), do: nil

  defp serialize_formatter_options(opts) when is_map(opts) do
    Map.new(opts, fn {k, v} ->
      key = if is_atom(k), do: Atom.to_string(k), else: k
      {key, v}
    end)
  end

  defp serialize_formatter_options(_), do: %{}

  @doc false
  def serialize_validator({:required, msg}),
    do: %{"type" => "required", "message" => msg}

  def serialize_validator({:min, val, msg}),
    do: %{"type" => "min", "value" => val, "message" => msg}

  def serialize_validator({:max, val, msg}),
    do: %{"type" => "max", "value" => val, "message" => msg}

  def serialize_validator({:min_length, val, msg}),
    do: %{"type" => "min_length", "value" => val, "message" => msg}

  def serialize_validator({:max_length, val, msg}),
    do: %{"type" => "max_length", "value" => val, "message" => msg}

  def serialize_validator({:pattern, regex, msg}),
    do: %{"type" => "pattern", "value" => Regex.source(regex), "message" => msg}

  def serialize_validator(%{} = map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
    |> Map.drop(["enabled"])
  end

  def serialize_validator(_), do: %{"type" => "unknown"}

  defp serialize_renderer(col) do
    case Map.get(col, :renderer_spec) do
      %{type: type, options: opts} ->
        %{"type" => to_string(type), "options" => serialize_renderer_options(opts)}

      _ ->
        nil
    end
  end

  defp serialize_renderer_options(opts) when is_map(opts) do
    Map.new(opts, fn
      {:colors, colors} when is_map(colors) ->
        {"colors", Map.new(colors, fn {k, v} -> {to_string(k), to_string(v)} end)}

      {k, v} when is_atom(k) ->
        {Atom.to_string(k), v}

      {k, v} ->
        {k, v}
    end)
  end

  defp serialize_renderer_options(_), do: %{}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  # ============================================================================
  # Deserialization (JSON → Elixir)
  # ============================================================================

  defp parse_json(str) do
    case Jason.decode(str) do
      {:ok, data} -> {:ok, data}
      {:error, _} -> {:error, ["유효하지 않은 JSON 파일입니다"]}
    end
  end

  defp validate_config(data) do
    errors =
      []
      |> validate_version(data)
      |> validate_grid_name(data)
      |> validate_grid_id(data)
      |> validate_columns(data)

    case errors do
      [] -> :ok
      errs -> {:error, Enum.reverse(errs)}
    end
  end

  defp validate_version(errors, %{"version" => v}) when v in ["1.0"], do: errors
  defp validate_version(errors, %{"version" => _}), do: ["지원하지 않는 설정 버전입니다" | errors]
  defp validate_version(errors, _), do: ["version 필드가 필요합니다" | errors]

  defp validate_grid_name(errors, %{"grid_name" => name}) when is_binary(name) and name != "",
    do: errors

  defp validate_grid_name(errors, _), do: ["그리드 이름이 필요합니다" | errors]

  defp validate_grid_id(errors, %{"grid_id" => id}) when is_binary(id) and id != "" do
    if Regex.match?(~r/^[a-z0-9_]+$/, id),
      do: errors,
      else: ["유효하지 않은 그리드 ID입니다 (영소문자, 숫자, _만 허용)" | errors]
  end

  defp validate_grid_id(errors, _), do: ["그리드 ID가 필요합니다" | errors]

  defp validate_columns(errors, %{"columns" => cols}) when is_list(cols) and cols != [] do
    col_errors =
      cols
      |> Enum.with_index()
      |> Enum.flat_map(fn {col, idx} -> validate_column(col, idx) end)

    fields = Enum.map(cols, &Map.get(&1, "field", "")) |> Enum.filter(&(&1 != ""))

    dup_error =
      if length(fields) != length(Enum.uniq(fields)) do
        dupes = fields -- Enum.uniq(fields)
        ["중복된 field가 있습니다: #{Enum.join(Enum.uniq(dupes), ", ")}"]
      else
        []
      end

    errors ++ col_errors ++ dup_error
  end

  defp validate_columns(errors, _), do: ["최소 1개 컬럼이 필요합니다" | errors]

  defp validate_column(col, idx) do
    prefix = "컬럼[#{idx}]"
    errs = []

    errs =
      case Map.get(col, "field") do
        f when is_binary(f) and f != "" ->
          if Regex.match?(@field_pattern, f),
            do: errs,
            else: ["#{prefix}: 유효하지 않은 field 이름 '#{f}'" | errs]

        _ ->
          ["#{prefix}: field가 필요합니다" | errs]
      end

    errs =
      case Map.get(col, "label") do
        l when is_binary(l) and l != "" -> errs
        _ -> ["#{prefix}: label이 필요합니다" | errs]
      end

    errs =
      case Map.get(col, "type") do
        t when t in @allowed_types -> errs
        nil -> errs
        t -> ["#{prefix}: 유효하지 않은 타입 '#{t}'" | errs]
      end

    errs
  end

  defp deserialize_column(col) do
    alias LiveViewGridWeb.Components.GridBuilder.BuilderHelpers

    base = %{
      field: String.to_atom(col["field"]),
      label: col["label"],
      type: safe_to_existing_atom(col["type"], @allowed_types, :string),
      width: deserialize_width(col["width"]),
      align: safe_to_existing_atom(col["align"], @allowed_aligns, :left),
      sortable: col["sortable"] == true,
      filterable: col["filterable"] == true,
      filter_type: BuilderHelpers.filter_type_for_col(
        safe_to_existing_atom(col["type"], @allowed_types, :string)
      ),
      editable: col["editable"] == true,
      editor_type: safe_to_existing_atom(col["editor_type"], @allowed_editor_types, :text),
      editor_options: col["editor_options"] || []
    }

    base = put_formatter(base, col["formatter"])
    base = put_formatter_options(base, col["formatter_options"])
    base = put_validators(base, col["validators"])
    base = put_renderer(base, col["renderer"])
    base = maybe_put_atom(base, :header_group, col["header_group"])
    base = maybe_put_atom(base, :summary, col["summary"])

    base
  end

  defp deserialize_width("auto"), do: :auto
  defp deserialize_width(w) when is_integer(w) and w > 0, do: w
  defp deserialize_width(_), do: :auto

  defp put_formatter(base, nil), do: base
  defp put_formatter(base, ""), do: base

  defp put_formatter(base, f) when is_binary(f) do
    if f in @allowed_formatters,
      do: Map.put(base, :formatter, String.to_existing_atom(f)),
      else: base
  end

  defp put_formatter(base, _), do: base

  defp put_formatter_options(base, nil), do: base

  defp put_formatter_options(base, opts) when is_map(opts) do
    atom_opts = Map.new(opts, fn {k, v} -> {String.to_atom(k), v} end)
    Map.put(base, :formatter_options, atom_opts)
  end

  defp put_formatter_options(base, _), do: base

  defp put_validators(base, nil), do: base
  defp put_validators(base, []), do: base

  defp put_validators(base, validators) when is_list(validators) do
    alias LiveViewGridWeb.Components.GridBuilder.BuilderHelpers

    tuples =
      validators
      |> Enum.map(fn v ->
        # string keys → atom keys for BuilderHelpers compatibility
        atomized =
          Map.new(v, fn
            {"type", val} -> {:type, val}
            {"value", val} -> {:value, to_string(val)}
            {"message", val} -> {:message, val}
            {k, val} -> {String.to_atom(k), val}
          end)

        BuilderHelpers.validator_map_to_tuple(atomized)
      end)

    Map.put(base, :validators, tuples)
  end

  defp put_validators(base, _), do: base

  defp put_renderer(base, nil), do: base

  defp put_renderer(base, %{"type" => type, "options" => opts}) when type in @allowed_renderer_types do
    alias LiveViewGridWeb.Components.GridBuilder.BuilderHelpers

    # BuilderHelpers.build_renderer/2 가 기대하는 형태로 변환
    renderer_col = %{
      renderer: type,
      renderer_options: deserialize_renderer_options(type, opts)
    }

    result = BuilderHelpers.build_renderer(base, renderer_col)

    # renderer_spec도 함께 저장
    Map.put(result, :renderer_spec, %{
      type: type,
      options: deserialize_renderer_spec_options(type, opts)
    })
  end

  defp put_renderer(base, _), do: base

  defp deserialize_renderer_options("badge", opts) do
    colors = Map.get(opts, "colors", %{})
    colors_text = Enum.map_join(colors, ", ", fn {k, v} -> "#{k}:#{v}" end)
    %{colors_text: colors_text}
  end

  defp deserialize_renderer_options("link", opts) do
    %{
      prefix: Map.get(opts, "prefix", ""),
      target: Map.get(opts, "target", "")
    }
  end

  defp deserialize_renderer_options("progress", opts) do
    %{
      max: Map.get(opts, "max", "100"),
      color: Map.get(opts, "color", "blue")
    }
  end

  defp deserialize_renderer_options(_, _), do: %{}

  defp deserialize_renderer_spec_options("badge", opts) do
    %{colors: Map.get(opts, "colors", %{})}
  end

  defp deserialize_renderer_spec_options("link", opts) do
    %{
      prefix: Map.get(opts, "prefix", ""),
      target: Map.get(opts, "target")
    }
  end

  defp deserialize_renderer_spec_options("progress", opts) do
    max = case Map.get(opts, "max", 100) do
      v when is_binary(v) -> String.to_integer(v)
      v when is_integer(v) -> v
      _ -> 100
    end

    %{
      max: max,
      color: Map.get(opts, "color", "blue")
    }
  end

  defp deserialize_renderer_spec_options(_, _), do: %{}

  defp deserialize_options(opts) when is_map(opts) do
    Map.new(opts, fn {k, v} ->
      atom_key = String.to_atom(k)
      {atom_key, v}
    end)
  end

  defp deserialize_options(_), do: %{}

  defp safe_to_existing_atom(nil, _allowed, default), do: default
  defp safe_to_existing_atom("", _allowed, default), do: default

  defp safe_to_existing_atom(value, allowed, default) when is_binary(value) do
    if value in allowed do
      String.to_existing_atom(value)
    else
      default
    end
  end

  defp safe_to_existing_atom(value, _allowed, _default) when is_atom(value), do: value
  defp safe_to_existing_atom(_, _allowed, default), do: default

  defp maybe_put_atom(base, _key, nil), do: base
  defp maybe_put_atom(base, key, value), do: Map.put(base, key, value)
end
