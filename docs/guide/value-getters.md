# Value Getters & Setters

컬럼의 값을 직접 필드에서 가져오는 대신, 함수를 통해 계산된 값을 표시하거나 설정합니다.

## Column Configuration

```elixir
%{
  field: :full_name,
  label: "이름",
  value_getter: fn row -> "#{row.last_name} #{row.first_name}" end
}

%{
  field: :total_price,
  label: "합계",
  value_getter: fn row -> row.quantity * row.unit_price end
}
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `value_getter` | `function/1` | `nil` | 행 데이터를 받아 표시할 값을 반환하는 함수 |
| `value_setter` | `function/1` | `nil` | 편집 값을 받아 저장할 값을 반환하는 함수 |

## API

```elixir
# 셀 값 조회 (value_getter 자동 적용)
value = Grid.get_cell_value(row, column)
```

## How It Works

```elixir
# value_getter가 설정된 경우 → 함수 호출
Grid.get_cell_value(%{first: "길동", last: "홍"}, %{value_getter: fn r -> "#{r.last} #{r.first}" end})
# => "홍 길동"

# value_getter가 nil인 경우 → Map.get(row, field) 사용
Grid.get_cell_value(%{name: "홍길동"}, %{field: :name})
# => "홍길동"
```

## Examples

```elixir
# 성과 이름 결합
%{field: :full_name, label: "성명",
  value_getter: fn row -> "#{row.last_name}#{row.first_name}" end}

# 계산 필드 (단가 x 수량)
%{field: :amount, label: "금액",
  value_getter: fn row -> row.unit_price * row.qty end}

# 날짜 포맷
%{field: :created, label: "등록일",
  value_getter: fn row -> Calendar.strftime(row.inserted_at, "%Y-%m-%d") end}

# 조건부 표시
%{field: :status_text, label: "상태",
  value_getter: fn row ->
    case row.status do
      :active -> "활성"
      :inactive -> "비활성"
      _ -> "알 수 없음"
    end
  end}
```
