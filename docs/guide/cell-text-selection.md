# Cell Text Selection

셀 내 텍스트를 마우스로 드래그하여 선택/복사할 수 있게 합니다.

## Enabling

```elixir
grid = Grid.new(columns, data, %{
  enable_cell_text_selection: true
})
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable_cell_text_selection` | boolean | `false` | 셀 텍스트 선택 활성화 |

## Behavior

- 활성화 시 셀의 `user-select: text`, `cursor: text` 적용
- 마우스 드래그로 셀 내 텍스트 부분 선택 가능
- `Ctrl+C`(또는 `Cmd+C`)로 선택된 텍스트 복사
- 상태 컬럼(`--status`)과 체크박스 컬럼(`--checkbox`)은 항상 선택 불가

## Default Behavior (비활성화 시)

기본적으로 셀 텍스트 선택은 비활성화되어 있습니다:
- `user-select: none` 적용
- 셀 클릭 시 행 선택/셀 편집으로 동작
- 범위 선택(cell range) 드래그와 충돌 방지

## CSS Classes

```css
.lv-grid--text-selectable              /* 텍스트 선택 활성화된 그리드 */
.lv-grid--text-selectable .lv-grid__cell        /* 텍스트 선택 가능 셀 */
.lv-grid--text-selectable .lv-grid__cell--status   /* 선택 제외: 상태 셀 */
.lv-grid--text-selectable .lv-grid__cell--checkbox /* 선택 제외: 체크박스 셀 */
```

## Note

> 셀 범위 선택(Cell Range Selection)과 텍스트 선택은 동시에 사용할 수 없습니다.
> 범위 선택 중에는 `lv-grid--selecting` 클래스가 적용되어 `user-select: none`으로 전환됩니다.
