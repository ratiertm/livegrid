# Cell Merge Design (F-904)

> **Plan Reference**: `docs/01-plan/features/cell-merge.plan.md`
> **Status**: Design
> **Implementation Steps**: 8

---

## Implementation Steps

### Step 1: state에 merge_regions 추가

**파일**: `lib/liveview_grid/grid.ex` (`initial_state/0`, ~line 1185)

`initial_state/0`의 반환 맵에 `merge_regions` 키를 추가합니다:

```elixir
defp initial_state do
  %{
    # ... 기존 필드들 ...
    cell_range: nil,
    # F-904: Cell Merge
    merge_regions: %{}
  }
end
```

`merge_regions`는 `%{{row_id, field} => %{rowspan: integer, colspan: integer}}` 형태의 맵입니다.

---

### Step 2: merge_cells/2 공개 API

**파일**: `lib/liveview_grid/grid.ex` (summary_data/1 이후, ~line 305)

셀 병합 영역을 등록하는 API를 추가합니다:

```elixir
@doc """
셀 병합 영역을 등록합니다.

## Parameters
- grid: Grid 맵
- merge_spec: %{row_id: any, col_field: atom, rowspan: integer, colspan: integer}

## Returns
- {:ok, grid} 또는 {:error, reason}
"""
@spec merge_cells(grid :: t(), merge_spec :: map()) :: {:ok, t()} | {:error, String.t()}
def merge_cells(grid, %{row_id: row_id, col_field: col_field} = spec) do
  rowspan = Map.get(spec, :rowspan, 1)
  colspan = Map.get(spec, :colspan, 1)

  if rowspan < 1 or colspan < 1 do
    {:error, "rowspan and colspan must be >= 1"}
  else
    display_cols = display_columns(grid)
    col_fields = Enum.map(display_cols, & &1.field)
    col_start_idx = Enum.find_index(col_fields, &(&1 == col_field))

    cond do
      is_nil(col_start_idx) ->
        {:error, "column #{col_field} not found"}

      col_start_idx + colspan > length(col_fields) ->
        {:error, "colspan exceeds column count"}

      has_merge_overlap?(grid, row_id, col_field, rowspan, colspan) ->
        {:error, "merge region overlaps with existing merge"}

      frozen_boundary_crossed?(grid, col_start_idx, colspan) ->
        {:error, "merge cannot cross frozen column boundary"}

      true ->
        region = %{rowspan: rowspan, colspan: colspan}
        new_regions = Map.put(grid.state.merge_regions, {row_id, col_field}, region)
        {:ok, put_in(grid.state.merge_regions, new_regions)}
    end
  end
end
```

---

### Step 3: unmerge_cells/3, clear_all_merges/1, 조회 API

**파일**: `lib/liveview_grid/grid.ex` (merge_cells/2 이후)

```elixir
@doc "특정 셀 병합을 해제합니다."
@spec unmerge_cells(grid :: t(), row_id :: any(), col_field :: atom()) :: t()
def unmerge_cells(grid, row_id, col_field) do
  new_regions = Map.delete(grid.state.merge_regions, {row_id, col_field})
  put_in(grid.state.merge_regions, new_regions)
end

@doc "모든 병합을 해제합니다."
@spec clear_all_merges(grid :: t()) :: t()
def clear_all_merges(grid) do
  put_in(grid.state.merge_regions, %{})
end

@doc "전체 병합 영역 목록을 반환합니다."
@spec merge_regions(grid :: t()) :: map()
def merge_regions(grid), do: grid.state.merge_regions

@doc "특정 셀이 병합(원점 또는 피병합)에 포함되는지 확인합니다."
@spec merged?(grid :: t(), row_id :: any(), col_field :: atom()) :: boolean()
def merged?(grid, row_id, col_field) do
  Map.has_key?(grid.state.merge_regions, {row_id, col_field}) or
    merge_origin(grid, row_id, col_field) != nil
end

@doc """
특정 셀이 다른 병합에 의해 가려지는 경우 원점 셀 정보를 반환합니다.
병합 원점이면 nil, 가려지는 셀이면 {:origin, row_id, col_field}를 반환합니다.
"""
@spec merge_origin(grid :: t(), row_id :: any(), col_field :: atom()) :: nil | {:origin, any(), atom()}
def merge_origin(grid, row_id, col_field) do
  skip_map = build_merge_skip_map(grid)
  Map.get(skip_map, {row_id, col_field})
end
```

