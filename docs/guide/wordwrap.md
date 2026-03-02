# Wordwrap

셀 내 텍스트가 컬럼 너비를 초과할 때 자동으로 줄바꿈합니다.

## Overview

기본적으로 셀 텍스트는 한 줄로 표시되고 넘치면 잘립니다(`text-overflow: ellipsis`). Wordwrap을 활성화하면 텍스트가 셀 너비에 맞춰 자동 줄바꿈되고, 행 높이가 내용에 맞게 확장됩니다.

## Enabling Wordwrap

컬럼 정의에 `wordwrap` 속성을 지정합니다:

```elixir
columns = [
  %{field: :name, label: "이름", width: 150},
  %{field: :description, label: "설명", width: 200, wordwrap: :word},
  %{field: :code, label: "코드", width: 100, wordwrap: :char}
]
```

## Wrap Modes

| Mode | 설명 | 줄바꿈 기준 |
|------|------|------------|
| 없음 (기본) | 줄바꿈 없음, 넘침 시 `...` 표시 | - |
| `:word` | 단어 단위 줄바꿈 | 공백/하이픈 위치에서 줄바꿈 |
| `:char` | 글자 단위 줄바꿈 | 모든 문자 위치에서 줄바꿈 가능 |

### 비교 예시

```
| word 모드          | char 모드          |
|--------------------|--------------------|
| This is a very     | This is a very lon |
| long text that     | g text that wraps  |
| wraps at words     | at characters      |
```

`:word`는 영문 텍스트에, `:char`는 한글/중국어/일본어 등 공백 없는 텍스트에 적합합니다.

## CSS Classes

| 클래스 | 적용 대상 |
|--------|----------|
| `.lv-grid__cell--wordwrap-word` | word 모드 셀 |
| `.lv-grid__cell--wordwrap-char` | char 모드 셀 |
| `.lv-grid__cell-value--wordwrap` | 셀 값 span (word 또는 char) |

## Custom Styling

wordwrap 셀의 스타일을 커스터마이징할 수 있습니다:

```css
/* 줄바꿈 셀의 최대 높이 제한 */
.lv-grid__cell--wordwrap-word {
  max-height: 80px;
  overflow-y: auto;
}
```

## Related

- [Column Definitions](./column-definitions.md) — wordwrap 속성
- [Row Height](./row-height.md) — 행 높이 자동 조절
- [Formatters](./formatters.md) — 값 포맷팅
