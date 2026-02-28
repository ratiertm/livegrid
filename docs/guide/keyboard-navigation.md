# Keyboard Navigation

Grid는 키보드만으로 완전한 탐색과 편집이 가능합니다.

## Navigation

| Shortcut | Action |
|----------|--------|
| `Arrow Keys` | 셀 간 이동 (상/하/좌/우) |
| `Tab` | 다음 셀로 이동 |
| `Shift+Tab` | 이전 셀로 이동 |
| `Home` | 행의 첫 번째 컬럼으로 이동 |
| `End` | 행의 마지막 컬럼으로 이동 |

## Editing

| Shortcut | Action |
|----------|--------|
| `Enter` | 셀 편집 시작 / 편집 확인 |
| `F2` | 셀 편집 시작 |
| `Escape` | 편집 취소 |
| `Tab` (편집 중) | 저장 후 다음 셀로 이동 |

## Clipboard

| Shortcut | Action |
|----------|--------|
| `Ctrl+C` | 선택된 셀/범위 복사 |
| `Ctrl+V` | 클립보드 내용 붙여넣기 |

## Edit History

| Shortcut | Action |
|----------|--------|
| `Ctrl+Z` | 마지막 편집 취소 (Undo) |
| `Ctrl+Y` | 취소한 편집 복원 (Redo) |

## Selection

| Shortcut | Action |
|----------|--------|
| `Ctrl+A` | 전체 행 선택 |
| `Right Click` | 컨텍스트 메뉴 표시 |

## GridKeyboardNav Hook

키보드 내비게이션은 `GridKeyboardNav` JS Hook으로 구현됩니다. Grid 컨테이너에 자동 적용되며 별도 설정이 필요 없습니다.

## Related

- [Cell Editing](./cell-editing.md) — 편집 워크플로우
- [Selection](./selection.md) — 셀 범위 선택
