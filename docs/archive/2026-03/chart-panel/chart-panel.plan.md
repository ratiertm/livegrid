# Chart Panel (차트 패널)

> **Version**: v0.21
> **Priority**: MEDIUM
> **Status**: Plan
> **Feature ID**: FA-031
> **AG Grid Ref**: Integrated Charts, Chart Panel

---

## 목표

Grid 데이터를 기반으로 **차트 패널**을 렌더링합니다.
사용자가 컬럼을 선택하면 해당 데이터로 Bar, Line, Pie 등 차트를 생성하여
그리드 하단(또는 우측)에 표시합니다.

AG Grid의 Integrated Charts 기능에 해당하며, 서버사이드 SVG 렌더링 방식으로 구현합니다.
(JS 차트 라이브러리 의존 없이 Phoenix LiveView 네이티브 구현)

## 기존 코드 분석

### 현재 상태
1. **이전 구현 기록**: v0.20.0 changelog에 FA-031로 "Chart panel UI rendering" 기록 있으나 **코드 전부 제거됨**
2. **Grid 상태**: `grid.state`에 차트 관련 필드 없음
3. **Grid 옵션**: `default_options()`에 차트 옵션 없음
4. **렌더링**: `grid_component.ex`, `render_helpers.ex`에 차트 코드 없음
5. **JS/CSS**: 차트 관련 훅, 스타일 없음

### 재사용 가능한 자산
1. **Grid 데이터 접근**: `grid.data` — 현재 페이지 데이터 배열
2. **컬럼 메타데이터**: `grid.columns` — 필드명, 타입, 포맷터 정보
3. **그룹핑/집계**: `operations/grouping.ex` — 데이터 집계 함수 재사용 가능
4. **CSS BEM 패턴**: `.lv-grid__chart-panel`, `.lv-grid__chart-*`
5. **설정 모달 구조**: Grid Settings 탭에 차트 옵션 추가 가능

## 요구사항

### FR-01: 차트 패널 토글

그리드 툴바에 차트 토글 버튼을 추가합니다:

```elixir
# 옵션으로 차트 패널 활성화
Grid.new(columns: columns, options: %{chart_panel: true})
```

- 툴바에 📊 차트 버튼 표시
- 클릭 시 차트 패널 토글 (show/hide)
- 패널 위치: 그리드 하단 (기본)

### FR-02: 차트 타입 선택

지원 차트 타입:

| 타입 | 설명 | 데이터 요건 |
|------|------|-------------|
| `bar` | 막대 차트 (기본) | 카테고리 + 숫자 컬럼 |
| `line` | 꺾은선 차트 | 연속 데이터 + 숫자 컬럼 |
| `pie` | 파이 차트 | 카테고리 + 숫자 컬럼 |
| `column` | 세로 막대 차트 | 카테고리 + 숫자 컬럼 |

### FR-03: 컬럼 매핑 UI

차트 데이터 소스를 설정합니다:

```elixir
# 차트 설정
%{
  chart_type: :bar,
  category_field: :department,    # X축 (카테고리)
  value_fields: [:salary, :age], # Y축 (값, 복수 가능)
  aggregation: :sum               # 집계 방식 (:sum, :avg, :count, :min, :max)
}
```

- 카테고리 컬럼 선택 (X축)
- 값 컬럼 선택 (Y축, 복수 선택 가능)
- 집계 방식 선택 (sum, avg, count, min, max)

### FR-04: SVG 차트 렌더링

서버사이드 SVG로 차트를 생성합니다:

- Phoenix LiveView HEEx 템플릿으로 SVG 직접 생성
- JS 차트 라이브러리 의존 없음
- 반응형 SVG (viewBox 기반)
- 차트 크기: 너비 100%, 높이 300px (기본, 조절 가능)

### FR-05: 데이터 연동

- 현재 그리드 데이터(필터/정렬 적용된 상태)를 차트에 반영
- 필터 변경 시 차트 자동 업데이트
- 정렬 변경은 차트에 영향 없음 (집계 기반)
- 페이지네이션: 전체 데이터 또는 현재 페이지 선택 가능

### FR-06: 차트 스타일링

- 라이트/다크 테마 대응 (CSS 변수)
- 차트 색상 팔레트 (8색)
- 툴팁: hover 시 값 표시 (CSS only, JS 최소화)
- 범례 표시

## 구현 범위

### 수정 파일
| 파일 | 변경 내용 |
|------|-----------|
| `lib/liveview_grid/chart.ex` | 차트 데이터 변환/집계 모듈 (NEW) |
| `lib/liveview_grid/chart/svg_renderer.ex` | SVG 차트 렌더링 모듈 (NEW) |
| `lib/liveview_grid/grid.ex` | state에 chart 필드 추가, 옵션에 chart_panel 추가 |
| `lib/liveview_grid_web/components/grid_component.ex` | 차트 패널 렌더링 |
| `lib/liveview_grid_web/components/grid_component/render_helpers.ex` | 차트 헬퍼 함수 |
| `lib/liveview_grid_web/components/grid_component/event_handlers.ex` | 차트 이벤트 핸들러 |
| `assets/css/grid/chart.css` | 차트 패널 스타일 (NEW) |
| `lib/liveview_grid_web/live/demo_live.ex` | 데모에 차트 예시 추가 |
| `test/liveview_grid/chart_test.exs` | 차트 모듈 테스트 (NEW) |

