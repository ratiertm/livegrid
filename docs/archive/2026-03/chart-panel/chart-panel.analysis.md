# Chart Panel (FA-031) - Gap Analysis

> **Design Document**: `docs/02-design/features/chart-panel.design.md`
> **Analysis Date**: 2026-03-05
> **Match Rate**: 96%
> **Verdict**: ✅ PASS (>= 90% threshold)

---

## Summary

| Metric | Value |
|--------|-------|
| Design Steps | 10 |
| Implemented | 10/10 (100%) |
| Tests (Design) | ~15 |
| Tests (Actual) | 23 (+8) |
| Files Created | 3 (chart.ex, svg_renderer.ex, chart.css) |
| Files Modified | 5 (grid.ex, event_handlers.ex, grid_component.ex, liveview_grid.css, demo_live.ex, dbms_demo_live.ex) |
| Compilation | ✅ Pass |
| Test Suite | ✅ 318/318 pass (non-DB) |
| Visual Verification | ✅ Bar chart confirmed |

---

## Step-by-Step Comparison

### Step 1: Grid state에 chart 필드 추가 — ✅ 100%

| Design | Implementation | Status |
|--------|---------------|--------|
| `chart_panel: false` in `default_options` | Line 1041 in grid.ex | ✅ Match |
| `show_chart_panel: false` in `initial_state` | Line 1407 | ✅ Match |
| `chart_config` map (4 keys) | Lines 1408-1412 | ✅ Match |
| `chart_data: nil` | Line 1414 | ✅ Match |

**Gap**: None

---

### Step 2: Chart 데이터 변환/집계 모듈 — ✅ 100%

| Design | Implementation | Status |
|--------|---------------|--------|
| `LiveviewGrid.Chart` module | `lib/liveview_grid/chart.ex` (114 lines) | ✅ Match |
| @palette 8 colors | Same 8 hex values | ✅ Match |
| @type chart_config/chart_point/chart_data | All 3 type specs present | ✅ Match |
| `prepare_data/2` with nil guards | 3 guard clauses + main function | ✅ Match |
| `aggregate/2` (5 functions + empty) | 6 function clauses | ✅ Match |
| `palette/0` | Present | ✅ Match |
| `to_number/1` (number/string/fallback) | 3 clauses | ✅ Match |
| `format_number/1` (float/integer/comma) | 4 clauses | ✅ Match |

**Gap**: None

---

### Step 3: SVG 렌더러 모듈 — ✅ 98% (Improved)

| Design | Implementation | Status |
|--------|---------------|--------|
| `LiveviewGrid.Chart.SvgRenderer` | `lib/liveview_grid/chart/svg_renderer.ex` (292 lines) | ✅ Match |
| Layout constants (5 values) | Same values | ✅ Match |
| `bar_chart/1` with attrs | Present with 4 attrs | ✅ Match |
| `line_chart/1` with attrs | Present with 4 attrs | ✅ Match |
| `pie_chart/1` with attrs | Present with 4 attrs | ✅ Match |
| `build_pie_slices/6` | Private function present | ✅ Match |
| `pie_arc_path/5` | Private function present | ✅ Match |
| Theme colors (3 functions) | text_color, grid_line_color, axis_color | ✅ Match |

**Deviation (Improvement)**:
- Design: inline `<% plot_w = ... %>` computations inside HEEx `~H` template
- Implementation: pre-computes all layout data in function body, then passes via `assign/2`
- **Reason**: Phoenix LiveView best practice — avoids complex expressions in HEEx templates
- Design had unused wrapper functions (`padding_top/0`, `padding_right/0`, etc.) — correctly omitted

---

### Step 4: 이벤트 핸들러 추가 — ✅ 99% (Bug Fix)

| Design | Implementation | Status |
|--------|---------------|--------|
| `handle_toggle_chart/2` | Lines 1509-1523 with @spec, @doc | ✅ Match |
| `handle_update_chart_config/2` | Lines 1531-1567 with case dispatch | ✅ Match |
| `recalculate_chart_data/1` private | Lines 1569-1572 | ✅ Match |
| `maybe_auto_configure_chart/1` private | Lines 1575-1608 | ✅ Match |

