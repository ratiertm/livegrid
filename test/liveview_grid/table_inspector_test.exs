defmodule LiveViewGrid.TableInspectorTest do
  use ExUnit.Case

  alias LiveViewGrid.TableInspector

  @repo LiveviewGrid.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(@repo)
    :ok
  end

  describe "list_tables/1" do
    test "returns {:ok, tables} with user tables" do
      {:ok, tables} = TableInspector.list_tables(@repo)
      assert is_list(tables)
      assert "demo_users" in tables
    end

    test "excludes schema_migrations table" do
      {:ok, tables} = TableInspector.list_tables(@repo)
      refute "schema_migrations" in tables
    end

    test "excludes sqlite_ prefixed tables" do
      {:ok, tables} = TableInspector.list_tables(@repo)

      for table <- tables do
        refute String.starts_with?(table, "sqlite_")
      end
    end

    test "tables are sorted alphabetically" do
      {:ok, tables} = TableInspector.list_tables(@repo)
      assert tables == Enum.sort(tables)
    end
  end

  describe "table_columns/2" do
    test "returns column info for existing table" do
      {:ok, columns} = TableInspector.table_columns(@repo, "demo_users")
      assert is_list(columns)
      assert length(columns) > 0
    end

    test "each column has required metadata" do
      {:ok, columns} = TableInspector.table_columns(@repo, "demo_users")

      for col <- columns do
        assert Map.has_key?(col, :name)
        assert Map.has_key?(col, :type)
        assert Map.has_key?(col, :pk)
        assert Map.has_key?(col, :nullable)
        assert Map.has_key?(col, :sqlite_type)
        assert is_binary(col.name)
        assert is_atom(col.type)
        assert is_boolean(col.pk)
      end
    end

    test "identifies primary key column" do
      {:ok, columns} = TableInspector.table_columns(@repo, "demo_users")
      pk_cols = Enum.filter(columns, & &1.pk)
      assert length(pk_cols) >= 1
    end

    test "returns error for invalid table name" do
      assert {:error, :invalid_table_name} = TableInspector.table_columns(@repo, "DROP TABLE;")
    end

    test "returns error for non-existent table" do
      assert {:error, :table_not_found} = TableInspector.table_columns(@repo, "nonexistent_table_xyz")
    end
  end

  describe "table_to_grid_columns/2" do
    test "returns grid-compatible column definitions" do
      {:ok, grid_cols} = TableInspector.table_to_grid_columns(@repo, "demo_users")
      assert is_list(grid_cols)
      assert length(grid_cols) > 0

      for col <- grid_cols do
        assert Map.has_key?(col, :field)
        assert Map.has_key?(col, :label)
        assert Map.has_key?(col, :type)
        assert Map.has_key?(col, :sortable)
        assert Map.has_key?(col, :editable)
        assert Map.has_key?(col, :editor_type)
      end
    end

    test "primary key columns are not editable" do
      {:ok, grid_cols} = TableInspector.table_to_grid_columns(@repo, "demo_users")
      # id is typically the first column and pk
      id_col = Enum.find(grid_cols, &(&1.field == "id"))

      if id_col do
        assert id_col.editable == false
      end
    end
  end
end
