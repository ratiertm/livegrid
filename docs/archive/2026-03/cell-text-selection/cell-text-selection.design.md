# FA-020 Cell Text Selection — 기술 설계서

> **Feature ID**: FA-020
> **Version**: v0.12.0
> **Created**: 2026-03-05

---

## Step 1: Grid 옵션 기본값 추가

**파일**: `lib/liveview_grid/grid.ex` — `default_options/0`

```elixir
# default_options 맵에 추가
text_selectable: false
```

## Step 2: grid_component.ex — 루트 클래스 조건부 추가

**파일**: `lib/liveview_grid_web/components/grid_component.ex`

Grid 루트 `<div class="lv-grid ...">` 에 조건부 클래스 추가:

```heex
<div class={"lv-grid #{if @grid.options[:text_selectable], do: "lv-grid--text-selectable"} ..."}>
```

## Step 3: CSS 규칙 추가

**파일**: `assets/css/grid/body.css`

```css
/* FA-020: Cell Text Selection */
.lv-grid--text-selectable .lv-grid__cell {
  user-select: text;
  -webkit-user-select: text;
  cursor: text;
}

.lv-grid--text-selectable .lv-grid__cell-value {
  user-select: text;
  -webkit-user-select: text;
}

/* 헤더, 행번호, 체크박스는 선택 제외 */
.lv-grid--text-selectable .lv-grid__header-cell,
.lv-grid--text-selectable .lv-grid__cell--row-number,
.lv-grid--text-selectable .lv-grid__cell-checkbox {
  user-select: none;
  -webkit-user-select: none;
  cursor: default;
}
```

## Step 4: 데모 페이지 적용

**파일**: `lib/liveview_grid_web/live/demo_live.ex`

```elixir
# grid 옵션에 추가
text_selectable: true
```

## 변경 요약

| Step | 파일 | 라인 수 |
|------|------|---------|
| 1 | grid.ex | +1 |
| 2 | grid_component.ex | +1 |
| 3 | body.css | +15 |
| 4 | demo_live.ex | +1 |
| **합계** | | **~18줄** |
