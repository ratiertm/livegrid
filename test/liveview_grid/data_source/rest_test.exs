defmodule LiveViewGrid.DataSource.RestTest do
  use ExUnit.Case, async: false

  alias LiveViewGrid.DataSource.Rest

  # ── Unit tests for internal helper logic ──

  describe "fetch_data/4" do
    test "returns empty tuple on connection error" do
      config = %{
        base_url: "http://localhost:99999",
        endpoint: "/nonexistent",
        request_opts: %{timeout: 500, retry: 0, retry_delay: 100}
      }

      state = %{
        pagination: %{current_page: 1},
        sort: %{field: nil, direction: :asc},
        global_search: nil,
        filters: %{}
      }

      {rows, total, filtered} = Rest.fetch_data(config, state, %{page_size: 20}, [])
      assert rows == []
      assert total == 0
      assert filtered == 0
    end
  end

  describe "insert_row/2" do
    test "returns error on connection failure" do
      config = %{
        base_url: "http://localhost:99999",
        endpoint: "/nonexistent",
        request_opts: %{timeout: 500, retry: 0, retry_delay: 100}
      }

      assert {:error, _reason} = Rest.insert_row(config, %{name: "Test"})
    end
  end

  describe "update_row/3" do
    test "returns error on connection failure" do
      config = %{
        base_url: "http://localhost:99999",
        endpoint: "/nonexistent",
        request_opts: %{timeout: 500, retry: 0, retry_delay: 100}
      }

      assert {:error, _reason} = Rest.update_row(config, 1, %{name: "Updated"})
    end
  end

  describe "delete_row/2" do
    test "returns error on connection failure" do
      config = %{
        base_url: "http://localhost:99999",
        endpoint: "/nonexistent",
        request_opts: %{timeout: 500, retry: 0, retry_delay: 100}
      }

      assert {:error, _reason} = Rest.delete_row(config, 1)
    end
  end
end
