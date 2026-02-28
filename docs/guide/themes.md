# Themes

Grid는 라이트/다크 모드를 지원하며, CSS 변수로 테마를 완전히 커스터마이징할 수 있습니다.

## Built-in Themes

```elixir
# 라이트 테마 (기본)
options = %{theme: "light"}

# 다크 테마
options = %{theme: "dark"}
```

## Custom CSS Variables

`custom_css_vars` 옵션으로 개별 색상을 오버라이드합니다:

```elixir
options = %{
  theme: "light",
  custom_css_vars: %{
    "--lv-grid-primary" => "#1976d2",
    "--lv-grid-primary-light" => "#e3f2fd",
    "--lv-grid-bg" => "#fafafa",
    "--lv-grid-border" => "#e0e0e0"
  }
}
```

## Available CSS Variables

### Core Colors

| Variable | Default (Light) | Description |
|----------|-----------------|-------------|
| `--lv-grid-bg` | `#ffffff` | Grid 배경 |
| `--lv-grid-text` | `#333333` | 기본 텍스트 |
| `--lv-grid-text-secondary` | `#666666` | 보조 텍스트 |
| `--lv-grid-border` | `#dddddd` | 테두리 |
| `--lv-grid-primary` | `#1976d2` | 주요 강조색 |
| `--lv-grid-primary-light` | `#e3f2fd` | 연한 강조색 |

### Row States

| Variable | Default | Description |
|----------|---------|-------------|
| `--lv-grid-row-new` | `#e8f5e9` | 새 행 배경 |
| `--lv-grid-row-updated` | `#fff3e0` | 수정된 행 배경 |
| `--lv-grid-row-deleted` | `#ffebee` | 삭제 행 배경 |
| `--lv-grid-row-hover` | `#f5f5f5` | 호버 배경 |
| `--lv-grid-row-selected` | `#e3f2fd` | 선택 배경 |

### Header

| Variable | Default | Description |
|----------|---------|-------------|
| `--lv-grid-header-bg` | `#f5f5f5` | 헤더 배경 |
| `--lv-grid-header-text` | `#333333` | 헤더 텍스트 |

## Related

- [Grid Options](./grid-options.md) — theme, custom_css_vars 속성
- [Getting Started](./getting-started.md) — CSS 설치
