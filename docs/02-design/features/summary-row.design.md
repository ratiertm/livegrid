# Summary Row Design 명세서

> **Feature**: F-950 Summary Row
> **Plan**: `docs/01-plan/features/summary-row.plan.md`
> **Status**: Design

---

## 1. 변경 파일 목록

| # | 파일 | 변경 유형 | 설명 |
|---|------|-----------|------|
| 1 | `lib/liveview_grid/grid.ex` | 수정 | normalize_columns에 summary 키 추가, summary_data/1 함수, default_options에 show_summary |
| 2 | `lib/liveview_grid_web/components/grid_component.ex` | 수정 | render_summary_row/1 추가, Body-Footer 사이 삽입 |
| 3 | `assets/css/grid/layout.css` | 수정 | Summary Row 스타일 추가 |
| 4 | `lib/liveview_grid_web/live/demo_live.ex` | 수정 | salary/age 컬럼에 summary 설정 |
| 5 | `test/liveview_grid/grid_test.exs` | 수정 | summary_data/1 테스트 추가 |

## 2. 상세 변경 명세

### Step 1: `grid.ex` — normalize_columns에 summary 키 추가

**위치**: `normalize_columns/1` (Line 1134-1157)

**변경**: 기본값 맵에 `summary: nil` 추가

```elixir
# 기존
Map.merge(%{
  type: :string,
  ...
  required: false
}, col)

# 변경 후
Map.merge(%{
  type: :string,
  ...
  required: false,
  summary: nil          # ← 추가: :sum | :avg | :count | :min | :max | nil
}, col)
```

### Step 2: `grid.ex` — default_options에 show_summary 추가

**위치**: `default_options/0` (Line 827-840)

**변경**: `show_summary: false` 추가

```elixir
def default_options do
  %{
    page_size: 20,
    show_header: true,
    show_footer: true,
    show_summary: false,    # ← 추가
    virtual_scroll: false,
    ...
  }
end
```

### Step 3: `grid.ex` — summary_data/1 공개 함수

**위치**: `filtered_count/1` 아래 (Line 286 부근)

**새 함수**:

```elixir
@doc """
Summary Row 집계 결과를 반환합니다.
컬럼에 summary가 지정된 필드만 집계합니다.
필터/검색 적용 후 데이터 기준.

## Returns
  - `%{field => value}` 맵 (summary 지정 컬럼만 포함)
  - summary 지정 컬럼이 없으면 빈 맵 `%{}`
"""
@spec summary_data(grid :: t()) :: map()
def summary_data(%{columns: columns} = grid) do
  aggregates =
    columns
    |> Enum.filter(& &1.summary)
    |> Map.new(& {&1.field, &1.summary})

  if map_size(aggregates) == 0 do
    %{}
  else
    data = filtered_data(grid)
    Grouping.compute_aggregates(data, aggregates)
  end
end
```

### Step 4: `grid.ex` — filtered_data/1 private 함수

**위치**: summary_data/1 바로 아래

**새 함수** (필터/검색 적용 후 전체 데이터, 페이지네이션 전):

```elixir
defp filtered_data(%{data_source: {_mod, _cfg}} = grid) do
  # DataSource 모드: grid.data에 이미 fetch된 데이터 사용
  grid.data
end
defp filtered_data(%{data: data, columns: columns, state: state}) do
  data
  |> apply_global_search(state.global_search, columns)
  |> apply_filters(state.filters, columns)
  |> apply_advanced_filters(state.advanced_filters, columns)
  |> ensure_new_rows_included(data, state.row_statuses)
end
```

### Step 5: `grid_component.ex` — has_summary?/1 헬퍼

**위치**: 기존 헬퍼 함수들 근처

```elixir
defp has_summary?(grid) do
  (grid.options.show_summary || Enum.any?(grid.columns, & &1.summary)) &&
    grid.options.show_footer
end
```

### Step 6: `grid_component.ex` — render_summary_row

**위치**: Body 렌더링 후, Footer 앞에 삽입

두 곳에 삽입 필요:
1. Virtual Scroll Body (`<div class="lv-grid__body--virtual">`) 닫힌 후
2. Pagination Body (일반 모드) 닫힌 후

