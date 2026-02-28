# Row Editing

행 단위 편집 모드는 한 행의 모든 편집 가능한 셀을 동시에 편집합니다.

## Overview

단일 셀 편집과 달리, 행 편집 모드는 행 전체를 편집 상태로 전환합니다. 모든 변경 사항을 한 번에 저장하거나 취소할 수 있습니다.

## Entering Row Edit Mode

행의 연필 아이콘(✏️)을 클릭하면 행 편집 모드에 진입합니다:

- 모든 editable 컬럼이 편집기로 전환
- 연필 아이콘이 ✓(저장) / ✕(취소) 버튼으로 변경

## Navigation

| 키 | 동작 |
|----|------|
| `Tab` | 다음 편집 가능한 셀로 이동 |
| `Shift+Tab` | 이전 편집 가능한 셀로 이동 |
| `Enter` | 모든 변경 저장 |
| `Escape` | 모든 변경 취소 |

## Save & Cancel

- **저장 (✓)**: 모든 셀의 변경 사항을 적용, 행 상태 `:updated`
- **취소 (✕)**: 모든 셀을 원래 값으로 복원

## Visual Feedback

편집 중인 행은 특별한 스타일로 구분됩니다:
- 배경색 변경 (연한 파란색)
- 테두리 강조
- 다른 행과 시각적 분리

## Related

- [Cell Editing](./cell-editing.md) — 단일 셀 편집
- [CRUD Operations](./crud-operations.md) — 변경 사항 저장
- [Keyboard Navigation](./keyboard-navigation.md) — Tab 이동
