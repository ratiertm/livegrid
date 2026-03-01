# Column Menu

Column Menu는 헤더 셀에 마우스를 올리면 표시되는 컨텍스트 메뉴입니다.
정렬, 컬럼 숨기기, 자동 너비 맞춤 등의 기능을 제공합니다.

## Overview

헤더 셀의 오른쪽에 표시되는 hamburger 메뉴 버튼을 클릭하면 드롭다운 메뉴가 열립니다.

## Features

### Menu Items

| Action | Description |
|--------|-------------|
| **Sort Ascending** | 오름차순 정렬 (sortable 컬럼만) |
| **Sort Descending** | 내림차순 정렬 (sortable 컬럼만) |
| **Clear Sort** | 정렬 초기화 (정렬 중인 컬럼만) |
| **Hide Column** | 컬럼 숨기기 |
| **Auto Size** | 자동 너비 맞춤 (내용에 맞게 너비 조정) |

### Show Hidden Columns

숨겨진 컬럼이 있으면 메뉴 하단에 "Show: [컬럼명]" 항목이 추가됩니다.

## Usage

Column Menu는 별도 설정 없이 기본으로 활성화됩니다. 헤더 셀에 마우스를 올리면 자동으로 표시됩니다.

## API

### Hide/Show Columns

```elixir
# 컬럼 숨기기
grid = Grid.hide_column(grid, :age)

# 컬럼 다시 표시
grid = Grid.show_column(grid, :age)

# 숨겨진 컬럼 목록 조회
hidden = Grid.hidden_columns(grid)
# => [:age]
```

### Display Columns

`Grid.display_columns/1`은 숨겨진 컬럼을 자동으로 제외합니다:

```elixir
# 현재 표시 중인 컬럼 목록
visible_cols = Grid.display_columns(grid)
```

## CSS Customization

```css
.lv-grid__column-menu-btn { /* 메뉴 버튼 */ }
.lv-grid__column-menu { /* 드롭다운 메뉴 */ }
.lv-grid__column-menu-item { /* 메뉴 항목 */ }
.lv-grid__column-menu-divider { /* 구분선 */ }
```

## Related

- [Column Definitions](./column-definitions.md) -- 컬럼 속성 전체
- [Sorting](./sorting.md) -- 정렬 동작 상세
- [Filtering](./filtering.md) -- 필터링 상세
