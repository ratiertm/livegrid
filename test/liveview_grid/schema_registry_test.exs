defmodule LiveViewGrid.SchemaRegistryTest do
  use ExUnit.Case

  alias LiveViewGrid.SchemaRegistry

  describe "list_schemas/0" do
    test "returns list of registered schemas" do
      schemas = SchemaRegistry.list_schemas()
      assert is_list(schemas)
    end

    test "each schema has required metadata" do
      schemas = SchemaRegistry.list_schemas()

      for schema <- schemas do
        assert Map.has_key?(schema, :module)
        assert Map.has_key?(schema, :table)
        assert Map.has_key?(schema, :label)
        assert Map.has_key?(schema, :fields)
        assert is_list(schema.fields)
      end
    end

    test "includes DemoUser when configured" do
      schemas = SchemaRegistry.list_schemas()
      modules = Enum.map(schemas, & &1.module)
      assert LiveviewGrid.DemoUser in modules
    end
  end

  describe "schema_info/1" do
    test "returns metadata for a valid Ecto schema" do
      info = SchemaRegistry.schema_info(LiveviewGrid.DemoUser)
      assert info != nil
      assert info.module == LiveviewGrid.DemoUser
      assert is_binary(info.table)
      assert is_binary(info.label)
      assert is_list(info.fields)
    end

    test "returns nil for non-schema module" do
      assert SchemaRegistry.schema_info(String) == nil
    end

    test "field info includes name, type, and ecto_type" do
      info = SchemaRegistry.schema_info(LiveviewGrid.DemoUser)

      for field <- info.fields do
        assert Map.has_key?(field, :name)
        assert Map.has_key?(field, :type)
        assert Map.has_key?(field, :ecto_type)
        assert is_atom(field.name)
        assert is_atom(field.type)
      end
    end
  end

  describe "schema_columns/1" do
    test "returns grid-compatible column definitions" do
      columns = SchemaRegistry.schema_columns(LiveviewGrid.DemoUser)
      assert is_list(columns)
      assert length(columns) > 0
    end

    test "each column has required grid fields" do
      columns = SchemaRegistry.schema_columns(LiveviewGrid.DemoUser)

      for col <- columns do
        assert Map.has_key?(col, :field)
        assert Map.has_key?(col, :label)
        assert Map.has_key?(col, :type)
        assert Map.has_key?(col, :sortable)
        assert Map.has_key?(col, :filterable)
        assert Map.has_key?(col, :editable)
        assert Map.has_key?(col, :editor_type)
        assert is_binary(col.field)
        assert is_binary(col.label)
      end
    end

    test "id column is not editable" do
      columns = SchemaRegistry.schema_columns(LiveviewGrid.DemoUser)
      id_col = Enum.find(columns, &(&1.field == "id"))
      assert id_col != nil
      assert id_col.editable == false
    end

    test "returns empty list for non-schema module" do
      assert SchemaRegistry.schema_columns(String) == []
    end
  end
end
