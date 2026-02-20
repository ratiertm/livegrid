defmodule LiveViewGrid.BenchmarkTest do
  @moduledoc """
  성능 벤치마크 테스트

  v0.1 기준: 각 작업 200ms 미만
  """
  use ExUnit.Case, async: true

  alias LiveViewGrid.Grid

  @tag :benchmark
  describe "performance benchmarks" do
    test "Grid.new with 1,000 rows < 200ms" do
      data = generate_data(1_000)
      columns = sample_columns()

      {time_us, grid} = :timer.tc(fn ->
        Grid.new(data: data, columns: columns)
      end)

      time_ms = time_us / 1_000
      assert grid.data |> length() == 1_000
      assert time_ms < 200, "Grid.new(1000행): #{time_ms}ms (기준: 200ms)"
    end

    test "visible_data with 10,000 rows pagination < 200ms" do
      data = generate_data(10_000)
      columns = sample_columns()

      grid = Grid.new(data: data, columns: columns, options: %{page_size: 20})

      {time_us, visible} = :timer.tc(fn ->
        Grid.visible_data(grid)
      end)

      time_ms = time_us / 1_000
      assert length(visible) == 20
      assert time_ms < 200, "visible_data(10000행, 페이징): #{time_ms}ms (기준: 200ms)"
    end

    test "visible_data with 10,000 rows virtual scroll < 200ms" do
      data = generate_data(10_000)
      columns = sample_columns()

      grid = Grid.new(
        data: data,
        columns: columns,
        options: %{virtual_scroll: true, row_height: 40, virtual_buffer: 5}
      )

      grid = put_in(grid.state.scroll_offset, 5_000)

      {time_us, visible} = :timer.tc(fn ->
        Grid.visible_data(grid)
      end)

      time_ms = time_us / 1_000
      assert length(visible) > 0
      assert time_ms < 200, "visible_data(10000행, 가상스크롤): #{time_ms}ms (기준: 200ms)"
    end

    test "sorting 10,000 rows < 200ms" do
      data = generate_data(10_000)
      columns = sample_columns()

      grid = Grid.new(
        data: data,
        columns: columns,
        options: %{page_size: 20}
      )

      grid = put_in(grid.state.sort, %{field: :name, direction: :asc})

      {time_us, visible} = :timer.tc(fn ->
        Grid.visible_data(grid)
      end)

      time_ms = time_us / 1_000
      assert length(visible) == 20
      assert time_ms < 200, "정렬+페이징(10000행): #{time_ms}ms (기준: 200ms)"
    end

    test "update_data with 10,000 rows < 200ms" do
      data = generate_data(1_000)
      columns = sample_columns()
      grid = Grid.new(data: data, columns: columns)

      new_data = generate_data(10_000)

      {time_us, updated} = :timer.tc(fn ->
        Grid.update_data(grid, new_data, columns, %{})
      end)

      time_ms = time_us / 1_000
      assert length(updated.data) == 10_000
      assert time_ms < 200, "update_data(10000행): #{time_ms}ms (기준: 200ms)"
    end
  end

  # Helper functions

  defp generate_data(count) do
    Enum.map(1..count, fn i ->
      %{
        id: i,
        name: "User #{i}",
        email: "user#{i}@example.com",
        age: rem(i, 60) + 20,
        city: Enum.at(["서울", "부산", "대전", "인천", "대구"], rem(i, 5))
      }
    end)
  end

  defp sample_columns do
    [
      %{field: :id, label: "ID", width: 80, sortable: true},
      %{field: :name, label: "이름", sortable: true},
      %{field: :email, label: "이메일", width: 250, sortable: true},
      %{field: :age, label: "나이", width: 80, sortable: true},
      %{field: :city, label: "도시", width: 120, sortable: true}
    ]
  end
end
