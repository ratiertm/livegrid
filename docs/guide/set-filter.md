# Set Filter

Set Filter는 Excel 스타일의 체크박스 필터입니다.
컬럼의 고유값 목록을 표시하고, 사용자가 항목을 선택/해제하여 필터링합니다.

## Overview

텍스트 입력 대신 체크박스 목록으로 필터링합니다. 카테고리형 데이터(도시, 부서, 상태 등)에 적합합니다.

## Setup

컬럼 정의에서 `filter_type: :set`을 설정합니다:

```elixir
%{
  field: :city,
  label: "City",
  filterable: true,
  filter_type: :set
}
```

## Features

### Dropdown Panel

Floating Filter 셀의 드롭다운 버튼을 클릭하면 패널이 표시됩니다:

- **전체 선택** -- 모든 항목을 선택합니다
- **전체 해제** -- 모든 항목을 해제합니다
- **개별 체크박스** -- 항목별로 선택/해제합니다

### Selected Count Badge

드롭다운 버튼에 현재 선택된 항목 수가 표시됩니다:
- 필터 없음: "전체"
- 필터 있음: "3개 선택" 형태

### Auto-Close

패널 외부를 클릭하면 자동으로 닫힙니다.

## Example

```elixir
grid = Grid.new(
  data: [
    %{id: 1, name: "Alice", city: "Seoul"},
    %{id: 2, name: "Bob", city: "Busan"},
    %{id: 3, name: "Charlie", city: "Seoul"},
    %{id: 4, name: "David", city: "Daejeon"}
  ],
  columns: [
    %{field: :name, label: "Name", filterable: true},
    %{field: :city, label: "City", filterable: true, filter_type: :set}
  ],
  options: %{floating_filter: true}
)
```

## Internal Implementation

Set Filter는 내부적으로 JSON 인코딩된 값 목록으로 필터 상태를 저장합니다:

```elixir
# grid.state.filters
%{city: "[\"Seoul\",\"Busan\"]"}
```

`Filter.extract_unique_values/2`가 데이터에서 고유값을 추출하고,
`Filter.apply/3`가 `:set` 타입에 대해 목록 매칭을 수행합니다.

## CSS Customization

```css
.lv-grid__set-filter-dropdown { /* 드롭다운 패널 */ }
.lv-grid__set-filter-item { /* 체크박스 항목 */ }
.lv-grid__set-filter-actions { /* 전체 선택/해제 버튼 영역 */ }
```

## Related

- [Filtering](./filtering.md) -- 필터링 전체 개요
- [Floating Filters](./floating-filters.md) -- Floating Filter 상세
- [Column Definitions](./column-definitions.md) -- filter_type 속성
