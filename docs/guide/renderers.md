# Cell Renderers

커스텀 셀 렌더러로 데이터를 시각적으로 표현합니다. Badge, Link, Progress 3가지 내장 렌더러를 제공합니다.

## Overview

```elixir
%{field: :status, label: "상태", renderer: LiveViewGrid.Renderers.badge(colors: %{...})}
```

## Badge Renderer

값에 따라 색상이 다른 뱃지로 표시합니다:

```elixir
%{
  field: :city,
  label: "도시",
  renderer: LiveViewGrid.Renderers.badge(
    colors: %{
      "서울" => "blue",
      "부산" => "green",
      "대구" => "red",
      "인천" => "purple"
    },
    default_color: "gray"
  )
}
```

### Available Colors

`blue`, `green`, `red`, `yellow`, `gray`, `purple`

## Link Renderer

셀 값을 클릭 가능한 하이퍼링크로 렌더링합니다:

```elixir
# prefix 방식
%{
  field: :email,
  label: "이메일",
  renderer: LiveViewGrid.Renderers.link(
    prefix: "mailto:",
    target: "_blank"
  )
}

# 동적 URL 방식
%{
  field: :name,
  label: "이름",
  renderer: LiveViewGrid.Renderers.link(
    href: fn row, _col -> "/users/#{row.id}" end
  )
}
```

## Progress Renderer

숫자 값을 프로그레스 바로 표시합니다:

```elixir
%{
  field: :age,
  label: "나이",
  renderer: LiveViewGrid.Renderers.progress(
    max: 60,
    color: "green",
    show_value: true
  )
}
```

### Options

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `max` | `100` | 최대값 |
| `color` | `"blue"` | 바 색상 (`blue`, `green`, `red`, `yellow`) |
| `show_value` | `true` | 숫자 값 표시 여부 |

## Custom Renderer

함수로 완전 커스텀 렌더링:

```elixir
%{
  field: :status,
  renderer: fn value, _row, _col ->
    case value do
      "active" -> ~s(<span style="color: green;">● Active</span>)
      "inactive" -> ~s(<span style="color: red;">● Inactive</span>)
      _ -> to_string(value)
    end
  end
}
```

## Related

- [Column Definitions](./column-definitions.md) — renderer 속성
- [Formatters](./formatters.md) — 값 포맷팅 (텍스트 변환)
