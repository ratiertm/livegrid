# Cell Merge (F-904) Analysis Report

> **Analysis Type**: Gap Analysis (Design vs Implementation)
>
> **Project**: LiveView Grid
> **Version**: v0.10
> **Analyst**: gap-detector
> **Date**: 2026-02-28
> **Design Doc**: [cell-merge.design.md](../02-design/features/cell-merge.design.md)

---

## 1. Analysis Overview

### 1.1 Analysis Purpose

Verify F-904 Cell Merge feature implementation against the 8-step design document. Identify any missing, added, or changed items.

### 1.2 Analysis Scope

- **Design Document**: `docs/02-design/features/cell-merge.design.md` (8 steps)
- **Implementation Files**:
  - `lib/liveview_grid/grid.ex` (core API + private functions)
  - `lib/liveview_grid_web/components/grid_component/render_helpers.ex` (render helpers)
  - `lib/liveview_grid_web/components/grid_component.ex` (HEEx body rendering)
  - `assets/css/grid/body.css` (CSS styles)
  - `test/liveview_grid/grid_test.exs` (unit tests)
  - `lib/liveview_grid_web/components/grid_component/event_handlers.ex` (merge_regions option)

---

## 2. Step-by-Step Gap Analysis

### Step 1: state에 merge_regions 추가

**Design**: `initial_state/0`에 `merge_regions: %{}` 추가
**Implementation**: `grid.ex:1341` -- `merge_regions: %{}`

| Item | Design | Implementation | Status |
|------|--------|----------------|--------|
| merge_regions key | `%{}` in initial_state | `merge_regions: %{}` at line 1341 | MATCH |
| Position | cell_range 이후 | cell_range (line 1339) 바로 아래 | MATCH |
| Comment | `# F-904: Cell Merge` | `# F-904: Cell Merge` | MATCH |

**Score: 100%**

---

### Step 2: merge_cells/2 공개 API

**Design**: `grid.ex` ~line 305에 merge_cells/2 추가
**Implementation**: `grid.ex:324-357`

| Item | Design | Implementation | Status |
|------|--------|----------------|--------|
| Function signature | `merge_cells(grid, spec)` | `merge_cells(grid, spec)` at line 325 | MATCH |
| @spec | `{:ok, t()} \| {:error, String.t()}` | Identical at line 324 | MATCH |
| @doc | Present | Present (lines 312-322) | MATCH |
| rowspan/colspan defaults | `Map.get(spec, :rowspan, 1)` | Identical at lines 326-327 | MATCH |
| Validation: < 1 check | `rowspan < 1 or colspan < 1` | Identical at line 329 | MATCH |
| Validation: column not found | `{:error, "column #{col_field} not found"}` | Identical at line 337 | MATCH |
| Validation: colspan exceeds | `{:error, "colspan exceeds column count"}` | Identical at line 340 | MATCH |
| Validation: overlap | `has_merge_overlap?` call | Identical at line 345 | MATCH |
| Validation: frozen boundary | `frozen_boundary_crossed?` call | Identical at line 348 | MATCH |
| Region storage | `Map.put(grid.state.merge_regions, ...)` | Identical at lines 352-354 | MATCH |
| **ADDED**: single-cell rejection | Not in design | `rowspan == 1 and colspan == 1` check at line 342 | ADDED |

**Details on ADDED item**: The implementation adds an extra validation at line 342-343:
```elixir
rowspan == 1 and colspan == 1 ->
  {:error, "merge must span more than one cell"}
```
This is a reasonable defensive check not present in the design. A merge with rowspan=1 and colspan=1 is a no-op, so rejecting it prevents confusion.

**Score: 100%** (ADDED item is an improvement, not a gap)

---

### Step 3: unmerge_cells/3, clear_all_merges/1, 조회 API

**Design**: 5 functions (unmerge_cells, clear_all_merges, merge_regions, merged?, merge_origin)
**Implementation**: `grid.ex:359-391`

| Function | Design | Implementation | Status |
|----------|--------|----------------|--------|
| `unmerge_cells/3` | lines 90-95 | grid.ex:360-363 | MATCH |
| `clear_all_merges/1` | lines 98-101 | grid.ex:367-370 | MATCH |
| `merge_regions/1` | lines 104-105 | grid.ex:373-374 | MATCH |
| `merged?/3` | lines 108-112 | grid.ex:377-381 | MATCH |
| `merge_origin/3` | lines 118-122 | grid.ex:387-391 | MATCH |
| @spec for all 5 | Present | Present for all 5 | MATCH |
| @doc for all 5 | Present | Present for all 5 | MATCH |

