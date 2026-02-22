# Advanced Features

## CRUD (행 추가/수정/삭제)

Grid는 행 상태를 추적하여 변경사항을 관리합니다.

### 행 상태

| 상태 | 뱃지 | 설명 |
|------|------|------|
| `:normal` | (없음) | 변경 없음 |
| `:new` | N | 새로 추가된 행 |
| `:updated` | U | 값이 수정된 행 |
| `:deleted` | D | 삭제 마킹된 행 |

### 워크플로우

```elixir
# 새 행 추가 (맨 위)
grid = Grid.add_row(grid, %{name: "", email: ""})

# 셀 값 수정
grid = Grid.update_cell(grid, row_id, :name, "Alice")

# 검증 실행
grid = Grid.validate_cell(grid, row_id, :name)

# 삭제 마킹
grid = Grid.delete_rows(grid, [row_id])

# 변경사항 조회
changes = Grid.changed_rows(grid)
# => [%{row: %{id: -1, name: "Alice"}, status: :new}, ...]

# 변경사항 유무 확인
Grid.has_changes?(grid)  # => true
```

### 검증 규칙 (Validators)

```elixir
validators: [
  {:required, "필수 입력입니다"},
  {:min, 0, "0 이상이어야 합니다"},
  {:max, 100, "100 이하여야 합니다"},
  {:min_length, 2, "2자 이상 입력하세요"},
  {:max_length, 50, "50자 이내로 입력하세요"},
  {:pattern, ~r/@/, "이메일 형식이 아닙니다"},
  {:custom, &MyValidator.check/1, "유효하지 않습니다"}
]
```

## Renderers (커스텀 셀 렌더러)

Renderer는 셀의 HTML 구조 자체를 변경합니다 (Formatter는 텍스트만 변경).

### 프로그레스바

```elixir
%{field: :progress, label: "진행률",
  renderer: LiveViewGrid.Renderers.progress(
    max: 100, color: "blue", show_value: true
  )}
```

### 뱃지

```elixir
%{field: :status, label: "상태",
  renderer: LiveViewGrid.Renderers.badge(
    colors: %{"active" => "green", "inactive" => "red"}
  )}
```

### 링크

```elixir
%{field: :email, label: "이메일",
  renderer: LiveViewGrid.Renderers.link(prefix: "mailto:", target: "_blank")}
```

### 커스텀 Renderer (함수)

```elixir
%{field: :avatar, label: "사진",
  renderer: fn row, _column, _assigns ->
    assigns = %{url: row.avatar_url}
    ~H|<img src={@url} class="w-8 h-8 rounded-full" />|
  end}
```

## Export (Excel/CSV 내보내기)

```elixir
# Excel
{:ok, {_filename, xlsx_binary}} = LiveViewGrid.Export.to_xlsx(data, columns)

# CSV (UTF-8 BOM 포함, Excel 한글 호환)
csv_string = LiveViewGrid.Export.to_csv(data, columns)

# 옵션
{:ok, {_, binary}} = Export.to_xlsx(data, columns,
  sheet_name: "사용자 목록",
  header_style: true
)
```

GridComponent에서는 "Export" 버튼이 자동으로 제공됩니다.

## Grouping (그룹핑)

데이터를 필드별로 그룹화하고 집계합니다.

```elixir
grid = grid
  |> Grid.set_group_by([:department, :team])
  |> Grid.set_group_aggregates(%{
    salary: :sum,
    age: :avg,
    id: :count
  })
```

### 집계 함수

| 함수 | 설명 |
|------|------|
| `:sum` | 합계 |
| `:avg` | 평균 |
| `:count` | 개수 |
| `:min` | 최솟값 |
| `:max` | 최댓값 |

그룹 헤더를 클릭하면 expand/collapse 됩니다.

## Tree Grid (트리 그리드)

`parent_id` 기반 계층 데이터를 트리 형태로 표시합니다.

```elixir
# 데이터 (parent_id가 nil이면 루트 노드)
data = [
  %{id: 1, name: "본부", parent_id: nil},
  %{id: 2, name: "개발팀", parent_id: 1},
  %{id: 3, name: "프론트엔드", parent_id: 2}
]

grid = Grid.set_tree_mode(grid, true, :parent_id)
```

트리 노드의 화살표를 클릭하면 expand/collapse 됩니다.

## Pivot Table (피벗 테이블)

데이터를 행/열 차원으로 교차 집계합니다.

```elixir
{columns, rows} = Grid.pivot_transform(grid, %{
  row_fields: [:department],   # 행 차원
  col_field: :quarter,         # 열 차원 (유니크 값이 동적 컬럼이 됨)
  value_field: :revenue,       # 집계할 값 필드
  aggregate: :sum              # 집계 함수
})
```

결과 예시:

| department | Q1 | Q2 | Q3 | Q4 | Total |
|-----------|-----|-----|-----|-----|-------|
| 개발 | 50M | 45M | 48M | 52M | 195M |
| 마케팅 | 30M | 35M | 32M | 38M | 135M |

## Virtual Scroll (가상 스크롤)

대용량 데이터(10,000행+)를 위한 viewport 기반 부분 렌더링:

```elixir
options: %{
  virtual_scroll: true,
  row_height: 40,          # 행 높이 (정확해야 함)
  viewport_height: 600,    # 뷰포트 높이
  virtual_buffer: 5        # 버퍼 행 수 (위/아래)
}
```

## 테마

```elixir
# 내장 테마
options: %{theme: "default"}  # 기본
options: %{theme: "dark"}     # 다크 모드
options: %{theme: "compact"}  # 밀집
options: %{theme: "striped"}  # 줄무늬
```
