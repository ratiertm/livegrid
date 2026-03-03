# Cell Tooltip

셀 텍스트가 잘릴 때 마우스를 올리면 전체 내용이 툴팁으로 표시됩니다.

## Overview

컬럼 너비보다 긴 텍스트는 말줄임(`...`)으로 표시됩니다. 마우스 호버 시 잘린 텍스트의 전체 내용이 네이티브 툴팁으로 나타납니다.

## Behavior

- **자동 감지**: `scrollWidth > clientWidth`인 셀에만 툴팁이 표시됩니다
- **네이티브 방식**: HTML `title` 속성을 사용합니다 (별도 JS 라이브러리 불필요)
- **동적 처리**: 컬럼 리사이즈 후에도 잘림 여부를 다시 계산합니다
- **비잘림 셀**: 텍스트가 잘리지 않은 셀에는 툴팁이 표시되지 않습니다

## 설정 불필요

별도 옵션 없이 자동으로 동작합니다. `GridKeyboardNav` Hook이 마우스 진입 이벤트를 감지하여 처리합니다.

## CSS

말줄임 표시는 셀 기본 스타일에 포함되어 있습니다:

```css
.lv-grid__cell-value {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
```

## Related

- [Column Sizing](./column-sizing.md) — 컬럼 너비 설정
- [Wordwrap](./wordwrap.md) — 자동 줄바꿈 (툴팁 대신 여러 줄 표시)
- [Formatters](./formatters.md) — 셀 값 포맷