**Minor difference**: `merge_origin/3` @spec return type:
- Design: `nil | {:origin, any(), atom()}`
- Implementation: `nil | tuple()` (line 387)

This is a **relaxed** type spec in the implementation -- functionally identical at runtime, but the design's type is more descriptive.

**Score: 98%** (minor @spec type relaxation)

---

### Step 4: 검증 및 skip 맵 빌드 private 함수

**Design**: `has_merge_overlap?/5`, `frozen_boundary_crossed?/3`, `visible_data_ids/1`, `build_merge_skip_map/1`
**Implementation**: `grid.ex:1350-1386` (private), `grid.ex:394-426` (build_merge_skip_map)

| Function | Design | Implementation | Status |
|----------|--------|----------------|--------|
| `has_merge_overlap?/5` | defp, MapSet intersection | grid.ex:1350-1375, identical logic | MATCH |
| `frozen_boundary_crossed?/3` | defp, frozen boundary check | grid.ex:1378-1386 | CHANGED |
| `visible_data_ids/1` | defp, separate helper | Not present (inlined) | CHANGED |
| `build_merge_skip_map/1` | `@doc false`, public def | grid.ex:394-426, public def | MATCH |

**frozen_boundary_crossed? CHANGED detail**:
- Design (line 174): includes reverse boundary check: `(col_start_idx >= frozen and col_end_idx < frozen and col_start_idx != col_end_idx)`
- Implementation (line 1382): simplified to `col_start_idx < frozen and col_end_idx >= frozen` only

The removed clause was marked as "impossible but safety net" in the design itself. Its removal is architecturally sound since `col_start_idx >= frozen` and `col_end_idx < frozen` with `col_end_idx = col_start_idx + colspan - 1` where `colspan >= 1` is indeed impossible (would require `col_start_idx + colspan - 1 < frozen <= col_start_idx`, i.e., `colspan < 1`).

**visible_data_ids/1 CHANGED detail**:
- Design has a separate `defp visible_data_ids(grid)` helper
- Implementation inlines the logic: `visible_data(grid) |> Enum.map(&Map.get(&1, :id))` is used directly inside `has_merge_overlap?` (line 1352) and `build_merge_skip_map` (lines 401-402)
- Functionally identical; code duplication is minimal (1-line expression)

**ADDED: build_merge_skip_map/1 fast path**:
- Implementation adds an empty-map guard clause at line 395:
  ```elixir
  def build_merge_skip_map(%{state: %{merge_regions: regions}} = _grid) when map_size(regions) == 0 do
    %{}
  end
  ```
- This is a performance optimization not in the design -- avoids computing display columns and visible data when no merges exist.

**Score: 95%** (intentional simplifications, no functional impact)

---

### Step 5: RenderHelpers에 merge 헬퍼 함수 추가

**Design**: 4 functions in render_helpers.ex
**Implementation**: render_helpers.ex:659-711

| Function | Design | Implementation | Status |
|----------|--------|----------------|--------|
| `merge_skip?/3` | lines 232-235 | render_helpers.ex:663-665 | MATCH |
| `merge_span/3` | lines 239-243 | render_helpers.ex:669-674 | MATCH |
| `merged_width_style/3` | lines 251-276 | render_helpers.ex:678-701 | MATCH |
| `merged_height_style/2` | lines 280-286 | render_helpers.ex:705-710 | MATCH |
| @spec for all 4 | Present | Present for all 4 | MATCH |
| @doc for all 4 | Present | Present for all 4 | MATCH |
| Border compensation logic | `(colspan - 1)` px | Identical | MATCH |
| Auto width flex calculation | `"flex: #{auto_count} 1 #{px}px"` | Identical | MATCH |
| z-index + position style | In merged_height_style | Identical | MATCH |

**Score: 100%**

---

### Step 6: grid_component.ex 렌더링에 merge 로직 적용

**Design**: 6a (merge data prep) + 6b (cell rendering changes)
**Implementation**: grid_component.ex:908-1013

