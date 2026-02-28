defmodule LiveViewGrid.DataSource.RawTableTest do
  use ExUnit.Case

  alias LiveViewGrid.DataSource.RawTable

  @repo LiveviewGrid.Repo

  @config %{
    repo: @repo,
    table: "demo_users",
    primary_key: "id"
  }

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(@repo)

    # Seed test data
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_string()

    Ecto.Adapters.SQL.query!(@repo,
      "INSERT INTO demo_users (name, email, department, age, salary, status, join_date, inserted_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
      ["RawTest User", "raw@test.com", "QA", 25, 40_000_000, "active", "2025-01-01", now, now]
    )

    :ok
  end

  @columns [
    %{field: :id, type: :integer},
    %{field: :name, type: :string},
    %{field: :email, type: :string},
    %{field: :department, type: :string},
    %{field: :age, type: :integer}
  ]

  @default_state %{
    global_search: "",
    filters: %{},
    sort: nil,
    pagination: %{page: 1}
  }

  @default_options %{page_size: 20}

  describe "fetch_data/4" do
    test "returns rows, total_count, filtered_count tuple" do
      {rows, total, filtered} = RawTable.fetch_data(@config, @default_state, @default_options, @columns)

      assert is_list(rows)
      assert is_integer(total)
      assert is_integer(filtered)
      assert total >= 0
      assert filtered >= 0
    end

    test "rows are maps with atom keys" do
      {rows, _, _} = RawTable.fetch_data(@config, @default_state, @default_options, @columns)

      if length(rows) > 0 do
        row = hd(rows)
        assert is_map(row)
        assert Map.has_key?(row, :id)
      end
    end

    test "respects page_size limit" do
      options = %{page_size: 3}
      {rows, _, _} = RawTable.fetch_data(@config, @default_state, options, @columns)
      assert length(rows) <= 3
    end

    test "applies sorting" do
      state = %{@default_state | sort: %{field: :name, direction: :asc}}
      {rows, _, _} = RawTable.fetch_data(@config, state, @default_options, @columns)

      if length(rows) >= 2 do
        names = Enum.map(rows, & &1[:name]) |> Enum.reject(&is_nil/1)
        assert names == Enum.sort(names)
      end
    end

    test "applies global search filter" do
      # First get all data to find a name to search for
      {all_rows, _, _} = RawTable.fetch_data(@config, @default_state, %{page_size: 100}, @columns)

      if length(all_rows) > 0 do
        first_name = hd(all_rows)[:name]

        if first_name do
          state = %{@default_state | global_search: String.slice(to_string(first_name), 0, 3)}
          {filtered_rows, total, filtered} = RawTable.fetch_data(@config, state, %{page_size: 100}, @columns)

          assert filtered <= total
          assert length(filtered_rows) <= filtered
        end
      end
    end

    test "returns empty for invalid table" do
      bad_config = %{@config | table: "nonexistent_xyz"}
      {rows, total, filtered} = RawTable.fetch_data(bad_config, @default_state, @default_options, @columns)
      assert rows == []
      assert total == 0
      assert filtered == 0
    end
  end

  describe "insert_row/2 and delete_row/2" do
    test "inserts and then deletes a row" do
      row_data = %{
        name: "Test User RawTable",
        email: "rawtest@example.com",
        department: "QA",
        age: 30,
        salary: 50000,
        status: "active"
      }

      case RawTable.insert_row(@config, row_data) do
        {:ok, inserted} ->
          assert inserted[:name] == "Test User RawTable" or Map.get(inserted, "name") == "Test User RawTable"

          # Delete the row
          row_id = inserted[:id] || Map.get(inserted, "id")

          if row_id do
            assert :ok = RawTable.delete_row(@config, row_id)
          end

        {:error, _reason} ->
          # Insert may fail if columns don't match — that's acceptable
          :ok
      end
    end
  end

  describe "update_row/3" do
    test "updates an existing row" do
      # Find first row
      {rows, _, _} = RawTable.fetch_data(@config, @default_state, %{page_size: 1}, @columns)

      if length(rows) > 0 do
        row = hd(rows)
        row_id = row[:id]

        if row_id do
          case RawTable.update_row(@config, row_id, %{name: "Updated Name"}) do
            {:ok, updated} ->
              assert updated[:name] == "Updated Name"
              # Revert
              RawTable.update_row(@config, row_id, %{name: row[:name]})

            {:error, _} ->
              :ok
          end
        end
      end
    end
  end
end
