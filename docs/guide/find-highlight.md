# Find & Highlight

그리드 내에서 텍스트를 검색하고 매치된 셀을 하이라이트합니다.

## API

```elixir
# 찾기 바 토글
grid = Grid.toggle_find_bar(grid)

# 텍스트 검색
grid = Grid.find_in_grid(grid, "검색어")

# 다음 매치로 이동
grid = Grid.find_next(grid)

# 이전 매치로 이동
grid = Grid.find_prev(grid)

# 검색 초기화
grid = Grid.find_in_grid(grid, "")
```

## Features

- 대소문자 무시 (case-insensitive)
- 모든 컬럼에서 검색
- 매치된 셀 하이라이트 표시
- 다음/이전 내비게이션 (순환)
- 현재 매치 위치 표시 (예: "3/15")

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+F` | 찾기 바 열기 |
| `Enter` | 다음 매치 |
| `Shift+Enter` | 이전 매치 |
| `Escape` | 찾기 바 닫기 |

## CSS Classes

```css
.lv-grid__find-bar             /* 찾기 바 컨테이너 */
.lv-grid__cell--find-match     /* 매치된 셀 하이라이트 */
.lv-grid__cell--find-current   /* 현재 포커스된 매치 */
```

## Difference from Global Search

| Feature | Global Search | Find & Highlight |
|---------|-------------|-----------------|
| 위치 | 툴바 검색창 | 별도 찾기 바 |
| 동작 | 데이터 필터링 (행 숨김) | 매치 하이라이트 (행 유지) |
| 내비게이션 | 없음 | 다음/이전 이동 |
