# Cell Editing

Grid는 인라인 셀 편집을 지원합니다. 더블클릭이나 F2 키로 편집 모드에 진입하고, 검증 규칙을 적용할 수 있습니다.

## Overview

편집을 활성화하려면 컬럼에 `editable: true`를 설정합니다:

```elixir
%{field: :name, label: "이름", editable: true}
```

## Editor Types

| editor_type | 설명 | 사용 예시 |
|-------------|------|-----------|
| `:text` | 텍스트 입력 (기본) | 이름, 이메일 |
| `:number` | 숫자 입력 | 나이, 가격 |
| `:select` | 드롭다운 선택 | 도시, 상태 |
| `:date` | 날짜 선택 | 가입일, 마감일 |
| `:checkbox` | 체크박스 토글 | 활성/비활성 |

### Text Editor

```elixir
%{field: :name, label: "이름", editable: true, editor_type: :text}
```

### Number Editor

```elixir
%{field: :age, label: "나이", editable: true, editor_type: :number}
```

### Select Editor

```elixir
%{
  field: :city,
  label: "도시",
  editable: true,
  editor_type: :select,
  editor_options: [
    {"서울", "서울"}, {"부산", "부산"}, {"대구", "대구"}
  ]
}
```

### Checkbox Editor

체크박스 컬럼은 항상 체크박스로 렌더링되며, 클릭 시 즉시 값이 토글됩니다:

```elixir
%{field: :active, label: "활성", editable: true, editor_type: :checkbox}
```

### Date Editor

```elixir
%{field: :created_at, label: "가입일", editable: true, editor_type: :date}
```

## Editing Workflow

1. **편집 진입**: 더블클릭 또는 F2 키
2. **값 입력**: 편집기에 값 입력
3. **저장**: Enter 키 또는 다른 셀 클릭
4. **취소**: Escape 키

## Input Validation

### Input Pattern (실시간 제한)

정규식으로 입력 자체를 제한합니다. 불일치 시 입력이 차단됩니다:

```elixir
# 숫자만 입력 허용
%{field: :phone, label: "전화번호", editable: true, input_pattern: ~r/^[0-9-]*$/}

# 영문만 입력 허용
%{field: :code, label: "코드", editable: true, input_pattern: ~r/^[a-zA-Z]*$/}
```

### Validators (저장 시 검증)

값이 저장될 때 검증 규칙을 적용합니다:

```elixir
%{
  field: :email,
  label: "이메일",
  editable: true,
  validators: [
    {:required, "이메일은 필수입니다"},
    {:pattern, ~r/@/, "이메일 형식이 올바르지 않습니다"}
  ]
}
```

### Validator Types

| Type | 파라미터 | 설명 |
|------|----------|------|
| `:required` | message | 빈 값 불가 |
| `:min` | value, message | 최소값 (숫자) |
| `:max` | value, message | 최대값 (숫자) |
| `:min_length` | value, message | 최소 길이 (문자열) |
| `:max_length` | value, message | 최대 길이 (문자열) |
| `:pattern` | regex, message | 정규식 매칭 |
| `:custom` | function, message | 커스텀 함수 |

```elixir
validators: [
  {:required, "필수 입력"},
  {:min, 1, "1 이상이어야 합니다"},
  {:max, 150, "150 이하이어야 합니다"},
  {:pattern, ~r/^[a-z]+$/, "소문자만 허용"},
  {:custom, &my_validator/1, "유효하지 않습니다"}
]
```

### Error Display

검증 실패 시 셀에 빨간색 테두리와 에러 메시지가 표시됩니다:

```elixir
Grid.validate_cell(grid, row_id, :email)
Grid.cell_error(grid, row_id, :email)  # => "이메일 형식이 올바르지 않습니다"
Grid.has_errors?(grid)                 # => true
Grid.error_count(grid)                 # => 2
```

## Undo / Redo

편집 이력을 추적하여 Undo/Redo를 지원합니다:

| 단축키 | 동작 |
|--------|------|
| `Ctrl+Z` | 마지막 편집 취소 (Undo) |
| `Ctrl+Y` | 취소된 편집 복원 (Redo) |

- 최대 50건의 편집 이력 보존
- 툴바의 ↩ / ↪ 버튼으로도 사용 가능

```elixir
Grid.can_undo?(grid)  # => true
Grid.undo(grid)       # 마지막 편집 취소
Grid.can_redo?(grid)  # => true
Grid.redo(grid)       # 복원
```

## Related

- [Row Editing](./row-editing.md) — 행 단위 편집 모드
- [CRUD Operations](./crud-operations.md) — 행 추가/삭제/저장
- [Column Definitions](./column-definitions.md) — editable, validators 속성
- [Keyboard Navigation](./keyboard-navigation.md) — 편집 단축키