---

### Step 4: 병합 검증 및 skip 맵 빌드 private 함수

**파일**: `lib/liveview_grid/grid.ex` (private functions 영역)

```elixir
# F-904: 병합 영역 겹침 검사
defp has_merge_overlap?(grid, new_row_id, new_col_field, new_rowspan, new_colspan) do
  display_cols = display_columns(grid)
  col_fields = Enum.map(display_cols, & &1.field)
  visible = visible_data_ids(grid)

  new_col_idx = Enum.find_index(col_fields, &(&1 == new_col_field)) || 0
  new_row_idx = Enum.find_index(visible, &(&1 == new_row_id)) || 0

  new_cells = for r <- new_row_idx..(new_row_idx + new_rowspan - 1),
                  c <- new_col_idx..(new_col_idx + new_colspan - 1),
                  into: MapSet.new() do
    {r, c}
  end

  Enum.any?(grid.state.merge_regions, fn {{origin_row_id, origin_col_field}, %{rowspan: rs, colspan: cs}} ->
    # 자기 자신은 제외
    if origin_row_id == new_row_id and origin_col_field == new_col_field do
      false
    else
      origin_col_idx = Enum.find_index(col_fields, &(&1 == origin_col_field)) || 0
      origin_row_idx = Enum.find_index(visible, &(&1 == origin_row_id)) || 0

      existing_cells = for r <- origin_row_idx..(origin_row_idx + rs - 1),
                           c <- origin_col_idx..(origin_col_idx + cs - 1),
                           into: MapSet.new() do
        {r, c}
      end

      MapSet.size(MapSet.intersection(new_cells, existing_cells)) > 0
    end
  end)
end

# F-904: frozen 컬럼 경계 초과 검사
defp frozen_boundary_crossed?(grid, col_start_idx, colspan) do
  frozen = grid.options.frozen_columns
  if frozen > 0 do
    col_end_idx = col_start_idx + colspan - 1
    # 시작이 frozen 내부이면서 끝이 frozen 바깥인 경우
    (col_start_idx < frozen and col_end_idx >= frozen) or
    # 시작이 frozen 바깥이면서 끝이 frozen 내부인 경우 (불가능하지만 안전장치)
    (col_start_idx >= frozen and col_end_idx < frozen and col_start_idx != col_end_idx)
  else
    false
  end
end

# F-904: visible 데이터의 row_id 목록 (merge 위치 계산용)
defp visible_data_ids(grid) do
  grid
  |> visible_data()
  |> Enum.map(&Map.get(&1, :id))
end

@doc false
# F-904: 렌더링 시 skip해야 할 셀 맵을 빌드합니다.
# 반환: %{{row_id, field} => {:origin, origin_row_id, origin_col_field}}
def build_merge_skip_map(grid) do
  display_cols = display_columns(grid)
  col_fields = Enum.map(display_cols, & &1.field)
  visible = visible_data(grid)
  row_ids = Enum.map(visible, &Map.get(&1, :id))

  Enum.reduce(grid.state.merge_regions, %{}, fn {{origin_row_id, origin_col_field}, %{rowspan: rs, colspan: cs}}, acc ->
    origin_col_idx = Enum.find_index(col_fields, &(&1 == origin_col_field))
    origin_row_idx = Enum.find_index(row_ids, &(&1 == origin_row_id))

    if is_nil(origin_col_idx) or is_nil(origin_row_idx) do
      acc
    else
      # 병합 영역의 모든 셀 (원점 제외)을 skip 맵에 추가
      for r_offset <- 0..(rs - 1),
          c_offset <- 0..(cs - 1),
          not (r_offset == 0 and c_offset == 0),
          r_idx = origin_row_idx + r_offset,
          c_idx = origin_col_idx + c_offset,
          r_idx < length(row_ids),
          c_idx < length(col_fields),
          reduce: acc do
        inner_acc ->
          target_row_id = Enum.at(row_ids, r_idx)
          target_col_field = Enum.at(col_fields, c_idx)
          Map.put(inner_acc, {target_row_id, target_col_field}, {:origin, origin_row_id, origin_col_field})
      end
    end
  end)
end
```

