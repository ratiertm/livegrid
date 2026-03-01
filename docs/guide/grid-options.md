# Grid Options

Grid 생성 시 `options` 맵으로 전체 동작을 제어합니다.

## Overview

```elixir
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="my-grid"
  data={@data}
  columns={@columns}
  options={%{page_size: 50, theme: "dark", virtual_scroll: true}}
/>
```

## Options Reference

### Pagination & Scrolling

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `page_size` | `integer` | `20` | 페이지당 행 수 |
| `virtual_scroll` | `boolean` | `false` | 가상 스크롤 활성화 |
| `virtual_buffer` | `integer` | `5` | 가상 스크롤 버퍼 행 수 |
| `row_height` | `integer` | `40` | 행 높이 (px) |

### Display

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `show_header` | `boolean` | `true` | 컬럼 헤더 표시 |
| `show_footer` | `boolean` | `true` | Footer(페이지네이션) 표시 |
| `show_row_number` | `boolean` | `false` | 행번호 컬럼 표시 |
| `show_summary` | `boolean` | `false` | Summary Row 표시 |
| `show_status_bar` | `boolean` | `false` | 하단 Status Bar 표시 (총 행수, 선택/필터/변경/고정 수) |
| `column_hover_highlight` | `boolean` | `false` | 마우스 위치 컬럼 전체 하이라이트 |

### State Persistence

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `state_persistence` | `boolean` | `false` | Grid 상태 localStorage 자동 저장/복원 |

### Layout

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `frozen_columns` | `integer` | `0` | 좌측 고정 컬럼 수 |

### Theme

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `theme` | `string` | `"light"` | `"light"` / `"dark"` / custom |
| `custom_css_vars` | `map` | `%{}` | CSS 변수 오버라이드 |

### Development

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `debug` | `boolean` | `false` | 디버그 패널 표시 |

## Runtime Configuration

Grid Settings 모달을 통해 런타임에 옵션을 변경할 수 있습니다:

```elixir
grid = Grid.apply_grid_settings(grid, %{
  page_size: 100,
  virtual_scroll: true,
  theme: "dark",
  row_height: 36
})
```

## Grid Config Modal

v0.7에서 추가된 Grid 설정 모달:
- 컬럼 표시/숨김 토글
- 컬럼 순서 드래그 & 드롭
- 컬럼 너비 조절
- Frozen 컬럼 설정
- 포맷터 변경
- Grid 옵션 변경 (페이지 크기, 테마, 가상 스크롤)
- 원본 정의로 리셋

## Related

- [Getting Started](./getting-started.md) -- 기본 설정
- [Pagination](./pagination.md) -- page_size, virtual_scroll 상세
- [Themes](./themes.md) -- 테마 커스터마이징
- [State Persistence](./state-persistence.md) -- 상태 저장/복원 상세
- [Find & Highlight](./find-and-highlight.md) -- 검색 하이라이트
