# Design: Custom Cell Renderer (F-300)

> **Feature**: custom-renderer
> **Phase**: Design
> **Created**: 2026-02-21
> **Plan Reference**: docs/01-plan/features/custom-renderer.plan.md

---

## 1. 아키텍처

### 1.1 render_cell 분기 로직

```
render_cell(assigns, row, column)
  │
  ├─ 편집 모드? (editing == {row.id, field})
  │   ├─ select → <select> 에디터
  │   └─ text/number → <input> 에디터
  │
  └─ 보기 모드
      ├─ column.renderer != nil → renderer 함수 호출 (NEW)
      │   └─ 에러 시 → fallback (plain text)
      └─ column.renderer == nil → 기존 plain text
```

### 1.2 renderer 함수 시그니처

```elixir
@type renderer_fn :: (row :: map(), column :: map(), assigns :: map() -> Phoenix.LiveView.Rendered.t())
```

**인자:**
- `row` - 현재 행 데이터 (`%{id: 1, name: "Alice", city: "서울"}`)
- `column` - 컬럼 정의 (`%{field: :city, label: "도시", ...}`)
- `assigns` - LiveComponent assigns (grid 전체 상태 접근용)

---

## 2. 변경 상세

### 2.1 grid.ex - normalize_columns

```elixir
# 기존 기본값 맵에 추가
defp normalize_columns(columns) do
  Enum.map(columns, fn col ->
    Map.merge(%{
      # ... 기존 기본값들 ...
      renderer: nil   # NEW: 커스텀 렌더러 (nil = plain text)
    }, col)
  end)
end
```

### 2.2 grid_component.ex - render_cell 변경

```elixir
defp render_cell(assigns, row, column) do
  if column.editable && editing?(assigns.grid.state.editing, row.id, column.field) do
    # 편집 모드 (기존 코드 유지)
    render_editor(assigns, row, column)
  else
    # 보기 모드
    cell_error = Grid.cell_error(assigns.grid, row.id, column.field)

    if column.renderer do
      # 커스텀 렌더러
      render_with_renderer(assigns, row, column, cell_error)
    else
      # 기존 plain text
      render_plain(assigns, row, column, cell_error)
    end
  end
end

defp render_with_renderer(assigns, row, column, cell_error) do
  rendered_content = try do
    column.renderer.(row, column, assigns)
  rescue
    _ -> Phoenix.HTML.raw(to_string(Map.get(row, column.field)))
  end

  assigns = assign(assigns, row: row, column: column, cell_error: cell_error, rendered_content: rendered_content)
  ~H"""
  <div class={"lv-grid__cell-wrapper #{if @cell_error, do: "lv-grid__cell-wrapper--error"}"}>
    <span
      class={"lv-grid__cell-value #{if @column.editable, do: "lv-grid__cell-value--editable"} #{if @cell_error, do: "lv-grid__cell-value--error"}"}
      id={if @column.editable, do: "cell-#{@row.id}-#{@column.field}"}
      phx-hook={if @column.editable, do: "CellEditable"}
      data-row-id={@row.id}
      data-field={@column.field}
      phx-target={@myself}
      title={@cell_error}
    >
      <%= @rendered_content %>
      <%= if @cell_error do %>
        <span class="lv-grid__cell-error-icon">!</span>
      <% end %>
    </span>
    <%= if @cell_error do %>
      <span class="lv-grid__cell-error-msg"><%= @cell_error %></span>
    <% end %>
  </div>
  """
end
```

### 2.3 renderers.ex - 내장 프리셋