```heex
<%= if has_summary?(@grid) do %>
  <div class="lv-grid__summary-row">
    <% summary = Grid.summary_data(@grid) %>
    <% display_cols = Grid.display_columns(@grid) %>

    <%!-- 행번호 컬럼 (show_row_number) --%>
    <%= if @grid.options.show_row_number do %>
      <div class="lv-grid__cell lv-grid__cell--row-number lv-grid__summary-cell" style="width: 50px; flex: 0 0 50px;">
      </div>
    <% end %>

    <%!-- 선택 체크박스 컬럼 --%>
    <div class="lv-grid__cell lv-grid__summary-cell" style="width: 90px; flex: 0 0 90px;">
    </div>

    <%!-- 데이터 컬럼 --%>
    <%= for col <- display_cols do %>
      <% width = Map.get(@grid.state.column_widths, col.field) %>
      <% value = Map.get(summary, col.field) %>
      <div
        class={"lv-grid__cell lv-grid__summary-cell #{if col.align == :right, do: "lv-grid__cell--right"} #{if col.align == :center, do: "lv-grid__cell--center"}"}
        style={if width, do: "width: #{width}px; flex: 0 0 #{width}px;", else: "flex: 1 1 0;"}
      >
        <%= if value do %>
          <span class="lv-grid__summary-value">
            <%= format_summary_number(value) %>
          </span>
        <% end %>
      </div>
    <% end %>
  </div>
<% end %>
```

### Step 7: `assets/css/grid/layout.css` — Summary Row 스타일

```css
/* F-950: Summary Row */
.lv-grid__summary-row {
  display: flex;
  border-top: 2px solid var(--lv-grid-border, #ddd);
  border-bottom: 1px solid var(--lv-grid-border, #ddd);
  background: var(--lv-grid-summary-bg, #f0f4f8);
  font-weight: 600;
  font-size: 13px;
  min-height: 36px;
  position: sticky;
  bottom: 0;
  z-index: 2;
}

.lv-grid__summary-cell {
  padding: 6px 8px;
  display: flex;
  align-items: center;
  border-right: 1px solid var(--lv-grid-border, #ddd);
}

.lv-grid__summary-cell:last-child {
  border-right: none;
}

.lv-grid__summary-value {
  color: var(--lv-grid-text, #333);
}
```

### Step 8: `demo_live.ex` — Summary 컬럼 설정

**변경**: 기존 컬럼 정의에 summary 키 추가

```elixir
# salary 컬럼
%{field: :salary, label: "급여", ..., summary: :sum}

# age 컬럼
%{field: :age, label: "나이", ..., summary: :avg}
```

### Step 9: 테스트 — summary_data/1

**파일**: `test/liveview_grid/grid_test.exs`

```elixir
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

    # Apply filter (name contains "A")
    filtered = put_in(grid.state.filters, %{name: "A"})
    result = Grid.summary_data(%{grid | state: filtered})
    # "Alice" only → salary = 100
    assert result.salary == 100
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
end
```

## 3. 구현 순서 (체크리스트)

- [ ] Step 1: normalize_columns에 `summary: nil` 추가
- [ ] Step 2: default_options에 `show_summary: false` 추가
- [ ] Step 3: `summary_data/1` 공개 함수 구현
- [ ] Step 4: `filtered_data/1` private 함수 구현
- [ ] Step 5: `has_summary?/1` 헬퍼 구현
- [ ] Step 6: Summary Row HEEx 렌더링 (virtual scroll + pagination 양쪽)
- [ ] Step 7: CSS 스타일 추가
- [ ] Step 8: demo_live.ex에 summary 설정 추가
- [ ] Step 9: 테스트 작성 및 실행

## 4. 검증 기준

- [ ] `mix compile --warnings-as-errors` 통과
- [ ] `mix test` 전체 통과 (기존 428+ 테스트 + 신규 6+ 테스트)
- [ ] Summary Row가 Body 아래, Footer 위에 렌더링
- [ ] 컬럼 너비 동기화 (리사이즈 반영)
- [ ] 필터 변경 시 집계 값 실시간 갱신
- [ ] summary 미지정 컬럼은 빈 셀
- [ ] Virtual Scroll 모드에서도 정상 동작
