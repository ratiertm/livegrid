# Filtering

Grid는 3가지 필터링 방식을 제공합니다: 컬럼 필터, 전체 검색, 고급 필터.

## Overview

필터를 활성화하려면 컬럼에 `filterable: true`를 설정합니다:

```elixir
%{field: :name, label: "이름", filterable: true, filter_type: :text}
```

## Column Filters

각 컬럼 아래에 필터 입력 필드가 표시됩니다. 필터 행은 툴바의 필터 토글 버튼으로 표시/숨김 전환합니다.

### Filter Types

| filter_type | 동작 | 예시 |
|------------|------|------|
| `:text` | 부분 문자열 매칭 (대소문자 무시) | "ali" → "Alice", "Alison" |
| `:number` | 숫자 비교 연산 | `">30"`, `">=25"`, `"<40"`, `"=30"` |
| `:date` | 날짜 범위 필터 | ISO 형식 날짜 비교 |

```elixir
columns = [
  %{field: :name, label: "이름", filterable: true, filter_type: :text},
  %{field: :age, label: "나이", filterable: true, filter_type: :number},
  %{field: :created_at, label: "가입일", filterable: true, filter_type: :date}
]
```

### Number Filter Operators

숫자 필터는 비교 연산자를 지원합니다:

| 입력 | 의미 |
|------|------|
| `30` | = 30 |
| `>30` | > 30 |
| `>=30` | >= 30 |
| `<30` | < 30 |
| `<=30` | <= 30 |

## Global Search

툴바의 검색 입력 필드를 통해 모든 컬럼에서 동시에 검색합니다:

- 300ms 디바운스 적용
- 대소문자 무시
- 모든 컬럼의 값을 문자열로 변환하여 매칭

## Advanced Filters

고급 필터는 여러 조건을 AND/OR로 조합할 수 있습니다:

### 지원 연산자

| Operator | 설명 | 적용 타입 |
|----------|------|-----------|
| `eq` | 같음 | 전체 |
| `ne` | 같지 않음 | 전체 |
| `gt` | 크다 | 숫자, 날짜 |
| `gte` | 크거나 같다 | 숫자, 날짜 |
| `lt` | 작다 | 숫자, 날짜 |
| `lte` | 작거나 같다 | 숫자, 날짜 |
| `contains` | 포함 | 텍스트 |
| `starts` | 시작 | 텍스트 |
| `ends` | 종료 | 텍스트 |
| `between` | 범위 | 숫자, 날짜 |

### 사용 흐름

1. 툴바의 "고급 필터" 버튼 클릭
2. 조건 추가: 필드 → 연산자 → 값
3. AND/OR 로직 선택
4. 여러 조건 조합 가능

## Filter State

필터 상태는 Grid state에서 관리됩니다:

```elixir
# 컬럼 필터 상태
grid.state.filters
# => %{name: "Alice", age: ">30"}

# 고급 필터 상태
grid.state.advanced_filters
# => %{logic: :and, conditions: [
#      %{field: :age, operator: :gte, value: 25},
#      %{field: :city, operator: :eq, value: "서울"}
#    ]}
```

## Clearing Filters

- 컬럼 필터: 각 필터 입력을 비우거나 "필터 초기화" 버튼
- 고급 필터: "고급 필터 초기화" 버튼
- 전체 검색: 검색 입력 비우기

## Floating Filters (v0.12)

헤더 바로 아래에 항상 표시되는 인라인 필터입니다. 토글 없이 바로 필터링이 가능합니다.

```elixir
grid = Grid.new(
  data: data,
  columns: columns,
  options: %{floating_filter: true}
)
```

컬럼별로 floating filter를 비활성화할 수 있습니다:

```elixir
%{field: :id, label: "ID", filterable: true, floating_filter: false}
```

자세한 내용은 [Floating Filters](./floating-filters.md) 가이드를 참고하세요.

## Date Filter Presets (v0.12)

Date 타입 필터에 빠른 범위 선택 프리셋이 추가되었습니다:

| 프리셋 | 설명 |
|--------|------|
| 오늘 | 오늘 날짜만 |
| 어제 | 어제 날짜만 |
| 이번 주 | 현재 주 (월~일) |
| 지난 주 | 이전 주 |
| 이번 달 | 현재 월 |
| 지난 달 | 이전 월 |
| 최근 30일 | 오늘 기준 30일 |
| 최근 90일 | 오늘 기준 90일 |

## Set Filter (v0.12)

Excel 스타일 체크박스 필터입니다. 고유값 목록에서 항목을 선택/해제하여 필터링합니다.

```elixir
%{field: :city, label: "도시", filterable: true, filter_type: :set}
```

자세한 내용은 [Set Filter](./set-filter.md) 가이드를 참고하세요.

## Column Menu (v0.12)

헤더 셀에 마우스를 올리면 표시되는 메뉴를 통해 정렬, 필터, 컬럼 숨기기 등을 수행할 수 있습니다. 자세한 내용은 [Column Menu](./column-menu.md) 가이드를 참고하세요.

## Related

- [Column Definitions](./column-definitions.md) — filterable, filter_type 속성
- [Floating Filters](./floating-filters.md) — Floating Filter 상세
- [Set Filter](./set-filter.md) — Set Filter 상세
- [Column Menu](./column-menu.md) — Column Menu 상세
- [Sorting](./sorting.md) — 필터와 정렬 조합
- [Data Sources](./data-sources.md) — 서버사이드 필터링
