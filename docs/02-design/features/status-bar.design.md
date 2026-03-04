# FA-004 Status Bar — 기술 설계서

> **Feature ID**: FA-004
> **Version**: v0.12.0
> **Created**: 2026-03-05

---

## 현황 분석

기존 `.lv-grid__info` (line 1304~1348)에 행수/선택합계/필터상태가 **인라인 스타일로 이미 구현**되어 있음.
FA-004는 이를 정식 **Status Bar 컴포넌트**로 리팩토링하는 작업.

## Step 1: Grid 옵션에 show_status_bar 추가

**파일**: `lib/liveview_grid/grid.ex` — `default_options/0`

```elixir
show_status_bar: true
```

## Step 2: .lv-grid__info를 .lv-grid__status-bar로 리팩토링

**파일**: `lib/liveview_grid_web/components/grid_component.ex`

기존 `.lv-grid__info` div를 `.lv-grid__status-bar`로 변환하고, 인라인 스타일을 모두 CSS 클래스로 교체:

```heex
<!-- FA-004: Status Bar -->
<%= if @grid.options[:show_status_bar] do %>
  <div class="lv-grid__status-bar">
    <%!-- 왼쪽: 행수 정보 --%>
    <div class="lv-grid__status-bar-left">
      <%= if @grid.state.global_search != "" or map_size(@grid.state.filters) > 0 do %>
        <span class="lv-grid__status-item lv-grid__status-item--filter">
          <%= Grid.filtered_count(@grid) %>개 검색됨 /
        </span>
      <% end %>
      <span class="lv-grid__status-item">
        총 <%= @grid.state.pagination.total_rows %>행
      </span>
      <%= if map_size(@grid.state.row_statuses) > 0 do %>
        <span class="lv-grid__status-separator">|</span>
        <span class="lv-grid__status-item lv-grid__status-item--changed">
          <%= map_size(@grid.state.row_statuses) %>개 변경됨
        </span>
      <% end %>
    </div>

    <%!-- 오른쪽: 선택 정보 --%>
    <div class="lv-grid__status-bar-right">
      <%= if (range_summary = Grid.cell_range_summary(@grid)) do %>
        <span class="lv-grid__status-item">Count: <strong><%= range_summary.count %></strong></span>
        <%= if range_summary.numeric_count > 0 do %>
          <span class="lv-grid__status-item">Sum: <strong><%= format_summary_number(range_summary.sum) %></strong></span>
          <span class="lv-grid__status-item">Avg: <strong><%= format_summary_number(range_summary.avg) %></strong></span>
        <% end %>
      <% end %>
      <%= if length(@grid.state.selection.selected_ids) > 0 do %>
        <span class="lv-grid__status-item lv-grid__status-item--selected">
          <%= length(@grid.state.selection.selected_ids) %>개 선택됨
        </span>
      <% end %>
    </div>
  </div>
<% end %>
```

## Step 3: CSS 스타일링

**파일**: `assets/css/grid/body.css`

```css
/* FA-004: Status Bar */
.lv-grid__status-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  font-size: var(--lv-grid-font-size-sm, 12px);
  color: var(--lv-grid-text-secondary, #666);
  background: var(--lv-grid-header-bg, #fafafa);
  border-top: 1px solid var(--lv-grid-border, #e0e0e0);
  min-height: 28px;
}

.lv-grid__status-bar-left,
.lv-grid__status-bar-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.lv-grid__status-item--filter {
  color: var(--lv-grid-warning, #ff9800);
  font-weight: 600;
}

.lv-grid__status-item--selected {
  color: var(--lv-grid-primary, #2196f3);
  font-weight: 600;
}

.lv-grid__status-item--changed {
  color: var(--lv-grid-warning, #ff9800);
  font-weight: 600;
}

.lv-grid__status-separator {
  color: var(--lv-grid-border, #ccc);
}
```

## Step 4: 기존 .lv-grid__info 제거

기존 `.lv-grid__info` 영역(line 1304~1348)의 인라인 스타일 코드를 Step 2의 Status Bar로 교체.

## Step 5: 데모 옵션 추가

**파일**: `lib/liveview_grid_web/live/demo_live.ex`

```elixir
options: [
  show_status_bar: true  # 기본값이 true이므로 별도 설정 불필요
]
```

## Step 6: 테스트

기존 테스트에 영향 없음 확인 (렌더링 레벨 변경이므로 단위 테스트 영향 없음)

## 변경 요약

| Step | 파일 | 라인 수 |
|------|------|---------|
| 1 | grid.ex | +1 |
| 2,4 | grid_component.ex | ~±40 |
| 3 | body.css | +35 |
| **합계** | | **~76줄** |
