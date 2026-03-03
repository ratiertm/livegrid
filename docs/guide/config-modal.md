# Grid Configuration Modal

4개 탭으로 구성된 그리드 설정 UI입니다. 컬럼 표시/숨김, 속성 편집, 포맷터, 그리드 옵션을 관리합니다.

## Overview

Grid Config Modal은 런타임에 그리드 설정을 변경할 수 있는 UI 컴포넌트입니다. GridDefinition(불변 블루프린트)을 기반으로, 사용자 변경사항을 Grid 상태에 반영합니다.

## Enabling Config Modal

`ConfigModal` 컴포넌트를 추가합니다:

```heex
<.live_component
  module={LiveViewGridWeb.Components.GridConfig.ConfigModal}
  id="grid_config"
  grid={@grid}
  on_apply={fn changes -> send(self(), {:config_applied, changes}) end}
/>
```

## Tabs

### 1. Visibility (컬럼 표시/순서)

- 컬럼 표시/숨김 토글
- 드래그로 컬럼 순서 변경

### 2. Properties (컬럼 속성)

- 컬럼 label, width, align 수정
- sortable, filterable, editable 토글

### 3. Formatters (포맷터/검증자)

- 16종 포맷터 중 선택
- 검증 규칙 추가 (required, min, max, pattern 등)

### 4. Grid Settings (그리드 옵션)

- 페이지 크기 변경
- 테마 선택
- 행 높이 설정
- 행번호/합계행 토글
- 틀 고정 컬럼 수 설정

## Event Handlers

```elixir
# 탭 전환
handle_event("select_tab", %{"tab" => "visibility"}, socket)

# 컬럼 표시/숨김 토글
handle_event("toggle_column_visibility", %{"field" => "name"}, socket)

# 컬럼 속성 변경
handle_event("update_property", %{"field" => "name", "key" => "width", "value" => "150"}, socket)

# 그리드 옵션 변경
handle_event("update_grid_option", %{"option" => "page_size", "value" => "50"}, socket)

# 원래 설정으로 복원
handle_event("reset", _params, socket)
```

## 3-Layer Architecture

```
Layer 1: GridDefinition (불변)  ← 원본 블루프린트
Layer 2: Grid.options (런타임) ← Config Modal에서 변경
Layer 3: Grid.state (상태)     ← 현재 정렬/필터/편집 상태
```

- **Reset** 버튼: Layer 1(GridDefinition)으로 복원
- **Apply** 버튼: Layer 2에 변경사항 반영

## Related

- [Grid Options](./grid-options.md) — 그리드 옵션 상세
- [Grid Builder](./grid-builder.md) — UI 기반 그리드 생성
- [Column Definitions](./column-definitions.md) — 컬럼 정의
- [Themes](./themes.md) — 테마 설정
