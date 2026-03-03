# Clipboard (Excel Paste)

Excel이나 스프레드시트에서 복사한 데이터를 Ctrl+V로 Grid에 붙여넣습니다.

## Overview

Excel, Google Sheets 등에서 셀 범위를 복사한 후 Grid에서 Ctrl+V를 누르면 현재 포커스 위치부터 데이터가 붙여넣어집니다. 탭으로 구분된 열, 줄바꿈으로 구분된 행을 자동 인식합니다.

## Keyboard Shortcuts

| 단축키 | 동작 |
|--------|------|
| `Ctrl+V` / `Cmd+V` | 클립보드 붙여넣기 |
| `Ctrl+C` / `Cmd+C` | 선택 영역 복사 |

## Paste Behavior

1. Grid에서 셀을 클릭하여 **시작 위치**를 선택합니다
2. `Ctrl+V`를 누릅니다
3. 클립보드 데이터가 시작 위치부터 채워집니다

```
Excel에서 복사:
┌────┬────┐
│ A1 │ B1 │     Grid 시작 위치: (row=2, col=1)
│ A2 │ B2 │     → Grid[2,1]=A1, Grid[2,2]=B1
└────┴────┘        Grid[3,1]=A2, Grid[3,2]=B2
```

## Server Event

JS Hook에서 파싱 후 서버로 전송합니다:

```elixir
# 자동 호출되는 이벤트 핸들러
handle_event("paste_cells", %{
  "start_row_id" => start_row_id,
  "start_col_idx" => start_col_idx,
  "data" => [["A1", "B1"], ["A2", "B2"]]
}, socket)
```

## Behavior

- **편집 모드가 아닐 때**만 붙여넣기가 동작합니다
- **포커스 셀**이 있어야 시작 위치가 결정됩니다
- 탭(`\t`) 구분 = 열, 줄바꿈(`\n`) 구분 = 행
- Grid 범위를 초과하는 데이터는 무시됩니다

## Related

- [Cell Editing](./cell-editing.md) — 셀 편집
- [Selection](./selection.md) — 셀 범위 선택
- [Import](./import.md) — 파일 기반 가져오기
- [Keyboard Navigation](./keyboard-navigation.md) — 키보드 조작