---

### Step 5: RenderHelpers에 merge 헬퍼 함수 추가

**파일**: `lib/liveview_grid_web/components/grid_component/render_helpers.ex`

```elixir
# ── Cell Merge (F-904) ──

@doc "셀이 merge skip 대상인지 확인합니다."
@spec merge_skip?(merge_skip_map :: map(), row_id :: any(), col_field :: atom()) :: boolean()
def merge_skip?(merge_skip_map, row_id, col_field) do
  Map.has_key?(merge_skip_map, {row_id, col_field})
end

@doc "셀이 merge 원점인지 확인하고, 원점이면 {rowspan, colspan}를 반환합니다."
@spec merge_span(merge_regions :: map(), row_id :: any(), col_field :: atom()) :: nil | {integer(), integer()}
def merge_span(merge_regions, row_id, col_field) do
  case Map.get(merge_regions, {row_id, col_field}) do
    %{rowspan: rs, colspan: cs} when rs > 1 or cs > 1 -> {rs, cs}
    _ -> nil
  end
end

@doc """
colspan에 대한 합산 너비 스타일을 계산합니다.
병합 시작 컬럼부터 colspan개 컬럼의 너비를 합산합니다.
"""
@spec merged_width_style(grid :: map(), col_field :: atom(), colspan :: integer()) :: String.t()
def merged_width_style(grid, col_field, colspan) when colspan > 1 do
  display_cols = Grid.display_columns(grid)
  col_fields = Enum.map(display_cols, & &1.field)
  start_idx = Enum.find_index(col_fields, &(&1 == col_field)) || 0

  target_cols = Enum.slice(display_cols, start_idx, colspan)

  {total_px, auto_count} = Enum.reduce(target_cols, {0, 0}, fn col, {px, auto} ->
    w = Map.get(grid.state.column_widths, col.field)
    cond do
      w != nil -> {px + w, auto}
      col.width == :auto -> {px, auto + 1}
      true -> {px + col.width, auto}
    end
  end)

  # border 너비 보정: (colspan - 1)개의 border 포함
  border_px = colspan - 1

  if auto_count > 0 do
    "flex: #{auto_count} 1 #{total_px + border_px}px"
  else
    "width: #{total_px + border_px}px; flex: 0 0 #{total_px + border_px}px"
  end
end
def merged_width_style(_grid, _col_field, _colspan), do: nil

@doc "rowspan에 대한 높이 스타일을 계산합니다."
@spec merged_height_style(grid :: map(), rowspan :: integer()) :: String.t()
def merged_height_style(grid, rowspan) when rowspan > 1 do
  row_h = Map.get(grid.options, :row_height, 40)
  # border 높이 보정: (rowspan - 1)개의 border 포함
  total_h = row_h * rowspan + (rowspan - 1)
  "height: #{total_h}px; position: relative; z-index: 1;"
end
def merged_height_style(_grid, _rowspan), do: nil
```

---

### Step 6: grid_component.ex 렌더링에 merge 로직 적용

**파일**: `lib/liveview_grid_web/components/grid_component.ex` (기본 Body, ~line 905-1010)

기본 Body 렌더링의 데이터 Row 루프를 수정합니다.

**6a. Body 시작 부분에 merge 데이터 준비** (~line 906 직후):

```elixir
<% p_data = Grid.visible_data(@grid) %>
<% merge_skip_map = Grid.build_merge_skip_map(@grid) %>
<% merge_regions = @grid.state.merge_regions %>
```

**6b. 컬럼 루프 내 셀 렌더링 변경** (~line 988-1006):

각 셀에 대해 merge 검사를 수행합니다:

