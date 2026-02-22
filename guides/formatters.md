# Formatters

Formatter는 셀 값의 **텍스트 표시 형식**을 변환합니다.
Renderer(HTML 구조 변경)와 달리 순수 텍스트만 변환합니다.

## 기본 사용법

컬럼 정의에서 `formatter` 옵션으로 지정합니다:

```elixir
columns = [
  %{field: :salary, label: "급여", formatter: :currency},
  %{field: :rate, label: "비율", formatter: :percent},
  %{field: :created_at, label: "생성일", formatter: :date}
]
```

## 지원 포맷터 목록

### 숫자 / 통화

| Formatter | 입력 | 출력 | 설명 |
|-----------|------|------|------|
| `:number` | `75000000` | `"75,000,000"` | 천 단위 구분자 |
| `:currency` | `75000000` | `"₩75,000,000"` | 원화 포맷 |
| `:dollar` | `1500.5` | `"$1,500.50"` | 달러 포맷 |
| `:percent` | `0.856` | `"85.6%"` | 백분율 (0~1 → 0~100%) |

**옵션 지정 (Tuple 형식):**

```elixir
# 엔화 (소수점 없이)
%{field: :price, formatter: {:currency, symbol: "¥", precision: 0}}

# 유로 (접미사)
%{field: :price, formatter: {:currency, symbol: "EUR ", position: :prefix}}

# 소수점 2자리 숫자
%{field: :score, formatter: {:number, precision: 2}}

# 퍼센트 (소수점 2자리)
%{field: :rate, formatter: {:percent, precision: 2}}
```

### 날짜 / 시간

| Formatter | 입력 | 출력 |
|-----------|------|------|
| `:date` | `~D[2026-02-22]` | `"2026-02-22"` |
| `:datetime` | `~N[2026-02-22 14:30:00]` | `"2026-02-22 14:30:00"` |
| `:time` | `~T[14:30:00]` | `"14:30:00"` |
| `:relative_time` | `~U[2026-02-20 00:00:00Z]` | `"2일 전"` |

**커스텀 날짜 포맷:**

```elixir
%{field: :date, formatter: {:date, "YYYY/MM/DD"}}
%{field: :date, formatter: {:date, "MM-DD"}}
%{field: :dt, formatter: {:datetime, "YYYY.MM.DD HH:mm"}}
```

### 텍스트

| Formatter | 입력 | 출력 |
|-----------|------|------|
| `:uppercase` | `"hello"` | `"HELLO"` |
| `:lowercase` | `"HELLO"` | `"hello"` |
| `:capitalize` | `"hello world"` | `"Hello World"` |
| `:truncate` | `"매우 긴 텍스트..."` | `"매우 긴 텍스..."` (50자) |

```elixir
# 최대 30자 말줄임
%{field: :desc, formatter: {:truncate, 30}}
```

### 기타

| Formatter | 입력 | 출력 |
|-----------|------|------|
| `:boolean` | `true` / `false` | `"예"` / `"아니오"` |
| `:filesize` | `1048576` | `"1.0 MB"` |
| `:mask` | `"01012345678"` | `"010-****-5678"` |

**마스킹 패턴:**

```elixir
# 자동 감지 (전화번호, 이메일 등)
%{field: :phone, formatter: :mask}

# 전화번호 강제
%{field: :phone, formatter: {:mask, :phone}}

# 이메일 마스킹
%{field: :email, formatter: {:mask, :email}}

# 카드번호 마스킹
%{field: :card, formatter: {:mask, :card}}
```

**불리언 커스텀 라벨:**

```elixir
%{field: :active, formatter: {:boolean, true_label: "활성", false_label: "비활성"}}
%{field: :active, formatter: {:boolean, true_label: "O", false_label: "X"}}
```

## 커스텀 함수 포맷터

함수를 직접 전달하여 완전히 자유로운 포맷팅이 가능합니다:

```elixir
%{field: :score, formatter: fn val ->
  cond do
    val >= 90 -> "A (#{val})"
    val >= 80 -> "B (#{val})"
    val >= 70 -> "C (#{val})"
    true -> "F (#{val})"
  end
end}
```

## 직접 호출

`LiveViewGrid.Formatter.format/2`를 직접 호출할 수도 있습니다:

```elixir
Formatter.format(75000000, :currency)     # => "₩75,000,000"
Formatter.format(0.856, :percent)         # => "85.6%"
Formatter.format(1500.5, {:currency, symbol: "$", precision: 2})  # => "$1,500.50"
```
