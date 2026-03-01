defmodule LiveViewGrid.StatePersistenceTest do
  use ExUnit.Case, async: true

  alias LiveViewGrid.{Grid, StatePersistence}

  @test_columns [
    %{field: :id, label: "ID", sortable: true},
    %{field: :name, label: "Name", sortable: true, filterable: true},
    %{field: :email, label: "Email"},
    %{field: :age, label: "Age", sortable: true}
  ]

  @test_data [
    %{id: 1, name: "Alice", email: "alice@test.com", age: 30},
    %{id: 2, name: "Bob", email: "bob@test.com", age: 25}
  ]

  describe "persistable_keys/0" do
    test "returns a list of known persistable keys" do
      keys = StatePersistence.persistable_keys()
      assert is_list(keys)
      assert :sort in keys
      assert :filters in keys
      assert :column_widths in keys
      assert :hidden_columns in keys
      assert :pagination in keys
    end
  end

  describe "export_state/1" do
    test "exports default state" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
      state = StatePersistence.export_state(grid)

      assert is_map(state)
      assert Map.has_key?(state, "sort")
      assert Map.has_key?(state, "filters")
      assert Map.has_key?(state, "column_widths")
    end

    test "exports sort state" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
      grid = put_in(grid.state.sort, %{field: :name, direction: :asc})

      state = StatePersistence.export_state(grid)
      assert state["sort"] == %{"field" => "name", "direction" => "asc"}
    end

    test "exports column widths" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
             |> Grid.resize_column(:name, 200)

      state = StatePersistence.export_state(grid)
      assert state["column_widths"] == %{"name" => 200}
    end

    test "exports hidden columns" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
      grid = put_in(grid.state[:hidden_columns], [:email])

      state = StatePersistence.export_state(grid)
      assert state["hidden_columns"] == ["email"]
    end

    test "does not export transient state" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
      state = StatePersistence.export_state(grid)

      refute Map.has_key?(state, "editing")
      refute Map.has_key?(state, "editing_row")
      refute Map.has_key?(state, "cell_range")
      refute Map.has_key?(state, "overlay")
      refute Map.has_key?(state, "scroll_offset")
    end
  end

  describe "import_state/2" do
    test "imports sort state" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
      state_map = %{"sort" => %{"field" => "name", "direction" => "desc"}}

      restored = StatePersistence.import_state(grid, state_map)
      assert restored.state.sort == %{field: :name, direction: :desc}
    end

    test "imports column widths" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
      state_map = %{"column_widths" => %{"name" => 250, "email" => 180}}

      restored = StatePersistence.import_state(grid, state_map)
      assert restored.state.column_widths == %{name: 250, email: 180}
    end

    test "filters invalid columns on import" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
      state_map = %{
        "column_widths" => %{"name" => 200, "nonexistent" => 100},
        "hidden_columns" => ["age", "invalid"]
      }

      restored = StatePersistence.import_state(grid, state_map)
      assert restored.state.column_widths == %{name: 200}
      assert restored.state.hidden_columns == [:age]
    end

    test "preserves non-persistable state" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
      grid = put_in(grid.state[:editing], %{row_id: 1, field: :name})

      state_map = %{"sort" => %{"field" => "name", "direction" => "asc"}}
      restored = StatePersistence.import_state(grid, state_map)

      # 기존 editing 상태 유지
      assert restored.state.editing == %{row_id: 1, field: :name}
    end
  end

  describe "serialize/1 and deserialize/1" do
    test "round-trip serialization" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
             |> Grid.resize_column(:name, 200)
      grid = put_in(grid.state.sort, %{field: :name, direction: :asc})

      exported = StatePersistence.export_state(grid)
      {:ok, json} = StatePersistence.serialize(exported)
      assert is_binary(json)

      {:ok, deserialized} = StatePersistence.deserialize(json)
      assert deserialized["sort"] == %{"field" => "name", "direction" => "asc"}
      assert deserialized["column_widths"] == %{"name" => 200}
    end

    test "deserialize returns error for invalid JSON" do
      assert {:error, _} = StatePersistence.deserialize("invalid json")
    end
  end

  describe "Grid.save_state/1 and Grid.restore_state/2" do
    test "save and restore round-trip" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
             |> Grid.resize_column(:name, 180)
      grid = put_in(grid.state.sort, %{field: :age, direction: :desc})
      grid = put_in(grid.state[:hidden_columns], [:email])

      saved = Grid.save_state(grid)

      fresh = Grid.new(data: @test_data, columns: @test_columns)
      restored = Grid.restore_state(fresh, saved)

      assert restored.state.sort == %{field: :age, direction: :desc}
      assert restored.state.column_widths == %{name: 180}
      assert restored.state.hidden_columns == [:email]
    end

    test "restore preserves pagination total_rows" do
      grid = Grid.new(data: @test_data, columns: @test_columns)
      saved = %{"pagination" => %{"current_page" => 3, "total_rows" => 100}}

      restored = Grid.restore_state(grid, saved)
      assert restored.state.pagination.current_page == 3
      assert restored.state.pagination.total_rows == 100
    end
  end
end
