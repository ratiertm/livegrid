# Infinite Scroll

스크롤이 하단에 도달하면 자동으로 다음 데이터를 로드합니다.

## Overview

Infinite Scroll은 페이지네이션 UI 없이 스크롤만으로 데이터를 연속 로드하는 방식입니다. Virtual Scroll과 결합하여 대용량 데이터를 효율적으로 표시합니다.

## Enabling Infinite Scroll

`options`에서 설정합니다:

```elixir
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="my-grid"
  data={@data}
  columns={@columns}
  options={%{
    virtual_scroll: true,
    page_size: 20,
    row_height: 40,
    virtual_buffer: 5
  }}
/>
```

## Virtual Scroll Options

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `virtual_scroll` | boolean | `false` | 가상 스크롤 활성화 |
| `page_size` | integer | `20` | 한 번에 표시할 행 수 |
| `row_height` | integer | `40` | 행 높이 (px) |
| `virtual_buffer` | integer | `5` | 뷰포트 위/아래 버퍼 행 수 |

## Detection Logic

v0.11.0에서 개선된 스크롤 감지:

- 스크롤 위치가 하단에 근접하면 다음 청크를 요청합니다
- 버퍼 영역을 활용하여 빈 화면이 보이기 전에 미리 로드합니다
- `scrollTop + clientHeight >= scrollHeight - threshold` 조건으로 감지합니다

## Server Push Events

```elixir
# 가상 스크롤 위치 초기화
push_event(socket, "reset_virtual_scroll", %{})

# 특정 행으로 스크롤
push_event(socket, "scroll_to_row", %{row_id: row_id})
```

## Behavior

- 뷰포트에 보이는 행만 DOM에 렌더링됩니다 (성능 최적화)
- 스크롤 방향에 따라 위/아래 버퍼가 동적으로 관리됩니다
- 정렬/필터 변경 시 스크롤 위치가 자동 초기화됩니다
- `append-data.md`의 데이터 추가 방식과 결합 가능합니다

## Related

- [Append Data](./append-data.md) — 데이터 동적 추가
- [Pagination](./pagination.md) — 페이지 기반 탐색
- [Row Data](./row-data.md) — 데이터 바인딩
- [Grid Options](./grid-options.md) — Virtual Scroll 설정
