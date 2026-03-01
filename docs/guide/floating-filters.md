# Floating Filters

Floating Filters는 헤더 바로 아래에 항상 표시되는 인라인 필터 행입니다.
사용자가 별도의 토글 없이 바로 필터 입력을 시작할 수 있습니다.

## Overview

기존 필터 행은 툴바 버튼으로 토글해야 표시되지만, Floating Filter는 그리드 옵션으로 항상 표시됩니다.

## Setup

Grid 옵션에서 `floating_filter: true`를 설정합니다:

```elixir
grid = Grid.new(
  data: data,
  columns: [
    %{field: :name, label: "Name", filterable: true},
    %{field: :age, label: "Age", filterable: true, filter_type: :number},
    %{field: :joined, label: "Joined", filterable: true, filter_type: :date}
  ],
  options: %{floating_filter: true}
)
```

## Per-Column Control

개별 컬럼에서 `floating_filter: false`를 설정하면 해당 컬럼의 필터를 숨깁니다:

```elixir
%{field: :id, label: "ID", filterable: true, floating_filter: false}
```

## Filter Input Types

컬럼의 `filter_type`에 따라 자동으로 적절한 입력 UI가 표시됩니다:

| filter_type | UI | Description |
|------------|-----|-------------|
| `:text` | 텍스트 입력 | 부분 문자열 매칭 |
| `:number` | 숫자 입력 | 비교 연산자 지원 (`>30`, `<=25`) |
| `:date` | 프리셋 드롭다운 + 날짜 범위 | 빠른 범위 선택 |
| `:set` | 드롭다운 체크박스 | 고유값 선택 필터 |

## Debounce

모든 필터 입력에는 300ms 디바운스가 적용되어 서버 부하를 최소화합니다.

## CSS Customization

Floating Filter 행은 `--floating` 변형 클래스를 사용합니다:

```css
.lv-grid__filter-row--floating {
  border-bottom: 2px solid var(--lv-grid-primary, #4285f4);
}
```

## Related

- [Filtering](./filtering.md) -- 필터링 전체 개요
- [Set Filter](./set-filter.md) -- Set Filter 상세
- [Column Definitions](./column-definitions.md) -- floating_filter 속성
