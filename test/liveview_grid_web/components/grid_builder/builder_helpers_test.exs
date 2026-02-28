defmodule LiveViewGridWeb.Components.GridBuilder.BuilderHelpersTest do
  use ExUnit.Case, async: true

  alias LiveViewGridWeb.Components.GridBuilder.BuilderHelpers

  # ── Test Column Fixtures ──

  defp valid_column(overrides \\ %{}) do
    Map.merge(
      %{
        temp_id: "col_1",
        field: "name",
        label: "이름",
        type: :string,
        width: :auto,
        align: :left,
        sortable: false,
        filterable: false,
        editable: false,
        editor_type: :text,
        editor_options: [],
        formatter: nil,
        formatter_options: %{},
        validators: [],
        renderer: nil,
        renderer_options: %{}
      },
      overrides
    )
  end

  defp valid_assigns(overrides \\ %{}) do
    Map.merge(
      %{
        grid_name: "테스트 그리드",
        grid_id: "test_grid",
        columns: [valid_column()],
        grid_options: %{page_size: 20, theme: "light"}
      },
      overrides
    )
  end

  # ══════════════════════════════════════════════════════
  # validate_builder/1
  # ══════════════════════════════════════════════════════

  describe "validate_builder/1" do
    test "returns :ok with valid assigns" do
      assert {:ok, params} = BuilderHelpers.validate_builder(valid_assigns())
      assert params.grid_name == "테스트 그리드"
      assert params.grid_id == "test_grid"
      assert length(params.columns) == 1
    end

    test "error when grid_name is empty" do
      assigns = valid_assigns(%{grid_name: ""})
      assert {:error, errors} = BuilderHelpers.validate_builder(assigns)
      assert Map.has_key?(errors, :grid_name)
    end

    test "error when columns is empty" do
      assigns = valid_assigns(%{columns: []})
      assert {:error, errors} = BuilderHelpers.validate_builder(assigns)
      assert Map.has_key?(errors, :columns)
    end

    test "error when a column has empty field" do
      assigns = valid_assigns(%{columns: [valid_column(%{field: ""})]})
      assert {:error, errors} = BuilderHelpers.validate_builder(assigns)
      assert Map.has_key?(errors, :field)
    end

    test "error when duplicate field names exist" do
      cols = [
        valid_column(%{temp_id: "col_1", field: "name"}),
        valid_column(%{temp_id: "col_2", field: "name"})
      ]

      assigns = valid_assigns(%{columns: cols})
      assert {:error, errors} = BuilderHelpers.validate_builder(assigns)
      assert Map.has_key?(errors, :duplicate)
    end

    test "multiple errors reported simultaneously" do
      assigns = valid_assigns(%{grid_name: "", columns: []})
      assert {:error, errors} = BuilderHelpers.validate_builder(assigns)
      assert Map.has_key?(errors, :grid_name)
      assert Map.has_key?(errors, :columns)
    end

    test "skips duplicate check for empty field names" do
      cols = [
        valid_column(%{temp_id: "col_1", field: "name"}),
        valid_column(%{temp_id: "col_2", field: ""})
      ]

      assigns = valid_assigns(%{columns: cols})
      # Should have :field error but not :duplicate
      assert {:error, errors} = BuilderHelpers.validate_builder(assigns)
      assert Map.has_key?(errors, :field)
      refute Map.has_key?(errors, :duplicate)
    end
  end

  # ══════════════════════════════════════════════════════
  # build_definition_params/1
  # ══════════════════════════════════════════════════════

  describe "build_definition_params/1" do
    test "converts field string to atom" do
      assigns = valid_assigns()
      result = BuilderHelpers.build_definition_params(assigns)

      [col | _] = result.columns
      assert col.field == :name
    end

    test "uses field name as label when label is empty" do
      cols = [valid_column(%{field: "age", label: ""})]
      assigns = valid_assigns(%{columns: cols})
      result = BuilderHelpers.build_definition_params(assigns)

      [col | _] = result.columns
      assert col.label == "age"
    end

    test "skips columns with empty field" do
      cols = [
        valid_column(%{temp_id: "col_1", field: "name"}),
        valid_column(%{temp_id: "col_2", field: ""})
      ]

      assigns = valid_assigns(%{columns: cols})
      result = BuilderHelpers.build_definition_params(assigns)
      assert length(result.columns) == 1
    end

    test "includes formatter when set" do
      cols = [valid_column(%{formatter: "number"})]
      assigns = valid_assigns(%{columns: cols})
      result = BuilderHelpers.build_definition_params(assigns)

      [col | _] = result.columns
      assert col.formatter == "number"
    end

    test "does not include formatter when nil" do
      assigns = valid_assigns()
      result = BuilderHelpers.build_definition_params(assigns)

      [col | _] = result.columns
      refute Map.has_key?(col, :formatter)
    end

    test "converts validators to tuples" do
      cols = [
        valid_column(%{
          validators: [
            %{type: "required", message: "필수"},
            %{type: "min_length", value: "2", message: "2자 이상"}
          ]
        })
      ]

      assigns = valid_assigns(%{columns: cols})
      result = BuilderHelpers.build_definition_params(assigns)

      [col | _] = result.columns
      assert {:required, "필수"} in col.validators
      assert {:min_length, 2, "2자 이상"} in col.validators
    end

    test "includes all base properties" do
      cols = [valid_column(%{sortable: true, editable: true, align: :center})]
      assigns = valid_assigns(%{columns: cols})
      result = BuilderHelpers.build_definition_params(assigns)

      [col | _] = result.columns
      assert col.sortable == true
      assert col.editable == true
      assert col.align == :center
    end
  end

  # ══════════════════════════════════════════════════════
  # validator_map_to_tuple/1
  # ══════════════════════════════════════════════════════

  describe "validator_map_to_tuple/1" do
    test "required validator" do
      assert {:required, "필수"} =
               BuilderHelpers.validator_map_to_tuple(%{type: "required", message: "필수"})
    end

    test "min validator" do
      assert {:min, 10, "최소 10"} =
               BuilderHelpers.validator_map_to_tuple(%{type: "min", value: "10", message: "최소 10"})
    end

    test "max validator" do
      assert {:max, 100, "최대 100"} =
               BuilderHelpers.validator_map_to_tuple(%{type: "max", value: "100", message: "최대 100"})
    end

    test "min_length validator" do
      assert {:min_length, 2, "2자 이상"} =
               BuilderHelpers.validator_map_to_tuple(%{type: "min_length", value: "2", message: "2자 이상"})
    end

    test "max_length validator" do
      assert {:max_length, 50, "50자 이하"} =
               BuilderHelpers.validator_map_to_tuple(%{type: "max_length", value: "50", message: "50자 이하"})
    end

    test "pattern validator with valid regex" do
      result = BuilderHelpers.validator_map_to_tuple(%{type: "pattern", value: "^[a-z]+$", message: "영소문자만"})
      assert {:pattern, %Regex{}, "영소문자만"} = result
    end

    test "pattern validator with invalid regex falls back" do
      result = BuilderHelpers.validator_map_to_tuple(%{type: "pattern", value: "[invalid", message: "에러"})
      assert {:pattern, %Regex{}, "에러"} = result
    end

    test "pattern validator with nil value" do
      result = BuilderHelpers.validator_map_to_tuple(%{type: "pattern", value: nil, message: "패턴"})
      assert {:pattern, %Regex{}, "패턴"} = result
    end

    test "unknown validator type falls back to required" do
      assert {:required, "기본 메시지"} =
               BuilderHelpers.validator_map_to_tuple(%{type: "unknown", message: "기본 메시지"})
    end

    test "min with integer value" do
      assert {:min, 5, "msg"} =
               BuilderHelpers.validator_map_to_tuple(%{type: "min", value: 5, message: "msg"})
    end

    test "max with float value rounds to nearest" do
      assert {:max, 11, "msg"} =
               BuilderHelpers.validator_map_to_tuple(%{type: "max", value: 10.5, message: "msg"})
    end

    test "min with nil value defaults to 0" do
      assert {:min, 0, "msg"} =
               BuilderHelpers.validator_map_to_tuple(%{type: "min", value: nil, message: "msg"})
    end
  end

  # ══════════════════════════════════════════════════════
  # build_renderer/2
  # ══════════════════════════════════════════════════════

  describe "build_renderer/2" do
    test "badge renderer parses colors" do
      col = %{renderer: "badge", renderer_options: %{colors_text: "active:green, inactive:red"}}
      result = BuilderHelpers.build_renderer(%{field: :status}, col)

      assert is_function(result.renderer)
    end

    test "badge renderer with empty colors" do
      col = %{renderer: "badge", renderer_options: %{colors_text: ""}}
      result = BuilderHelpers.build_renderer(%{field: :status}, col)

      assert is_function(result.renderer)
    end

    test "badge renderer without colors_text key" do
      col = %{renderer: "badge", renderer_options: %{}}
      result = BuilderHelpers.build_renderer(%{field: :status}, col)

      assert is_function(result.renderer)
    end

    test "link renderer with prefix and target" do
      col = %{renderer: "link", renderer_options: %{prefix: "mailto:", target: "_blank"}}
      result = BuilderHelpers.build_renderer(%{field: :email}, col)

      assert is_function(result.renderer)
    end

    test "link renderer with empty target becomes nil" do
      col = %{renderer: "link", renderer_options: %{prefix: "", target: ""}}
      result = BuilderHelpers.build_renderer(%{field: :email}, col)

      assert is_function(result.renderer)
    end

    test "progress renderer with string max" do
      col = %{renderer: "progress", renderer_options: %{max: "200", color: "green"}}
      result = BuilderHelpers.build_renderer(%{field: :score}, col)

      assert is_function(result.renderer)
    end

    test "progress renderer with integer max" do
      col = %{renderer: "progress", renderer_options: %{max: 50, color: "blue"}}
      result = BuilderHelpers.build_renderer(%{field: :score}, col)

      assert is_function(result.renderer)
    end

    test "no renderer returns base unchanged" do
      base = %{field: :name}
      col = %{renderer: nil, renderer_options: %{}}
      result = BuilderHelpers.build_renderer(base, col)

      assert result == base
    end

    test "empty string renderer returns base unchanged" do
      base = %{field: :name}
      col = %{renderer: "", renderer_options: %{}}
      result = BuilderHelpers.build_renderer(base, col)

      assert result == base
    end
  end

  # ══════════════════════════════════════════════════════
  # generate_grid_id/1 & sanitize functions
  # ══════════════════════════════════════════════════════

  describe "generate_grid_id/1" do
    test "converts English name to snake_case" do
      assert BuilderHelpers.generate_grid_id("User List") == "user_list"
    end

    test "handles mixed case" do
      assert BuilderHelpers.generate_grid_id("MyGrid") == "mygrid"
    end

    test "generates hash-based ID for Korean-only names" do
      result = BuilderHelpers.generate_grid_id("사용자 목록")
      assert String.starts_with?(result, "grid_")
    end

    test "strips special characters" do
      assert BuilderHelpers.generate_grid_id("My Grid!@#") == "my_grid"
    end

    test "handles empty string" do
      result = BuilderHelpers.generate_grid_id("")
      assert String.starts_with?(result, "grid_")
    end
  end

  describe "sanitize_grid_id/1" do
    test "keeps valid characters" do
      assert BuilderHelpers.sanitize_grid_id("user_grid_1") == "user_grid_1"
    end

    test "removes special characters" do
      assert BuilderHelpers.sanitize_grid_id("user grid!@#") == "usergrid"
    end

    test "lowercases" do
      assert BuilderHelpers.sanitize_grid_id("MyGrid") == "mygrid"
    end
  end

  describe "sanitize_field_name/1" do
    test "keeps valid characters" do
      assert BuilderHelpers.sanitize_field_name("user_name") == "user_name"
    end

    test "removes special characters" do
      assert BuilderHelpers.sanitize_field_name("User Name!") == "username"
    end

    test "lowercases" do
      assert BuilderHelpers.sanitize_field_name("Age") == "age"
    end
  end

  describe "coerce_option/2" do
    test "page_size to integer" do
      assert BuilderHelpers.coerce_option("page_size", "50") == 50
    end

    test "row_height to integer" do
      assert BuilderHelpers.coerce_option("row_height", "40") == 40
    end

    test "frozen_columns to integer" do
      assert BuilderHelpers.coerce_option("frozen_columns", "2") == 2
    end

    test "other keys pass through" do
      assert BuilderHelpers.coerce_option("theme", "dark") == "dark"
    end
  end

  describe "parse_number/1" do
    test "nil returns 0" do
      assert BuilderHelpers.parse_number(nil) == 0
    end

    test "integer passes through" do
      assert BuilderHelpers.parse_number(42) == 42
    end

    test "float rounds" do
      assert BuilderHelpers.parse_number(3.7) == 4
    end

    test "string parses" do
      assert BuilderHelpers.parse_number("123") == 123
    end

    test "invalid string returns 0" do
      assert BuilderHelpers.parse_number("abc") == 0
    end

    test "other types return 0" do
      assert BuilderHelpers.parse_number(:atom) == 0
    end
  end
end
