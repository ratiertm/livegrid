# Sorting

Grid는 컬럼 헤더를 클릭하여 데이터를 정렬합니다. 숫자, 문자열, 날짜 타입을 자동 감지하며, null 값의 위치도 제어할 수 있습니다.

## Overview

정렬을 활성화하려면 컬럼에 `sortable: true`를 설정합니다:

```elixir
%{field: :name, label: "이름", sortable: true}
```

헤더 클릭 시 `asc` → `desc` → `없음` 순으로 순환합니다.

## Enabling Sorting

```elixir
columns = [
  %{field: :name, label: "이름", sortable: true},
  %{field: :age, label: "나이", sortable: true},
  %{field: :email, label: "이메일", sortable: false}  # 정렬 비활성
]
```

## Sort Indicators

정렬 상태는 헤더에 시각적으로 표시됩니다:

| 상태 | 아이콘 | 설명 |
|------|--------|------|
| 미정렬 | - | 클릭 가능 (sortable일 때) |
| 오름차순 | ▲ | A → Z, 1 → 9 |
| 내림차순 | ▼ | Z → A, 9 → 1 |

## Null Value Handling

null/nil 값의 정렬 위치를 컬럼별로 제어합니다:

```elixir
# null 값을 마지막에 배치 (기본값)
%{field: :score, label: "점수", sortable: true, nulls: :last}

# null 값을 처음에 배치
%{field: :score, label: "점수", sortable: true, nulls: :first}
```

### 동작 예시

| 데이터 | nulls: :last (기본) | nulls: :first |
|--------|-------------------|---------------|
| `[nil, 30, nil, 10, 20]` | `[10, 20, 30, nil, nil]` | `[nil, nil, 10, 20, 30]` |

## Programmatic Sorting

Grid 상태를 직접 제어하여 프로그래밍 방식으로 정렬할 수 있습니다:

```elixir
# mount에서 초기 정렬 설정
grid = Grid.new(data: users, columns: columns)
grid = put_in(grid.state.sort, %{field: :name, direction: :asc})
```

## DataSource Sorting

Ecto/REST DataSource 사용 시 정렬은 서버사이드에서 처리됩니다:

```elixir
# Ecto: ORDER BY 쿼리 자동 생성
# REST: ?sort=name&order=asc 파라미터 전달
```

## Related

- [Column Definitions](./column-definitions.md) — sortable, nulls 속성
- [Filtering](./filtering.md) — 필터와 정렬 조합
- [Data Sources](./data-sources.md) — 서버사이드 정렬
