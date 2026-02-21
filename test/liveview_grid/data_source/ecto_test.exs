defmodule LiveViewGrid.DataSource.EctoTest do
  use ExUnit.Case

  alias LiveviewGrid.{Repo, DemoUser}
  alias LiveViewGrid.DataSource.Ecto, as: EctoAdapter

  @columns [
    %{field: :id, filter_type: :number},
    %{field: :name, filter_type: :text},
    %{field: :email, filter_type: :text},
    %{field: :department, filter_type: :text},
    %{field: :age, filter_type: :number},
    %{field: :salary, filter_type: :number},
    %{field: :status, filter_type: :text}
  ]

  @default_state %{
    global_search: "",
    filters: %{},
    advanced_filters: %{logic: :and, conditions: []},
    sort: nil,
    pagination: %{current_page: 1, total_rows: 0},
    scroll_offset: 0
  }

  @default_options %{
    page_size: 20,
    virtual_scroll: false,
    row_height: 40,
    virtual_buffer: 5
  }

  @config %{repo: Repo, schema: DemoUser}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    seed_test_data()
    :ok
  end

  defp seed_test_data do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    users = [
      %{name: "김민수", email: "kim@test.com", department: "개발", age: 30, salary: 50_000_000, status: "재직", join_date: "2020-01-15", inserted_at: now, updated_at: now},
      %{name: "이영희", email: "lee@test.com", department: "디자인", age: 28, salary: 45_000_000, status: "재직", join_date: "2021-03-20", inserted_at: now, updated_at: now},
      %{name: "박철수", email: "park@test.com", department: "개발", age: 35, salary: 60_000_000, status: "재직", join_date: "2019-07-10", inserted_at: now, updated_at: now},
      %{name: "정미영", email: "jung@test.com", department: "마케팅", age: 32, salary: 48_000_000, status: "휴직", join_date: "2020-09-01", inserted_at: now, updated_at: now},
      %{name: "최준호", email: "choi@test.com", department: "개발", age: 25, salary: 40_000_000, status: "재직", join_date: "2022-06-15", inserted_at: now, updated_at: now},
      %{name: "강서연", email: "kang@test.com", department: "디자인", age: 27, salary: 43_000_000, status: "재직", join_date: "2021-11-01", inserted_at: now, updated_at: now},
      %{name: "조현우", email: "jo@test.com", department: "영업", age: 40, salary: 55_000_000, status: "재직", join_date: "2018-02-28", inserted_at: now, updated_at: now},
      %{name: "윤하나", email: "yoon@test.com", department: "인사", age: 33, salary: 47_000_000, status: "퇴직", join_date: "2019-04-15", inserted_at: now, updated_at: now},
      %{name: "임동현", email: "lim@test.com", department: "개발", age: 29, salary: 52_000_000, status: "재직", join_date: "2020-08-01", inserted_at: now, updated_at: now},
      %{name: "한지은", email: "han@test.com", department: "기획", age: 31, salary: 46_000_000, status: "재직", join_date: "2021-01-10", inserted_at: now, updated_at: now}
    ]

    Repo.insert_all(DemoUser, users)
  end

  describe "fetch_data/4" do
    test "returns all rows with default state" do
      {rows, total, filtered} = EctoAdapter.fetch_data(@config, @default_state, @default_options, @columns)

      assert total == 10
      assert filtered == 10
      assert length(rows) == 10
    end

    test "returns rows as maps with expected fields" do
      {[row | _], _, _} = EctoAdapter.fetch_data(@config, @default_state, @default_options, @columns)

      assert is_map(row)
      assert Map.has_key?(row, :id)
      assert Map.has_key?(row, :name)
      assert Map.has_key?(row, :email)
      assert Map.has_key?(row, :department)
      refute Map.has_key?(row, :__meta__)
    end

    test "applies global search" do
      state = %{@default_state | global_search: "kim"}
      {rows, total, filtered} = EctoAdapter.fetch_data(@config, state, @default_options, @columns)

      assert total == 10
      assert filtered == 1
      assert length(rows) == 1
      assert hd(rows).email == "kim@test.com"
    end

    test "applies column filter (text)" do
      state = %{@default_state | filters: %{department: "개발"}}
      {rows, total, filtered} = EctoAdapter.fetch_data(@config, state, @default_options, @columns)

      assert total == 10
      assert filtered == 4
      assert length(rows) == 4
      assert Enum.all?(rows, &(&1.department == "개발"))
    end

    test "applies column filter (number)" do
      state = %{@default_state | filters: %{age: ">30"}}
      {rows, total, filtered} = EctoAdapter.fetch_data(@config, state, @default_options, @columns)

      assert total == 10
      assert filtered > 0
      assert Enum.all?(rows, &(&1.age > 30))
    end

    test "applies sort ascending" do
      state = %{@default_state | sort: %{field: :age, direction: :asc}}
      {rows, _, _} = EctoAdapter.fetch_data(@config, state, @default_options, @columns)

      ages = Enum.map(rows, & &1.age)
      assert ages == Enum.sort(ages)
    end

    test "applies sort descending" do
      state = %{@default_state | sort: %{field: :salary, direction: :desc}}
      {rows, _, _} = EctoAdapter.fetch_data(@config, state, @default_options, @columns)

      salaries = Enum.map(rows, & &1.salary)
      assert salaries == Enum.sort(salaries, :desc)
    end

    test "applies pagination" do
      options = %{@default_options | page_size: 3}
      {rows, total, filtered} = EctoAdapter.fetch_data(@config, @default_state, options, @columns)

      assert total == 10
      assert filtered == 10
      assert length(rows) == 3
    end

    test "applies pagination page 2" do
      options = %{@default_options | page_size: 3}
      state = put_in(@default_state.pagination.current_page, 2)
      {rows, _, _} = EctoAdapter.fetch_data(@config, state, options, @columns)

      assert length(rows) == 3
    end

    test "combined: filter + sort + pagination" do
      state = %{@default_state |
        filters: %{department: "개발"},
        sort: %{field: :age, direction: :asc}
      }
      options = %{@default_options | page_size: 2}

      {rows, total, filtered} = EctoAdapter.fetch_data(@config, state, options, @columns)

      assert total == 10
      assert filtered == 4
      assert length(rows) == 2
      # Should be sorted by age ascending
      assert Enum.at(rows, 0).age <= Enum.at(rows, 1).age
    end

    test "advanced filter with AND logic" do
      state = %{@default_state |
        advanced_filters: %{
          logic: :and,
          conditions: [
            %{field: :department, operator: "equals", value: "개발"},
            %{field: :age, operator: "gt", value: "28"}
          ]
        }
      }

      {rows, total, filtered} = EctoAdapter.fetch_data(@config, state, @default_options, @columns)

      assert total == 10
      assert filtered > 0
      assert Enum.all?(rows, fn r -> r.department == "개발" and r.age > 28 end)
    end

    test "advanced filter with OR logic" do
      state = %{@default_state |
        advanced_filters: %{
          logic: :or,
          conditions: [
            %{field: :status, operator: "equals", value: "휴직"},
            %{field: :status, operator: "equals", value: "퇴직"}
          ]
        }
      }

      {rows, total, filtered} = EctoAdapter.fetch_data(@config, state, @default_options, @columns)

      assert total == 10
      assert filtered == 2
      assert Enum.all?(rows, fn r -> r.status in ["휴직", "퇴직"] end)
    end
  end

  describe "insert_row/2" do
    test "inserts a new row" do
      attrs = %{name: "신규사원", email: "new@test.com", department: "개발", age: 24, salary: 35_000_000, status: "재직"}

      assert {:ok, row} = EctoAdapter.insert_row(@config, attrs)
      assert row.name == "신규사원"
      assert row.email == "new@test.com"
      assert is_integer(row.id)
    end
  end

  describe "update_row/3" do
    test "updates an existing row" do
      {[row | _], _, _} = EctoAdapter.fetch_data(@config, @default_state, @default_options, @columns)

      assert {:ok, updated} = EctoAdapter.update_row(@config, row.id, %{name: "수정됨"})
      assert updated.name == "수정됨"
    end

    test "returns error for non-existent row" do
      assert {:error, :not_found} = EctoAdapter.update_row(@config, 999_999, %{name: "없음"})
    end
  end

  describe "delete_row/2" do
    test "deletes an existing row" do
      {[row | _], _, _} = EctoAdapter.fetch_data(@config, @default_state, @default_options, @columns)

      assert :ok = EctoAdapter.delete_row(@config, row.id)

      # Verify deleted
      {_, total, _} = EctoAdapter.fetch_data(@config, @default_state, @default_options, @columns)
      assert total == 9
    end

    test "returns error for non-existent row" do
      assert {:error, :not_found} = EctoAdapter.delete_row(@config, 999_999)
    end
  end
end
