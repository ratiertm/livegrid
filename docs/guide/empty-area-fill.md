# Empty Area Fill

데이터 행이 부족할 때 빈 행으로 그리드 영역을 채워 일정한 높이를 유지합니다.

## Enabling

```elixir
grid = Grid.new(columns, data, %{
  fill_empty_area: true,
  empty_area_rows: 10    # 최소 행 수 (기본값: 5)
})
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `fill_empty_area` | boolean | `false` | 빈 영역 채우기 활성화 |
| `empty_area_rows` | integer | `5` | 최소 표시 행 수 |

## Behavior

- 데이터 행 수가 `empty_area_rows`보다 적으면 나머지를 빈 행으로 채움
- 예: `empty_area_rows: 10`, 데이터 3건 → 빈 행 7개 추가
- 빈 행은 편집/선택/정렬 불가
- 각 빈 행의 셀 너비는 실제 컬럼 너비와 동일

## Example

```elixir
# 3건의 데이터 + 빈 행 7개 = 총 10행 표시
grid = Grid.new(columns, [row1, row2, row3], %{
  fill_empty_area: true,
  empty_area_rows: 10
})

# 데이터가 10건 이상이면 빈 행 없음
grid = Grid.new(columns, many_rows, %{
  fill_empty_area: true,
  empty_area_rows: 10
})
```

## CSS Classes

```css
.lv-grid__row--empty    /* 빈 행 (min-height: 40px, border-bottom) */
```

## CSS Customization

```css
/* 빈 행 배경색 */
.lv-grid__row--empty {
  background-color: #fafafa;
}

/* 빈 행 높이 조절 */
.lv-grid__row--empty {
  min-height: 32px;
}
```
