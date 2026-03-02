# Full-Width Rows

그리드 전체 너비를 사용하는 특수 행을 삽입합니다. 공지사항, 구분선, 설명 텍스트 등에 활용합니다.

## API

```elixir
# 맨 위에 전체 너비 행 추가
grid = Grid.add_full_width_row(grid, "공지: 3월 정산 마감일은 25일입니다")

# 특정 위치에 삽입 (index)
grid = Grid.add_full_width_row(grid, "--- 부서별 구분선 ---", 5)
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `content` | string | 행에 표시할 텍스트/HTML |
| `position` | integer | 삽입 위치 인덱스 (기본값: 0) |

## Behavior

- 자동 생성 ID: `fw_` prefix (예: `fw_1709234567`)
- 행 내부 데이터: `%{_row_type: :full_width, _content: content}`
- 모든 컬럼을 하나로 병합하여 표시
- 정렬/필터에 영향받지 않음
- 편집 불가

## CSS Class

```css
.lv-grid__row--full-width      /* 전체 너비 행 */
```
