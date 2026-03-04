# FA-005 Overlay System — 기술 설계서

> **Feature ID**: FA-005
> **Version**: v0.12.0
> **Created**: 2026-03-05

---

## Step 1: Grid state에 loading/error 필드 추가

**파일**: `lib/liveview_grid/grid.ex` — `initial_state/0`

```elixir
# initial_state에 추가
loading: false,
error: nil
```

## Step 2: Grid 옵션에 커스텀 메시지 추가

**파일**: `lib/liveview_grid/grid.ex` — `default_options/0`

```elixir
overlay_loading_text: "데이터 로딩 중...",
overlay_no_data_text: "표시할 데이터가 없습니다",
overlay_error_text: nil  # nil이면 error 메시지 그대로 표시
```

## Step 3: Grid 상태 변경 API

**파일**: `lib/liveview_grid/grid.ex`

```elixir
@spec set_loading(t(), boolean()) :: t()
def set_loading(grid, loading) when is_boolean(loading) do
  put_in(grid.state.loading, loading)
end

@spec set_error(t(), String.t() | nil) :: t()
def set_error(grid, error) when is_binary(error) or is_nil(error) do
  put_in(grid.state.error, error)
end
```

## Step 4: HEEx 오버레이 렌더링

**파일**: `lib/liveview_grid_web/components/grid_component.ex`

데이터 body 영역 바로 뒤(또는 body 내부)에 오버레이 삽입:

```heex
<!-- Overlay System (FA-005) -->
<%= cond do %>
  <% @grid.state.loading -> %>
    <div class="lv-grid__overlay">
      <div class="lv-grid__overlay-content">
        <div class="lv-grid__overlay-spinner"></div>
        <span class="lv-grid__overlay-text">
          <%= @grid.options[:overlay_loading_text] || "데이터 로딩 중..." %>
        </span>
      </div>
    </div>
  <% @grid.state.error -> %>
    <div class="lv-grid__overlay lv-grid__overlay--error">
      <div class="lv-grid__overlay-content">
        <span class="lv-grid__overlay-icon">&#x26A0;</span>
        <span class="lv-grid__overlay-text">
          <%= @grid.options[:overlay_error_text] || @grid.state.error %>
        </span>
      </div>
    </div>
  <% @grid.data == [] || @grid.state.current_page_data == [] -> %>
    <div class="lv-grid__overlay lv-grid__overlay--no-data">
      <div class="lv-grid__overlay-content">
        <span class="lv-grid__overlay-icon">&#x1F4ED;</span>
        <span class="lv-grid__overlay-text">
          <%= @grid.options[:overlay_no_data_text] || "표시할 데이터가 없습니다" %>
        </span>
      </div>
    </div>
  <% true -> %>
<% end %>
```

## Step 5: CSS 스타일링

**파일**: `assets/css/grid/body.css`

```css
/* FA-005: Overlay System */
.lv-grid__overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.85);
  z-index: 20;
  min-height: 200px;
}

[data-theme="dark"] .lv-grid__overlay {
  background: rgba(30, 30, 30, 0.85);
}

.lv-grid__overlay-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 24px;
}

.lv-grid__overlay-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid var(--lv-grid-border);
  border-top-color: var(--lv-grid-primary);
  border-radius: 50%;
  animation: lv-grid-spin 0.8s linear infinite;
}

@keyframes lv-grid-spin {
  to { transform: rotate(360deg); }
}

.lv-grid__overlay-text {
  color: var(--lv-grid-text-muted);
  font-size: var(--lv-grid-font-size-md);
}

.lv-grid__overlay-icon {
  font-size: 32px;
}

.lv-grid__overlay--error .lv-grid__overlay-text {
  color: var(--lv-grid-danger);
}
```

## Step 6: Grid body 영역에 position: relative 확인

body 영역이 overlay의 position 기준이 되려면 `position: relative` 필요.

## Step 7: 테스트

```elixir
test "set_loading/2" do
  grid = Grid.new(columns: [...], data: [])
  assert Grid.set_loading(grid, true).state.loading == true
end

test "set_error/2" do
  grid = Grid.new(columns: [...], data: [])
  assert Grid.set_error(grid, "Failed").state.error == "Failed"
end
```

## 변경 요약

| Step | 파일 | 라인 수 |
|------|------|---------|
| 1-3 | grid.ex | +20 |
| 4 | grid_component.ex | +25 |
| 5 | body.css | +45 |
| 7 | grid_test.exs | +10 |
| **합계** | | **~100줄** |
