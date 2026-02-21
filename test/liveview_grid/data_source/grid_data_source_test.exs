defmodule LiveViewGrid.GridDataSourceTest do
  use ExUnit.Case

  alias LiveviewGrid.{Repo, DemoUser}
  alias LiveViewGrid.Grid

  @columns [
    %{field: :id, label: "ID"},
    %{field: :name, label: "이름", sortable: true, filterable: true, filter_type: :text},
    %{field: :age, label: "나이", sortable: true, filterable: true, filter_type: :number}
  ]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    now = DateTime.utc_now() |> DateTime.truncate(:second)
    Repo.insert_all(DemoUser, [
      %{name: "김민수", email: "kim@test.com", department: "개발", age: 30, salary: 50_000_000, status: "재직", join_date: "2020-01-15", inserted_at: now, updated_at: now},
      %{name: "이영희", email: "lee@test.com", department: "디자인", age: 28, salary: 45_000_000, status: "재직", join_date: "2021-03-20", inserted_at: now, updated_at: now},
      %{name: "박철수", email: "park@test.com", department: "개발", age: 35, salary: 60_000_000, status: "재직", join_date: "2019-07-10", inserted_at: now, updated_at: now}
    ])

    :ok
  end

  describe "Grid.new with data_source" do
    test "creates grid with Ecto data source" do
      grid = Grid.new(
        columns: @columns,
        data_source: {LiveViewGrid.DataSource.Ecto, %{repo: Repo, schema: DemoUser}}
      )

      assert grid.data_source == {LiveViewGrid.DataSource.Ecto, %{repo: Repo, schema: DemoUser}}
      assert grid.state.pagination.total_rows == 3
    end

    test "visible_data delegates to Ecto adapter" do
      grid = Grid.new(
        columns: @columns,
        data_source: {LiveViewGrid.DataSource.Ecto, %{repo: Repo, schema: DemoUser}}
      )

      rows = Grid.visible_data(grid)
      assert length(rows) == 3
      assert is_map(hd(rows))
      assert Map.has_key?(hd(rows), :name)
    end

    test "filtered_count delegates to Ecto adapter" do
      grid = Grid.new(
        columns: @columns,
        data_source: {LiveViewGrid.DataSource.Ecto, %{repo: Repo, schema: DemoUser}}
      )

      assert Grid.filtered_count(grid) == 3
    end

    test "filtered_count with filter" do
      grid = Grid.new(
        columns: @columns,
        data_source: {LiveViewGrid.DataSource.Ecto, %{repo: Repo, schema: DemoUser}}
      )

      # Apply a filter
      grid = put_in(grid.state.filters, %{name: "김"})
      assert Grid.filtered_count(grid) == 1
    end
  end

  describe "backward compatibility" do
    test "Grid.new without data_source still works (InMemory)" do
      data = [%{id: 1, name: "Test", age: 25}]

      grid = Grid.new(data: data, columns: @columns)

      assert grid.data_source == nil
      assert grid.data == data
      assert Grid.visible_data(grid) == data
    end

    test "Grid.new with empty data works" do
      grid = Grid.new(data: [], columns: @columns)

      assert grid.data == []
      assert Grid.visible_data(grid) == []
    end
  end
end