| Item | Design | Implementation | Status |
|------|--------|----------------|--------|
| merge_skip_map computation | `Grid.build_merge_skip_map(@grid)` | line 908 | MATCH |
| merge_regions assign | `@grid.state.merge_regions` | line 909 | MATCH |
| Skip cell rendering | `if not merge_skip?(...)` | line 991 | MATCH |
| Span lookup | `merge_span(merge_regions, ...)` | line 992 | MATCH |
| {rs, cs} destructure | `if span, do: span, else: {1, 1}` | line 993 | MATCH |
| Width style conditional | `if cs > 1, do: merged_width_style(...)` | line 994 | MATCH |
| Height style conditional | `if rs > 1, do: merged_height_style(...)` | line 995 | MATCH |
| `.lv-grid__cell--merged` class | `#{if span, do: "lv-grid__cell--merged"}` | line 996 | MATCH |
| data-merge-rowspan attr | `data-merge-rowspan={if rs > 1, do: rs}` | NOT present | MISSING |
| data-merge-colspan attr | `data-merge-colspan={if cs > 1, do: cs}` | NOT present | MISSING |

**MISSING: data-merge-rowspan and data-merge-colspan attributes**

The design specifies (lines 324-325):
```heex
data-merge-rowspan={if rs > 1, do: rs}
data-merge-colspan={if cs > 1, do: cs}
```

These data attributes are not present in the implementation. They would be useful for:
1. JavaScript hooks that need to know merge dimensions
2. CSS selectors targeting merged cells
3. Debugging/inspection

Currently no JS hook or CSS rule references these attributes, so the functional impact is **Low**. However, they may be needed for future interactive merge features.

**Score: 90%** (2 data attributes missing from HEEx template)

---

### Step 7: CSS 스타일 추가

**Design**: 3 CSS rules in body.css
**Implementation**: body.css:321-334

| CSS Rule | Design | Implementation | Status |
|----------|--------|----------------|--------|
| Section comment | `/* 5.11 Cell Merge (F-904) */` | `/* 5.11 Cell Merge (F-904) */` at line 321 | MATCH |
| `.lv-grid__cell--merged` | overflow:visible, z-index:1, bg | lines 322-326 | MATCH |
| `.lv-grid__row:hover .lv-grid__cell--merged` | hover bg | lines 328-330 | MATCH |
| `.lv-grid__row--selected .lv-grid__cell--merged` | selected bg | lines 332-334 | MATCH |
| Uses CSS variables | `var(--lv-grid-bg)`, `var(--lv-grid-hover)`, `var(--lv-grid-selected)` | Identical | MATCH |

**Score: 100%**

---

### Step 8: 테스트 작성

**Design**: 10 test cases in `describe "cell merge (F-904)"`
**Implementation**: grid_test.exs:1757-1835 -- 11 test cases

| Test Case | Design | Implementation | Status |
|-----------|--------|----------------|--------|
| setup (columns + data) | 4 columns, 3 rows | Identical at lines 1758-1771 | MATCH |
| merge_cells/2 registers colspan | Present | line 1774 | MATCH |
| merge_cells/2 registers rowspan | Present | line 1780 | MATCH |
| merge_cells/2 rejects overlapping merge | Present | line 1789 | MATCH |
| merge_cells/2 rejects colspan exceeding | Present | line 1794 | MATCH |
| unmerge_cells/3 removes merge | Present | line 1798 | MATCH |
| clear_all_merges/1 removes all | Present | line 1804 | MATCH |
| merge_regions/1 returns all | Present | line 1811 | MATCH |
| merged?/3 detects merged cells | Present | line 1817 | MATCH |
| build_merge_skip_map/1 skip entries | Present | line 1824 | MATCH |
| frozen boundary merge rejected | Present | line 1831 | MATCH |
| **ADDED**: rejects single cell merge | Not in design | line 1785 | ADDED |

**ADDED test detail**: Tests the extra validation added in Step 2:
```elixir
test "merge_cells/2 rejects single cell merge", %{grid: grid} do
  assert {:error, _msg} = Grid.merge_cells(grid, %{row_id: 1, col_field: :name, rowspan: 1, colspan: 1})
end
```

This test covers the defensive validation added beyond the design. All 10 design tests are present, plus 1 additional test.

**Score: 100%** (11/10 tests -- exceeds design)

---

## 3. Additional Implementation (Not in Design)

### 3.1 merge_regions option in apply_v07_options

**File**: `event_handlers.ex:1153-1162`

The implementation includes `merge_regions` support in `apply_v07_options`, allowing merge regions to be specified via the grid options map:

```elixir
grid = if Map.has_key?(options, :merge_regions) do
  Enum.reduce(Map.get(options, :merge_regions, []), grid, fn spec, acc ->
    case Grid.merge_cells(acc, spec) do
      {:ok, updated} -> updated
      {:error, _reason} -> acc
    end
  end)
else
  grid
end
```