### 제외 범위 (향후 확장)
- 드래그로 셀 범위 선택 → 차트 생성 (AG Grid Range Chart)
- 차트 내 데이터 포인트 클릭 → 그리드 필터 연동
- 차트 이미지 내보내기 (PNG/SVG 다운로드)
- 3D 차트, 스택형 차트, 워터폴 차트 등 고급 차트
- JS 차트 라이브러리 연동 (Chart.js, ApexCharts)
- 실시간 데이터 스트리밍 차트

## 기술적 접근

### Phase 1: SVG 기본 차트 (Bar/Column)

서버사이드 SVG 렌더링으로 가장 단순한 차트부터:

```elixir
defmodule LiveviewGrid.Chart do
  @doc "그리드 데이터로 차트 데이터 생성"
  def prepare_data(grid, chart_config) do
    grid.data
    |> group_by_category(chart_config.category_field)
    |> aggregate(chart_config.value_fields, chart_config.aggregation)
    |> normalize_for_svg()
  end
end

defmodule LiveviewGrid.Chart.SvgRenderer do
  @doc "차트 데이터를 SVG HEEx로 렌더링"
  def render_bar(chart_data, opts \\ []) do
    # SVG <rect> 요소로 막대 차트 렌더
  end
end
```

### Phase 2: Line/Pie 차트 추가

- Line: SVG `<polyline>` 또는 `<path>` 사용
- Pie: SVG `<circle>` + `stroke-dasharray` 또는 `<path>` arc 사용

### Phase 3: 인터랙티브 기능

- 차트 타입 전환 UI
- 컬럼 매핑 변경 UI
- 툴팁 (CSS hover 기반)

### 데이터 구조

```elixir
# grid.state 확장
%{
  show_chart_panel: false,
  chart_config: %{
    chart_type: :bar,
    category_field: nil,
    value_fields: [],
    aggregation: :sum,
    chart_height: 300,
    show_legend: true,
    position: :bottom  # :bottom | :right
  },
  chart_data: nil  # 계산된 차트 데이터 캐시
}

# grid.options 확장
%{
  chart_panel: false  # 차트 기능 활성화 여부
}
```

### SVG 렌더링 전략

```
┌──────────────────────────────────┐
│ Grid Toolbar  [📊 차트]          │
├──────────────────────────────────┤
│ Grid Body (rows)                 │
│ ...                              │
├──────────────────────────────────┤
│ Chart Panel (SVG)                │
│ ┌─ Chart Type: [Bar ▼]  ────┐   │
│ │  Category: [부서 ▼]       │   │
│ │  Values: [급여 ✓] [나이 ✓]│   │
│ │  Aggregation: [합계 ▼]    │   │
│ ├────────────────────────────┤   │
│ │  ┌──┐                     │   │
│ │  │██│ ┌──┐                │   │
│ │  │██│ │██│ ┌──┐           │   │
│ │  │██│ │██│ │██│ ┌──┐      │   │
│ │  └──┘ └──┘ └──┘ └──┘      │   │
│ │  개발   영업  기획  CS     │   │
│ └────────────────────────────┘   │
└──────────────────────────────────┘
```

## 의존성

- 없음 (JS 차트 라이브러리 불필요, 순수 SVG)
- 기존 `operations/grouping.ex` 집계 로직 참고 가능

## 테스트 계획

| # | 테스트 | 설명 |
|---|--------|------|
| 1 | prepare_data/2 기본 | 카테고리별 집계 데이터 생성 |
| 2 | prepare_data/2 다중 값 | 복수 value_fields 집계 |
| 3 | aggregation 방식 | sum, avg, count, min, max 각각 |
| 4 | SVG bar 렌더링 | SVG 문자열 생성 확인 |
| 5 | SVG line 렌더링 | polyline 좌표 계산 |
| 6 | SVG pie 렌더링 | arc path 계산 |
| 7 | 빈 데이터 처리 | 데이터 없을 때 empty state |
| 8 | 차트 설정 변경 | 타입/컬럼 변경 시 데이터 재계산 |
| 9 | 필터 연동 | 필터 적용 후 차트 데이터 변경 확인 |
| 10 | 테마 대응 | 다크/라이트 모드 색상 |

## 일정

- Plan: 0.5일
- Design: 1일
- Do: 3일 (SVG 렌더러 1일 + 차트 모듈 1일 + UI 통합 1일)
- Check/Act: 1일

## 관련 기능

- [FA-031] 이전 구현 (코드 제거됨, changelog에만 기록)
- [F-500] Grouping/Aggregate — 집계 로직 재사용
- [Grid Settings] — 차트 옵션 설정 탭 추가 가능
- [Export] — 차트 이미지 내보내기 (향후)
