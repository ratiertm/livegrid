# Cell Merge (셀 병합)

> **Version**: v0.8
> **Priority**: HIGH (미구현 #2)
> **Status**: Plan
> **Feature ID**: F-904
> **Nexacro Ref**: 3.6, 24.9, 24.29~31

---

## 목표

Grid의 Body 영역에서 **셀 병합**(rowspan/colspan)을 지원합니다.
프로그래밍 방식으로 병합 영역을 지정하면, 병합된 셀이 하나의 큰 셀로 렌더링됩니다.

넥사크로 Grid의 Merge Cells 기능에 해당합니다.

## 기존 코드 분석

### 현재 렌더링 구조
1. **Flex 기반 Row 레이아웃** (`grid_component.ex:905-1010`)
   - 각 `.lv-grid__row`는 독립적인 `display: flex` 컨테이너
   - 각 `.lv-grid__cell`은 flex item으로 컬럼 너비 적용
   - rowspan은 단일 row 내부에서 처리 불가 → CSS `position: absolute` 또는 CSS Grid 필요

2. **컬럼 너비 시스템** (`grid_component.ex:989`)
   - `column_width_style/2`로 각 셀 너비 결정
   - `@grid.state.column_widths`에 사용자 리사이즈 너비 저장
   - colspan 시 여러 컬럼 너비를 합산해야 함

3. **Frozen 컬럼** (`grid_component.ex:989`)
   - `frozen_class/2`, `frozen_style/2`로 좌측 고정 컬럼 처리
   - 병합 영역이 frozen 경계를 넘지 않도록 제약 필요

4. **Virtual Scroll** (`grid_component.ex:832-901`)
   - viewport 밖 행은 DOM에 없음
   - rowspan 셀이 viewport 경계에 걸칠 수 있음 → 특별 처리 필요

### 재사용 가능한 자산
1. **`Grid.display_columns/1`** — 표시 컬럼 목록 (colspan 너비 합산 시 사용)
2. **CSS BEM 패턴** (`.lv-grid__cell--merged`, `.lv-grid__cell--hidden`)
3. **`column_width_style/2`** — 컬럼 너비 계산 (확장하여 colspan 너비 계산)

## 요구사항

### FR-01: 병합 영역 정의 API

프로그래밍 방식으로 셀 병합 영역을 지정합니다:

```elixir
grid = Grid.merge_cells(grid, %{
  row_id: 1,
  col_field: :name,
  rowspan: 2,
  colspan: 3
})
```

- `row_id`: 병합 시작 행 ID
- `col_field`: 병합 시작 컬럼 필드
- `rowspan`: 세로 병합 행 수 (기본: 1)
- `colspan`: 가로 병합 컬럼 수 (기본: 1)
- 여러 병합 영역을 중첩 없이 등록 가능

### FR-02: 병합 해제 API

```elixir
grid = Grid.unmerge_cells(grid, row_id, col_field)
grid = Grid.clear_all_merges(grid)
```

### FR-03: Colspan 렌더링

- 병합 시작 셀의 너비 = 병합 대상 컬럼들의 너비 합
- 병합에 포함된 후속 컬럼 셀은 숨김 처리
- 병합 셀 값은 시작 셀의 값 사용

### FR-04: Rowspan 렌더링

- 병합 시작 셀의 높이 = `row_height × rowspan`
- 병합에 포함된 후속 행의 해당 컬럼 셀은 숨김 처리
- `position: relative` + `height` 확장으로 구현
- 후속 행에서 해당 컬럼 위치에 빈 공간 확보

### FR-05: 병합 제약 조건

- 병합 영역이 서로 겹치면 에러 반환
- Frozen 컬럼 경계를 넘는 colspan 불가
- 그룹 헤더 행은 병합 불가
- 편집 모드 셀은 병합 해제 후 편집

### FR-06: 병합 상태 조회

```elixir
Grid.merge_regions(grid)          # 전체 병합 영역 목록
Grid.merged?(grid, row_id, field) # 특정 셀이 병합에 포함 여부
Grid.merge_origin(grid, row_id, field) # 병합 시작 셀 정보
```

## 구현 범위

### 수정 파일
| 파일 | 변경 내용 |
|------|-----------|
| `lib/liveview_grid/grid.ex` | merge_cells/2, unmerge_cells/3, clear_all_merges/1, merge 상태 관리 |
| `lib/liveview_grid/grid.ex` | state에 `merge_regions` 맵 추가 |
| `lib/liveview_grid_web/components/grid_component.ex` | 렌더링 시 merge skip/span 로직 |
| `lib/liveview_grid_web/components/grid_component/render_helpers.ex` | merge 헬퍼 함수 |
| `assets/css/grid/layout.css` | .lv-grid__cell--merged, --hidden 스타일 |
| `lib/liveview_grid_web/live/demo_live.ex` | 데모에 merge 예시 추가 |
| `test/liveview_grid/grid_test.exs` | merge API 테스트 |

### 제외 범위 (향후 확장)
- 선택 영역 자동 병합 (F-940 셀 범위 선택과 연동)
- Suppress 동일값 자동 병합 (F-903 별도 기능)
- 드래그로 병합 영역 지정 UI
- Virtual Scroll과 rowspan 교차 처리 (V1에서는 페이지네이션 모드만)

## 기술적 접근

### V1: Colspan 우선 구현 (Flex 호환)

현재 Flex Row 레이아웃에서 colspan은 자연스럽게 구현 가능:
1. 병합 시작 셀의 `flex` 너비를 colspan 컬럼 너비 합으로 설정
2. 병합에 포함된 후속 셀은 `display: none`

### V2: Rowspan 추가 (CSS Position 활용)

Flex Row에서 rowspan은 추가 CSS 처리 필요:
1. 병합 시작 셀에 `position: relative; z-index: 1; height: (row_height × rowspan)px`
2. 후속 행의 해당 컬럼 위치에 동일 너비의 빈 셀 (투명) 배치
3. 또는 후속 행 셀에 `visibility: hidden` 적용

### 데이터 구조

```elixir
# grid.state.merge_regions
%{
  {row_id, :field_name} => %{rowspan: 2, colspan: 3}
}

# 렌더링 시 skip 맵 생성 (O(1) 조회)
# merge_skip_set = MapSet of {row_id, field} tuples to skip
```

## 의존성

- 없음 (독립 기능, 기존 렌더링에 병합 로직 추가)

## 테스트 계획

| # | 테스트 | 설명 |
|---|--------|------|
| 1 | merge_cells/2 기본 | colspan=2 병합 등록 확인 |
| 2 | unmerge_cells/3 | 병합 해제 확인 |
| 3 | 중첩 병합 거부 | 겹치는 영역 등록 시 에러 |
| 4 | merge_regions/1 조회 | 전체 병합 영역 반환 |
| 5 | merged?/3 | 특정 셀 병합 포함 여부 |
| 6 | clear_all_merges/1 | 전체 해제 |
| 7 | frozen 경계 초과 거부 | colspan이 frozen 경계 넘으면 에러 |

## 일정

- Plan: 1일
- Design: 1일
- Do: 2일 (colspan 1일 + rowspan 1일)
- Check/Act: 1일

## 관련 기능

- [F-903] Suppress (동일값 병합) — 자동 rowspan과 유사하나 별도 기능
- [F-940] 셀 범위 선택 — 선택 영역 병합 연동 가능
- [F-910] 다중 헤더 — 헤더 영역 병합은 별도 구현