This is not in the design document but enables declarative merge setup through grid options, which is consistent with how other features (tree_mode, frozen_columns) are configured. Error cases are silently skipped (`{:error, _reason} -> acc`).

**Impact**: Positive (convenience API for configuration-based merge setup)

---

## 4. Match Rate Summary

```
+-------------------------------------------------+
|  Overall Match Rate: 97%                        |
+-------------------------------------------------+
|  Step 1 (state):              100%              |
|  Step 2 (merge_cells API):    100%   +1 added   |
|  Step 3 (query APIs):          98%   @spec diff  |
|  Step 4 (private functions):   95%   simplified  |
|  Step 5 (RenderHelpers):      100%              |
|  Step 6 (HEEx rendering):     90%   -2 data-*   |
|  Step 7 (CSS):                100%              |
|  Step 8 (Tests):              100%   +1 test    |
+-------------------------------------------------+
|  Weighted Average:             97%   PASS       |
+-------------------------------------------------+
```

---

## 5. Differences Found

### MISSING (Design O, Implementation X)

| Item | Design Location | Implementation Impact | Severity |
|------|-----------------|----------------------|----------|
| `data-merge-rowspan` attribute | design:324 | No JS/CSS currently uses it | Low |
| `data-merge-colspan` attribute | design:325 | No JS/CSS currently uses it | Low |
| `visible_data_ids/1` helper | design:181-185 | Logic inlined; no functional gap | None |

### ADDED (Design X, Implementation O)

| Item | Implementation Location | Description | Impact |
|------|------------------------|-------------|--------|
| Single-cell merge rejection | grid.ex:342-343 | Rejects rowspan=1, colspan=1 | Positive |
| build_merge_skip_map fast path | grid.ex:395-397 | Empty map guard for perf | Positive |
| `merge_regions` option support | event_handlers.ex:1153-1162 | Declarative merge config | Positive |
| Extra test case | grid_test.exs:1785-1787 | Tests single-cell rejection | Positive |

### CHANGED (Design != Implementation)

| Item | Design | Implementation | Impact |
|------|--------|----------------|--------|
| `merge_origin/3` @spec | `nil \| {:origin, any(), atom()}` | `nil \| tuple()` | Low (runtime identical) |
| `frozen_boundary_crossed?/3` | Includes impossible reverse check | Simplified (correct) | None |
| `visible_data_ids/1` | Separate defp helper | Inlined in callers | None (style) |

---

## 6. Verification Checklist Status

| Checklist Item | Status |
|----------------|--------|
| `mix compile --warnings-as-errors` | Assumed PASS (no warnings noted) |
| `mix test` full pass | 11 F-904 tests in describe block |
| colspan merged cell correct width | merged_width_style/3 implemented |
| rowspan merged cell correct height | merged_height_style/2 implemented |
| Overlapping merge returns error | has_merge_overlap?/5 implemented |
| Frozen boundary merge returns error | frozen_boundary_crossed?/3 implemented |
| Unmerge/clear_all works | unmerge_cells/3 + clear_all_merges/1 |
| Demo page visual confirmation | Not verifiable via static analysis |

---

## 7. Recommended Actions

### 7.1 Low Priority (Documentation Housekeeping)

| Priority | Item | Description |
|----------|------|-------------|
| Low | Add `data-merge-rowspan/colspan` | Add 2 data attributes to HEEx for future JS hook use |
| Low | Update `merge_origin` @spec | Use descriptive type `nil \| {:origin, any(), atom()}` |
| Low | Update design doc | Reflect 4 ADDED items (single-cell check, fast path, option support, extra test) |

### 7.2 No Immediate Action Required

The implementation is functionally complete and exceeds the design in several defensive areas. No critical or high-severity gaps exist.

---

## 8. Overall Score

| Category | Score | Status |
|----------|:-----:|:------:|
| Step 1: State Structure | 100% | PASS |
| Step 2: merge_cells API | 100% | PASS |
| Step 3: Query APIs | 98% | PASS |
| Step 4: Private Functions | 95% | PASS |
| Step 5: RenderHelpers | 100% | PASS |
| Step 6: HEEx Rendering | 90% | PASS |
| Step 7: CSS Styles | 100% | PASS |
| Step 8: Tests | 100% | PASS |
| **Overall** | **97%** | **PASS** |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-28 | Initial F-904 gap analysis | gap-detector |
