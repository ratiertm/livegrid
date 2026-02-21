defmodule LiveViewGrid.DataSource.Ecto.QueryBuilderTest do
  use ExUnit.Case

  alias LiveviewGrid.{Repo, DemoUser}
  alias LiveViewGrid.DataSource.Ecto.QueryBuilder

  import Ecto.Query

  @columns [
    %{field: :name, filter_type: :text},
    %{field: :age, filter_type: :number},
    %{field: :department, filter_type: :text},
    %{field: :salary, filter_type: :number}
  ]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    seed_data()
    :ok
  end

  defp seed_data do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Repo.insert_all(DemoUser, [
      %{name: "Alice Kim", email: "alice@test.com", department: "개발", age: 30, salary: 50_000_000, status: "재직", join_date: "2020-01-15", inserted_at: now, updated_at: now},
      %{name: "Bob Lee", email: "bob@test.com", department: "디자인", age: 25, salary: 40_000_000, status: "재직", join_date: "2021-06-01", inserted_at: now, updated_at: now},
      %{name: "Charlie Park", email: "charlie@test.com", department: "개발", age: 35, salary: 60_000_000, status: "휴직", join_date: "2019-03-20", inserted_at: now, updated_at: now}
    ])
  end

  defp base_query, do: from(_ in DemoUser)

  describe "apply_global_search/3" do
    test "empty search returns all" do
      result = base_query() |> QueryBuilder.apply_global_search("", @columns) |> Repo.all()
      assert length(result) == 3
    end

    test "nil search returns all" do
      result = base_query() |> QueryBuilder.apply_global_search(nil, @columns) |> Repo.all()
      assert length(result) == 3
    end

    test "searches across all columns" do
      result = base_query() |> QueryBuilder.apply_global_search("alice", @columns) |> Repo.all()
      assert length(result) == 1
      assert hd(result).name == "Alice Kim"
    end

    test "searches case-insensitively" do
      result = base_query() |> QueryBuilder.apply_global_search("ALICE", @columns) |> Repo.all()
      # SQLite LIKE is case-insensitive for ASCII
      assert length(result) == 1
    end
  end

  describe "apply_filters/3" do
    test "text filter with contains" do
      result =
        base_query()
        |> QueryBuilder.apply_filters(%{department: "개발"}, @columns)
        |> Repo.all()

      assert length(result) == 2
      assert Enum.all?(result, &(&1.department == "개발"))
    end

    test "number filter with >" do
      result =
        base_query()
        |> QueryBuilder.apply_filters(%{age: ">28"}, @columns)
        |> Repo.all()

      assert length(result) == 2
      assert Enum.all?(result, &(&1.age > 28))
    end

    test "number filter with <=" do
      result =
        base_query()
        |> QueryBuilder.apply_filters(%{age: "<=30"}, @columns)
        |> Repo.all()

      assert length(result) == 2
      assert Enum.all?(result, &(&1.age <= 30))
    end

    test "number filter with exact value" do
      result =
        base_query()
        |> QueryBuilder.apply_filters(%{age: "30"}, @columns)
        |> Repo.all()

      assert length(result) == 1
      assert hd(result).age == 30
    end

    test "empty filter returns all" do
      result =
        base_query()
        |> QueryBuilder.apply_filters(%{name: ""}, @columns)
        |> Repo.all()

      assert length(result) == 3
    end
  end

  describe "apply_advanced_filters/2" do
    test "AND conditions" do
      conditions = %{
        logic: :and,
        conditions: [
          %{field: :department, operator: "equals", value: "개발"},
          %{field: :age, operator: "gt", value: "30"}
        ]
      }

      result = base_query() |> QueryBuilder.apply_advanced_filters(conditions) |> Repo.all()

      assert length(result) == 1
      assert hd(result).name == "Charlie Park"
    end

    test "OR conditions" do
      conditions = %{
        logic: :or,
        conditions: [
          %{field: :department, operator: "equals", value: "개발"},
          %{field: :department, operator: "equals", value: "디자인"}
        ]
      }

      result = base_query() |> QueryBuilder.apply_advanced_filters(conditions) |> Repo.all()

      assert length(result) == 3
    end

    test "contains operator" do
      conditions = %{
        logic: :and,
        conditions: [
          %{field: :name, operator: "contains", value: "Kim"}
        ]
      }

      result = base_query() |> QueryBuilder.apply_advanced_filters(conditions) |> Repo.all()
      assert length(result) == 1
    end

    test "starts_with operator" do
      conditions = %{
        logic: :and,
        conditions: [
          %{field: :name, operator: "starts_with", value: "Bob"}
        ]
      }

      result = base_query() |> QueryBuilder.apply_advanced_filters(conditions) |> Repo.all()
      assert length(result) == 1
    end

    test "empty conditions returns all" do
      result =
        base_query()
        |> QueryBuilder.apply_advanced_filters(%{logic: :and, conditions: []})
        |> Repo.all()

      assert length(result) == 3
    end
  end

  describe "apply_sort/2" do
    test "sort ascending" do
      result =
        base_query()
        |> QueryBuilder.apply_sort(%{field: :age, direction: :asc})
        |> Repo.all()

      ages = Enum.map(result, & &1.age)
      assert ages == [25, 30, 35]
    end

    test "sort descending" do
      result =
        base_query()
        |> QueryBuilder.apply_sort(%{field: :salary, direction: :desc})
        |> Repo.all()

      salaries = Enum.map(result, & &1.salary)
      assert salaries == [60_000_000, 50_000_000, 40_000_000]
    end

    test "nil sort returns original order" do
      result = base_query() |> QueryBuilder.apply_sort(nil) |> Repo.all()
      assert length(result) == 3
    end
  end

  describe "apply_pagination/3" do
    test "first page" do
      result =
        base_query()
        |> QueryBuilder.apply_pagination(%{current_page: 1}, 2)
        |> Repo.all()

      assert length(result) == 2
    end

    test "second page" do
      result =
        base_query()
        |> QueryBuilder.apply_pagination(%{current_page: 2}, 2)
        |> Repo.all()

      assert length(result) == 1
    end

    test "empty page" do
      result =
        base_query()
        |> QueryBuilder.apply_pagination(%{current_page: 10}, 2)
        |> Repo.all()

      assert length(result) == 0
    end
  end
end
