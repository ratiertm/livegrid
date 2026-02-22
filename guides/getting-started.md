# Getting Started

LiveView Grid는 Phoenix LiveView 위에서 동작하는 풀 피처 데이터 그리드입니다.

## 설치

`mix.exs`에 의존성을 추가합니다:

```elixir
def deps do
  [
    {:liveview_grid, "~> 0.7"}
  ]
end
```

## 기본 사용법

### 1. Grid 생성 (LiveView mount)

```elixir
defmodule MyAppWeb.UserLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    users = [
      %{id: 1, name: "Alice", age: 30, city: "Seoul"},
      %{id: 2, name: "Bob", age: 25, city: "Busan"},
      %{id: 3, name: "Charlie", age: 35, city: "Daegu"}
    ]

    columns = [
      %{field: :id, label: "ID", width: 60, sortable: true},
      %{field: :name, label: "Name", sortable: true, filterable: true, editable: true},
      %{field: :age, label: "Age", sortable: true, formatter: :number, align: :right},
      %{field: :city, label: "City", sortable: true,
        editable: true, editor_type: :select,
        editor_options: [{"Seoul", "Seoul"}, {"Busan", "Busan"}, {"Daegu", "Daegu"}]}
    ]

    grid = LiveViewGrid.Grid.new(
      data: users,
      columns: columns,
      options: %{page_size: 20, theme: "default"}
    )

    {:ok, assign(socket, grid: grid)}
  end
end
```

### 2. 템플릿에서 GridComponent 사용

```heex
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id={@grid.id}
  grid={@grid}
/>
```

이것만으로 정렬, 필터, 페이지네이션, 셀 편집이 모두 동작합니다.

## 컬럼 정의

각 컬럼은 맵으로 정의하며, 다양한 옵션을 지원합니다:

```elixir
%{
  # 필수
  field: :name,           # 데이터 필드명 (atom)
  label: "Name",          # 헤더 표시 텍스트

  # 레이아웃
  width: 150,             # 컬럼 너비 (px 또는 :auto)
  align: :left,           # 텍스트 정렬 (:left, :center, :right)

  # 정렬/필터
  sortable: true,         # 정렬 가능 여부
  filterable: true,       # 필터 가능 여부
  filter_type: :text,     # 필터 타입 (:text, :number, :select, :date)

  # 편집
  editable: true,         # 셀 편집 가능 여부
  editor_type: :text,     # 에디터 타입 (:text, :number, :select, :textarea, :date)
  editor_options: [],     # select 에디터용 옵션 리스트

  # 검증
  validators: [
    {:required, "필수 입력"},
    {:min_length, 2, "2자 이상"},
    {:max, 200, "200 이하"},
    {:pattern, ~r/@/, "이메일 형식"}
  ],

  # 표시 형식
  formatter: :currency,   # 값 포맷터 (atom, tuple, function)
  renderer: :progress     # 커스텀 렌더러 (atom, tuple, function)
}
```

## Grid 옵션

```elixir
%{
  page_size: 20,           # 페이지당 행 수
  theme: "default",        # 테마 ("default", "dark", "compact", "striped")
  virtual_scroll: false,   # Virtual Scroll 활성화
  row_height: 40,          # 행 높이 (px)
  frozen_columns: 0,       # 고정 컬럼 수 (왼쪽부터)
  show_header: true,       # 헤더 표시 여부
  show_footer: true        # 푸터 (페이지네이션) 표시 여부
}
```

## 다음 단계

- `LiveViewGrid.Formatter` - 셀 값 포맷터 (숫자, 통화, 날짜 등 16종)
- `LiveViewGrid.Renderers` - 커스텀 셀 렌더러 (프로그레스바, 뱃지, 링크)
- `LiveViewGrid.Export` - Excel/CSV 내보내기
- `LiveViewGrid.DataSource` - 데이터 소스 (InMemory, Ecto, REST API)
