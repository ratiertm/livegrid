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

  describe "필터 통합" do
    setup do
      data = [
        %{id: 1, name: "Alice", age: 30, city: "서울"},
        %{id: 2, name: "Bob", age: 25, city: "부산"},
        %{id: 3, name: "Charlie", age: 35, city: "대전"},
        %{id: 4, name: "David", age: 28, city: "서울"},
        %{id: 5, name: "Eve", age: 40, city: "인천"}
      ]

      columns = [
        %{field: :name, label: "이름", sortable: true, filterable: true, filter_type: :text},
        %{field: :age, label: "나이", sortable: true, filterable: true, filter_type: :number},
        %{field: :city, label: "도시", filterable: true, filter_type: :text}
      ]

      grid = Grid.new(data: data, columns: columns, options: %{page_size: 10})
      %{grid: grid}
    end

    test "visible_data에 텍스트 필터 적용", %{grid: grid} do
      grid = put_in(grid.state.filters, %{name: "ali"})
      visible = Grid.visible_data(grid)
      assert length(visible) == 1
      assert hd(visible).name == "Alice"
    end

    test "visible_data에 숫자 필터 적용", %{grid: grid} do
      grid = put_in(grid.state.filters, %{age: ">30"})
      visible = Grid.visible_data(grid)
      assert length(visible) == 2
      names = Enum.map(visible, & &1.name) |> Enum.sort()
      assert names == ["Charlie", "Eve"]
    end

    test "필터 + 정렬 동시 적용", %{grid: grid} do
      grid = put_in(grid.state.filters, %{city: "서울"})
      grid = put_in(grid.state.sort, %{field: :name, direction: :asc})
      visible = Grid.visible_data(grid)
      assert length(visible) == 2
      assert hd(visible).name == "Alice"
    end

    test "필터 + 페이징 동시 적용", %{grid: grid} do
      grid = put_in(grid.state.filters, %{age: ">=25"})
      grid = %{grid | options: %{grid.options | page_size: 2}}
      visible = Grid.visible_data(grid)
      assert length(visible) == 2
    end

    test "빈 필터는 전체 데이터 반환", %{grid: grid} do
      grid = put_in(grid.state.filters, %{})
      visible = Grid.visible_data(grid)
      assert length(visible) == 5
    end

    test "filtered_count 필터 적용 건수", %{grid: grid} do
      grid = put_in(grid.state.filters, %{city: "서울"})
      assert Grid.filtered_count(grid) == 2
    end

    test "filtered_count 빈 필터는 전체 건수", %{grid: grid} do
      assert Grid.filtered_count(grid) == 5
    end

    test "필터 + virtual scroll", %{grid: grid} do
      grid = %{grid | options: %{grid.options | virtual_scroll: true, row_height: 40, virtual_buffer: 5}}
      grid = put_in(grid.state.filters, %{city: "서울"})
      visible = Grid.visible_data(grid)
      assert length(visible) == 2
      assert Enum.all?(visible, fn row -> row.city == "서울" end)
    end

    test "initial_state에 filters와 show_filter_row 포함" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}])
      assert grid.state.filters == %{}
      assert grid.state.show_filter_row == false
      assert grid.state.global_search == ""
    end
  end

  describe "셀 편집" do
    setup do
      data = [
        %{id: 1, name: "Alice", age: 30},
        %{id: 2, name: "Bob", age: 25},
        %{id: 3, name: "Charlie", age: 35}
      ]

      columns = [
        %{field: :name, label: "이름", editable: true},
        %{field: :age, label: "나이", editable: true, editor_type: :number}
      ]

      grid = Grid.new(data: data, columns: columns)
      %{grid: grid}
    end

    test "initial_state에 editing: nil 포함" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}])
      assert grid.state.editing == nil
    end

    test "normalize_columns에 editable/editor_type 기본값" do
      grid = Grid.new(data: [], columns: [%{field: :name, label: "이름"}])
      [col | _] = grid.columns
      assert col.editable == false
      assert col.editor_type == :text
    end

    test "update_cell로 값 변경", %{grid: grid} do
      updated = Grid.update_cell(grid, 1, :name, "Alice Updated")
      row = Enum.find(updated.data, &(&1.id == 1))
      assert row.name == "Alice Updated"
    end

    test "update_cell로 숫자 값 변경", %{grid: grid} do
      updated = Grid.update_cell(grid, 2, :age, 99)
      row = Enum.find(updated.data, &(&1.id == 2))
      assert row.age == 99
    end

    test "update_cell 없는 row_id는 무시", %{grid: grid} do
      updated = Grid.update_cell(grid, 999, :name, "Ghost")
      assert updated.data == grid.data
    end

    test "update_cell은 다른 행에 영향 없음", %{grid: grid} do
      updated = Grid.update_cell(grid, 1, :name, "Changed")
      bob = Enum.find(updated.data, &(&1.id == 2))
      assert bob.name == "Bob"
    end

    test "editable 컬럼 설정 유지", %{grid: grid} do
      name_col = Enum.find(grid.columns, &(&1.field == :name))
      age_col = Enum.find(grid.columns, &(&1.field == :age))

      assert name_col.editable == true
      assert name_col.editor_type == :text
      assert age_col.editable == true
      assert age_col.editor_type == :number
    end
  end

  describe "전체 검색 통합" do
    setup do
      data = [
        %{id: 1, name: "Alice", age: 30, city: "서울"},
        %{id: 2, name: "Bob", age: 25, city: "부산"},
        %{id: 3, name: "Charlie", age: 35, city: "대전"},
        %{id: 4, name: "David", age: 28, city: "서울"},
        %{id: 5, name: "Eve", age: 40, city: "인천"}
      ]

      columns = [
        %{field: :name, label: "이름", sortable: true, filterable: true, filter_type: :text},
        %{field: :age, label: "나이", sortable: true, filterable: true, filter_type: :number},
        %{field: :city, label: "도시", filterable: true, filter_type: :text}
      ]

      grid = Grid.new(data: data, columns: columns, options: %{page_size: 10})
      %{grid: grid}
    end

    test "visible_data에 전체 검색 적용", %{grid: grid} do
      grid = put_in(grid.state.global_search, "alice")
      visible = Grid.visible_data(grid)
      assert length(visible) == 1
      assert hd(visible).name == "Alice"
    end

    test "전체 검색 + 컬럼 필터 동시 적용", %{grid: grid} do
      grid = put_in(grid.state.global_search, "서울")
      grid = put_in(grid.state.filters, %{name: "ali"})
      visible = Grid.visible_data(grid)
      assert length(visible) == 1
      assert hd(visible).name == "Alice"
    end

    test "전체 검색 + 정렬 동시 적용", %{grid: grid} do
      grid = put_in(grid.state.global_search, "서울")
      grid = put_in(grid.state.sort, %{field: :name, direction: :desc})
      visible = Grid.visible_data(grid)
      assert length(visible) == 2
      assert hd(visible).name == "David"
    end

    test "filtered_count가 전체 검색 반영", %{grid: grid} do
      grid = put_in(grid.state.global_search, "서울")
      assert Grid.filtered_count(grid) == 2
    end

    test "빈 검색어는 전체 데이터 반환", %{grid: grid} do
      grid = put_in(grid.state.global_search, "")
      visible = Grid.visible_data(grid)
      assert length(visible) == 5
    end
  end

  describe "행 상태 추적 (row status)" do
    setup do
      data = [
        %{id: 1, name: "Alice", age: 30},
        %{id: 2, name: "Bob", age: 25},
        %{id: 3, name: "Charlie", age: 35}
      ]
      columns = [
        %{field: :name, label: "이름", editable: true},
        %{field: :age, label: "나이", editable: true, editor_type: :number}
      ]
      grid = Grid.new(data: data, columns: columns)
      %{grid: grid}
    end

    test "initial_state에 row_statuses와 show_status_column 포함" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}])
      assert grid.state.row_statuses == %{}
      assert grid.state.show_status_column == true
    end

    test "update_cell이 자동으로 :updated 마킹", %{grid: grid} do
      updated = Grid.update_cell(grid, 1, :name, "Alice Updated")
      assert Grid.row_status(updated, 1) == :updated
      assert Grid.row_status(updated, 2) == :normal
    end

    test "update_cell은 :new 상태를 덮어쓰지 않음", %{grid: grid} do
      grid = Grid.mark_row_status(grid, 1, :new)
      updated = Grid.update_cell(grid, 1, :name, "Alice New")
      assert Grid.row_status(updated, 1) == :new
    end

    test "mark_row_status로 상태 설정/해제", %{grid: grid} do
      grid = Grid.mark_row_status(grid, 2, :deleted)
      assert Grid.row_status(grid, 2) == :deleted
      grid = Grid.mark_row_status(grid, 2, :normal)
      assert Grid.row_status(grid, 2) == :normal
      refute Map.has_key?(grid.state.row_statuses, 2)
    end

    test "clear_row_statuses로 모든 상태 초기화", %{grid: grid} do
      grid = Grid.mark_row_status(grid, 1, :new)
      grid = Grid.mark_row_status(grid, 2, :updated)
      grid = Grid.clear_row_statuses(grid)
      assert grid.state.row_statuses == %{}
    end

    test "status_counts 정확한 카운트", %{grid: grid} do
      grid = Grid.mark_row_status(grid, 1, :new)
      grid = Grid.mark_row_status(grid, 2, :updated)
      grid = Grid.mark_row_status(grid, 3, :updated)
      counts = Grid.status_counts(grid)
      assert counts[:new] == 1
      assert counts[:updated] == 2
    end

    test "update_data가 row_statuses 보존", %{grid: grid} do
      grid = Grid.mark_row_status(grid, 1, :updated)
      updated = Grid.update_data(grid, grid.data, [%{field: :name, label: "이름"}], %{})
      assert Grid.row_status(updated, 1) == :updated
    end
  end
end
