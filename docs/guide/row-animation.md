# Row Animation

행 상태 변경 시 시각적 애니메이션 효과를 적용합니다.

## Overview

행이 추가·수정·삭제될 때 CSS 애니메이션으로 변경을 시각화합니다. 사용자가 어떤 행이 변경되었는지 쉽게 인식할 수 있습니다.

## Animation Types

| 상태 | 효과 | 설명 |
|------|------|------|
| 추가 (New) | fade-in | 새 행이 부드럽게 나타남 |
| 수정 (Updated) | highlight | 배경색이 잠시 강조됨 |
| 삭제 (Deleted) | fade-out | 행이 부드럽게 사라짐 |

## CSS Animations

행 상태에 따라 자동으로 CSS 클래스가 적용됩니다:

```css
/* 추가된 행 */
.lv-grid__row--new {
  animation: fadeIn 0.3s ease-in;
}

/* 수정된 행 */
.lv-grid__row--updated {
  animation: highlight 0.5s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes highlight {
  0% { background-color: #fff3cd; }
  100% { background-color: transparent; }
}
```

## Status Badge Animation

행 상태 배지(N/U/D)에도 펄스 애니메이션이 적용됩니다:

```css
.lv-grid__status-badge {
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
```

## Behavior

- 행의 `row_status`가 변경될 때 애니메이션이 자동 트리거됩니다
- `nil` status는 애니메이션이 적용되지 않습니다 (v0.11.0 버그 수정)
- 저장 후 상태가 초기화되면 애니메이션도 제거됩니다

## Related

- [CRUD Operations](./crud-operations.md) — 행 추가/수정/삭제
- [Row Editing](./row-editing.md) — 행 단위 편집
- [Themes](./themes.md) — 테마 스타일
