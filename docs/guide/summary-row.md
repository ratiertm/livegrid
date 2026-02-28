# Summary Row

Grid 하단에 고정된 집계 행을 표시합니다. 컬럼별로 합계, 평균, 건수 등을 자동 계산합니다.

## Overview

Summary Row는 데이터 Body 아래, Footer(페이지네이션) 위에 고정 위치로 표시됩니다. 필터/검색 결과에 따라 실시간으로 재계산됩니다.

## Enabling Summary Row

컬럼 정의에 `summary` 속성을 지정합니다:

```elixir
columns = [
  %{field: :name, label: "이름"},
  %{field: :salary, label: "급여", align: :right, summary: :sum},
  %{field: :age, label: "나이", align: :right, summary: :avg},
  %{field: :active, label: "활성", summary: :count}
]
```

`summary` 속성이 있는 컬럼이 하나라도 있으면 Summary Row가 자동 표시됩니다.

## Aggregate Functions

| Function | 설명 | 동작 |
|----------|------|------|
| `:sum` | 합계 | 숫자 값의 총합 (nil 제외) |
| `:avg` | 평균 | 숫자 값의 산술 평균 (nil 제외) |
| `:count` | 건수 | 전체 행 수 (타입 무관) |
| `:min` | 최소값 | 숫자 값 중 최소 (nil 제외) |
| `:max` | 최대값 | 숫자 값 중 최대 (nil 제외) |

## Programmatic Access

```elixir
# 집계 결과 조회
Grid.summary_data(grid)
# => %{salary: 15300000, age: 31.3, active: 3}
```

## Behavior

- **필터 반응**: 필터/검색 적용 시 필터링된 데이터 기준으로 재계산
- **정렬 무관**: 정렬 변경은 집계에 영향 없음
- **nil 처리**: nil 값은 sum/avg/min/max 계산에서 제외, count에는 포함
- **포맷팅**: `format_summary_number` 적용 (천단위 구분자, 소수점 2자리)

## show_summary Option

명시적으로 표시 여부를 제어할 수 있습니다:

```elixir
# 명시적 활성화
options = %{show_summary: true}

# 명시적 비활성화 (summary 컬럼이 있어도 숨김)
options = %{show_summary: false}
```

## Visual Structure

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

## Related

- [Grouping](./grouping.md) — 그룹별 집계
- [Column Definitions](./column-definitions.md) — summary 속성
- [Formatters](./formatters.md) — 값 포맷팅