```elixir
defmodule LiveViewGrid.Renderers do
  @moduledoc """
  내장 셀 렌더러 프리셋.
  컬럼 정의의 renderer 옵션에 사용.
  """
  use Phoenix.Component

  @doc """
  값을 색상 뱃지로 표시.

  ## Options
    - colors: %{"값" => "색상"} 매핑
    - default_color: 매핑에 없을 때 기본 색상 (기본: "gray")

  ## Example
      renderer: LiveViewGrid.Renderers.badge(
        colors: %{"서울" => "blue", "부산" => "green"},
        default_color: "gray"
      )
  """
  def badge(opts \\ []) do
    colors = Keyword.get(opts, :colors, %{})
    default_color = Keyword.get(opts, :default_color, "gray")

    fn row, column, _assigns ->
      value = Map.get(row, column.field)
      color = Map.get(colors, to_string(value), default_color)
      assigns = %{value: value, color: color}

      ~H"""
      <span class={"lv-grid__badge lv-grid__badge--#{@color}"}><%= @value %></span>
      """
    end
  end

  @doc """
  값을 클릭 가능한 링크로 표시.

  ## Options
    - href: 링크 URL 생성 함수 fn(row, column) -> url
    - prefix: URL 접두사 (예: "mailto:", "tel:")
    - target: 링크 target ("_blank" 등)

  ## Example
      renderer: LiveViewGrid.Renderers.link(prefix: "mailto:")
  """
  def link(opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "")
    target = Keyword.get(opts, :target, nil)
    href_fn = Keyword.get(opts, :href, nil)

    fn row, column, _assigns ->
      value = Map.get(row, column.field)
      url = if href_fn, do: href_fn.(row, column), else: "#{prefix}#{value}"
      assigns = %{value: value, url: url, target: target}

      ~H"""
      <a href={@url} target={@target} class="lv-grid__link"><%= @value %></a>
      """
    end
  end

  @doc """
  숫자를 프로그레스바로 표시.

  ## Options
    - max: 최대값 (기본: 100)
    - color: 바 색상 (기본: "blue")
    - show_value: 숫자 텍스트 표시 여부 (기본: true)

  ## Example
      renderer: LiveViewGrid.Renderers.progress(max: 60, color: "green")
  """
  def progress(opts \\ []) do
    max_val = Keyword.get(opts, :max, 100)
    color = Keyword.get(opts, :color, "blue")
    show_value = Keyword.get(opts, :show_value, true)

    fn row, column, _assigns ->
      value = Map.get(row, column.field) || 0
      numeric = if is_number(value), do: value, else: 0
      pct = min(100, round(numeric / max_val * 100))
      assigns = %{value: value, pct: pct, color: color, show_value: show_value}

      ~H"""
      <div class="lv-grid__progress">
        <div class={"lv-grid__progress-bar lv-grid__progress-bar--#{@color}"} style={"width: #{@pct}%"}></div>
        <%= if @show_value do %>
          <span class="lv-grid__progress-text"><%= @value %></span>
        <% end %>
      </div>
      """
    end
  end
end
```

### 2.4 CSS 스타일

```css
/* Badge Renderer */
.lv-grid__badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  line-height: 1.4;
}
.lv-grid__badge--blue { background: #e3f2fd; color: #1565c0; }
.lv-grid__badge--green { background: #e8f5e9; color: #2e7d32; }
.lv-grid__badge--red { background: #ffebee; color: #c62828; }
.lv-grid__badge--yellow { background: #fff8e1; color: #f57f17; }
.lv-grid__badge--gray { background: #f5f5f5; color: #616161; }
.lv-grid__badge--purple { background: #f3e5f5; color: #6a1b9a; }

/* Link Renderer */
.lv-grid__link {
  color: #1976d2;
  text-decoration: none;
}
.lv-grid__link:hover {
  text-decoration: underline;
}

/* Progress Renderer */
.lv-grid__progress {
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
}
.lv-grid__progress-bar {
  height: 6px;
  border-radius: 3px;
  flex: 1;
  background: #e0e0e0;
  position: relative;
}
.lv-grid__progress-bar::after {
  content: '';
  position: absolute;
  left: 0; top: 0; bottom: 0;
  border-radius: 3px;
  width: inherit;
}
.lv-grid__progress-bar--blue { background: #e3f2fd; }
.lv-grid__progress-bar--blue::after { background: #1976d2; width: 100%; }
.lv-grid__progress-bar--green { background: #e8f5e9; }
.lv-grid__progress-bar--green::after { background: #2e7d32; width: 100%; }
.lv-grid__progress-text {
  font-size: 12px;
  color: #666;
  min-width: 30px;
  text-align: right;
}
```

### 2.5 demo_live.ex 적용 예시

```elixir
columns={[
  %{field: :id, label: "ID", width: 80, sortable: true},
  %{field: :name, label: "이름", width: 150, sortable: true, ...},
  %{field: :email, label: "이메일", width: 250, sortable: true, ...,
    renderer: LiveViewGrid.Renderers.link(prefix: "mailto:")},
  %{field: :age, label: "나이", width: 100, sortable: true, ...,
    renderer: LiveViewGrid.Renderers.progress(max: 60, color: "green")},
  %{field: :city, label: "도시", width: 120, sortable: true, ...,
    renderer: LiveViewGrid.Renderers.badge(
      colors: %{"서울" => "blue", "부산" => "green", "대구" => "red",
                "인천" => "purple", "광주" => "yellow"})}
]}
```

---

## 3. 구현 순서

1. `grid.ex` - normalize_columns에 `renderer: nil` 추가
2. `renderers.ex` - 내장 렌더러 모듈 생성
3. `grid_component.ex` - render_cell 리팩토링 (renderer 분기)
4. `liveview_grid.css` - 렌더러 CSS 추가
5. `demo_live.ex` - 데모에 렌더러 적용
6. 테스트 작성
7. Chrome MCP 브라우저 테스트

---

## 4. 완료 기준 체크리스트

- [ ] renderer 함수로 커스텀 HEEx 렌더링 동작
- [ ] renderer nil일 때 기존 동작 유지
- [ ] 편집 모드에서 renderer 무시
- [ ] validation 에러와 renderer 함께 동작
- [ ] 내장 렌더러: badge, link, progress
- [ ] renderer 에러 시 fallback
- [ ] 데모 페이지 적용 확인
- [ ] 테스트 통과