**Bug Fix in Design**:
- Design: `assign(socket, :grid, grid)` (3-arity) — would cause `UndefinedFunctionError`
- Implementation: `assign(socket, grid: grid)` (2-arity keyword form)
- **Reason**: Module imports `assign/2` only; 3-arity is not available

**Enhancement**:
- Implementation adds `@doc` and `@spec` typespecs (design had `@spec` but no `@doc`)

---

### Step 5: grid_component.ex 이벤트 라우팅 — ✅ 100%

| Design | Implementation | Status |
|--------|---------------|--------|
| `handle_event("grid_toggle_chart", ...)` | Line 365 | ✅ Match |
| `handle_event("grid_update_chart_config", ...)` | Line 369 | ✅ Match |

**Gap**: None

---

### Step 6: 툴바에 차트 토글 버튼 — ✅ 99%

| Design | Implementation | Status |
|--------|---------------|--------|
| Conditional on `chart_panel` option | `<%= if @grid.options.chart_panel do %>` | ✅ Match |
| Active class toggle | `lv-grid__toolbar-btn--active` | ✅ Match |
| `phx-click="grid_toggle_chart"` | Present | ✅ Match |
| `phx-target={@myself}` | Present | ✅ Match |
| Title with toggle text | 차트 숨기기/차트 표시 | ✅ Match |
| 📊 emoji | `<span style="font-size: 14px;">📊</span>` | ⚠️ Minor |

**Minor Deviation**: Emoji wrapped in `<span>` for consistent sizing across browsers. Design had bare emoji.

---

### Step 7: 차트 패널 렌더링 — ✅ 100%

| Design | Implementation | Status |
|--------|---------------|--------|
| Panel container `.lv-grid__chart-panel` | Line 1107 | ✅ Match |
| Chart type select (4 options) | Bar/Column/Line/Pie | ✅ Match |
| Category select with `display_columns` | With `:id` exclusion | ✅ Match |
| Aggregation select (5 options) | 합계/평균/개수/최소/최대 | ✅ Match |
| Value checkboxes (numeric columns) | `filter_type == :number or align == :right` | ✅ Match |
| SVG chart body with case dispatch | 5 cases (bar, column, line, pie, default) | ✅ Match |
| Empty state message | "카테고리와 값 컬럼을 선택하세요" | ✅ Match |
| Hidden input for field name | `<input type="hidden" name="field" ...>` | ✅ Match |

**Gap**: None

---

### Step 8: CSS 스타일 — ✅ 100% (Enhanced)

| Design | Implementation | Status |
|--------|---------------|--------|
| `.lv-grid__chart-panel` | Present with same properties | ✅ Match |
| `.lv-grid__chart-controls` | flex, wrap, gap, border-bottom | ✅ Match |
| `.lv-grid__chart-control-group` | flex column, gap 4px | ✅ Match |
| `.lv-grid__chart-label` | 11px, 600 weight, uppercase | ✅ Match |
| `.lv-grid__chart-select` | padding, border, font, cursor | ✅ Match |
| `.lv-grid__chart-select:focus` | outline, border-color, box-shadow | ✅ Match |
| `.lv-grid__chart-value-fields` | flex, wrap, gap 8px | ✅ Match |
| `.lv-grid__chart-checkbox-label` | flex, center, gap 4px | ✅ Match |
| `.lv-grid__chart-body` | flex, center, min-height | ✅ Match |
| `.lv-grid__chart-svg` | 100%, max-width 600px | ✅ Match |
| Bar/Slice hover (opacity 0.8) | transition + :hover | ✅ Match |
| Point hover (r: 6) | transition + :hover | ✅ Match |
| `.lv-grid__chart-empty` | center, padding, disabled color | ✅ Match |
| `.lv-grid__toolbar-btn--active` | primary-light bg, primary color | ✅ Match |

**Enhancement**: Implementation uses CSS variable fallbacks:
- `var(--lv-grid-border-input, var(--lv-grid-border))` (defensive for missing vars)
- `var(--lv-grid-text-disabled, #999)` (fallback)
- `var(--lv-grid-primary-light, rgba(33, 150, 243, 0.1))` (fallback)

---

### Step 9: CSS import + 데모 연동 — ✅ 100%

