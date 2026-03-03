# Input Restriction (Regex + IME)

정규식 패턴으로 셀 입력을 실시간 제한합니다. 한글(IME) 입력도 지원합니다.

## Overview

숫자만 허용, 전화번호 형식, 영문만 입력 등의 제한을 정규식으로 설정할 수 있습니다. IME 조합 중인 한글/중국어/일본어 입력도 올바르게 처리됩니다.

## Enabling Input Pattern

컬럼 정의에 `input_pattern`을 지정합니다:

```elixir
columns = [
  %{field: :phone, label: "전화번호", editable: true,
    input_pattern: "^[0-9-]*$"},

  %{field: :code, label: "코드", editable: true,
    input_pattern: "^[A-Z0-9]*$"},

  %{field: :amount, label: "금액", editable: true,
    input_pattern: "^[0-9.]*$"}
]
```

## Common Patterns

| 용도 | 패턴 | 설명 |
|------|------|------|
| 숫자만 | `^[0-9]*$` | 0-9만 허용 |
| 전화번호 | `^[0-9-]*$` | 숫자와 하이픈 |
| 영문 대문자 | `^[A-Z]*$` | A-Z만 허용 |
| 영문+숫자 | `^[A-Za-z0-9]*$` | 영숫자만 |
| 소수점 포함 | `^[0-9.]*$` | 숫자와 점 |
| 이메일 문자 | `^[a-zA-Z0-9@._-]*$` | 이메일 허용 문자 |

## IME Support

한글, 중국어, 일본어 등 IME 조합 입력을 올바르게 처리합니다:

- `compositionstart`: 조합 시작 시 검증을 일시 중지합니다
- `compositionend`: 조합 완료 후 패턴을 검증합니다
- 유효하지 않은 조합 결과는 마지막 유효 값으로 복원됩니다

## Behavior

- 입력할 때마다 **실시간**으로 패턴을 검증합니다
- 패턴에 맞지 않으면 **마지막 유효 값**으로 자동 복원됩니다
- `CellEditor` JS Hook에서 처리됩니다
- 서버 측 `validators`와 함께 사용하면 이중 검증이 가능합니다

## Related

- [Cell Editing](./cell-editing.md) — 셀 편집 및 서버 측 검증
- [Column Definitions](./column-definitions.md) — 컬럼 속성 정의
- [Keyboard Navigation](./keyboard-navigation.md) — 편집 모드 진입
