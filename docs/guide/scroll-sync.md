# Scroll Sync

두 Grid의 스크롤 위치를 동기화합니다.

## Overview

Scroll Sync는 한 Grid를 스크롤하면 다른 Grid도 같은 위치로 스크롤되는 기능입니다. 마스터-디테일 뷰나 비교 뷰에 유용합니다.

## Enabling Scroll Sync

Grid의 wrapper에 `ScrollSync` Hook과 `data-sync-target`을 지정합니다:

```heex
<div id="grid-left" phx-hook="ScrollSync" data-sync-target="grid-right">
  <.live_component module={LiveviewGridWeb.GridComponent}
    id="left-grid"
    data={@left_data}
    columns={@columns}
  />
</div>

<div id="grid-right">
  <.live_component module={LiveviewGridWeb.GridComponent}
    id="right-grid"
    data={@right_data}
    columns={@columns}
  />
</div>
```

## Bidirectional Sync

양방향 동기화를 원하면 양쪽 모두에 Hook을 설정합니다:

```heex
<div id="grid-a" phx-hook="ScrollSync" data-sync-target="grid-b">...</div>
<div id="grid-b" phx-hook="ScrollSync" data-sync-target="grid-a">...</div>
```

## Sync Behavior

- 수직 스크롤(`scrollTop`)만 동기화됩니다
- 원본 Grid의 `.lv-grid__body` 스크롤 이벤트를 감지합니다
- 대상 Grid의 `.lv-grid__body`에 동일한 `scrollTop` 값을 설정합니다

## JS Hook

`ScrollSync` Hook은 `assets/js/hooks/scroll-sync.js`에 정의됩니다. app.js에서 자동 등록됩니다.

## Related

- [Pagination](./pagination.md) — 페이지 동기화
- [Grid Options](./grid-options.md) — virtual_scroll 옵션
