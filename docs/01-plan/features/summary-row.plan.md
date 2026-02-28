# Summary Row (하단 고정 집계 행)

> **Version**: v0.8
> **Priority**: HIGH
> **Status**: Plan
> **Feature ID**: F-950

---

## 목표

Grid 하단(Footer 위)에 **Summary Band**(고정 집계 행)를 렌더링합니다.
컬럼별로 `sum`, `avg`, `count`, `min`, `max` 등의 집계 함수를 지정하면
전체 데이터(또는 필터 적용 후 데이터)에 대한 집계 값이 항상 표시됩니다.

넥사크로 Grid의 Summary Band에 해당하는 기능입니다.

## 기존 코드 분석

### 재사용 가능한 자산
1. **`Grouping.compute_aggregates/2`** (`grouping.ex:81-104`)
   - 이미 `sum`, `avg`, `count`, `min`, `max` 지원
   - `%{field => func}` 맵을 받아 `%{field => result}` 반환
   - Summary Row에서 그대로 재사용 가능

2. **`Grid.cell_range_summary/1`** (`grid.ex:1073-1126`)
   - 셀 범위 선택 시 통계 계산 (유사 패턴 참고)

3. **`RenderHelpers.format_summary_number/1`** (`render_helpers.ex:632-644`)
   - 천단위 구분자 포맷팅 (Summary Row에서도 재사용)

4. **CSS BEM 패턴** (`.lv-grid__*`)
   - 기존 footer, range-summary 스타일 참고

### 기존 구조와의 관계
- `options.show_footer` — Footer 내에 Summary Row 표시
- `state.group_aggregates` — 그룹 집계와 별개로 전체 데이터 집계
- 페이지네이션/virtual scroll과 무관하게 **전체 데이터** 기반 집계

## 요구사항

### FR-01: 컬럼별 집계 함수 지정
- 컬럼 정의에 `summary: :sum` 형태로 집계 함수 지정
- 지원 함수: `:sum`, `:avg`, `:count`, `:min`, `:max`
- 미지정 컬럼은 빈 셀로 표시

### FR-02: Summary 행 렌더링
- 데이터 Body 아래, Footer(페이지네이션) 위에 고정 위치
- 스크롤 시에도 항상 보임 (sticky)
- 각 셀은 해당 컬럼과 동일한 너비 유지 (frozen 컬럼, 리사이즈 반영)

### FR-03: 실시간 집계 갱신
- 데이터 변경(편집, 추가, 삭제) 시 자동 재계산
- 필터/검색 적용 시 필터링된 데이터 기준 재계산
- 정렬 변경은 집계에 영향 없음 (값 불변)

### FR-04: 포맷팅
- `format_summary_number/1` 재사용 (천단위 구분자)
- 컬럼에 `formatter`가 지정된 경우 해당 포맷터 적용

### FR-05: 옵션
- `options.show_summary: true/false` — Summary 행 표시 여부 (기본: false)
- 컬럼에 `summary` 키가 하나라도 있으면 자동 활성화

### FR-06: DataSource 호환
- InMemory: 로컬 데이터 기반 집계
- Ecto/REST: 가져온 데이터(`grid.data`) 기반 집계 (서버사이드 집계는 향후)

## 구현 범위

### 1. Backend (Elixir)

#### grid.ex
- `default_options`에 `show_summary: false` 추가
- `normalize_columns`에 `summary` 키 정규화 (기본값: nil)
- `compute_summary/1` 함수: 컬럼의 summary 설정을 추출 → `Grouping.compute_aggregates/2` 호출
- `summary_data/1` 공개 함수: 필터/검색 적용 후 데이터 기반 집계 결과 반환

#### grouping.ex
- 변경 없음 (기존 `compute_aggregates/2` 재사용)

### 2. Frontend (HEEx Template)

#### grid_component.ex
- `render_summary_row/1` 함수 추가
  - Body와 Footer 사이에 위치
  - 각 컬럼에 대해 집계 값 또는 빈 셀 렌더링
  - frozen 컬럼, 행번호 컬럼, 체크박스 컬럼 처리
  - 컬럼 너비(column_widths) 반영

### 3. CSS

#### liveview_grid.css (또는 assets/css/grid/layout.css)
- `.lv-grid__summary-row` — 고정 위치, 배경색 구분
- `.lv-grid__summary-cell` — 셀 스타일 (우측 정렬, bold)
- `.lv-grid__summary-label` — 집계 함수명 라벨 (선택적)

### 4. Demo

#### demo_live.ex
- salary 컬럼에 `summary: :sum` 추가
- age 컬럼에 `summary: :avg` 추가
- Summary Row 동작 시연

## 의존성

- `Grouping.compute_aggregates/2` ✅ 구현 완료
- `RenderHelpers.format_summary_number/1` ✅ 구현 완료
- Footer 렌더링 구조 ✅ 구현 완료
- Frozen 컬럼 ✅ 구현 완료

## 구현 순서

1. `grid.ex`: `normalize_columns`에 `summary` 키 추가 + `default_options`에 `show_summary` 추가
2. `grid.ex`: `summary_data/1` 공개 함수 구현 (필터 적용 데이터 → `compute_aggregates` 호출)
3. `grid_component.ex`: `render_summary_row/1` 함수 추가 (Body-Footer 사이)
4. CSS: Summary Row 스타일링
5. `demo_live.ex`: Summary 컬럼 설정 추가
6. 테스트: `summary_data/1` 단위 테스트 + 렌더링 테스트

## 예상 소요

- 난이도: ⭐⭐ (기존 집계 로직 재사용, 렌더링만 추가)
- 변경 파일: 4개 (grid.ex, grid_component.ex, CSS, demo_live.ex)
- 신규 함수: 2개 (`summary_data/1`, `render_summary_row/1`)

## 사용 예시

```elixir
Grid.new(
  data: employees,
  columns: [
    %{field: :name, label: "이름"},
    %{field: :department, label: "부서"},
    %{field: :salary, label: "급여", formatter: :currency, align: :right, summary: :sum},
    %{field: :age, label: "나이", align: :right, summary: :avg},
    %{field: :active, label: "활성", editor_type: :checkbox, summary: :count}
  ],
  options: %{show_summary: true}
)
```

렌더링 결과:
```
| 이름   | 부서   |    급여    | 나이 | 활성 |
|--------|--------|-----------|------|------|
| Alice  | Dev    | 5,000,000 |  28  |  ✓   |
| Bob    | Sales  | 4,200,000 |  35  |  ✓   |
| Carol  | Dev    | 6,100,000 |  31  |      |
|========|========|===========|======|======|
|        |        |15,300,000 | 31.3 |   3  |  ← Summary Row
|--------|--------|-----------|------|------|
|          << 1 2 3 >>  | 3건 / 3건       |  ← Footer
```
