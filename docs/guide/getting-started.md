# Getting Started

LiveView Grid를 60초 안에 Phoenix LiveView 프로젝트에 추가할 수 있습니다.

## Overview

LiveView Grid는 Phoenix LiveView를 위한 고성능 데이터 그리드 컴포넌트입니다. 정렬, 필터, 페이지네이션, 인라인 편집, CRUD, 가상 스크롤 등 62개 기능을 제공합니다.

## 1. Install

`mix.exs`에 의존성을 추가합니다:

```elixir
defp deps do
  [
    {:liveview_grid, "~> 0.7"}
  ]
end
```

```bash
mix deps.get
```

## 2. Add CSS

`assets/css/app.css`에 그리드 스타일시트를 추가합니다:

```css
@import "../../deps/liveview_grid/assets/css/liveview_grid.css";
```

## 3. Add JS Hooks

`assets/js/app.js`에 그리드 Hooks를 등록합니다:

```javascript
import { GridHooks } from "../../deps/liveview_grid/assets/js/hooks"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...GridHooks }
})
```

## 4. Define Data

LiveView의 `mount/3`에서 데이터를 준비합니다:

```elixir
defmodule MyAppWeb.UserLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    users = [
      %{id: 1, name: "Alice", email: "alice@example.com", age: 28},
      %{id: 2, name: "Bob", email: "bob@example.com", age: 35},
      %{id: 3, name: "Carol", email: "carol@example.com", age: 31}
    ]

    {:ok, assign(socket, users: users)}
  end
end
```

## 5. Define Columns

컬럼 정의는 `field`(데이터 키)와 `label`(헤더 표시명)이 필수입니다:

```elixir
columns = [
  %{field: :name, label: "이름", width: 150, sortable: true},
  %{field: :email, label: "이메일", width: 250, sortable: true},
  %{field: :age, label: "나이", width: 100, sortable: true, align: :right}
]
```

## 6. Render the Grid

HEEx 템플릿에 `GridComponent`를 배치합니다:

```heex
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="users-grid"
  data={@users}
  columns={[
    %{field: :name, label: "이름", width: 150, sortable: true},
    %{field: :email, label: "이메일", width: 250, sortable: true},
    %{field: :age, label: "나이", width: 100, sortable: true, align: :right}
  ]}
  options={%{page_size: 20}}
/>
```

이것만으로 정렬, 페이지네이션이 포함된 데이터 테이블이 렌더링됩니다.

## What's Next

기능별 상세 가이드를 참고하세요:

| Guide | Description |
|-------|-------------|
| [Row Data](./row-data.md) | 데이터 제공 방식과 Row ID |
| [Column Definitions](./column-definitions.md) | 컬럼 속성 전체 레퍼런스 |
| [Sorting](./sorting.md) | 단일/다중 정렬, null 처리 |
| [Filtering](./filtering.md) | 컬럼 필터, 전체 검색, 고급 필터 |
| [Pagination](./pagination.md) | 페이지네이션과 가상 스크롤 |
| [Cell Editing](./cell-editing.md) | 인라인 편집, 검증, Undo/Redo |
| [Row Editing](./row-editing.md) | 행 단위 편집 모드 |
| [CRUD Operations](./crud-operations.md) | 행 추가/수정/삭제/저장 |
| [Data Sources](./data-sources.md) | InMemory, Ecto(DB), REST API |
| [Formatters](./formatters.md) | 16가지 내장 포맷터 |
| [Renderers](./renderers.md) | Badge, Link, Progress 렌더러 |
| [Selection](./selection.md) | 행 선택, 셀 범위 선택 |
| [Grouping](./grouping.md) | 다중 레벨 그룹핑 + 집계 |
| [Tree Grid](./tree-grid.md) | 계층 데이터 트리 뷰 |
| [Pivot Table](./pivot-table.md) | 피벗 테이블 변환 |
| [Export](./export.md) | Excel/CSV 내보내기 |
| [Themes](./themes.md) | 라이트/다크 모드, 커스텀 테마 |
| [Grid Options](./grid-options.md) | 전체 옵션 레퍼런스 |
| [Keyboard Navigation](./keyboard-navigation.md) | 단축키 안내 |
| [Summary Row](./summary-row.md) | 하단 집계 행 |
