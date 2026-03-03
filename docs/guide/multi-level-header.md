# Multi-level Header

컬럼을 그룹으로 묶어 2단 이상의 헤더를 표시합니다.

## Overview

관련 컬럼들을 하나의 그룹 헤더 아래에 배치할 수 있습니다. 보고서나 복잡한 데이터 구조에서 컬럼 간의 관계를 시각적으로 표현합니다.

```
┌───────── 개인정보 ──────────┬──── 연락처 ────┐
│ 이름    │ 나이  │ 성별      │ 이메일  │ 전화  │
├─────────┼───────┼──────────┼────────┼───────┤
│ Alice   │ 28    │ F        │ a@..   │ 010.. │
```

## Enabling Header Groups

컬럼 정의에 `header_group`을 지정합니다:

```elixir
columns = [
  %{field: :name, label: "이름", header_group: "개인정보"},
  %{field: :age, label: "나이", header_group: "개인정보"},
  %{field: :gender, label: "성별", header_group: "개인정보"},
  %{field: :email, label: "이메일", header_group: "연락처"},
  %{field: :phone, label: "전화", header_group: "연락처"}
]
```

## Helper Functions

RenderHelpers에서 헤더 그룹을 생성합니다:

```elixir
# 헤더 그룹 존재 여부 확인
RenderHelpers.has_header_groups?(columns)
# => true

# 그룹 정보 생성 (colspan 자동 계산)
RenderHelpers.build_header_groups(columns, grid)
# => [%{label: "개인정보", colspan: 3}, %{label: "연락처", colspan: 2}]
```

## Behavior

- 같은 `header_group` 값을 가진 **인접한** 컬럼이 하나의 그룹으로 묶입니다
- `header_group`이 `nil`인 컬럼은 그룹 없이 단독으로 표시됩니다
- 그룹 행은 일반 헤더 행 위에 추가됩니다
- 컬럼 순서 변경 시 그룹이 자동 재계산됩니다

## CSS Classes

| 클래스 | 적용 대상 |
|--------|----------|
| `.lv-grid__header-row` | 그룹 헤더 행 |
| `.lv-grid__header-cell--group` | 그룹 헤더 셀 |

## Related

- [Column Definitions](./column-definitions.md) — 컬럼 정의
- [Header Wrap](./header-wrap.md) — 헤더 줄바꿈
- [Frozen Columns](./frozen-columns.md) — 컬럼 고정
