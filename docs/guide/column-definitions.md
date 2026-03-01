# Column Definitions

컬럼 정의는 Grid의 핵심 설정입니다. 각 컬럼의 표시, 동작, 편집, 포맷, 검증을 제어합니다.

## Overview

컬럼은 맵 리스트로 정의합니다. `field`와 `label`이 필수이며, 나머지는 선택 속성입니다:

```elixir
columns = [
  %{field: :name, label: "이름"},
  %{field: :email, label: "이메일", width: 250},
  %{field: :salary, label: "급여", formatter: :currency, align: :right}
]
```

## Column Properties Reference

### Display Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `field` | `atom` | **필수** | 데이터 맵의 키 |
| `label` | `string` | **필수** | 헤더에 표시할 텍스트 |
| `width` | `integer \| :auto` | `:auto` | 컬럼 너비 (px). `:auto`면 균등 분배 |
| `align` | `:left \| :center \| :right` | `:left` | 텍스트 정렬 |
| `header_group` | `string \| nil` | `nil` | 다중 레벨 헤더 그룹명 |

### Interaction Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `sortable` | `boolean` | `false` | 헤더 클릭 시 정렬 허용 |
| `filterable` | `boolean` | `false` | 컬럼 필터 UI 표시 |
| `filter_type` | `:text \| :number \| :date \| :set` | `:text` | 필터 입력 유형. `:set`은 체크박스 필터 |
| `nulls` | `:first \| :last` | `:last` | null 값 정렬 위치 |

### Editing Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `editable` | `boolean` | `false` | 인라인 편집 허용 |
| `editor_type` | `:text \| :number \| :select \| :rich_select \| :date \| :checkbox` | `:text` | 편집기 유형 |
| `editor_options` | `list` | `[]` | select/rich_select 편집기의 옵션 목록 |
| `input_pattern` | `regex \| nil` | `nil` | 입력 제한 정규식 |
| `required` | `boolean` | `false` | 필수 필드 표시 |

### Layout & Behavior

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `resizable` | `boolean` | `true` | 컬럼 너비 드래그 리사이즈 허용. `false`면 resize handle 숨김 |
| `text_selectable` | `boolean` | `false` | 셀 텍스트 드래그 선택 허용. 이메일, URL 등 복사가 필요한 컬럼에 유용 |
| `floating_filter` | `boolean` | `true` | 개별 컬럼의 floating filter 표시 여부. `false`면 해당 컬럼 필터 숨김 |

### Formatting & Rendering

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `formatter` | `atom \| tuple \| function` | `nil` | 값 포맷터 |
| `renderer` | `function` | `nil` | 커스텀 셀 렌더러 |
| `style_expr` | `function \| nil` | `nil` | 조건부 셀 스타일 |

### Validation

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `validators` | `list` | `[]` | 검증 규칙 리스트 |

### Summary

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `summary` | `:sum \| :avg \| :count \| :min \| :max \| nil` | `nil` | 하단 집계 함수 |

## Examples

### Basic Columns

```elixir
%{field: :id, label: "ID", width: 80, sortable: true}
```

### Editable Text Column

```elixir
%{
  field: :name,
  label: "이름",
  width: 150,
  sortable: true,
  filterable: true,
  editable: true,
  validators: [{:required, "이름은 필수입니다"}]
}
```

### Number Column with Formatting

```elixir
%{
  field: :salary,
  label: "급여",
  width: 120,
  align: :right,
  sortable: true,
  formatter: :currency,
  summary: :sum
}
```

### Select (Dropdown) Column

```elixir
%{
  field: :city,
  label: "도시",
  width: 120,
  editable: true,
  editor_type: :select,
  editor_options: [
    {"서울", "서울"}, {"부산", "부산"}, {"대구", "대구"}
  ]
}
```

### Rich Select (Searchable Dropdown) Column

```elixir
%{
  field: :department,
  label: "부서",
  width: 150,
  editable: true,
  editor_type: :rich_select,
  editor_options: [
    %{value: "engineering", label: "Engineering"},
    %{value: "design", label: "Design"},
    %{value: "marketing", label: "Marketing"},
    %{value: "sales", label: "Sales"}
  ]
}
```

### Checkbox Column

```elixir
%{
  field: :active,
  label: "활성",
  width: 70,
  editable: true,
  editor_type: :checkbox
}
```

### Date Column

```elixir
%{
  field: :created_at,
  label: "가입일",
  width: 160,
  sortable: true,
  editable: true,
  editor_type: :date,
  formatter: :date
}
```

### Conditional Styling

```elixir
%{
  field: :age,
  label: "나이",
  style_expr: fn row ->
    age = Map.get(row, :age)
    cond do
      is_nil(age) -> nil
      age >= 50 -> %{bg: "#ffebee", color: "#c62828"}
      age < 30 -> %{bg: "#e3f2fd", color: "#1565c0"}
      true -> nil
    end
  end
}
```

### Custom Renderer

```elixir
%{
  field: :status,
  label: "상태",
  renderer: LiveViewGrid.Renderers.badge(
    colors: %{"active" => "green", "inactive" => "red"}
  )
}
```

### Multi-level Header Groups

```elixir
columns = [
  %{field: :name, label: "이름", header_group: "인적 정보"},
  %{field: :age, label: "나이", header_group: "인적 정보"},
  %{field: :city, label: "도시", header_group: "부가 정보"},
  %{field: :created_at, label: "가입일", header_group: "부가 정보"}
]
```

## Related

- [Formatters](./formatters.md) -- 16가지 내장 포맷터 상세
- [Renderers](./renderers.md) -- Badge, Link, Progress 렌더러
- [Sorting](./sorting.md) -- 정렬 동작 상세
- [Filtering](./filtering.md) -- 필터 유형별 설명
- [Cell Editing](./cell-editing.md) -- 편집기 유형별 동작
- [Rich Select Editor](./rich-select-editor.md) -- 검색 가능 드롭다운 에디터