```heex
<%= for {column, col_idx} <- Enum.with_index(Grid.display_columns(@grid)) do %>
  <%= if not merge_skip?(merge_skip_map, row.id, column.field) do %>
    <% span = merge_span(merge_regions, row.id, column.field) %>
    <% {rs, cs} = if span, do: span, else: {1, 1} %>
    <% width_style = if cs > 1,
         do: merged_width_style(@grid, column.field, cs),
         else: column_width_style(column, @grid) %>
    <% height_style = if rs > 1,
         do: merged_height_style(@grid, rs),
         else: nil %>
    <div
      class={"lv-grid__cell #{frozen_class(col_idx, @grid)} #{if cell_in_range?(@grid.state.cell_range, row.id, col_idx, p_row_id_to_pos), do: "lv-grid__cell--in-range"} #{if Map.get(column, :filter_type) == :number, do: "lv-grid__cell--numeric"} #{if span, do: "lv-grid__cell--merged"}"}
      style={"#{width_style}; #{frozen_style(col_idx, @grid)}; #{tree_indent_style(row, col_idx)}; #{height_style || ""}"}
      data-col-index={col_idx}
      data-merge-rowspan={if rs > 1, do: rs}
      data-merge-colspan={if cs > 1, do: cs}
    >
      <%= if col_idx == 0 && Map.has_key?(row, :_tree_has_children) do %>
        <!-- tree toggle (기존 코드 유지) -->
      <% end %>
      <%= render_cell(assigns, row, column) %>
    </div>
  <% end %>
<% end %>
```

핵심 변경:
1. `merge_skip?`로 가려지는 셀은 렌더링 건너뛰기
2. `merge_span`으로 원점 셀의 rowspan/colspan 확인
3. colspan > 1이면 `merged_width_style`로 합산 너비 적용
4. rowspan > 1이면 `merged_height_style`로 높이 확장
5. `.lv-grid__cell--merged` CSS 클래스 추가

---

### Step 7: CSS 스타일 추가

**파일**: `assets/css/grid/body.css` (파일 끝에 추가)

```css
/* 5.11 Cell Merge (F-904) */
.lv-grid__cell--merged {
  overflow: visible;
  z-index: 1;
  background: var(--lv-grid-bg);
}

.lv-grid__row:hover .lv-grid__cell--merged {
  background: var(--lv-grid-hover);
}

.lv-grid__row--selected .lv-grid__cell--merged {
  background: var(--lv-grid-selected);
}
```

---

### Step 8: 테스트 작성

**파일**: `test/liveview_grid/grid_test.exs`

```elixir
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
    assert Grid.merged?(grid, 1, :email) == true  # covered by merge
    assert Grid.merged?(grid, 1, :age) == false    # not in merge
  end

  test "build_merge_skip_map/1 generates skip entries", %{grid: grid} do
    {:ok, grid} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, colspan: 2})
    skip_map = Grid.build_merge_skip_map(grid)
    assert Map.has_key?(skip_map, {1, :email})
    refute Map.has_key?(skip_map, {1, :name})  # origin is not skipped
  end

  test "frozen boundary merge is rejected", %{grid: grid} do
    grid = %{grid | options: Map.put(grid.options, :frozen_columns, 1)}
    # name(idx=0)은 frozen, email(idx=1)은 non-frozen → 경계 초과
    assert {:error, _msg} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, colspan: 2})
  end
end
```

---

## Verification Checklist

- [ ] `mix compile --warnings-as-errors` 통과
- [ ] `mix test` 전체 통과 (기존 434 + 신규 ~10)
- [ ] colspan 병합 셀이 올바른 너비로 렌더링됨
- [ ] rowspan 병합 셀이 올바른 높이로 렌더링됨
- [ ] 겹치는 병합 영역 등록 시 에러 반환
- [ ] frozen 경계 초과 병합 시 에러 반환
- [ ] 병합 해제/전체 해제 정상 동작
- [ ] 데모 페이지에서 병합 셀 시각적 확인

## Implementation Order

1. Step 1 → state 구조 변경 (기반)
2. Step 2 → merge_cells API (핵심)
3. Step 3 → unmerge/clear/조회 API
4. Step 4 → 검증 및 skip 맵 빌드 (렌더링 전 필수)
5. Step 5 → RenderHelpers (렌더링 헬퍼)
6. Step 6 → grid_component.ex 렌더링 수정
7. Step 7 → CSS 스타일
8. Step 8 → 테스트
