defmodule LiveViewGrid.GridConfigSerializerTest do
  use ExUnit.Case, async: true

  alias LiveViewGrid.GridConfigSerializer

  # ============================================================================
  # Test fixtures
  # ============================================================================

  defp sample_grid_map do
    %{
      id: "employee_list",
      name: "사원 목록",
      source_type: "sample",
      options: %{
        page_size: 20,
        theme: "light",
        virtual_scroll: false,
        row_height: 40,
        frozen_columns: 0,
        show_row_number: false,
        show_header: true,
        show_footer: true
      },
      columns: [
        %{
          field: :name,
          label: "이름",
          type: :string,
          width: 150,
          align: :left,
          sortable: true,
          filterable: true,
          editable: false,
          editor_type: :text,
          editor_options: [],
          formatter: nil,
          formatter_options: %{},
          validators: [{:required, "필수 입력"}],
          renderer: nil
        },
        %{
          field: :age,
          label: "나이",
          type: :integer,
          width: 80,
          align: :center,
          sortable: true,
          filterable: false,
          editable: true,
          editor_type: :number,
          editor_options: [],
          formatter: :number,
          formatter_options: %{},
          validators: [{:min, 0, "0 이상"}, {:max, 200, "200 이하"}],
          renderer: nil
        },
        %{
          field: :status,
          label: "상태",
          type: :string,
          width: 100,
          align: :center,
          sortable: true,
          filterable: true,
          editable: false,
          editor_type: :text,
          editor_options: [],
          formatter: nil,
          formatter_options: %{},
          validators: [],
          renderer: LiveViewGrid.Renderers.badge(colors: %{"Active" => "green", "Inactive" => "red"}),
          renderer_spec: %{type: "badge", options: %{colors: %{"Active" => "green", "Inactive" => "red"}}}
        }
      ]
    }
  end

  # ============================================================================
  # serialize/1
  # ============================================================================

  describe "serialize/1" do
    test "produces valid JSON with version and exported_at" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      data = Jason.decode!(json)

      assert data["version"] == "1.0"
      assert is_binary(data["exported_at"])
      assert data["grid_name"] == "사원 목록"
      assert data["grid_id"] == "employee_list"
    end

    test "serializes grid options with string keys" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      data = Jason.decode!(json)

      assert data["options"]["page_size"] == 20
      assert data["options"]["theme"] == "light"
      assert data["options"]["virtual_scroll"] == false
    end

    test "serializes column field as string" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      data = Jason.decode!(json)

      fields = Enum.map(data["columns"], & &1["field"])
      assert fields == ["name", "age", "status"]
    end

    test "serializes atom values (type, align) as strings" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      data = Jason.decode!(json)

      name_col = Enum.find(data["columns"], &(&1["field"] == "name"))
      assert name_col["type"] == "string"
      assert name_col["align"] == "left"

      age_col = Enum.find(data["columns"], &(&1["field"] == "age"))
      assert age_col["type"] == "integer"
      assert age_col["align"] == "center"
    end

    test "serializes width :auto as string 'auto'" do
      grid = %{sample_grid_map() | columns: [
        %{field: :test, label: "Test", type: :string, width: :auto, align: :left,
          sortable: false, filterable: false, editable: false, editor_type: :text,
          editor_options: [], formatter: nil, formatter_options: %{}, validators: [], renderer: nil}
      ]}

      {:ok, json} = GridConfigSerializer.serialize(grid)
      data = Jason.decode!(json)

      assert hd(data["columns"])["width"] == "auto"
    end

    test "serializes validators as maps" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      data = Jason.decode!(json)

      name_col = Enum.find(data["columns"], &(&1["field"] == "name"))
      assert name_col["validators"] == [%{"type" => "required", "message" => "필수 입력"}]

      age_col = Enum.find(data["columns"], &(&1["field"] == "age"))
      assert age_col["validators"] == [
        %{"type" => "min", "value" => 0, "message" => "0 이상"},
        %{"type" => "max", "value" => 200, "message" => "200 이하"}
      ]
    end

    test "serializes renderer_spec" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      data = Jason.decode!(json)

      status_col = Enum.find(data["columns"], &(&1["field"] == "status"))
      assert status_col["renderer"]["type"] == "badge"
      assert status_col["renderer"]["options"]["colors"]["Active"] == "green"
    end

    test "serializes nil renderer as null" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      data = Jason.decode!(json)

      name_col = Enum.find(data["columns"], &(&1["field"] == "name"))
      assert name_col["renderer"] == nil
    end

    test "serializes formatter as string" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      data = Jason.decode!(json)

      age_col = Enum.find(data["columns"], &(&1["field"] == "age"))
      assert age_col["formatter"] == "number"
    end

    test "serializes pattern validator with regex source" do
      grid = %{sample_grid_map() | columns: [
        %{field: :email, label: "Email", type: :string, width: 200, align: :left,
          sortable: false, filterable: false, editable: true, editor_type: :text,
          editor_options: [], formatter: nil, formatter_options: %{},
          validators: [{:pattern, ~r/@/, "이메일 형식"}], renderer: nil}
      ]}

      {:ok, json} = GridConfigSerializer.serialize(grid)
      data = Jason.decode!(json)

      validator = hd(hd(data["columns"])["validators"])
      assert validator["type"] == "pattern"
      assert validator["value"] == "@"
      assert validator["message"] == "이메일 형식"
    end
  end

  # ============================================================================
  # deserialize/1
  # ============================================================================

  describe "deserialize/1" do
    test "round-trip: serialize then deserialize produces equivalent params" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      {:ok, params} = GridConfigSerializer.deserialize(json)

      assert params.grid_name == "사원 목록"
      assert params.grid_id == "employee_list"
      assert params.data_source_type == "sample"
      assert length(params.columns) == 3
    end

    test "restores atom fields from JSON strings" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      {:ok, params} = GridConfigSerializer.deserialize(json)

      name_col = Enum.find(params.columns, &(&1.field == :name))
      assert name_col.type == :string
      assert name_col.align == :left
      assert name_col.editor_type == :text
    end

    test "restores width :auto from string" do
      json = Jason.encode!(%{
        "version" => "1.0",
        "grid_name" => "test",
        "grid_id" => "test_grid",
        "columns" => [%{
          "field" => "name", "label" => "Name", "type" => "string",
          "width" => "auto", "align" => "left"
        }]
      })

      {:ok, params} = GridConfigSerializer.deserialize(json)
      assert hd(params.columns).width == :auto
    end

    test "restores integer width" do
      json = Jason.encode!(%{
        "version" => "1.0",
        "grid_name" => "test",
        "grid_id" => "test_grid",
        "columns" => [%{
          "field" => "name", "label" => "Name", "type" => "string",
          "width" => 150
        }]
      })

      {:ok, params} = GridConfigSerializer.deserialize(json)
      assert hd(params.columns).width == 150
    end

    test "restores validators as tuples" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      {:ok, params} = GridConfigSerializer.deserialize(json)

      name_col = Enum.find(params.columns, &(&1.field == :name))
      assert name_col.validators == [{:required, "필수 입력"}]

      age_col = Enum.find(params.columns, &(&1.field == :age))
      assert [{:min, 0, "0 이상"}, {:max, 200, "200 이하"}] = age_col.validators
    end

    test "restores renderer function from spec" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      {:ok, params} = GridConfigSerializer.deserialize(json)

      status_col = Enum.find(params.columns, &(&1.field == :status))
      assert is_function(status_col.renderer, 3)
      assert status_col.renderer_spec.type == "badge"
    end

    test "restores formatter as atom" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      {:ok, params} = GridConfigSerializer.deserialize(json)

      age_col = Enum.find(params.columns, &(&1.field == :age))
      assert age_col.formatter == :number
    end

    test "restores options with atom keys" do
      {:ok, json} = GridConfigSerializer.serialize(sample_grid_map())
      {:ok, params} = GridConfigSerializer.deserialize(json)

      assert params.options.page_size == 20
      assert params.options.theme == "light"
    end
  end

  # ============================================================================
  # Validation errors
  # ============================================================================

  describe "deserialize/1 validation" do
    test "rejects invalid JSON" do
      assert {:error, ["유효하지 않은 JSON 파일입니다"]} =
               GridConfigSerializer.deserialize("not json")
    end

    test "rejects missing version" do
      json = Jason.encode!(%{"grid_name" => "test", "grid_id" => "test", "columns" => [%{"field" => "a", "label" => "A"}]})
      {:error, errors} = GridConfigSerializer.deserialize(json)
      assert "version 필드가 필요합니다" in errors
    end

    test "rejects unsupported version" do
      json = Jason.encode!(%{"version" => "99.0", "grid_name" => "test", "grid_id" => "test", "columns" => [%{"field" => "a", "label" => "A"}]})
      {:error, errors} = GridConfigSerializer.deserialize(json)
      assert "지원하지 않는 설정 버전입니다" in errors
    end

    test "rejects empty grid_name" do
      json = Jason.encode!(%{"version" => "1.0", "grid_name" => "", "grid_id" => "test", "columns" => [%{"field" => "a", "label" => "A"}]})
      {:error, errors} = GridConfigSerializer.deserialize(json)
      assert "그리드 이름이 필요합니다" in errors
    end

    test "rejects invalid grid_id" do
      json = Jason.encode!(%{"version" => "1.0", "grid_name" => "test", "grid_id" => "BAD-ID!", "columns" => [%{"field" => "a", "label" => "A"}]})
      {:error, errors} = GridConfigSerializer.deserialize(json)
      assert Enum.any?(errors, &String.contains?(&1, "유효하지 않은 그리드 ID"))
    end

    test "rejects empty columns" do
      json = Jason.encode!(%{"version" => "1.0", "grid_name" => "test", "grid_id" => "test", "columns" => []})
      {:error, errors} = GridConfigSerializer.deserialize(json)
      assert "최소 1개 컬럼이 필요합니다" in errors
    end

    test "rejects column without field" do
      json = Jason.encode!(%{"version" => "1.0", "grid_name" => "test", "grid_id" => "test", "columns" => [%{"label" => "A"}]})
      {:error, errors} = GridConfigSerializer.deserialize(json)
      assert Enum.any?(errors, &String.contains?(&1, "field가 필요합니다"))
    end

    test "rejects column without label" do
      json = Jason.encode!(%{"version" => "1.0", "grid_name" => "test", "grid_id" => "test", "columns" => [%{"field" => "a"}]})
      {:error, errors} = GridConfigSerializer.deserialize(json)
      assert Enum.any?(errors, &String.contains?(&1, "label이 필요합니다"))
    end

    test "rejects invalid column type" do
      json = Jason.encode!(%{"version" => "1.0", "grid_name" => "test", "grid_id" => "test",
        "columns" => [%{"field" => "a", "label" => "A", "type" => "invalid_type"}]})
      {:error, errors} = GridConfigSerializer.deserialize(json)
      assert Enum.any?(errors, &String.contains?(&1, "유효하지 않은 타입"))
    end

    test "rejects duplicate fields" do
      json = Jason.encode!(%{"version" => "1.0", "grid_name" => "test", "grid_id" => "test",
        "columns" => [
          %{"field" => "name", "label" => "Name1"},
          %{"field" => "name", "label" => "Name2"}
        ]})
      {:error, errors} = GridConfigSerializer.deserialize(json)
      assert Enum.any?(errors, &String.contains?(&1, "중복된 field"))
    end

    test "rejects non-binary input" do
      assert {:error, ["유효하지 않은 입력입니다"]} =
               GridConfigSerializer.deserialize(123)
    end
  end

  # ============================================================================
  # Edge cases
  # ============================================================================

  describe "edge cases" do
    test "handles grid with minimal columns" do
      json = Jason.encode!(%{
        "version" => "1.0",
        "grid_name" => "minimal",
        "grid_id" => "minimal",
        "columns" => [%{"field" => "id", "label" => "ID"}]
      })

      {:ok, params} = GridConfigSerializer.deserialize(json)
      col = hd(params.columns)
      assert col.field == :id
      assert col.type == :string
      assert col.width == :auto
      assert col.sortable == false
    end

    test "handles link renderer round-trip" do
      grid = %{sample_grid_map() | columns: [
        %{field: :email, label: "Email", type: :string, width: 200, align: :left,
          sortable: false, filterable: false, editable: false, editor_type: :text,
          editor_options: [], formatter: nil, formatter_options: %{}, validators: [],
          renderer: LiveViewGrid.Renderers.link(prefix: "mailto:", target: "_blank"),
          renderer_spec: %{type: "link", options: %{prefix: "mailto:", target: "_blank"}}}
      ]}

      {:ok, json} = GridConfigSerializer.serialize(grid)
      {:ok, params} = GridConfigSerializer.deserialize(json)

      col = hd(params.columns)
      assert is_function(col.renderer, 3)
      assert col.renderer_spec.type == "link"
    end

    test "handles progress renderer round-trip" do
      grid = %{sample_grid_map() | columns: [
        %{field: :score, label: "Score", type: :integer, width: 200, align: :left,
          sortable: false, filterable: false, editable: false, editor_type: :number,
          editor_options: [], formatter: nil, formatter_options: %{}, validators: [],
          renderer: LiveViewGrid.Renderers.progress(max: 200, color: "green"),
          renderer_spec: %{type: "progress", options: %{max: 200, color: "green"}}}
      ]}

      {:ok, json} = GridConfigSerializer.serialize(grid)
      {:ok, params} = GridConfigSerializer.deserialize(json)

      col = hd(params.columns)
      assert is_function(col.renderer, 3)
      assert col.renderer_spec.type == "progress"
      assert col.renderer_spec.options.max == 200
    end

    test "handles min_length and max_length validators" do
      grid = %{sample_grid_map() | columns: [
        %{field: :code, label: "Code", type: :string, width: 100, align: :left,
          sortable: false, filterable: false, editable: true, editor_type: :text,
          editor_options: [], formatter: nil, formatter_options: %{}, validators: [
            {:min_length, 3, "최소 3자"},
            {:max_length, 10, "최대 10자"}
          ], renderer: nil}
      ]}

      {:ok, json} = GridConfigSerializer.serialize(grid)
      data = Jason.decode!(json)

      validators = hd(data["columns"])["validators"]
      assert Enum.at(validators, 0)["type"] == "min_length"
      assert Enum.at(validators, 1)["type"] == "max_length"

      {:ok, params} = GridConfigSerializer.deserialize(json)
      col = hd(params.columns)
      assert {:min_length, 3, "최소 3자"} in col.validators
      assert {:max_length, 10, "최대 10자"} in col.validators
    end
  end
end
