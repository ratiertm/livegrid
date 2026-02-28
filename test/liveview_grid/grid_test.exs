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
end
