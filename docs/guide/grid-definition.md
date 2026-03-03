# Grid Definition (3-Layer Architecture)

GridDefinition은 그리드의 불변 블루프린트입니다. 컬럼 정의와 기본 옵션을 담고 있으며, 설정 초기화 시 원본으로 사용됩니다.

## Overview

Grid는 3개의 레이어로 상태를 관리합니다:

```
Layer 1: GridDefinition  — 불변 원본 (초기 설정)
Layer 2: Grid.options    — 런타임 설정 (사용자 변경)
Layer 3: Grid.state      — 현재 상태 (정렬, 필터, 편집 등)
```

Config Modal에서 "Reset" 시 Layer 1로 복원되고, 일반 사용 중 변경은 Layer 2~3에만 영향을 줍니다.

## Creating a Definition

```elixir
definition = GridDefinition.new(
  [
    %{field: :name, label: "이름", type: :string, width: 150},
    %{field: :age, label: "나이", type: :integer, width: 80, align: :right},
    %{field: :email, label: "이메일", type: :string, editable: true}
  ],
  %{page_size: 20, theme: :light, virtual_scroll: true}
)
```

## Column Definition Fields

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `field` | atom | (필수) | 데이터 키 |
| `label` | string | field명 | 헤더 표시 텍스트 |
| `type` | atom | `:string` | string/integer/float/boolean/date/datetime |
| `width` | integer | `:auto` | 컬럼 너비(px) |
| `align` | atom | `:left` | left/center/right |
| `sortable` | boolean | `true` | 정렬 가능 여부 |
| `filterable` | boolean | `true` | 필터 가능 여부 |
| `editable` | boolean | `false` | 편집 가능 여부 |
| `editor_type` | atom | `:text` | text/number/select/date |
| `formatter` | atom | `nil` | 포맷터 종류 |
| `validators` | list | `[]` | 검증 규칙 목록 |
| `renderer` | atom | `nil` | badge/link/progress |
| `header_group` | string | `nil` | 다중 헤더 그룹명 |
| `input_pattern` | string | `nil` | 입력 제한 정규식 |
| `suppress` | boolean | `false` | 동일값 숨김 |
| `nulls` | atom | `:last` | null 정렬 위치 |

## Query Functions

```elixir
# 특정 컬럼 조회
GridDefinition.get_column(definition, :name)
# => %{field: :name, label: "이름", ...}

# 전체 필드명 목록
GridDefinition.fields(definition)
# => [:name, :age, :email]

# 컬럼 수
GridDefinition.column_count(definition)
# => 3
```

## Config Management

```elixir
# 사용자 변경 적용
grid = Grid.apply_config_changes(grid, %{
  columns: [%{field: :name, width: 200}],
  options: %{page_size: 50}
})

# 원본 블루프린트로 복원
grid = Grid.reset_to_definition(grid)
```

## Related

- [Config Modal](./config-modal.md) — UI 기반 설정 변경
- [Grid Builder](./grid-builder.md) — UI 기반 그리드 생성
- [Grid Options](./grid-options.md) — 런타임 옵션
- [Column Definitions](./column-definitions.md) — 컬럼 속성 상세
