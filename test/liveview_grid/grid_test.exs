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

    test "update_data가 누락된 state 키를 보충 (hot-reload 대응)", %{grid: grid} do
      # hot-reload로 기존 state에 새 키(row_statuses, show_status_column)가 없는 상황 시뮬레이션
      old_state = Map.drop(grid.state, [:row_statuses, :show_status_column])
      old_grid = %{grid | state: old_state}

      updated = Grid.update_data(old_grid, grid.data, [%{field: :name, label: "이름"}], %{})

      # 누락된 키가 initial_state 기본값으로 보충됨
      assert updated.state.row_statuses == %{}
      assert updated.state.show_status_column == true
    end

    test "changed_rows가 변경된 행만 반환", %{grid: grid} do
      grid = Grid.update_cell(grid, 1, :name, "Alice Updated")
      grid = Grid.mark_row_status(grid, 3, :deleted)

      changed = Grid.changed_rows(grid)
      assert length(changed) == 2

      updated_row = Enum.find(changed, fn c -> c.status == :updated end)
      assert updated_row.row.id == 1
      assert updated_row.row.name == "Alice Updated"

      deleted_row = Enum.find(changed, fn c -> c.status == :deleted end)
      assert deleted_row.row.id == 3
    end

    test "has_changes?는 변경사항 유무를 반환", %{grid: grid} do
      refute Grid.has_changes?(grid)

      grid = Grid.update_cell(grid, 1, :name, "Changed")
      assert Grid.has_changes?(grid)

      grid = Grid.clear_row_statuses(grid)
      refute Grid.has_changes?(grid)
    end
  end

  describe "행 추가 (add_row)" do
    setup do
      data = [
        %{id: 1, name: "Alice", age: 30},
        %{id: 2, name: "Bob", age: 25}
      ]
      columns = [
        %{field: :name, label: "이름", editable: true},
        %{field: :age, label: "나이", editable: true, editor_type: :number}
      ]
      grid = Grid.new(data: data, columns: columns)
      %{grid: grid}
    end

    test "맨 앞에 새 행 추가 (기본)", %{grid: grid} do
      updated = Grid.add_row(grid, %{name: "", age: 0})
      assert length(updated.data) == 3
      first = hd(updated.data)
      assert first.id < 0
      assert Grid.row_status(updated, first.id) == :new
    end

    test "맨 뒤에 새 행 추가", %{grid: grid} do
      updated = Grid.add_row(grid, %{name: "New"}, :bottom)
      last = List.last(updated.data)
      assert last.id < 0
      assert last.name == "New"
    end

    test "임시 ID는 음수로 자동 부여", %{grid: grid} do
      g1 = Grid.add_row(grid)
      g2 = Grid.add_row(g1)
      ids = Enum.map(g2.data, & &1.id) |> Enum.filter(& &1 < 0)
      assert length(ids) == 2
      assert Enum.uniq(ids) == ids
    end

    test "total_rows가 증가", %{grid: grid} do
      updated = Grid.add_row(grid)
      assert updated.state.pagination.total_rows == 3
    end
  end

  describe "행 삭제 (delete_rows)" do
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

    test "기존 행을 :deleted로 마킹", %{grid: grid} do
      updated = Grid.delete_rows(grid, [1, 2])
      assert Grid.row_status(updated, 1) == :deleted
      assert Grid.row_status(updated, 2) == :deleted
      assert Grid.row_status(updated, 3) == :normal
      # 데이터에서 제거하지 않음
      assert length(updated.data) == 3
    end

    test ":new 행은 데이터에서 완전 제거", %{grid: grid} do
      grid = Grid.add_row(grid, %{name: "New"})
      new_id = hd(grid.data).id
      assert new_id < 0

      updated = Grid.delete_rows(grid, [new_id])
      assert length(updated.data) == 3
      refute Enum.any?(updated.data, fn r -> r.id == new_id end)
      refute Map.has_key?(updated.state.row_statuses, new_id)
    end

    test "선택 목록에서도 삭제된 행 제거", %{grid: grid} do
      grid = Grid.add_row(grid, %{name: "New"})
      new_id = hd(grid.data).id
      grid = put_in(grid.state.selection.selected_ids, [new_id, 1])

      updated = Grid.delete_rows(grid, [new_id])
      refute new_id in updated.state.selection.selected_ids
      assert 1 in updated.state.selection.selected_ids
    end
  end

  describe "frozen_columns 옵션" do
    test "기본값은 0" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}])
      assert grid.options.frozen_columns == 0
    end

    test "frozen_columns 옵션 설정" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}], options: %{frozen_columns: 2})
      assert grid.options.frozen_columns == 2
    end
  end

  describe "셀 검증 (validation)" do
    setup do
      data = [
        %{id: 1, name: "Alice", age: 30, email: "alice@example.com"},
        %{id: 2, name: "Bob", age: 25, email: "bob@example.com"},
        %{id: 3, name: "", age: 0, email: "invalid"}
      ]

      columns = [
        %{field: :name, label: "이름", editable: true,
          validators: [{:required, "이름은 필수입니다"}]},
        %{field: :age, label: "나이", editable: true, editor_type: :number,
          validators: [{:required, "나이는 필수입니다"}, {:min, 1, "1 이상이어야 합니다"}, {:max, 150, "150 이하이어야 합니다"}]},
        %{field: :email, label: "이메일", editable: true,
          validators: [{:required, "이메일은 필수입니다"}, {:pattern, ~r/@/, "이메일 형식이 올바르지 않습니다"}]}
      ]

      grid = Grid.new(data: data, columns: columns)
      %{grid: grid}
    end

    test "initial_state에 cell_errors 포함" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}])
      assert grid.state.cell_errors == %{}
    end

    test "normalize_columns에서 validators 기본값은 빈 리스트" do
      grid = Grid.new(data: [], columns: [%{field: :name, label: "이름"}])
      [col | _] = grid.columns
      assert col.validators == []
    end

    test "required 검증 - 빈 값이면 에러", %{grid: grid} do
      # 이름을 빈 값으로 변경
      grid = Grid.update_cell(grid, 1, :name, "")
      grid = Grid.validate_cell(grid, 1, :name)
      assert Grid.cell_error(grid, 1, :name) == "이름은 필수입니다"
    end

    test "required 검증 - nil 값이면 에러", %{grid: grid} do
      grid = Grid.update_cell(grid, 1, :name, nil)
      grid = Grid.validate_cell(grid, 1, :name)
      assert Grid.cell_error(grid, 1, :name) == "이름은 필수입니다"
    end

    test "required 검증 - 값 있으면 에러 없음", %{grid: grid} do
      grid = Grid.validate_cell(grid, 1, :name)
      assert Grid.cell_error(grid, 1, :name) == nil
    end

    test "min 검증 - 최소값 미만이면 에러", %{grid: grid} do
      grid = Grid.update_cell(grid, 1, :age, 0)
      grid = Grid.validate_cell(grid, 1, :age)
      assert Grid.cell_error(grid, 1, :age) == "1 이상이어야 합니다"
    end

    test "min 검증 - 최소값 이상이면 에러 없음", %{grid: grid} do
      grid = Grid.validate_cell(grid, 1, :age)
      assert Grid.cell_error(grid, 1, :age) == nil
    end

    test "max 검증 - 최대값 초과이면 에러", %{grid: grid} do
      grid = Grid.update_cell(grid, 1, :age, 200)
      grid = Grid.validate_cell(grid, 1, :age)
      assert Grid.cell_error(grid, 1, :age) == "150 이하이어야 합니다"
    end

    test "max 검증 - 최대값 이하이면 에러 없음", %{grid: grid} do
      grid = Grid.update_cell(grid, 1, :age, 150)
      grid = Grid.validate_cell(grid, 1, :age)
      assert Grid.cell_error(grid, 1, :age) == nil
    end

    test "pattern 검증 - 패턴 불일치 에러", %{grid: grid} do
      grid = Grid.update_cell(grid, 1, :email, "invalid-email")
      grid = Grid.validate_cell(grid, 1, :email)
      assert Grid.cell_error(grid, 1, :email) == "이메일 형식이 올바르지 않습니다"
    end

    test "pattern 검증 - 패턴 일치 에러 없음", %{grid: grid} do
      grid = Grid.validate_cell(grid, 1, :email)
      assert Grid.cell_error(grid, 1, :email) == nil
    end

    test "has_errors? - 에러 있을 때 true", %{grid: grid} do
      grid = Grid.update_cell(grid, 1, :name, "")
      grid = Grid.validate_cell(grid, 1, :name)
      assert Grid.has_errors?(grid)
    end

    test "has_errors? - 에러 없을 때 false", %{grid: grid} do
      refute Grid.has_errors?(grid)
    end

    test "error_count - 에러 개수 반환", %{grid: grid} do
      grid = Grid.update_cell(grid, 1, :name, "")
      grid = Grid.validate_cell(grid, 1, :name)
      grid = Grid.update_cell(grid, 2, :age, 0)
      grid = Grid.validate_cell(grid, 2, :age)
      assert Grid.error_count(grid) == 2
    end

    test "검증 에러 수정 시 에러 제거", %{grid: grid} do
      # 에러 발생
      grid = Grid.update_cell(grid, 1, :name, "")
      grid = Grid.validate_cell(grid, 1, :name)
      assert Grid.has_errors?(grid)

      # 에러 수정
      grid = Grid.update_cell(grid, 1, :name, "Alice Fixed")
      grid = Grid.validate_cell(grid, 1, :name)
      refute Grid.has_errors?(grid)
    end

    test "clear_cell_errors로 모든 에러 초기화", %{grid: grid} do
      grid = Grid.update_cell(grid, 1, :name, "")
      grid = Grid.validate_cell(grid, 1, :name)
      assert Grid.has_errors?(grid)

      grid = Grid.clear_cell_errors(grid)
      refute Grid.has_errors?(grid)
    end

    test "validators 미설정 시 검증 통과", %{grid: _grid} do
      # validators 없는 컬럼
      grid = Grid.new(
        data: [%{id: 1, name: "Test"}],
        columns: [%{field: :name, label: "이름", editable: true}]
      )
      grid = Grid.validate_cell(grid, 1, :name)
      refute Grid.has_errors?(grid)
    end

    test "update_data가 cell_errors 보존", %{grid: grid} do
      grid = Grid.update_cell(grid, 1, :name, "")
      grid = Grid.validate_cell(grid, 1, :name)
      assert Grid.has_errors?(grid)

      updated = Grid.update_data(grid, grid.data, grid.columns, %{})
      assert Grid.has_errors?(updated)
      assert Grid.cell_error(updated, 1, :name) == "이름은 필수입니다"
    end
  end

  describe "min_length / max_length 검증" do
    test "min_length - 짧으면 에러" do
      columns = [%{field: :name, label: "이름", validators: [{:min_length, 3, "3자 이상이어야 합니다"}]}]
      grid = Grid.new(data: [%{id: 1, name: "AB"}], columns: columns)
      grid = Grid.validate_cell(grid, 1, :name)
      assert Grid.cell_error(grid, 1, :name) == "3자 이상이어야 합니다"
    end

    test "min_length - 충분하면 에러 없음" do
      columns = [%{field: :name, label: "이름", validators: [{:min_length, 3, "3자 이상이어야 합니다"}]}]
      grid = Grid.new(data: [%{id: 1, name: "ABC"}], columns: columns)
      grid = Grid.validate_cell(grid, 1, :name)
      assert Grid.cell_error(grid, 1, :name) == nil
    end

    test "max_length - 길면 에러" do
      columns = [%{field: :name, label: "이름", validators: [{:max_length, 5, "5자 이하이어야 합니다"}]}]
      grid = Grid.new(data: [%{id: 1, name: "ABCDEF"}], columns: columns)
      grid = Grid.validate_cell(grid, 1, :name)
      assert Grid.cell_error(grid, 1, :name) == "5자 이하이어야 합니다"
    end

    test "max_length - 짧으면 에러 없음" do
      columns = [%{field: :name, label: "이름", validators: [{:max_length, 5, "5자 이하이어야 합니다"}]}]
      grid = Grid.new(data: [%{id: 1, name: "ABC"}], columns: columns)
      grid = Grid.validate_cell(grid, 1, :name)
      assert Grid.cell_error(grid, 1, :name) == nil
    end
  end

  describe "custom 검증" do
    test "custom 함수 - 검증 실패" do
      is_even = fn val -> is_number(val) and rem(val, 2) == 0 end
      columns = [%{field: :age, label: "나이", validators: [{:custom, is_even, "짝수여야 합니다"}]}]
      grid = Grid.new(data: [%{id: 1, age: 3}], columns: columns)
      grid = Grid.validate_cell(grid, 1, :age)
      assert Grid.cell_error(grid, 1, :age) == "짝수여야 합니다"
    end

    test "custom 함수 - 검증 통과" do
      is_even = fn val -> is_number(val) and rem(val, 2) == 0 end
      columns = [%{field: :age, label: "나이", validators: [{:custom, is_even, "짝수여야 합니다"}]}]
      grid = Grid.new(data: [%{id: 1, age: 4}], columns: columns)
      grid = Grid.validate_cell(grid, 1, :age)
      assert Grid.cell_error(grid, 1, :age) == nil
    end
  end

  describe "select editor (드롭다운 편집기)" do
    test "normalize_columns에서 editor_options 기본값은 빈 리스트" do
      columns = [%{field: :city, label: "도시"}]
      grid = Grid.new(data: [], columns: columns)

      [column | _] = grid.columns
      assert column.editor_options == []
      assert column.editor_type == :text
    end

    test "editor_options가 설정되면 유지됨" do
      options = [{"서울", "서울"}, {"부산", "부산"}, {"대구", "대구"}]
      columns = [%{field: :city, label: "도시", editor_type: :select, editor_options: options}]
      grid = Grid.new(data: [], columns: columns)

      [column | _] = grid.columns
      assert column.editor_type == :select
      assert column.editor_options == options
      assert length(column.editor_options) == 3
    end

    test "select 컬럼의 editor_options 첫 번째 값 확인" do
      options = [{"서울", "서울"}, {"부산", "부산"}]
      columns = [%{field: :city, label: "도시", editor_type: :select, editor_options: options}]
      grid = Grid.new(data: [], columns: columns)

      [column | _] = grid.columns
      {label, value} = hd(column.editor_options)
      assert label == "서울"
      assert value == "서울"
    end
  end

  # ── F-200: 테마 시스템 테스트 ──

  describe "theme system (F-200)" do
    setup do
      data = [%{id: 1, name: "Alice"}]
      columns = [%{field: :name, label: "이름"}]
      %{data: data, columns: columns}
    end

    test "T-08: default theme is 'light' when not specified", %{data: data, columns: columns} do
      grid = Grid.new(data: data, columns: columns)
      assert grid.options.theme == "light"
    end

    test "T-08: default theme is 'light' with empty options", %{data: data, columns: columns} do
      grid = Grid.new(data: data, columns: columns, options: %{})
      assert grid.options.theme == "light"
    end

    test "T-02: theme 'dark' is stored correctly", %{data: data, columns: columns} do
      grid = Grid.new(data: data, columns: columns, options: %{theme: "dark"})
      assert grid.options.theme == "dark"
    end

    test "T-01: theme 'light' is stored correctly", %{data: data, columns: columns} do
      grid = Grid.new(data: data, columns: columns, options: %{theme: "light"})
      assert grid.options.theme == "light"
    end

    test "theme is preserved during update_data", %{data: data, columns: columns} do
      grid = Grid.new(data: data, columns: columns, options: %{theme: "dark"})
      updated = Grid.update_data(grid, data, columns, %{theme: "dark"})
      assert updated.options.theme == "dark"
    end

    test "theme can be changed via update_data", %{data: data, columns: columns} do
      grid = Grid.new(data: data, columns: columns, options: %{theme: "light"})
      updated = Grid.update_data(grid, data, columns, %{theme: "dark"})
      assert updated.options.theme == "dark"
    end

    test "other options are not affected by theme", %{data: data, columns: columns} do
      grid = Grid.new(data: data, columns: columns, options: %{theme: "dark", page_size: 50})
      assert grid.options.theme == "dark"
      assert grid.options.page_size == 50
      assert grid.options.show_header == true
    end
  end

  # ── v0.4: Column Resize & Reorder ──

  describe "resize_column/3" do
    setup do
      data = [%{id: 1, name: "Alice", age: 30}]
      columns = [
        %{field: :name, label: "이름", width: 150},
        %{field: :age, label: "나이", width: 100}
      ]
      grid = Grid.new(data: data, columns: columns)
      %{grid: grid}
    end

    test "sets column width in state", %{grid: grid} do
      updated = Grid.resize_column(grid, :name, 200)
      assert updated.state.column_widths[:name] == 200
    end

    test "overwrites existing width", %{grid: grid} do
      updated = grid
        |> Grid.resize_column(:name, 200)
        |> Grid.resize_column(:name, 300)
      assert updated.state.column_widths[:name] == 300
    end

    test "enforces minimum width of 50", %{grid: grid} do
      updated = Grid.resize_column(grid, :name, 50)
      assert updated.state.column_widths[:name] == 50
    end

    test "raises for width below 50", %{grid: grid} do
      assert_raise FunctionClauseError, fn ->
        Grid.resize_column(grid, :name, 30)
      end
    end

    test "supports multiple columns independently", %{grid: grid} do
      updated = grid
        |> Grid.resize_column(:name, 200)
        |> Grid.resize_column(:age, 80)
      assert updated.state.column_widths[:name] == 200
      assert updated.state.column_widths[:age] == 80
    end
  end

  describe "reorder_columns/2" do
    setup do
      data = [%{id: 1, name: "Alice", age: 30, dept: "개발"}]
      columns = [
        %{field: :name, label: "이름"},
        %{field: :age, label: "나이"},
        %{field: :dept, label: "부서"}
      ]
      grid = Grid.new(data: data, columns: columns)
      %{grid: grid}
    end

    test "sets column order in state", %{grid: grid} do
      updated = Grid.reorder_columns(grid, [:dept, :name, :age])
      assert updated.state.column_order == [:dept, :name, :age]
    end

    test "overwrites existing order", %{grid: grid} do
      updated = grid
        |> Grid.reorder_columns([:dept, :name, :age])
        |> Grid.reorder_columns([:age, :dept, :name])
      assert updated.state.column_order == [:age, :dept, :name]
    end
  end

  describe "display_columns/1" do
    setup do
      data = [%{id: 1, name: "Alice", age: 30, dept: "개발"}]
      columns = [
        %{field: :name, label: "이름"},
        %{field: :age, label: "나이"},
        %{field: :dept, label: "부서"}
      ]
      %{data: data, columns: columns}
    end

    test "returns original order when column_order is nil", %{data: data, columns: columns} do
      grid = Grid.new(data: data, columns: columns)
      display = Grid.display_columns(grid)
      assert Enum.map(display, & &1.field) == [:name, :age, :dept]
    end

    test "returns reordered columns", %{data: data, columns: columns} do
      grid = Grid.new(data: data, columns: columns)
        |> Grid.reorder_columns([:dept, :age, :name])
      display = Grid.display_columns(grid)
      assert Enum.map(display, & &1.field) == [:dept, :age, :name]
    end

    test "frozen columns stay first regardless of order", %{data: data, columns: columns} do
      grid = Grid.new(data: data, columns: columns, options: %{frozen_columns: 1})
        |> Grid.reorder_columns([:dept, :age, :name])
      display = Grid.display_columns(grid)
      fields = Enum.map(display, & &1.field)
      # :name (frozen, index 0) stays first
      assert hd(fields) == :name
      # remaining columns follow the order (with :name removed from non-frozen)
      assert tl(fields) == [:dept, :age]
    end

    test "ignores fields not in columns", %{data: data, columns: columns} do
      grid = Grid.new(data: data, columns: columns)
        |> Grid.reorder_columns([:dept, :nonexistent, :age, :name])
      display = Grid.display_columns(grid)
      assert Enum.map(display, & &1.field) == [:dept, :age, :name]
    end
  end

  describe "initial_state column fields" do
    test "column_widths starts empty" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}])
      assert grid.state.column_widths == %{}
    end

    test "column_order starts nil" do
      grid = Grid.new(data: [], columns: [%{field: :id, label: "ID"}])
      assert grid.state.column_order == nil
    end
  end

  # ── Grid Configuration (apply_config_changes/2) ──

  describe "apply_config_changes/2" do
    setup do
      data = [
        %{id: 1, name: "Alice", salary: 5000, department: "Engineering"},
        %{id: 2, name: "Bob", salary: 4500, department: "Sales"}
      ]

      columns = [
        %{field: :name, label: "Name", width: 120, align: :left, sortable: true, editable: true},
        %{field: :salary, label: "Salary", width: 100, align: :right, sortable: true},
        %{field: :department, label: "Department", width: 120, align: :left}
      ]

      grid = Grid.new(data: data, columns: columns)
      %{grid: grid}
    end

    test "changes column label", %{grid: grid} do
      config = %{
        "columns" => [%{"field" => "name", "label" => "Full Name"}]
      }

      updated = Grid.apply_config_changes(grid, config)
      name_col = Enum.find(updated.columns, &(&1.field == :name))
      assert name_col.label == "Full Name"
    end

    test "changes column width", %{grid: grid} do
      config = %{
        "columns" => [%{"field" => "salary", "width" => 200}]
      }

      updated = Grid.apply_config_changes(grid, config)
      salary_col = Enum.find(updated.columns, &(&1.field == :salary))
      assert salary_col.width == 200
    end

    test "changes column alignment", %{grid: grid} do
      config = %{
        "columns" => [%{"field" => "name", "align" => "center"}]
      }

      updated = Grid.apply_config_changes(grid, config)
      name_col = Enum.find(updated.columns, &(&1.field == :name))
      assert name_col.align == :center
    end

    test "changes sortable flag", %{grid: grid} do
      config = %{
        "columns" => [%{"field" => "salary", "sortable" => false}]
      }

      updated = Grid.apply_config_changes(grid, config)
      salary_col = Enum.find(updated.columns, &(&1.field == :salary))
      assert salary_col.sortable == false
    end

    test "changes editable flag", %{grid: grid} do
      config = %{
        "columns" => [%{"field" => "department", "editable" => true}]
      }

      updated = Grid.apply_config_changes(grid, config)
      dept_col = Enum.find(updated.columns, &(&1.field == :department))
      assert dept_col.editable == true
    end

    test "reorders columns via column_order", %{grid: grid} do
      config = %{
        "column_order" => ["department", "salary", "name"]
      }

      updated = Grid.apply_config_changes(grid, config)
      fields = Enum.map(updated.columns, & &1.field)
      assert fields == [:department, :salary, :name]
    end

    test "applies multiple column changes at once", %{grid: grid} do
      config = %{
        "columns" => [
          %{"field" => "name", "label" => "Employee", "width" => 200},
          %{"field" => "salary", "align" => "center", "sortable" => false}
        ]
      }

      updated = Grid.apply_config_changes(grid, config)
      name_col = Enum.find(updated.columns, &(&1.field == :name))
      salary_col = Enum.find(updated.columns, &(&1.field == :salary))

      assert name_col.label == "Employee"
      assert name_col.width == 200
      assert salary_col.align == :center
      assert salary_col.sortable == false
    end

    test "unchanged columns retain their original values", %{grid: grid} do
      config = %{
        "columns" => [%{"field" => "name", "label" => "Changed"}]
      }

      updated = Grid.apply_config_changes(grid, config)
      dept_col = Enum.find(updated.columns, &(&1.field == :department))
      assert dept_col.label == "Department"
      assert dept_col.width == 120
    end

    test "returns grid unchanged when no columns key", %{grid: grid} do
      config = %{}
      updated = Grid.apply_config_changes(grid, config)
      assert updated.columns == grid.columns
    end

    test "raises on invalid column field", %{grid: grid} do
      config = %{
        "columns" => [%{"field" => "nonexistent", "label" => "Ghost"}]
      }

      assert_raise RuntimeError, fn ->
        Grid.apply_config_changes(grid, config)
      end
    end

    test "changes formatter for a column", %{grid: grid} do
      config = %{
        "columns" => [%{"field" => "salary", "formatter" => "currency"}]
      }

      updated = Grid.apply_config_changes(grid, config)
      salary_col = Enum.find(updated.columns, &(&1.field == :salary))
      assert salary_col.formatter == :currency
    end

    test "changes filterable flag", %{grid: grid} do
      config = %{
        "columns" => [%{"field" => "name", "filterable" => true}]
      }

      updated = Grid.apply_config_changes(grid, config)
      name_col = Enum.find(updated.columns, &(&1.field == :name))
      assert name_col.filterable == true
    end

    test "data remains unchanged after config apply", %{grid: grid} do
      config = %{
        "columns" => [%{"field" => "name", "label" => "New Label"}]
      }

      updated = Grid.apply_config_changes(grid, config)
      assert updated.data == grid.data
    end
  end

  # ── Grid Settings (apply_grid_settings/2) ──

  describe "apply_grid_settings/2" do
    setup do
      data = [
        %{id: 1, name: "Alice", salary: 5000},
        %{id: 2, name: "Bob", salary: 4500}
      ]

      columns = [
        %{field: :name, label: "Name", width: 120, align: :left, sortable: true},
        %{field: :salary, label: "Salary", width: 100, align: :right, sortable: true}
      ]

      grid = Grid.new(data: data, columns: columns)
      %{grid: grid}
    end

    test "applies valid page_size", %{grid: grid} do
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"page_size" => 50})
      assert new_grid.options.page_size == 50
    end

    test "applies valid theme dark", %{grid: grid} do
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"theme" => "dark"})
      assert new_grid.options.theme == "dark"
    end

    test "applies valid theme light", %{grid: grid} do
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"theme" => "light"})
      assert new_grid.options.theme == "light"
    end

    test "applies valid theme custom", %{grid: grid} do
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"theme" => "custom"})
      assert new_grid.options.theme == "custom"
    end

    test "applies virtual_scroll toggle", %{grid: grid} do
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"virtual_scroll" => true})
      assert new_grid.options.virtual_scroll == true
    end

    test "applies valid row_height", %{grid: grid} do
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"row_height" => 55})
      assert new_grid.options.row_height == 55
    end

    test "applies valid frozen_columns", %{grid: grid} do
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"frozen_columns" => 1})
      assert new_grid.options.frozen_columns == 1
    end

    test "applies show_row_number boolean", %{grid: grid} do
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"show_row_number" => false})
      assert new_grid.options.show_row_number == false
    end

    test "applies show_header boolean", %{grid: grid} do
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"show_header" => false})
      assert new_grid.options.show_header == false
    end

    test "applies show_footer boolean", %{grid: grid} do
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"show_footer" => true})
      assert new_grid.options.show_footer == true
    end

    test "applies multiple options at once", %{grid: grid} do
      changes = %{
        "page_size" => 25,
        "theme" => "dark",
        "row_height" => 50,
        "virtual_scroll" => true
      }

      {:ok, new_grid} = Grid.apply_grid_settings(grid, changes)
      assert new_grid.options.page_size == 25
      assert new_grid.options.theme == "dark"
      assert new_grid.options.row_height == 50
      assert new_grid.options.virtual_scroll == true
    end

    test "accepts atom keys as well as string keys", %{grid: grid} do
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{page_size: 100})
      assert new_grid.options.page_size == 100
    end

    test "validates page_size upper bound", %{grid: grid} do
      {:error, reason} = Grid.apply_grid_settings(grid, %{"page_size" => 200_000})
      assert String.contains?(reason, "page_size")
    end

    test "validates page_size lower bound (zero)", %{grid: grid} do
      {:error, reason} = Grid.apply_grid_settings(grid, %{"page_size" => 0})
      assert String.contains?(reason, "page_size")
    end

    test "validates row_height upper bound", %{grid: grid} do
      {:error, reason} = Grid.apply_grid_settings(grid, %{"row_height" => 100})
      assert String.contains?(reason, "row_height")
    end

    test "validates row_height lower bound", %{grid: grid} do
      {:error, reason} = Grid.apply_grid_settings(grid, %{"row_height" => 10})
      assert String.contains?(reason, "row_height")
    end

    test "validates invalid theme value", %{grid: grid} do
      {:error, reason} = Grid.apply_grid_settings(grid, %{"theme" => "purple"})
      assert String.contains?(reason, "theme")
    end

    test "validates frozen_columns upper bound (exceeds column count)", %{grid: grid} do
      {:error, reason} = Grid.apply_grid_settings(grid, %{"frozen_columns" => 99})
      assert String.contains?(reason, "frozen_columns")
    end

    test "validates frozen_columns lower bound (negative)", %{grid: grid} do
      {:error, reason} = Grid.apply_grid_settings(grid, %{"frozen_columns" => -1})
      assert String.contains?(reason, "frozen_columns")
    end

    test "ignores unknown option keys without error", %{grid: grid} do
      {:ok, _new_grid} = Grid.apply_grid_settings(grid, %{"unknown_option" => "value"})
    end

    test "returns error for nil options_changes", %{grid: grid} do
      {:error, _reason} = Grid.apply_grid_settings(grid, nil)
    end

    test "preserves existing options not in changes", %{grid: grid} do
      original_show_header = grid.options.show_header
      {:ok, new_grid} = Grid.apply_grid_settings(grid, %{"page_size" => 50})
      assert new_grid.options.show_header == original_show_header
    end
  end

  # ==========================================================================
  # GridDefinition Tests
  # ==========================================================================

  describe "GridDefinition.new/2" do
    alias LiveViewGrid.GridDefinition

    test "creates definition with columns and default options" do
      columns = [%{field: :name, label: "Name"}, %{field: :age, label: "Age"}]
      definition = GridDefinition.new(columns)

      assert length(definition.columns) == 2
      assert definition.options == %{}
    end

    test "merges column defaults" do
      columns = [%{field: :name, label: "Name"}]
      definition = GridDefinition.new(columns)

      [col] = definition.columns
      assert col.width == :auto
      assert col.sortable == false
      assert col.align == :left
      assert col.type == :string
      assert col.required == false
    end

    test "preserves user-specified column values" do
      columns = [%{field: :name, label: "Name", width: 200, sortable: true}]
      definition = GridDefinition.new(columns)

      [col] = definition.columns
      assert col.width == 200
      assert col.sortable == true
    end

    test "preserves options" do
      columns = [%{field: :id, label: "ID"}]
      opts = %{page_size: 50, theme: "dark"}
      definition = GridDefinition.new(columns, opts)

      assert definition.options == opts
    end

    test "raises on missing field" do
      assert_raise ArgumentError, ~r/field/, fn ->
        GridDefinition.new([%{label: "Name"}])
      end
    end

    test "raises on missing label" do
      assert_raise ArgumentError, ~r/label/, fn ->
        GridDefinition.new([%{field: :name}])
      end
    end

    test "raises on duplicate fields" do
      assert_raise ArgumentError, ~r/중복/, fn ->
        GridDefinition.new([
          %{field: :name, label: "Name"},
          %{field: :name, label: "Name2"}
        ])
      end
    end
  end

  describe "GridDefinition.get_column/2" do
    alias LiveViewGrid.GridDefinition

    test "returns column by field" do
      definition = GridDefinition.new([
        %{field: :name, label: "Name"},
        %{field: :age, label: "Age"}
      ])

      col = GridDefinition.get_column(definition, :name)
      assert col.field == :name
      assert col.label == "Name"
    end

    test "returns nil for unknown field" do
      definition = GridDefinition.new([%{field: :name, label: "Name"}])
      assert GridDefinition.get_column(definition, :unknown) == nil
    end
  end

  describe "GridDefinition.fields/1" do
    alias LiveViewGrid.GridDefinition

    test "returns all field atoms" do
      definition = GridDefinition.new([
        %{field: :id, label: "ID"},
        %{field: :name, label: "Name"},
        %{field: :email, label: "Email"}
      ])

      assert GridDefinition.fields(definition) == [:id, :name, :email]
    end
  end

  describe "Grid.new with definition" do
    test "definition field is auto-created" do
      grid = Grid.new(
        data: [%{id: 1, name: "Alice"}],
        columns: [%{field: :name, label: "Name"}]
      )

      assert grid.definition != nil
      assert length(grid.definition.columns) == 1
    end

    test "definition.columns preserves original column info" do
      columns = [
        %{field: :name, label: "Name", width: 200, sortable: true},
        %{field: :email, label: "Email"}
      ]
      grid = Grid.new(data: [], columns: columns)

      [name_col, _email_col] = grid.definition.columns
      assert name_col.field == :name
      assert name_col.width == 200
      assert name_col.sortable == true
    end

    test "definition.options preserves grid options" do
      grid = Grid.new(
        data: [],
        columns: [%{field: :id, label: "ID"}],
        options: %{page_size: 50, theme: "dark"}
      )

      assert grid.definition.options == %{page_size: 50, theme: "dark"}
    end
  end

  describe "apply_config_changes with definition" do
    setup do
      columns = [
        %{field: :id, label: "ID", width: 80},
        %{field: :name, label: "Name", width: 150, sortable: true, editable: true},
        %{field: :email, label: "Email", width: 200},
        %{field: :age, label: "Age", width: 80}
      ]

      grid = Grid.new(data: [%{id: 1, name: "Alice", email: "a@b.c", age: 30}], columns: columns)
      %{grid: grid}
    end

    test "hidden columns are recoverable from definition", %{grid: grid} do
      # Hide id and email
      updated = Grid.apply_config_changes(grid, %{
        "hidden_columns" => ["id", "email"]
      })

      assert length(updated.columns) == 2
      fields = Enum.map(updated.columns, & &1.field)
      assert :id not in fields
      assert :email not in fields

      # Apply again with id visible
      restored = Grid.apply_config_changes(updated, %{
        "hidden_columns" => ["email"]
      })

      assert length(restored.columns) == 3
      restored_fields = Enum.map(restored.columns, & &1.field)
      assert :id in restored_fields
      assert :email not in restored_fields
    end

    test "state[:all_columns] always persists runtime column state", %{grid: grid} do
      updated = Grid.apply_config_changes(grid, %{
        "hidden_columns" => ["id"]
      })

      # runtime 변경사항은 항상 state[:all_columns]에 저장됨 (모달 재오픈 시 참조)
      assert Map.has_key?(updated.state, :all_columns)
      all_fields = Enum.map(updated.state[:all_columns], & &1.field)
      assert :id in all_fields
      assert :name in all_fields
    end
  end

  describe "reset_to_definition/1" do
    test "restores original columns" do
      columns = [
        %{field: :id, label: "ID"},
        %{field: :name, label: "Name"},
        %{field: :email, label: "Email"}
      ]
      grid = Grid.new(data: [], columns: columns)

      # Hide a column
      modified = Grid.apply_config_changes(grid, %{
        "hidden_columns" => ["email"],
        "columns" => [%{"field" => "name", "label" => "성명"}]
      })

      assert length(modified.columns) == 2

      # Reset to definition
      restored = Grid.reset_to_definition(modified)

      assert length(restored.columns) == 3
      assert restored.state[:hidden_columns] == []
      assert restored.state[:column_order] == nil
    end

    test "restores original options" do
      grid = Grid.new(
        data: [],
        columns: [%{field: :id, label: "ID"}],
        options: %{page_size: 25, theme: "dark"}
      )

      assert grid.options.page_size == 25
      assert grid.options.theme == "dark"

      restored = Grid.reset_to_definition(grid)

      assert restored.options.page_size == 25
      assert restored.options.theme == "dark"
    end

    test "no-op when definition is nil" do
      grid = %{
        id: "test",
        data: [],
        columns: [],
        definition: nil,
        state: %{},
        options: %{},
        data_source: nil
      }

      assert Grid.reset_to_definition(grid) == grid
    end
  end

  # ── F-941: Cell Range Summary ──

  describe "cell_range_summary/1" do
    setup do
      data = [
        %{id: 1, name: "Alice", age: 25, salary: 3000},
        %{id: 2, name: "Bob", age: 30, salary: 4000},
        %{id: 3, name: "Carol", age: 35, salary: 5000},
        %{id: 4, name: "Dave", age: 40, salary: 6000}
      ]
      columns = [
        %{field: :name, label: "이름"},
        %{field: :age, label: "나이"},
        %{field: :salary, label: "급여"}
      ]
      grid = Grid.new(data: data, columns: columns, options: %{page_size: 100})
      %{grid: grid}
    end

    test "returns nil when no range is selected", %{grid: grid} do
      assert Grid.cell_range_summary(grid) == nil
    end

    test "calculates summary for numeric range", %{grid: grid} do
      # 나이 컬럼 (col_idx 1): rows 1~3 → ages 25, 30, 35
      grid = Grid.set_cell_range(grid, %{
        anchor_row_id: 1, anchor_col_idx: 1,
        extent_row_id: 3, extent_col_idx: 1
      })

      summary = Grid.cell_range_summary(grid)
      assert summary.count == 3
      assert summary.numeric_count == 3
      assert summary.sum == 90
      assert summary.min == 25
      assert summary.max == 35
      assert_in_delta summary.avg, 30.0, 0.01
    end

    test "calculates summary for mixed text/numeric range", %{grid: grid} do
      # 이름 + 나이 (col 0~1), rows 1~2
      grid = Grid.set_cell_range(grid, %{
        anchor_row_id: 1, anchor_col_idx: 0,
        extent_row_id: 2, extent_col_idx: 1
      })

      summary = Grid.cell_range_summary(grid)
      assert summary.count == 4   # 2 names + 2 ages
      assert summary.numeric_count == 2
      assert summary.sum == 55    # 25 + 30
    end

    test "returns count-only for non-numeric range", %{grid: grid} do
      # 이름 컬럼만 (col 0), rows 1~4
      grid = Grid.set_cell_range(grid, %{
        anchor_row_id: 1, anchor_col_idx: 0,
        extent_row_id: 4, extent_col_idx: 0
      })

      summary = Grid.cell_range_summary(grid)
      assert summary.count == 4
      assert summary.numeric_count == 0
      assert summary.sum == nil
      assert summary.avg == nil
    end

    test "handles single cell selection", %{grid: grid} do
      grid = Grid.set_cell_range(grid, %{
        anchor_row_id: 2, anchor_col_idx: 2,
        extent_row_id: 2, extent_col_idx: 2
      })

      summary = Grid.cell_range_summary(grid)
      assert summary.count == 1
      assert summary.numeric_count == 1
      assert summary.sum == 4000
      assert summary.avg == 4000.0
    end

    test "handles full grid range", %{grid: grid} do
      grid = Grid.set_cell_range(grid, %{
        anchor_row_id: 1, anchor_col_idx: 0,
        extent_row_id: 4, extent_col_idx: 2
      })

      summary = Grid.cell_range_summary(grid)
      assert summary.count == 12   # 4 rows * 3 cols
      assert summary.numeric_count == 8  # 4 ages + 4 salaries
      assert summary.sum == 25 + 30 + 35 + 40 + 3000 + 4000 + 5000 + 6000
    end
  end

  # ── F-950: Summary Row ──

  describe "summary_data/1" do
    test "returns aggregates for columns with summary" do
      grid = Grid.new(
        data: [
          %{id: 1, name: "A", salary: 100, age: 20},
          %{id: 2, name: "B", salary: 200, age: 30},
          %{id: 3, name: "C", salary: 300, age: 40}
        ],
        columns: [
          %{field: :name, label: "Name"},
          %{field: :salary, label: "Salary", summary: :sum},
          %{field: :age, label: "Age", summary: :avg}
        ]
      )

      result = Grid.summary_data(grid)
      assert result.salary == 600
      assert result.age == 30.0
      refute Map.has_key?(result, :name)
    end

    test "returns empty map when no summary columns" do
      grid = Grid.new(
        data: [%{id: 1, name: "A"}],
        columns: [%{field: :name, label: "Name"}]
      )
      assert Grid.summary_data(grid) == %{}
    end

    test "handles nil values gracefully" do
      grid = Grid.new(
        data: [
          %{id: 1, salary: 100},
          %{id: 2, salary: nil},
          %{id: 3, salary: 300}
        ],
        columns: [%{field: :salary, label: "Salary", summary: :sum}]
      )
      result = Grid.summary_data(grid)
      assert result.salary == 400
    end

    test "count includes all rows" do
      grid = Grid.new(
        data: [
          %{id: 1, active: true},
          %{id: 2, active: false},
          %{id: 3, active: true}
        ],
        columns: [%{field: :active, label: "Active", summary: :count}]
      )
      result = Grid.summary_data(grid)
      assert result.active == 3
    end

    test "min and max functions" do
      grid = Grid.new(
        data: [
          %{id: 1, score: 85},
          %{id: 2, score: 92},
          %{id: 3, score: 78}
        ],
        columns: [%{field: :score, label: "Score", summary: :min}]
      )
      assert Grid.summary_data(grid).score == 78

      grid2 = Grid.new(
        data: grid.data,
        columns: [%{field: :score, label: "Score", summary: :max}]
      )
      assert Grid.summary_data(grid2).score == 92
    end

    test "respects active filters" do
      grid = Grid.new(
        data: [
          %{id: 1, name: "Alice", salary: 100},
          %{id: 2, name: "Bob", salary: 200},
          %{id: 3, name: "Carol", salary: 300}
        ],
        columns: [
          %{field: :name, label: "Name", filterable: true},
          %{field: :salary, label: "Salary", summary: :sum}
        ]
      )

      grid = put_in(grid.state.filters, %{name: "Alice"})
      result = Grid.summary_data(grid)
      assert result.salary == 100
    end
  end

  describe "cell merge (F-904)" do
    setup do
      columns = [
        %{field: :name, label: "Name"},
        %{field: :email, label: "Email"},
        %{field: :age, label: "Age", align: :right},
        %{field: :city, label: "City"}
      ]
      data = [
        %{id: 1, name: "Alice", email: "a@test.com", age: 30, city: "Seoul"},
        %{id: 2, name: "Bob", email: "b@test.com", age: 25, city: "Seoul"},
        %{id: 3, name: "Carol", email: "c@test.com", age: 35, city: "Busan"}
      ]
      grid = Grid.new(data: data, columns: columns, options: %{page_size: 99999})
      %{grid: grid}
    end

    test "merge_cells/2 registers colspan", %{grid: grid} do
      assert {:ok, grid} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, colspan: 2})
      assert Map.has_key?(grid.state.merge_regions, {1, :name})
      assert grid.state.merge_regions[{1, :name}] == %{rowspan: 1, colspan: 2}
    end

    test "merge_cells/2 registers rowspan", %{grid: grid} do
      assert {:ok, grid} = Grid.merge_cells(grid, %{row_id: 1, col_field: :city, rowspan: 3})
      assert grid.state.merge_regions[{1, :city}] == %{rowspan: 3, colspan: 1}
    end

    test "merge_cells/2 rejects single cell merge", %{grid: grid} do
      assert {:error, _msg} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, rowspan: 1, colspan: 1})
    end

    test "merge_cells/2 rejects overlapping merge", %{grid: grid} do
      {:ok, grid} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, colspan: 2})
      assert {:error, _msg} = Grid.merge_cells(grid, %{row_id: 1, col_field: :email, colspan: 2})
    end

    test "merge_cells/2 rejects colspan exceeding columns", %{grid: grid} do
      assert {:error, _msg} = Grid.merge_cells(grid, %{row_id: 1, col_field: :city, colspan: 5})
    end

    test "unmerge_cells/3 removes merge", %{grid: grid} do
      {:ok, grid} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, colspan: 2})
      grid = Grid.unmerge_cells(grid, 1, :name)
      assert grid.state.merge_regions == %{}
    end

    test "clear_all_merges/1 removes all merges", %{grid: grid} do
      {:ok, grid} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, colspan: 2})
      {:ok, grid} = Grid.merge_cells(grid, %{row_id: 2, col_field: :age, rowspan: 2})
      grid = Grid.clear_all_merges(grid)
      assert grid.state.merge_regions == %{}
    end

    test "merge_regions/1 returns all regions", %{grid: grid} do
      {:ok, grid} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, colspan: 2})
      regions = Grid.merge_regions(grid)
      assert map_size(regions) == 1
    end

    test "merged?/3 detects merged cells", %{grid: grid} do
      {:ok, grid} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, colspan: 2})
      assert Grid.merged?(grid, 1, :name) == true
      assert Grid.merged?(grid, 1, :email) == true
      assert Grid.merged?(grid, 1, :age) == false
    end

    test "build_merge_skip_map/1 generates skip entries", %{grid: grid} do
      {:ok, grid} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, colspan: 2})
      skip_map = Grid.build_merge_skip_map(grid)
      assert Map.has_key?(skip_map, {1, :email})
      refute Map.has_key?(skip_map, {1, :name})
    end

    test "frozen boundary merge is rejected", %{grid: grid} do
      grid = %{grid | options: Map.put(grid.options, :frozen_columns, 1)}
      assert {:error, _msg} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, colspan: 2})
    end
  end

  describe "wordwrap (F-911)" do
    alias LiveviewGridWeb.GridComponent.RenderHelpers

    test "wordwrap_class/1 returns correct class for :char" do
      assert RenderHelpers.wordwrap_class(%{wordwrap: :char}) == "lv-grid__cell--wordwrap-char"
    end

    test "wordwrap_class/1 returns correct class for :word" do
      assert RenderHelpers.wordwrap_class(%{wordwrap: :word}) == "lv-grid__cell--wordwrap-word"
    end

    test "wordwrap_class/1 returns empty for no wordwrap" do
      assert RenderHelpers.wordwrap_class(%{}) == ""
      assert RenderHelpers.wordwrap_class(%{wordwrap: :none}) == ""
    end

    test "wordwrap?/1 detects wordwrap columns" do
      assert RenderHelpers.wordwrap?(%{wordwrap: :char}) == true
      assert RenderHelpers.wordwrap?(%{wordwrap: :word}) == true
      assert RenderHelpers.wordwrap?(%{wordwrap: :none}) == false
      assert RenderHelpers.wordwrap?(%{}) == false
    end

    test "column with wordwrap option is preserved in grid" do
      grid = Grid.new(
        data: [%{id: 1, name: "test"}],
        columns: [%{field: :name, label: "Name", wordwrap: :word}]
      )

      col = hd(grid.columns)
      assert Map.get(col, :wordwrap) == :word
    end
  end

  describe "row move (F-930)" do
    setup do
      grid = Grid.new(
        data: [
          %{id: 1, name: "Alice"},
          %{id: 2, name: "Bob"},
          %{id: 3, name: "Charlie"},
          %{id: 4, name: "David"}
        ],
        columns: [%{field: :name, label: "Name"}]
      )
      %{grid: grid}
    end

    test "move_row/3 moves row to new position", %{grid: grid} do
      updated = Grid.move_row(grid, 3, 1)
      ids = Enum.map(updated.data, & &1.id)
      assert ids == [3, 1, 2, 4]
    end

    test "move_row/3 to end of list", %{grid: grid} do
      updated = Grid.move_row(grid, 1, 4)
      ids = Enum.map(updated.data, & &1.id)
      assert ids == [2, 3, 1, 4]
    end

    test "move_row/3 same id returns unchanged", %{grid: grid} do
      updated = Grid.move_row(grid, 2, 2)
      assert updated.data == grid.data
    end

    test "move_row/3 invalid from_id returns unchanged", %{grid: grid} do
      updated = Grid.move_row(grid, 999, 1)
      assert updated.data == grid.data
    end
  end

  describe "right column freeze" do
    alias LiveviewGridWeb.GridComponent.RenderHelpers

    test "frozen_class returns frozen-right for rightmost column" do
      grid = Grid.new(
        data: [%{id: 1, name: "A", age: 20, city: "Seoul"}],
        columns: [
          %{field: :name, label: "Name", width: 150},
          %{field: :age, label: "Age", width: 100},
          %{field: :city, label: "City", width: 120}
        ],
        options: %{frozen_right_columns: 1}
      )
      # col_idx 2 (city) should be frozen-right (3 columns, last 1 frozen)
      assert RenderHelpers.frozen_class(2, grid) == "lv-grid__cell--frozen-right"
      assert RenderHelpers.frozen_class(1, grid) == ""
      assert RenderHelpers.frozen_class(0, grid) == ""
    end

    test "frozen_style returns sticky right for frozen-right column" do
      grid = Grid.new(
        data: [%{id: 1, name: "A", age: 20, city: "Seoul"}],
        columns: [
          %{field: :name, label: "Name", width: 150},
          %{field: :age, label: "Age", width: 100},
          %{field: :city, label: "City", width: 120}
        ],
        options: %{frozen_right_columns: 1}
      )
      style = RenderHelpers.frozen_style(2, grid)
      assert style =~ "position: sticky"
      assert style =~ "right: 0px"
    end

    test "both left and right freeze work together" do
      grid = Grid.new(
        data: [%{id: 1, name: "A", age: 20, city: "Seoul"}],
        columns: [
          %{field: :name, label: "Name", width: 150},
          %{field: :age, label: "Age", width: 100},
          %{field: :city, label: "City", width: 120}
        ],
        options: %{frozen_columns: 1, frozen_right_columns: 1}
      )
      assert RenderHelpers.frozen_class(0, grid) == "lv-grid__cell--frozen"
      assert RenderHelpers.frozen_class(1, grid) == ""
      assert RenderHelpers.frozen_class(2, grid) == "lv-grid__cell--frozen-right"
    end
  end

  describe "F-903: Suppress (동일값 병합)" do
    alias LiveviewGridWeb.GridComponent.RenderHelpers

    test "suppress_cell? returns true when current value equals previous row" do
      col = %{field: :city, suppress: true}
      row = %{id: 2, city: "서울"}
      prev = %{id: 1, city: "서울"}
      assert RenderHelpers.suppress_cell?(col, row, prev) == true
    end

    test "suppress_cell? returns false when values differ" do
      col = %{field: :city, suppress: true}
      row = %{id: 2, city: "부산"}
      prev = %{id: 1, city: "서울"}
      assert RenderHelpers.suppress_cell?(col, row, prev) == false
    end

    test "suppress_cell? returns false for first row (nil prev)" do
      col = %{field: :city, suppress: true}
      row = %{id: 1, city: "서울"}
      assert RenderHelpers.suppress_cell?(col, row, nil) == false
    end

    test "suppress_cell? returns false when suppress not set" do
      col = %{field: :city}
      row = %{id: 2, city: "서울"}
      prev = %{id: 1, city: "서울"}
      assert RenderHelpers.suppress_cell?(col, row, prev) == false
    end

    test "build_suppress_map builds correct set for adjacent duplicates" do
      rows = [
        %{id: 1, city: "서울", name: "A"},
        %{id: 2, city: "서울", name: "B"},
        %{id: 3, city: "부산", name: "B"},
        %{id: 4, city: "부산", name: "B"}
      ]
      columns = [
        %{field: :city, suppress: true},
        %{field: :name, suppress: true}
      ]
      result = RenderHelpers.build_suppress_map(rows, columns)
      assert MapSet.member?(result, {2, :city})
      assert MapSet.member?(result, {3, :name})
      assert MapSet.member?(result, {4, :city})
      assert MapSet.member?(result, {4, :name})
      refute MapSet.member?(result, {1, :city})
      refute MapSet.member?(result, {1, :name})
      refute MapSet.member?(result, {2, :name})
      refute MapSet.member?(result, {3, :city})
    end

    test "build_suppress_map returns empty set when no suppress columns" do
      rows = [%{id: 1, city: "서울"}, %{id: 2, city: "서울"}]
      columns = [%{field: :city}]
      result = RenderHelpers.build_suppress_map(rows, columns)
      assert MapSet.size(result) == 0
    end

    test "suppressed? checks membership correctly" do
      smap = MapSet.new([{2, :city}])
      assert RenderHelpers.suppressed?(smap, 2, :city) == true
      assert RenderHelpers.suppressed?(smap, 1, :city) == false
    end
  end

  describe "Auto-fit Height & Per-row Height" do
    test "set_row_height sets individual row height" do
      grid = Grid.new(
        columns: [%{field: :name, label: "Name"}],
        data: [%{id: 1, name: "A"}, %{id: 2, name: "B"}]
      )
      updated = Grid.set_row_height(grid, 1, 80)
      assert updated.state.row_heights == %{1 => 80}
    end

    test "reset_row_height removes individual row height" do
      grid = Grid.new(
        columns: [%{field: :name, label: "Name"}],
        data: [%{id: 1, name: "A"}]
      )
      updated = grid |> Grid.set_row_height(1, 80) |> Grid.reset_row_height(1)
      assert updated.state.row_heights == %{}
    end

    test "get_row_height returns per-row height or default" do
      grid = Grid.new(
        columns: [%{field: :name, label: "Name"}],
        data: [%{id: 1, name: "A"}, %{id: 2, name: "B"}]
      )
      updated = Grid.set_row_height(grid, 1, 60)
      assert Grid.get_row_height(updated, 1) == 60
      assert Grid.get_row_height(updated, 2) == 40
    end

    test "autofit_type defaults to :none" do
      grid = Grid.new(
        columns: [%{field: :name, label: "Name"}],
        data: []
      )
      assert grid.options.autofit_type == :none
    end
  end

  describe "Dynamic Freeze" do
    test "set_frozen_columns changes frozen count" do
      grid = Grid.new(
        columns: [%{field: :a, label: "A"}, %{field: :b, label: "B"}, %{field: :c, label: "C"}],
        data: []
      )
      updated = Grid.set_frozen_columns(grid, 2)
      assert updated.options.frozen_columns == 2
    end

    test "set_frozen_columns caps at column count" do
      grid = Grid.new(
        columns: [%{field: :a, label: "A"}, %{field: :b, label: "B"}],
        data: []
      )
      updated = Grid.set_frozen_columns(grid, 5)
      assert updated.options.frozen_columns == 2
    end

    test "set_frozen_columns to 0 unfreezes" do
      grid = Grid.new(
        columns: [%{field: :a, label: "A"}],
        data: [],
        options: %{frozen_columns: 1}
      )
      updated = Grid.set_frozen_columns(grid, 0)
      assert updated.options.frozen_columns == 0
    end
  end

  describe "Dataset Merge (append_data)" do
    test "append_data adds rows to end of data" do
      grid = Grid.new(
        columns: [%{field: :name, label: "Name"}],
        data: [%{id: 1, name: "A"}]
      )
      updated = Grid.append_data(grid, [%{id: 2, name: "B"}, %{id: 3, name: "C"}])
      assert length(updated.data) == 3
      assert Enum.at(updated.data, 2).name == "C"
    end

    test "append_data with empty list returns unchanged" do
      grid = Grid.new(
        columns: [%{field: :name, label: "Name"}],
        data: [%{id: 1, name: "A"}]
      )
      updated = Grid.append_data(grid, [])
      assert updated.data == grid.data
    end
  end

  # ========================================
  # Phase v0.11 — 핵심 UX 보완 기능 테스트
  # ========================================

  describe "FA-001: Row Pinning" do
    setup do
      data = [
        %{id: 1, name: "Alice"},
        %{id: 2, name: "Bob"},
        %{id: 3, name: "Charlie"}
      ]

      grid = Grid.new(data: data, columns: [%{field: :name, label: "Name"}])
      %{grid: grid}
    end

    test "pin_rows/3 pins rows to top", %{grid: grid} do
      updated = Grid.pin_rows(grid, [1], :top)
      assert updated.state.pinned_top_ids == [1]
      assert updated.state.pinned_bottom_ids == []
    end

    test "pin_rows/3 pins rows to bottom", %{grid: grid} do
      updated = Grid.pin_rows(grid, [2], :bottom)
      assert updated.state.pinned_bottom_ids == [2]
      assert updated.state.pinned_top_ids == []
    end

    test "pin_rows/3 moves row from bottom to top", %{grid: grid} do
      updated = grid
        |> Grid.pin_rows([1], :bottom)
        |> Grid.pin_rows([1], :top)
      assert 1 in updated.state.pinned_top_ids
      refute 1 in updated.state.pinned_bottom_ids
    end

    test "pin_rows/3 deduplicates ids", %{grid: grid} do
      updated = grid
        |> Grid.pin_rows([1], :top)
        |> Grid.pin_rows([1], :top)
      assert updated.state.pinned_top_ids == [1]
    end

    test "unpin_rows/2 removes pinned rows", %{grid: grid} do
      updated = grid
        |> Grid.pin_rows([1, 2], :top)
        |> Grid.unpin_rows([1])
      assert updated.state.pinned_top_ids == [2]
    end

    test "unpin_rows/2 removes from both top and bottom", %{grid: grid} do
      updated = grid
        |> Grid.pin_rows([1], :top)
        |> Grid.pin_rows([2], :bottom)
        |> Grid.unpin_rows([1, 2])
      assert updated.state.pinned_top_ids == []
      assert updated.state.pinned_bottom_ids == []
    end

    test "pinned_top_rows/1 returns matching rows", %{grid: grid} do
      updated = Grid.pin_rows(grid, [1, 3], :top)
      rows = Grid.pinned_top_rows(updated)
      assert length(rows) == 2
      assert Enum.any?(rows, &(&1.id == 1))
      assert Enum.any?(rows, &(&1.id == 3))
    end

    test "pinned_bottom_rows/1 returns matching rows", %{grid: grid} do
      updated = Grid.pin_rows(grid, [2], :bottom)
      rows = Grid.pinned_bottom_rows(updated)
      assert length(rows) == 1
      assert hd(rows).id == 2
    end

    test "pinned_top_rows/1 returns [] when empty", %{grid: grid} do
      assert Grid.pinned_top_rows(grid) == []
    end

    test "pinned_bottom_rows/1 returns [] when empty", %{grid: grid} do
      assert Grid.pinned_bottom_rows(grid) == []
    end

    test "pinned?/2 returns :top for top-pinned row", %{grid: grid} do
      updated = Grid.pin_rows(grid, [1], :top)
      assert Grid.pinned?(updated, 1) == :top
    end

    test "pinned?/2 returns :bottom for bottom-pinned row", %{grid: grid} do
      updated = Grid.pin_rows(grid, [2], :bottom)
      assert Grid.pinned?(updated, 2) == :bottom
    end

    test "pinned?/2 returns false for unpinned row", %{grid: grid} do
      assert Grid.pinned?(grid, 1) == false
    end
  end

  describe "FA-005: Overlay System" do
    setup do
      grid = Grid.new(data: [%{id: 1, name: "A"}], columns: [%{field: :name, label: "Name"}])
      %{grid: grid}
    end

    test "set_overlay/3 sets loading overlay", %{grid: grid} do
      updated = Grid.set_overlay(grid, :loading)
      assert updated.state.overlay.type == :loading
      assert updated.state.overlay.message == nil
    end

    test "set_overlay/3 sets loading overlay with message", %{grid: grid} do
      updated = Grid.set_overlay(grid, :loading, "불러오는 중...")
      assert updated.state.overlay.type == :loading
      assert updated.state.overlay.message == "불러오는 중..."
    end

    test "set_overlay/3 sets no_data overlay", %{grid: grid} do
      updated = Grid.set_overlay(grid, :no_data, "데이터 없음")
      assert updated.state.overlay.type == :no_data
      assert updated.state.overlay.message == "데이터 없음"
    end

    test "set_overlay/3 sets error overlay", %{grid: grid} do
      updated = Grid.set_overlay(grid, :error, "서버 오류")
      assert updated.state.overlay.type == :error
      assert updated.state.overlay.message == "서버 오류"
    end

    test "set_overlay/3 with nil clears overlay", %{grid: grid} do
      updated = grid
        |> Grid.set_overlay(:loading)
        |> Grid.set_overlay(nil)
      assert updated.state.overlay == nil
    end

    test "clear_overlay/1 clears overlay", %{grid: grid} do
      updated = grid
        |> Grid.set_overlay(:error, "오류")
        |> Grid.clear_overlay()
      assert updated.state.overlay == nil
    end

    test "initial state has nil overlay", %{grid: grid} do
      assert grid.state.overlay == nil
    end
  end

  describe "FA-004: Status Bar option" do
    test "default show_status_bar is false" do
      grid = Grid.new(data: [%{id: 1, name: "A"}], columns: [%{field: :name, label: "Name"}])
      assert grid.options.show_status_bar == false
    end

    test "show_status_bar can be enabled" do
      grid = Grid.new(
        data: [%{id: 1, name: "A"}],
        columns: [%{field: :name, label: "Name"}],
        options: %{show_status_bar: true}
      )
      assert grid.options.show_status_bar == true
    end
  end

  describe "FA-020: Cell Text Selection column option" do
    test "default text_selectable is false" do
      grid = Grid.new(data: [%{id: 1, name: "A"}], columns: [%{field: :name, label: "Name"}])
      col = hd(grid.columns)
      assert col.text_selectable == false
    end

    test "text_selectable can be enabled" do
      grid = Grid.new(
        data: [%{id: 1, name: "A"}],
        columns: [%{field: :name, label: "Name", text_selectable: true}]
      )
      col = hd(grid.columns)
      assert col.text_selectable == true
    end
  end

  describe "FA-022: Resize Lock column option" do
    test "default resizable is true" do
      grid = Grid.new(data: [%{id: 1, name: "A"}], columns: [%{field: :name, label: "Name"}])
      col = hd(grid.columns)
      assert col.resizable == true
    end

    test "resizable can be disabled" do
      grid = Grid.new(
        data: [%{id: 1, name: "A"}],
        columns: [%{field: :name, label: "Name", resizable: false}]
      )
      col = hd(grid.columns)
      assert col.resizable == false
    end
  end

  # ── Phase 2 (v0.12) Tests ──

  describe "FA-011: Floating Filter option" do
    test "default floating_filter is false" do
      grid = Grid.new(data: [%{id: 1, name: "A"}], columns: [%{field: :name, label: "Name"}])
      assert grid.options.floating_filter == false
    end

    test "floating_filter can be enabled globally" do
      grid = Grid.new(
        data: [%{id: 1, name: "A"}],
        columns: [%{field: :name, label: "Name"}],
        options: %{floating_filter: true}
      )
      assert grid.options.floating_filter == true
    end

    test "per-column floating_filter defaults to true" do
      grid = Grid.new(
        data: [%{id: 1, name: "A"}],
        columns: [%{field: :name, label: "Name"}]
      )
      col = hd(grid.columns)
      assert col.floating_filter == true
    end

    test "per-column floating_filter can be disabled" do
      grid = Grid.new(
        data: [%{id: 1, name: "A"}],
        columns: [%{field: :name, label: "Name", floating_filter: false}]
      )
      col = hd(grid.columns)
      assert col.floating_filter == false
    end

    test "floating_filter with filterable columns shows filter row" do
      alias LiveviewGridWeb.GridComponent.RenderHelpers
      grid = Grid.new(
        data: [%{id: 1, name: "A"}],
        columns: [%{field: :name, label: "Name", filterable: true}],
        options: %{floating_filter: true}
      )
      assert RenderHelpers.show_filter_row?(grid) == true
    end

    test "floating_filter without filterable columns hides filter row" do
      alias LiveviewGridWeb.GridComponent.RenderHelpers
      grid = Grid.new(
        data: [%{id: 1, name: "A"}],
        columns: [%{field: :name, label: "Name", filterable: false}],
        options: %{floating_filter: true}
      )
      assert RenderHelpers.show_filter_row?(grid) == false
    end
  end

  describe "FA-010: Column Menu - hide/show columns" do
    setup do
      data = [%{id: 1, name: "Alice", age: 30, city: "서울"}]
      columns = [
        %{field: :name, label: "Name"},
        %{field: :age, label: "Age"},
        %{field: :city, label: "City"}
      ]
      grid = Grid.new(data: data, columns: columns)
      %{grid: grid}
    end

    test "initial hidden_columns is empty", %{grid: grid} do
      assert grid.state.hidden_columns == []
    end

    test "hide_column adds field to hidden_columns", %{grid: grid} do
      grid = Grid.hide_column(grid, :age)
      assert :age in grid.state.hidden_columns
    end

    test "hide_column does not duplicate", %{grid: grid} do
      grid = grid |> Grid.hide_column(:age) |> Grid.hide_column(:age)
      assert Enum.count(grid.state.hidden_columns, &(&1 == :age)) == 1
    end

    test "show_column removes field from hidden_columns", %{grid: grid} do
      grid = grid |> Grid.hide_column(:age) |> Grid.show_column(:age)
      assert :age not in grid.state.hidden_columns
    end

    test "display_columns excludes hidden columns", %{grid: grid} do
      grid = Grid.hide_column(grid, :age)
      display = Grid.display_columns(grid)
      fields = Enum.map(display, & &1.field)
      assert :name in fields
      assert :age not in fields
      assert :city in fields
    end

    test "hidden_columns/1 returns hidden field list", %{grid: grid} do
      grid = grid |> Grid.hide_column(:name) |> Grid.hide_column(:city)
      hidden = Grid.hidden_columns(grid)
      assert :name in hidden
      assert :city in hidden
      assert :age not in hidden
    end
  end

  describe "FA-019: Date Editor column config" do
    test "editor_type :date is preserved in column" do
      grid = Grid.new(
        data: [%{id: 1, joined: ~D[2025-01-15]}],
        columns: [%{field: :joined, label: "Joined", editor_type: :date, editable: true}]
      )
      col = hd(grid.columns)
      assert col.editor_type == :date
      assert col.editable == true
    end

    test "editor_input_type returns date for date editor" do
      alias LiveviewGridWeb.GridComponent.RenderHelpers
      assert RenderHelpers.editor_input_type(%{editor_type: :date}) == "date"
    end

    test "format_date_for_input with Date struct" do
      alias LiveviewGridWeb.GridComponent.RenderHelpers
      assert RenderHelpers.format_date_for_input(~D[2025-03-15]) == "2025-03-15"
    end

    test "parse_date_value with ISO string" do
      alias LiveviewGridWeb.GridComponent.RenderHelpers
      assert RenderHelpers.parse_date_value("2025-03-15") == ~D[2025-03-15]
    end

    test "parse_date_value with empty string returns nil" do
      alias LiveviewGridWeb.GridComponent.RenderHelpers
      assert RenderHelpers.parse_date_value("") == nil
    end
  end

  # ========================================
  # FA-016: Column State Save/Restore
  # ========================================
  describe "FA-016: export_column_state/1 and import_column_state/2" do
    setup do
      columns = [
        %{field: :id, label: "ID"},
        %{field: :name, label: "Name"},
        %{field: :email, label: "Email"},
        %{field: :age, label: "Age"}
      ]
      grid = Grid.new(data: [], columns: columns)
      %{grid: grid}
    end

    test "export_column_state returns empty defaults", %{grid: grid} do
      state = Grid.export_column_state(grid)
      assert state.column_widths == %{}
      assert state.column_order == nil
      assert state.hidden_columns == []
    end

    test "export_column_state captures widths and order", %{grid: grid} do
      grid = grid
        |> Grid.resize_column(:name, 200)
        |> Grid.resize_column(:email, 300)
        |> Grid.reorder_columns([:email, :name, :id, :age])

      state = Grid.export_column_state(grid)
      assert state.column_widths == %{name: 200, email: 300}
      assert state.column_order == [:email, :name, :id, :age]
    end

    test "import_column_state round-trip preserves state", %{grid: grid} do
      grid = grid
        |> Grid.resize_column(:name, 150)
        |> Grid.reorder_columns([:age, :email, :name, :id])

      exported = Grid.export_column_state(grid)
      fresh_grid = Grid.new(data: [], columns: [
        %{field: :id, label: "ID"},
        %{field: :name, label: "Name"},
        %{field: :email, label: "Email"},
        %{field: :age, label: "Age"}
      ])

      restored = Grid.import_column_state(fresh_grid, exported)
      assert restored.state.column_widths == %{name: 150}
      assert restored.state.column_order == [:age, :email, :name, :id]
    end

    test "import_column_state filters out invalid fields", %{grid: grid} do
      invalid_state = %{
        column_widths: %{name: 200, nonexistent: 100},
        column_order: [:email, :nonexistent, :name, :id, :age],
        hidden_columns: [:age, :invalid_field]
      }

      restored = Grid.import_column_state(grid, invalid_state)
      assert restored.state.column_widths == %{name: 200}
      assert :nonexistent not in restored.state.column_order
      assert restored.state.hidden_columns == [:age]
    end

    test "import_column_state handles nil column_order" do
      grid = Grid.new(data: [], columns: [%{field: :name, label: "Name"}])
      restored = Grid.import_column_state(grid, %{column_order: nil, column_widths: %{}, hidden_columns: []})
      assert restored.state.column_order == nil
    end
  end

  # ========================================
  # FA-044: Find & Highlight
  # ========================================
  describe "FA-044: find_matches/2" do
    setup do
      data = [
        %{id: 1, name: "Alice", email: "alice@test.com", city: "Seoul"},
        %{id: 2, name: "Bob", email: "bob@test.com", city: "Busan"},
        %{id: 3, name: "Charlie", email: "charlie@test.com", city: "Seoul"},
        %{id: 4, name: "alice_lower", email: "al@test.com", city: "Daegu"}
      ]
      columns = [
        %{field: :name, label: "Name", sortable: true},
        %{field: :email, label: "Email"},
        %{field: :city, label: "City"}
      ]
      grid = Grid.new(data: data, columns: columns, options: %{page_size: 100})
      %{grid: grid}
    end

    test "empty search returns empty list", %{grid: grid} do
      assert Grid.find_matches(grid, "") == []
      assert Grid.find_matches(grid, nil) == []
    end

    test "finds case-insensitive matches", %{grid: grid} do
      matches = Grid.find_matches(grid, "alice")
      assert length(matches) >= 2
      assert {1, :name} in matches
      assert {4, :name} in matches
    end

    test "finds matches across multiple columns", %{grid: grid} do
      matches = Grid.find_matches(grid, "Seoul")
      assert {1, :city} in matches
      assert {3, :city} in matches
    end

    test "no matches for non-existent text", %{grid: grid} do
      assert Grid.find_matches(grid, "zzzznonexistent") == []
    end

    test "partial text match works", %{grid: grid} do
      matches = Grid.find_matches(grid, "bob")
      assert {2, :name} in matches
      assert {2, :email} in matches
    end

    test "find state defaults in initial_state" do
      grid = Grid.new(data: [], columns: [%{field: :name, label: "Name"}])
      assert grid.state[:find_text] == ""
      assert grid.state[:find_matches] == []
      assert grid.state[:find_current_index] == 0
      assert grid.state[:show_find_bar] == false
    end
  end

  # ========================================
  # FA-037: Column Hover Highlight
  # ========================================
  describe "FA-037: column_hover_highlight option" do
    test "column_hover_highlight defaults to false" do
      grid = Grid.new(data: [], columns: [%{field: :name, label: "Name"}])
      assert grid.options[:column_hover_highlight] == false
    end

    test "column_hover_highlight can be enabled" do
      grid = Grid.new(
        data: [],
        columns: [%{field: :name, label: "Name"}],
        options: %{column_hover_highlight: true}
      )
      assert grid.options[:column_hover_highlight] == true
    end
  end

  # ========================================
  # FA-035: Rich Select Editor
  # ========================================
  describe "FA-035: rich_select editor_type" do
    test "column with editor_type :rich_select is normalized" do
      columns = [
        %{field: :status, label: "Status", editable: true,
          editor_type: :rich_select,
          editor_options: [{"Active", "active"}, {"Inactive", "inactive"}]}
      ]
      grid = Grid.new(data: [%{id: 1, status: "active"}], columns: columns)
      [col] = grid.columns
      assert col.editor_type == :rich_select
      assert col.editor_options == [{"Active", "active"}, {"Inactive", "inactive"}]
    end

    test "default editor_type is :text" do
      grid = Grid.new(data: [], columns: [%{field: :name, label: "Name"}])
      [col] = grid.columns
      assert col.editor_type == :text
    end

    test "state_persistence defaults to false" do
      grid = Grid.new(data: [], columns: [%{field: :name, label: "Name"}])
      assert grid.options[:state_persistence] == false
    end
  end
end
