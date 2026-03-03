# Context Menu

셀에서 우클릭하면 복사, 행 추가/삭제 등의 작업을 수행할 수 있는 컨텍스트 메뉴가 나타납니다.

## Overview

Grid 셀 영역에서 마우스 우클릭 시 위치 기반 컨텍스트 메뉴가 표시됩니다. 브라우저 기본 메뉴를 대체합니다.

## Available Actions

| 액션 | 설명 |
|------|------|
| `copy_cell` | 셀 값 클립보드 복사 |
| `copy_row` | 행 전체 복사 |
| `insert_row_above` | 위에 새 행 삽입 |
| `insert_row_below` | 아래에 새 행 삽입 |
| `duplicate_row` | 현재 행 복제 |
| `delete_row` | 행 삭제 |

## Event Handlers

서버 측 이벤트 흐름:

```elixir
# 메뉴 표시 (JS에서 자동 호출)
handle_event("show_context_menu", %{
  "row_id" => row_id,
  "col_idx" => col_idx,
  "x" => x,
  "y" => y
}, socket)

# 메뉴 숨김
handle_event("hide_context_menu", _params, socket)

# 액션 실행
handle_event("context_menu_action", %{
  "action" => "copy_cell",
  "row-id" => row_id,
  "col_idx" => col_idx
}, socket)
```

## Behavior

- 셀 영역 우클릭 시 브라우저 기본 메뉴 대신 Grid 메뉴가 표시됩니다
- 메뉴 외부 클릭 시 자동으로 닫힙니다
- `Esc` 키로도 닫을 수 있습니다
- 편집 모드에서는 표시되지 않습니다

## CSS Classes

| 클래스 | 적용 대상 |
|--------|----------|
| `.lv-grid__context-menu` | 메뉴 컨테이너 |
| `.lv-grid__context-menu-item` | 메뉴 항목 |

## Related

- [Cell Editing](./cell-editing.md) — 셀 편집
- [CRUD Operations](./crud-operations.md) — 행 추가/삭제
- [Selection](./selection.md) — 행/셀 선택
- [Keyboard Navigation](./keyboard-navigation.md) — 키보드 단축키
