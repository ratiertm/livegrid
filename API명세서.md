# LiveView Grid API 명세서

> **버전**: v0.1.0 (초안)  
> **작성일**: 2026-02-20  
> **상태**: Draft - 개발 전 인터페이스 확정

---

## 📋 목차

1. [개요](#개요)
2. [Grid 초기화](#grid-초기화)
3. [컬럼 정의](#컬럼-정의)
4. [데이터 조작](#데이터-조작)
5. [이벤트 핸들러](#이벤트-핸들러)
6. [속성 (Assigns)](#속성-assigns)
7. [메서드](#메서드)
8. [타입 정의](#타입-정의)

---

## 개요

LiveView Grid는 Phoenix LiveView 기반의 서버 사이드 렌더링 그리드 컴포넌트입니다.

**핵심 원칙:**
- 서버 사이드 상태 관리 (LiveView assigns)
- WebSocket 기반 실시간 업데이트
- 선언적 API (Declarative API)
- 타입 안정성 (Typespec)

---

## Grid 초기화

### `LiveViewGrid.new/1`

Grid 인스턴스를 생성하고 초기화합니다.

#### 시그니처
```elixir
@spec new(opts :: keyword()) :: map()
```

#### 파라미터
```elixir
opts = [
  data: list(),              # 필수: 표시할 데이터 (list of maps)
  columns: list(),           # 필수: 컬럼 정의 (list of column specs)
  id: String.t(),            # 선택: Grid ID (기본값: 자동 생성)
  options: map()             # 선택: Grid 옵션
]
```

#### 반환값
```elixir
%{
  id: "grid_abc123",
  data: [...],
  columns: [...],
  options: %{...}
}
```

#### 사용 예시
```elixir
# LiveView mount/3
def mount(_params, _session, socket) do
  grid = LiveViewGrid.new(
    data: [
      %{id: 1, name: "Alice", age: 30, email: "alice@example.com"},
      %{id: 2, name: "Bob", age: 25, email: "bob@example.com"}
    ],
    columns: [
      %{field: :name, label: "이름", width: 150, sortable: true},
      %{field: :age, label: "나이", width: 80, sortable: true},
      %{field: :email, label: "이메일", width: 200}
    ],
    options: %{
      page_size: 20,
      frozen_columns: 1,
      show_header: true
    }
  )
  
  {:ok, assign(socket, grid: grid)}
end
```

---

## 컬럼 정의

### Column Spec 구조

```elixir
@type column :: %{
  field: atom(),                      # 필수: 데이터 필드명
  label: String.t(),                  # 필수: 헤더 표시 텍스트
  width: integer() | :auto,           # 선택: 컬럼 너비 (px, 기본값: :auto)
  sortable: boolean(),                # 선택: 정렬 가능 여부 (기본값: false)
  filterable: boolean(),              # 선택: 필터 가능 여부 (기본값: false)
  editable: boolean(),                # 선택: 편집 가능 여부 (기본값: false)
  visible: boolean(),                 # 선택: 표시 여부 (기본값: true)
  align: :left | :center | :right,   # 선택: 정렬 (기본값: :left)
  format: format_spec(),              # 선택: 포맷터
  filter: filter_spec(),              # 선택: 필터 옵션
  editor: editor_spec(),              # 선택: 에디터 옵션
  renderer: function(),               # 선택: 커스텀 렌더러
  frozen: boolean()                   # 선택: 틀 고정 (기본값: false)
}
```

### 컬럼 타입별 예시

#### 기본 텍스트
```elixir
%{
  field: :name,
  label: "이름",
  width: 150,
  sortable: true,
  filterable: true
}
```

#### 숫자 (포맷팅)
```elixir
%{
  field: :price,
  label: "가격",
  width: 120,
  align: :right,
  format: %{
    type: :number,
    decimals: 2,
    prefix: "$"
  }
}
```

#### 날짜
```elixir
%{
  field: :created_at,
  label: "생성일",
  width: 150,
  format: %{
    type: :date,
    pattern: "YYYY-MM-DD"
  }
}
```

#### 불린 (체크박스)
```elixir
%{
  field: :active,
  label: "활성",
  width: 80,
  align: :center,
  format: %{
    type: :boolean,
    display: :checkbox
  }
}
```

#### 커스텀 렌더러
```elixir
%{
  field: :status,
  label: "상태",
  width: 100,
  renderer: fn row, _column ->
    case row.status do
      :active -> ~H"<span class=\"badge-green\">활성</span>"
      :inactive -> ~H"<span class=\"badge-gray\">비활성</span>"
    end
  end
}
```

---

## 데이터 조작

### `LiveViewGrid.set_data/2`

Grid 데이터를 업데이트합니다.

```elixir
@spec set_data(grid :: map(), data :: list()) :: map()

# 사용 예시
def handle_event("load_users", _params, socket) do
  users = Users.list_users()
  updated_grid = LiveViewGrid.set_data(socket.assigns.grid, users)
  {:noreply, assign(socket, grid: updated_grid)}
end
```

### `LiveViewGrid.add_row/2`

새 행을 추가합니다.

```elixir
@spec add_row(grid :: map(), row :: map()) :: map()

# 사용 예시
new_grid = LiveViewGrid.add_row(grid, %{
  id: 3,
  name: "Charlie",
  age: 28
})
```

### `LiveViewGrid.update_row/3`

특정 행을 업데이트합니다.

```elixir
@spec update_row(grid :: map(), row_id :: any(), updates :: map()) :: map()

# 사용 예시
new_grid = LiveViewGrid.update_row(grid, 1, %{age: 31})
```

### `LiveViewGrid.delete_row/2`

행을 삭제합니다.

```elixir
@spec delete_row(grid :: map(), row_id :: any()) :: map()

# 사용 예시
new_grid = LiveViewGrid.delete_row(grid, 1)
```

---

## 이벤트 핸들러

### 정렬 이벤트

#### `handle_event("grid_sort", params, socket)`

컬럼 헤더 클릭 시 발생합니다.

**파라미터:**
```elixir
%{
  "grid_id" => "grid_abc123",
  "field" => "name",
  "direction" => "asc" | "desc"
}
```

**구현 예시:**
```elixir
def handle_event("grid_sort", %{"field" => field, "direction" => direction}, socket) do
  grid = socket.assigns.grid
  sorted_data = LiveViewGrid.sort(grid.data, field, direction)
  updated_grid = %{grid | data: sorted_data, sort: %{field: field, direction: direction}}
  
  {:noreply, assign(socket, grid: updated_grid)}
end
```

---

### 필터 이벤트

#### `handle_event("grid_filter", params, socket)`

필터 입력 시 발생합니다.

**파라미터:**
```elixir
%{
  "grid_id" => "grid_abc123",
  "field" => "name",
  "value" => "Ali",
  "operator" => "contains" | "equals" | "starts_with"
}
```

**구현 예시:**
```elixir
def handle_event("grid_filter", %{"field" => field, "value" => value}, socket) do
  grid = socket.assigns.grid
  filtered_data = LiveViewGrid.filter(grid.data, field, value)
  updated_grid = %{grid | data: filtered_data, filters: Map.put(grid.filters, field, value)}
  
  {:noreply, assign(socket, grid: updated_grid)}
end
```

---

### 페이지네이션 이벤트

#### `handle_event("grid_page_change", params, socket)`

페이지 변경 시 발생합니다.

**파라미터:**
```elixir
%{
  "grid_id" => "grid_abc123",
  "page" => 2
}
```

**구현 예시:**
```elixir
def handle_event("grid_page_change", %{"page" => page}, socket) do
  grid = socket.assigns.grid
  updated_grid = %{grid | current_page: page}
  
  {:noreply, assign(socket, grid: updated_grid)}
end
```

---

### 행 선택 이벤트

#### `handle_event("grid_row_select", params, socket)`

행 선택 시 발생합니다.

**파라미터:**
```elixir
%{
  "grid_id" => "grid_abc123",
  "row_id" => 1,
  "selected" => true | false
}
```

**구현 예시:**
```elixir
def handle_event("grid_row_select", %{"row_id" => row_id, "selected" => selected}, socket) do
  grid = socket.assigns.grid
  updated_selected = 
    if selected do
      [row_id | grid.selected_rows]
    else
      List.delete(grid.selected_rows, row_id)
    end
  
  updated_grid = %{grid | selected_rows: updated_selected}
  {:noreply, assign(socket, grid: updated_grid)}
end
```

---

### 셀 편집 이벤트

#### `handle_event("grid_cell_edit", params, socket)`

셀 편집 시 발생합니다.

**파라미터:**
```elixir
%{
  "grid_id" => "grid_abc123",
  "row_id" => 1,
  "field" => "name",
  "value" => "Alice Updated"
}
```

**구현 예시:**
```elixir
def handle_event("grid_cell_edit", %{"row_id" => row_id, "field" => field, "value" => value}, socket) do
  grid = socket.assigns.grid
  updated_grid = LiveViewGrid.update_cell(grid, row_id, field, value)
  
  # 데이터베이스 업데이트
  Users.update_user(row_id, %{String.to_atom(field) => value})
  
  {:noreply, assign(socket, grid: updated_grid)}
end
```

---

## 속성 (Assigns)

### Grid Assigns 구조

```elixir
@type grid_assigns :: %{
  # 필수
  id: String.t(),
  data: list(map()),
  columns: list(column()),
  
  # 상태
  sort: %{field: atom(), direction: :asc | :desc} | nil,
  filters: %{atom() => any()},
  selected_rows: list(any()),
  current_page: integer(),
  
  # 옵션
  options: %{
    page_size: integer(),
    frozen_columns: integer(),
    show_header: boolean(),
    show_footer: boolean(),
    selectable: boolean(),
    editable: boolean()
  },
  
  # 계산된 값
  total_rows: integer(),
  total_pages: integer(),
  filtered_count: integer()
}
```

---

## 메서드

### 정렬

#### `LiveViewGrid.sort/3`

```elixir
@spec sort(data :: list(), field :: atom(), direction :: :asc | :desc) :: list()

# 예시
sorted = LiveViewGrid.sort(data, :name, :asc)
```

---

### 필터링

#### `LiveViewGrid.filter/3`

```elixir
@spec filter(data :: list(), field :: atom(), value :: any()) :: list()

# 예시
filtered = LiveViewGrid.filter(data, :name, "Alice")
```

#### `LiveViewGrid.filter_multi/2`

```elixir
@spec filter_multi(data :: list(), filters :: map()) :: list()

# 예시
filtered = LiveViewGrid.filter_multi(data, %{
  name: "Ali",
  age: "> 25"
})
```

---

### 페이지네이션

#### `LiveViewGrid.paginate/3`

```elixir
@spec paginate(data :: list(), page :: integer(), page_size :: integer()) :: list()

# 예시
page_data = LiveViewGrid.paginate(data, 1, 20)
```

---

### 선택

#### `LiveViewGrid.select_row/2`

```elixir
@spec select_row(grid :: map(), row_id :: any()) :: map()

# 예시
updated_grid = LiveViewGrid.select_row(grid, 1)
```

#### `LiveViewGrid.select_all/1`

```elixir
@spec select_all(grid :: map()) :: map()

# 예시
updated_grid = LiveViewGrid.select_all(grid)
```

#### `LiveViewGrid.deselect_all/1`

```elixir
@spec deselect_all(grid :: map()) :: map()

# 예시
updated_grid = LiveViewGrid.deselect_all(grid)
```

---

## 타입 정의

### Format Spec

```elixir
@type format_spec :: %{
  type: :text | :number | :date | :boolean | :custom,
  
  # number 타입
  decimals: integer(),
  prefix: String.t(),
  suffix: String.t(),
  thousand_separator: String.t(),
  
  # date 타입
  pattern: String.t(),  # "YYYY-MM-DD", "MM/DD/YYYY" 등
  
  # boolean 타입
  display: :checkbox | :text | :badge,
  true_text: String.t(),
  false_text: String.t(),
  
  # custom 타입
  formatter: function()
}
```

---

### Filter Spec

```elixir
@type filter_spec :: %{
  type: :text | :number | :date | :select,
  
  # text 타입
  operators: list(:contains | :equals | :starts_with | :ends_with),
  case_sensitive: boolean(),
  
  # number 타입
  operators: list(:eq | :ne | :gt | :gte | :lt | :lte),
  
  # select 타입
  options: list({value :: any(), label :: String.t()}),
  
  # 공통
  placeholder: String.t()
}
```

---

### Editor Spec

```elixir
@type editor_spec :: %{
  type: :text | :number | :date | :select | :checkbox,
  
  # text 타입
  max_length: integer(),
  pattern: Regex.t(),
  
  # select 타입
  options: list({value :: any(), label :: String.t()}),
  
  # 공통
  validator: function(),
  on_change: function()
}
```

---

## 완전한 사용 예시

### LiveView 모듈

```elixir
defmodule MyAppWeb.UserLive.Index do
  use MyAppWeb, :live_view
  alias LiveViewGrid

  def mount(_params, _session, socket) do
    grid = LiveViewGrid.new(
      data: list_users(),
      columns: [
        %{field: :id, label: "ID", width: 80, sortable: true, frozen: true},
        %{field: :name, label: "이름", width: 150, sortable: true, filterable: true},
        %{field: :email, label: "이메일", width: 200, filterable: true},
        %{field: :age, label: "나이", width: 80, sortable: true, align: :right},
        %{
          field: :active,
          label: "활성",
          width: 80,
          align: :center,
          format: %{type: :boolean, display: :checkbox}
        }
      ],
      options: %{
        page_size: 20,
        frozen_columns: 1,
        selectable: true,
        editable: true
      }
    )
    
    {:ok, assign(socket, grid: grid)}
  end
  
  def handle_event("grid_sort", %{"field" => field, "direction" => direction}, socket) do
    grid = socket.assigns.grid
    sorted_data = LiveViewGrid.sort(grid.data, String.to_atom(field), String.to_atom(direction))
    updated_grid = %{grid | data: sorted_data, sort: %{field: field, direction: direction}}
    
    {:noreply, assign(socket, grid: updated_grid)}
  end
  
  def handle_event("grid_filter", %{"field" => field, "value" => value}, socket) do
    grid = socket.assigns.grid
    filtered_data = LiveViewGrid.filter(grid.data, String.to_atom(field), value)
    updated_grid = %{grid | data: filtered_data}
    
    {:noreply, assign(socket, grid: updated_grid)}
  end
  
  defp list_users do
    [
      %{id: 1, name: "Alice", email: "alice@example.com", age: 30, active: true},
      %{id: 2, name: "Bob", email: "bob@example.com", age: 25, active: false},
      %{id: 3, name: "Charlie", email: "charlie@example.com", age: 35, active: true}
    ]
  end
end
```

### 템플릿 (HEEx)

```heex
<LiveViewGrid.render grid={@grid} />
```

---

## 버전 이력

| 버전 | 날짜 | 변경사항 |
|------|------|----------|
| v0.1.0 | 2026-02-20 | 초안 작성 |

---

## 다음 단계

- [ ] 실제 구현과 함께 API 검증
- [ ] 타입스펙 완성도 높이기
- [ ] 예외 처리 명세 추가
- [ ] 성능 최적화 API 추가

🐾