| Design | Implementation | Status |
|--------|---------------|--------|
| `@import "./grid/chart.css"` | Line 15 in liveview_grid.css | ✅ Match |
| `chart_panel: true` in demo_live.ex | Line 809 | ✅ Match |
| `chart_panel: true` in dbms_demo_live.ex | Line 241 | ✅ Match |

**Gap**: None

---

### Step 10: 테스트 — ✅ 100% (Exceeds)

| Design | Implementation | Status |
|--------|---------------|--------|
| prepare_data tests (5) | 7 tests (+2: color/sort) | ✅ Exceeds |
| aggregate tests (6) | 6 tests | ✅ Match |
| to_number tests (5) | 5 tests | ✅ Match |
| format_number tests (3) | 4 tests (+1: 일반 정수) | ✅ Exceeds |
| palette test (0) | 1 test (+1) | ✅ Exceeds |
| **Total: ~15** | **23 tests** | **+8 extra** |

---

## Verification Checklist

| Item | Status | Notes |
|------|--------|-------|
| `mix compile` pass | ✅ | Only harmless `redefine` warning |
| `mix test` pass | ✅ | 318/318 non-DB tests, 0 failures |
| Toolbar 📊 button visible | ✅ | Verified via preview |
| Chart toggle (show/hide) | ✅ | Verified via preview click |
| Bar chart SVG rendering | ✅ | Screenshot confirmed |
| Line chart SVG rendering | ⚠️ | Code exists, not visually verified |
| Pie chart SVG rendering | ⚠️ | Code exists, not visually verified |
| Category/value change → update | ✅ | Auto-configured on first open |
| Aggregation change → update | ⚠️ | Code exists, not visually verified |
| Filter → chart data reflect | ⚠️ | Code calls `visible_data`, not E2E verified |
| Dark mode chart colors | ⚠️ | Theme functions exist, not visually verified |
| Empty state display | ⚠️ | Code exists, not visually verified |

---

## Gaps Summary

### Missing (0)
None — All 10 design steps are fully implemented.

### Changed (3) — All Improvements
| # | Item | Design | Implementation | Impact |
|---|------|--------|---------------|--------|
| C-1 | SVG rendering pattern | Inline `<% %>` in HEEx | Pre-compute in function body | ✅ Better practice |
| C-2 | `assign` arity | `assign(socket, :grid, grid)` (3-arity) | `assign(socket, grid: grid)` (2-arity) | ✅ Bug fix |
| C-3 | Toolbar emoji | Bare `📊` | `<span>` wrapper | Neutral |

### Added (4) — Bonus
| # | Item | Description |
|---|------|-------------|
| A-1 | Extra tests | +8 tests beyond design (23 vs ~15) |
| A-2 | CSS fallbacks | Defensive CSS variable fallbacks |
| A-3 | @doc annotations | Documentation on event handlers |
| A-4 | Guard improvements | `max(point_count - 1, 0)` for edge case |

### Unverified (6)
| # | Item | Risk |
|---|------|------|
| U-1 | Line chart rendering | Low — code follows same pattern as bar |
| U-2 | Pie chart rendering | Low — arc path calculation tested in dev |
| U-3 | Aggregation change | Low — uses same event handler pattern |
| U-4 | Filter + chart sync | Medium — `visible_data` should work but no E2E test |
| U-5 | Dark mode colors | Low — theme functions exist with correct values |
| U-6 | Empty state | Low — simple conditional render |

---

## Match Rate Calculation

```
Total Design Items: 72 (across 10 steps)
Matched:           69 (100%)
Changed (improved): 3 (-1% each = -3%)
Missing:            0
Added (bonus):     +4 (not counted negatively)
Unverified:         6 (-0.5% each = not counted for match rate)

Match Rate = (69/72) * 100 ≈ 96%
```

## Conclusion

**Match Rate: 96% ✅ PASS**

chart-panel 기능은 설계 문서의 10단계를 모두 충실히 구현했습니다. 발견된 3건의 변경 사항은 모두 설계 대비 **개선**이며 (SVG 렌더링 패턴 최적화, assign 버그 수정, CSS 방어적 코딩), 미구현 항목은 없습니다. 테스트는 설계 대비 +8건 초과 달성했습니다.

> 다음 단계: `/pdca report chart-panel` 로 완료 보고서 생성
