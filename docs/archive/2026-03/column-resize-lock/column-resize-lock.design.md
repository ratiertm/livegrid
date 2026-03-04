# F-914 컬럼 리사이즈 제한 — 기술 설계서

> **Feature ID**: F-914
> **Version**: v0.12.0
> **Created**: 2026-03-05

---

## Step 1: 컬럼 기본값에 `resizable` 추가

**파일**: `lib/liveview_grid/grid.ex` — `normalize_columns/1`

```elixir
# Line ~1339 Map.merge 블록에 추가
defp normalize_columns(columns) do
  Enum.map(columns, fn col ->
    Map.merge(%{
      type: :string,
      width: :auto,
      sortable: false,
      filterable: false,
      filter_type: :text,
      editable: false,
      editor_type: :text,
      editor_options: [],
      validators: [],
      input_pattern: nil,
      renderer: nil,
      formatter: nil,
      formatter_options: %{},
      align: :left,
      style_expr: nil,
      header_group: nil,
      nulls: :last,
      required: false,
      summary: nil,
      resizable: true       # ← 추가 (기본: 리사이즈 허용)
    }, col)
  end)
end
```

**검증**: `resizable` 키가 없는 기존 컬럼은 자동으로 `true` 적용.

---

## Step 2: `Grid.resize_column/3` 서버 사이드 가드

**파일**: `lib/liveview_grid/grid.ex` — `resize_column/3`

```elixir
@doc """
컬럼 너비를 업데이트합니다. 최소 50px. resizable: false 컬럼은 무시.
"""
@spec resize_column(grid :: t(), field :: atom(), width :: pos_integer()) :: t()
def resize_column(grid, field, width) when is_atom(field) and is_integer(width) and width >= 50 do
  column = Enum.find(grid.columns, &(&1.field == field))

  if column && Map.get(column, :resizable, true) do
    put_in(grid.state.column_widths, Map.put(grid.state.column_widths, field, width))
  else
    grid  # resizable: false → 변경 없이 반환
  end
end
```

**검증**: `resizable: false` 컬럼으로 resize 이벤트 전송 시 grid 상태 불변.

---

## Step 3: HEEx 리사이즈 핸들 조건부 렌더링

**파일**: `lib/liveview_grid_web/components/grid_component.ex` — 헤더 셀 (Line ~640)

```heex
<%# 기존: 항상 렌더링 %>
<span class="lv-grid__resize-handle" phx-hook="ColumnResize" ...></span>

<%# 변경: resizable 조건부 %>
<%= if Map.get(column, :resizable, true) do %>
  <span
    class="lv-grid__resize-handle"
    phx-hook="ColumnResize"
    id={"resize-#{column.field}"}
    data-col-index={col_idx}
    data-field={column.field}
  ></span>
<% end %>
```

**검증**: `resizable: false` 컬럼에서 `.lv-grid__resize-handle` DOM 미존재.

---

## Step 4: JS 훅 방어 코드 (column-resize.js)

**파일**: `assets/js/hooks/column-resize.js`

```javascript
// mounted() 내부 - handleMouseDown 시작 부분에 가드 추가
this.handleMouseDown = (e) => {
  // resizable 체크 (data 속성 기반 방어)
  const headerCell = this.el.parentElement
  if (headerCell && headerCell.dataset.resizable === "false") return

  e.preventDefault()
  e.stopPropagation()
  // ... 기존 코드
}

// handleDblClick도 동일 가드
this.handleDblClick = (e) => {
  const headerCell = this.el.parentElement
  if (headerCell && headerCell.dataset.resizable === "false") return

  e.preventDefault()
  e.stopPropagation()
  // ... 기존 코드
}
```

**참고**: Step 3에서 핸들 자체를 렌더링하지 않으므로 JS 가드는 보조 방어.
HEEx 헤더 셀에 `data-resizable` 속성 추가:

```heex
<div
  class={"lv-grid__header-cell ..."}
  data-resizable={to_string(Map.get(column, :resizable, true))}
  ...
>
```

---

## Step 5: 데모 페이지 적용

**파일**: `lib/liveview_grid_web/live/demo_live.ex`

ID 또는 Name 컬럼에 `resizable: false` 추가:

```elixir
%{field: :id, label: "ID", type: :integer, width: 60, sortable: true, resizable: false},
```

**검증**: 데모 페이지에서 ID 컬럼 리사이즈 핸들 미표시, 드래그 불가 확인.

---

## Step 6: 단위 테스트

**파일**: `test/liveview_grid/grid_test.exs`

```elixir
describe "resize_column/3 with resizable option" do
  test "resizable: true (기본값) 컬럼은 리사이즈 허용" do
    grid = Grid.new(columns: [%{field: :name, label: "Name"}], rows: [])
    updated = Grid.resize_column(grid, :name, 200)
    assert updated.state.column_widths[:name] == 200
  end

  test "resizable: false 컬럼은 리사이즈 차단" do
    grid = Grid.new(columns: [%{field: :id, label: "ID", resizable: false}], rows: [])
    updated = Grid.resize_column(grid, :id, 200)
    assert updated.state.column_widths[:id] == nil
  end

  test "resizable 키 미지정 시 기본값 true로 동작" do
    grid = Grid.new(columns: [%{field: :age, label: "Age"}], rows: [])
    assert Enum.find(grid.columns, &(&1.field == :age)).resizable == true
  end
end
```

**검증**: 3개 테스트 모두 통과.

---

## 변경 요약

| Step | 파일 | 변경 유형 | 라인 수 |
|------|------|----------|---------|
| 1 | grid.ex | normalize_columns 기본값 | +1 |
| 2 | grid.ex | resize_column 가드 | +5 |
| 3 | grid_component.ex | 핸들 조건부 렌더링 | +3 |
| 4 | column-resize.js | JS 방어 코드 | +4 |
| 5 | demo_live.ex | 데모 적용 | +1 |
| 6 | grid_test.exs | 테스트 추가 | +15 |
| **합계** | | | **~29줄** |
