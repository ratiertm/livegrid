defmodule LiveViewGrid.GridTest do
  use ExUnit.Case, async: true

  alias LiveViewGrid.Grid

  describe "new/1" do
    test "creates grid with required data and columns" do
      data = [%{id: 1, name: "Alice"}]
      columns = [%{field: :name, label: "이름"}]

      grid = Grid.new(data: data, columns: columns)

      assert grid.id != nil
      assert grid.data == data
      assert length(grid.columns) == 1
    end

    test "applies default options" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}])

      assert grid.options.page_size == 20
      assert grid.options.show_header == true
      assert grid.options.show_footer == true
    end

    test "normalizes columns with defaults" do
      columns = [%{field: :name, label: "이름"}]
      grid = Grid.new(data: [], columns: columns)

      [column | _] = grid.columns

      assert column.width == :auto
      assert column.sortable == false
      assert column.align == :left
    end
  end

  describe "visible_data/1" do
    setup do
      data = [
        %{id: 3, name: "Charlie"},
        %{id: 1, name: "Alice"},
        %{id: 2, name: "Bob"}
      ]

      columns = [%{field: :name, label: "이름", sortable: true}]

      grid = Grid.new(data: data, columns: columns, options: %{page_size: 2})
      %{grid: grid}
    end

    test "returns first page without sort", %{grid: grid} do
      visible = Grid.visible_data(grid)

      assert length(visible) == 2
      assert hd(visible).name == "Charlie"
    end

    test "returns sorted data", %{grid: grid} do
      # 정렬 적용
      grid = put_in(grid.state.sort, %{field: :name, direction: :asc})
      visible = Grid.visible_data(grid)

      assert hd(visible).name == "Alice"
    end

    test "returns second page", %{grid: grid} do
      # 2페이지로 이동
      grid = put_in(grid.state.pagination.current_page, 2)
      visible = Grid.visible_data(grid)

      assert length(visible) == 1
      assert hd(visible).name == "Bob"
    end
  end

  describe "update_data/4" do
    test "preserves state while updating data" do
      grid = Grid.new(data: [%{id: 1, name: "Alice"}], columns: [%{field: :id, label: "ID"}])

      # 사용자 상호작용 시뮬레이션
      grid = put_in(grid.state.scroll_offset, 10)
      grid = put_in(grid.state.sort, %{field: :id, direction: :asc})
      grid = put_in(grid.state.selection.selected_ids, [1])

      # 부모가 새 데이터 전송
      new_data = [%{id: 1}, %{id: 2}, %{id: 3}]
      updated = Grid.update_data(grid, new_data, [%{field: :id, label: "ID"}], %{})

      assert updated.data == new_data
      assert updated.state.scroll_offset == 10
      assert updated.state.sort == %{field: :id, direction: :asc}
      assert updated.state.selection.selected_ids == [1]
      assert updated.state.pagination.total_rows == 3
    end

    test "preserves grid id" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}])
      original_id = grid.id

      updated = Grid.update_data(grid, [%{id: 1}], [%{field: :id, label: "ID"}], %{})
      assert updated.id == original_id
    end
  end

  describe "virtual scrolling" do
    test "visible_data returns correct slice for virtual scroll" do
      data = Enum.map(1..100, &%{id: &1, name: "User #{&1}"})
      grid = Grid.new(
        data: data,
        columns: [%{field: :id, label: "ID"}],
        options: %{virtual_scroll: true, row_height: 40, virtual_buffer: 5}
      )

      # 스크롤 offset 20으로 설정
      grid = put_in(grid.state.scroll_offset, 20)
      visible = Grid.visible_data(grid)

      # buffer 5를 고려: start=15, end=40 (visible_rows=15 + buffer=5)
      first = hd(visible)
      assert first._virtual_index == 15
      assert length(visible) > 0
    end

    test "visible_data handles empty data with virtual scroll" do
      grid = Grid.new(
        data: [],
        columns: [%{field: :id, label: "ID"}],
        options: %{virtual_scroll: true, row_height: 40}
      )

      assert Grid.visible_data(grid) == []
    end

    test "visible_data handles scroll_offset beyond data range" do
      data = Enum.map(1..10, &%{id: &1})
      grid = Grid.new(
        data: data,
        columns: [%{field: :id, label: "ID"}],
        options: %{virtual_scroll: true, row_height: 40, virtual_buffer: 5}
      )

      grid = put_in(grid.state.scroll_offset, 100)
      visible = Grid.visible_data(grid)

      assert visible == []
    end

    test "virtual_offset_top returns 0 for empty data" do
      grid = Grid.new(
        data: [],
        columns: [%{field: :id, label: "ID"}],
        options: %{virtual_scroll: true, row_height: 40}
      )

      assert Grid.virtual_offset_top(grid) == 0
    end

    test "virtual_offset_top calculates correct position" do
      data = Enum.map(1..100, &%{id: &1})
      grid = Grid.new(
        data: data,
        columns: [%{field: :id, label: "ID"}],
        options: %{virtual_scroll: true, row_height: 40, virtual_buffer: 5}
      )

      grid = put_in(grid.state.scroll_offset, 20)
      # start_index = max(0, 20 - 5) = 15, offset = 15 * 40 = 600
      assert Grid.virtual_offset_top(grid) == 600
    end
  end

  describe "new/1 with optional id" do
    test "accepts custom id" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}], id: "my-grid")
      assert grid.id == "my-grid"
    end

    test "generates id when not provided" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}])
      assert String.starts_with?(grid.id, "grid_")
    end
  end

  describe "edge cases" do
    test "single row data" do
      grid = Grid.new(
        data: [%{id: 1, name: "Solo"}],
        columns: [%{field: :name, label: "Name"}]
      )

      visible = Grid.visible_data(grid)
      assert length(visible) == 1
      assert hd(visible).name == "Solo"
    end

    test "grid with no columns renders data" do
      grid = Grid.new(data: [%{id: 1}], columns: [])
      assert grid.columns == []
      assert grid.data == [%{id: 1}]
    end

    test "virtual scroll with sort combined" do
      data = Enum.map(1..50, &%{id: &1, name: "User #{51 - &1}"})
      grid = Grid.new(
        data: data,
        columns: [%{field: :name, label: "Name", sortable: true}],
        options: %{virtual_scroll: true, row_height: 40, virtual_buffer: 3}
      )

      # 정렬 + 가상 스크롤 동시 적용
      grid = put_in(grid.state.sort, %{field: :name, direction: :asc})
      grid = put_in(grid.state.scroll_offset, 0)
      visible = Grid.visible_data(grid)

      # 정렬 후 첫 번째는 "User 1"이어야 함
      first = hd(visible)
      assert first.name == "User 1"
    end

    test "update_data changes options" do
      grid = Grid.new(
        data: [%{id: 1}],
        columns: [%{field: :id, label: "ID"}],
        options: %{virtual_scroll: false}
      )
      assert grid.options.virtual_scroll == false

      # virtual_scroll 옵션 변경
      updated = Grid.update_data(grid, [%{id: 1}], [%{field: :id, label: "ID"}], %{virtual_scroll: true})
      assert updated.options.virtual_scroll == true
    end

    test "debug option defaults to false" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}])
      assert grid.options.debug == false
    end
  end
end
