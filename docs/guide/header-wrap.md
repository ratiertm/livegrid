# Header Wrap

헤더 텍스트가 긴 경우 여러 줄로 줄바꿈합니다.

## Overview

기본적으로 헤더 셀은 한 줄(`white-space: nowrap`)로 표시됩니다. `header_wrap: true`를 설정하면 헤더 텍스트가 컬럼 너비에 맞게 자동 줄바꿈됩니다.

## Enabling Header Wrap

컬럼 정의에 `header_wrap: true`를 지정합니다:

```elixir
columns = [
  %{field: :long_field, label: "매우 긴 컬럼 헤더 이름", width: 100, header_wrap: true},
  %{field: :name, label: "이름", width: 150}
]
```

## CSS Classes

| 클래스 | 적용 대상 |
|--------|----------|
| `.lv-grid__header-cell--wrap` | 줄바꿈 활성화된 헤더 셀 |

`header_wrap: true` 셀은 `white-space: normal`, `height: auto`, `min-height: 48px`이 적용됩니다.

## Related

- [Column Definitions](./column-definitions.md) — header_wrap 속성
- [Wordwrap](./wordwrap.md) — 데이터 셀 줄바꿈
