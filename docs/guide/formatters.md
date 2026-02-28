# Formatters

Grid는 16가지 내장 포맷터를 제공합니다. 컬럼 정의에 `formatter` 속성으로 지정합니다.

## Overview

```elixir
%{field: :salary, label: "급여", formatter: :currency}
```

## Built-in Formatters

### Number Formatters

| Formatter | Input | Output |
|-----------|-------|--------|
| `:number` | `75000000` | `75,000,000` |
| `:currency` | `75000000` | `₩75,000,000` |
| `:dollar` | `1500.5` | `$1,500.50` |
| `:percent` | `0.856` | `85.6%` |
| `:filesize` | `1048576` | `1.0 MB` |

### Date/Time Formatters

| Formatter | Input | Output |
|-----------|-------|--------|
| `:date` | `~N[2026-02-22 14:30:00]` | `2026-02-22` |
| `:datetime` | `~N[2026-02-22 14:30:00]` | `2026-02-22 14:30:00` |
| `:time` | `~N[2026-02-22 14:30:00]` | `14:30:00` |
| `:relative_time` | `~N[2026-02-19 ...]` | `3일 전` |

### Text Formatters

| Formatter | Input | Output |
|-----------|-------|--------|
| `:uppercase` | `"hello"` | `"HELLO"` |
| `:lowercase` | `"HELLO"` | `"hello"` |
| `:capitalize` | `"hello world"` | `"Hello world"` |
| `:truncate` | `"long text..."` | `"long text..."` (50자 기본) |
| `:boolean` | `true` | `"예"` |
| `:mask` | `"01012345678"` | `"010-****-5678"` |

## Formatter with Options

튜플로 옵션을 전달합니다:

```elixir
# 소수점 2자리 숫자
%{field: :price, formatter: {:number, %{precision: 2}}}

# 커스텀 통화 기호
%{field: :price, formatter: {:currency, %{symbol: "$", precision: 2}}}

# 100자로 잘라내기
%{field: :description, formatter: {:truncate, 100}}

# 커스텀 날짜 형식
%{field: :date, formatter: {:date, "DD/MM/YYYY"}}
```

## Custom Formatter

함수로 직접 포맷터를 만들 수 있습니다:

```elixir
%{
  field: :score,
  label: "점수",
  formatter: fn
    nil -> "-"
    value when value >= 90 -> "A (#{value})"
    value when value >= 80 -> "B (#{value})"
    value -> "C (#{value})"
  end
}
```

## Related

- [Column Definitions](./column-definitions.md) — formatter 속성
- [Renderers](./renderers.md) — 시각적 셀 렌더링
