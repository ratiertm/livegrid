# Row Animation

행 추가/삭제 시 부드러운 애니메이션 효과를 적용합니다.

## Enabling

```elixir
grid = Grid.new(columns, data, %{
  animate_rows: true
})
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `animate_rows` | boolean | `false` | 행 애니메이션 활성화 |

## Animations

### Row Enter (행 추가)

새 행이 삽입될 때 위에서 아래로 슬라이드하며 나타남:
- Duration: 0.2s
- Easing: ease-out
- 효과: opacity 0→1, translateY -8px→0

### Row Exit (행 삭제)

행이 삭제될 때 아래로 슬라이드하며 사라짐:
- Duration: 0.2s
- Easing: ease-in
- 효과: opacity 1→0, translateY 0→8px

## CSS Classes

```css
.lv-grid--animate-rows          /* 애니메이션 활성화된 그리드 */
.lv-grid--animate-rows .lv-grid__row  /* enter 애니메이션 자동 적용 */
.lv-grid__row--removing         /* exit 애니메이션 (삭제 시) */
```

## CSS Customization

```css
/* 애니메이션 속도 변경 */
.lv-grid--animate-rows .lv-grid__row {
  animation-duration: 0.4s;
}

/* 애니메이션 비활성화 (접근성) */
@media (prefers-reduced-motion: reduce) {
  .lv-grid--animate-rows .lv-grid__row {
    animation: none;
  }
}
```
