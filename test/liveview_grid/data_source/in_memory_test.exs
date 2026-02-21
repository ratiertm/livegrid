defmodule LiveViewGrid.DataSource.InMemoryTest do
  use ExUnit.Case, async: true

  alias LiveViewGrid.DataSource.InMemory

  @sample_data [
    %{id: 1, name: "Alice", age: 30, city: "서울"},
    %{id: 2, name: "Bob", age: 25, city: "부산"},
    %{id: 3, name: "Charlie", age: 35, city: "대구"},
    %{id: 4, name: "Diana", age: 28, city: "서울"},
    %{id: 5, name: "Eve", age: 22, city: "인천"}
  ]

  @columns [
    %{field: :id, filter_type: :number},
    %{field: :name, filter_type: :text},
    %{field: :age, filter_type: :number},
    %{field: :city, filter_type: :text}
  ]

  @default_state %{
    global_search: "",
    filters: %{},
    advanced_filters: %{logic: :and, conditions: []},
    sort: nil,
    pagination: %{current_page: 1, total_rows: 5},
    scroll_offset: 0
  }

  @default_options %{
    page_size: 20,
    virtual_scroll: false,
    row_height: 40,
    virtual_buffer: 5
  }

  defp config, do: %{data: @sample_data}

  describe "fetch_data/4" do
    test "returns all data with default state" do
      {rows, total, filtered} = InMemory.fetch_data(config(), @default_state, @default_options, @columns)

      assert length(rows) == 5
      assert total == 5
      assert filtered == 5
    end

    test "applies global search" do
      state = %{@default_state | global_search: "ali"}
      {rows, total, filtered} = InMemory.fetch_data(config(), state, @default_options, @columns)

      assert length(rows) == 1
      assert total == 5
      assert filtered == 1
      assert hd(rows).name == "Alice"
    end

    test "applies column filter (text)" do
      state = %{@default_state | filters: %{city: "서울"}}
      {rows, total, filtered} = InMemory.fetch_data(config(), state, @default_options, @columns)

      assert length(rows) == 2
      assert total == 5
      assert filtered == 2
    end

    test "applies sort" do
      state = %{@default_state | sort: %{field: :age, direction: :asc}}
      {rows, _total, _filtered} = InMemory.fetch_data(config(), state, @default_options, @columns)

      ages = Enum.map(rows, & &1.age)
      assert ages == [22, 25, 28, 30, 35]
    end

    test "applies sort descending" do
      state = %{@default_state | sort: %{field: :name, direction: :desc}}
      {rows, _total, _filtered} = InMemory.fetch_data(config(), state, @default_options, @columns)

      names = Enum.map(rows, & &1.name)
      assert names == ["Eve", "Diana", "Charlie", "Bob", "Alice"]
    end

    test "applies pagination" do
      options = %{@default_options | page_size: 2}
      {rows, total, filtered} = InMemory.fetch_data(config(), @default_state, options, @columns)

      assert length(rows) == 2
      assert total == 5
      assert filtered == 5
    end

    test "applies pagination page 2" do
      options = %{@default_options | page_size: 2}
      state = put_in(@default_state.pagination.current_page, 2)
      {rows, _total, _filtered} = InMemory.fetch_data(config(), state, options, @columns)

      assert length(rows) == 2
      assert hd(rows).id == 3
    end

    test "combined filter + sort + pagination" do
      state = %{@default_state |
        filters: %{city: "서울"},
        sort: %{field: :age, direction: :desc}
      }
      options = %{@default_options | page_size: 1}

      {rows, total, filtered} = InMemory.fetch_data(config(), state, options, @columns)

      assert length(rows) == 1
      assert total == 5
      assert filtered == 2
      assert hd(rows).name == "Alice"  # age 30, 서울 - highest age in 서울
    end
  end

  describe "CRUD callbacks" do
    test "insert_row returns ok" do
      assert {:ok, _} = InMemory.insert_row(config(), %{id: 6, name: "Frank"})
    end

    test "update_row returns ok" do
      assert {:ok, _} = InMemory.update_row(config(), 1, %{name: "Updated"})
    end

    test "delete_row returns ok" do
      assert :ok = InMemory.delete_row(config(), 1)
    end
  end
end
