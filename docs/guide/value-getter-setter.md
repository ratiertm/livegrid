# Value Getter / Setter

컬럼에 커스텀 값 접근 로직을 정의하여 계산 컬럼, 중첩 데이터 접근 등을 구현합니다.

## Overview

Value Getter는 셀에 표시할 값을 커스텀 함수로 결정합니다. Value Setter는 편집된 값을 데이터에 저장하는 방식을 정의합니다. 원본 데이터 구조와 표시 형식이 다를 때 유용합니다.

## Value Getter

컬럼 정의에 `value_getter` 함수를 지정합니다:

```elixir
columns = [
  %{field: :full_name, label: "이름",
    value_getter: fn row -> "#{row.first_name} #{row.last_name}" end},

  %{field: :total, label: "합계",
    value_getter: fn row -> row.price * row.quantity end},

  %{field: :status_text, label: "상태",
    value_getter: fn row ->
      case row.status do
        :active -> "활성"
        :inactive -> "비활성"
        _ -> "알 수 없음"
      end
    end}
]
```

## Value Setter

편집 가능한 계산 컬럼에 `value_setter`를 지정합니다:

```elixir
%{field: :full_name, label: "이름", editable: true,
  value_getter: fn row -> "#{row.first_name} #{row.last_name}" end,
  value_setter: fn row, value ->
    [first, last] = String.split(value, " ", parts: 2)
    row |> Map.put(:first_name, first) |> Map.put(:last_name, last)
  end}
```

## Use Cases

| 패턴 | 설명 |
|------|------|
| 계산 컬럼 | `price * quantity` 같은 파생값 표시 |
| 중첩 데이터 | `row.user.name` 같은 깊은 경로 접근 |
| 값 변환 | 코드 → 한글명 변환 |
| 포맷팅 | 복잡한 커스텀 포맷 |

## Behavior

- `value_getter`가 있으면 `field` 키 대신 함수 반환값을 표시합니다
- `value_setter`가 없는 계산 컬럼은 읽기 전용입니다
- 정렬/필터는 getter의 반환값을 기준으로 동작합니다
- 편집기에는 getter의 현재 값이 초기값으로 표시됩니다

## Related

- [Column Definitions](./column-definitions.md) — 컬럼 속성 정의
- [Formatters](./formatters.md) — 내장 포맷터 (간단한 변환)
- [Renderers](./renderers.md) — 커스텀 셀 렌더링
- [Cell Editing](./cell-editing.md) — 셀 편집
