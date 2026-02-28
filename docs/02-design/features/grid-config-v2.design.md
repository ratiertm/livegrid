# Design - Grid Configuration v2 (3-Layer Architecture)

> Plan 참조: `docs/01-plan/features/grid-config-v2.plan.md`

---

## Phase 1: GridDefinition (Blueprint)

### 1.1 모듈 구조

```
lib/liveview_grid/
  ├── grid.ex                    # MODIFY: definition 필드 추가
  └── grid_definition.ex         # NEW: GridDefinition 모듈
```

### 1.2 GridDefinition 모듈

**파일**: `lib/liveview_grid/grid_definition.ex`

```elixir
defmodule LiveViewGrid.GridDefinition do
  @moduledoc """
  Grid의 원본 정의(Blueprint).

  Runtime Config(컬럼 숨기기, 속성 변경 등)와 분리된 불변 원본.
  Config Modal의 Reset, 컬럼 복원 등의 기준점이 된다.
  """

  @type column_def :: %{
    field: atom(),
    label: String.t(),
    type: :string | :integer | :float | :boolean | :date | :datetime,
    width: integer() | :auto,
    align: :left | :center | :right,
    sortable: boolean(),
    filterable: boolean(),
    filter_type: atom(),
    editable: boolean(),
    editor_type: atom(),
    editor_options: list(),
    formatter: atom() | nil,
    formatter_options: map(),
    validators: list(),
    renderer: atom() | nil,
    header_group: String.t() | nil,
    input_pattern: String.t() | nil,
    style_expr: term(),
    nulls: :first | :last,
    required: boolean()
  }

  @type t :: %{
    columns: [column_def()],
    options: map()
  }

  @column_defaults %{
    type: :string,
    width: :auto,
    align: :left,
    sortable: false,
    filterable: false,
    filter_type: :text,
    editable: false,
    editor_type: :text,
    editor_options: [],
    formatter: nil,
    formatter_options: %{},
    validators: [],
    renderer: nil,
    header_group: nil,
    input_pattern: nil,
    style_expr: nil,
    nulls: :last,
    required: false
  }

  @doc """
  컬럼 정의 리스트와 옵션으로 GridDefinition을 생성한다.

  각 컬럼에 기본값을 머지하고, field/label 필수 검증을 수행한다.
  """
  @spec new(columns :: [map()], options :: map()) :: t()
  def new(columns, options \\ %{}) when is_list(columns) do
    normalized = Enum.map(columns, &normalize_column_def/1)
    validate!(normalized)
    %{columns: normalized, options: options}
  end

  @doc "Definition에서 특정 field의 컬럼 정의를 조회한다."
  @spec get_column(t(), atom()) :: column_def() | nil
  def get_column(%{columns: columns}, field) do
    Enum.find(columns, &(&1.field == field))
  end

  @doc "Definition의 전체 field 목록을 반환한다."
  @spec fields(t()) :: [atom()]
  def fields(%{columns: columns}), do: Enum.map(columns, & &1.field)

  @doc "Definition의 컬럼 수를 반환한다."
  @spec column_count(t()) :: non_neg_integer()
  def column_count(%{columns: columns}), do: length(columns)

  # -- Private --

  defp normalize_column_def(col) do
    Map.merge(@column_defaults, col)
  end

  defp validate!(columns) do
    Enum.each(columns, fn col ->
      unless Map.has_key?(col, :field) and is_atom(col.field) do
        raise ArgumentError, "컬럼에 :field (atom) 필수: #{inspect(col)}"
      end
      unless Map.has_key?(col, :label) and is_binary(col.label) do
        raise ArgumentError, "컬럼에 :label (string) 필수: #{inspect(col)}"
      end
    end)

    fields = Enum.map(columns, & &1.field)
    if length(fields) != length(Enum.uniq(fields)) do
      raise ArgumentError, "컬럼 field 중복 불가: #{inspect(fields)}"
    end
  end
end
```

### 1.3 Grid Struct 변경

**파일**: `lib/liveview_grid/grid.ex`

#### 변경 1: @type에 definition 추가

```elixir
# Before
@type t :: %{
  id: String.t(),
  data: list(map()),
  columns: list(map()),
  state: map(),
  options: map(),
  data_source: {module(), map()} | nil
}

# After
@type t :: %{
  id: String.t(),
  data: list(map()),
  columns: list(map()),
  definition: LiveViewGrid.GridDefinition.t() | nil,
  state: map(),
  options: map(),
  data_source: {module(), map()} | nil
}
```

#### 변경 2: Grid.new/1에서 definition 보존

```elixir
# After (호환성 유지 + definition 자동 생성)
def new(opts) do
  data = Keyword.get(opts, :data, [])
  columns = Keyword.fetch!(opts, :columns)
  options = Keyword.get(opts, :options, %{})
  id = Keyword.get(opts, :id, generate_id())
  data_source = Keyword.get(opts, :data_source, nil)

  normalized_columns = normalize_columns(columns)

  # Definition: 원본 컬럼 + 옵션 보존
  definition = GridDefinition.new(columns, options)

  grid = %{
    id: id,
    data: data,
    columns: normalized_columns,
    definition: definition,
    state: initial_state(),
    options: merge_default_options(options),
    data_source: data_source
  }

  if data_source, do: refresh_from_source(grid), else: grid
end
```

#### 변경 3: apply_config_changes에서 definition 참조

```elixir
def apply_config_changes(grid, config_changes) do
  config_changes = normalize_config_changes(config_changes)

  # definition.columns = 숨긴 컬럼 포함 전체 원본
  all_columns =
    if grid.definition do
      grid.definition.columns
    else
      # definition이 없는 레거시 grid → state 우회 (하위 호환)
      Map.get(grid.state, :all_columns, grid.columns)
    end

  validate_columns_list!(config_changes, all_columns)
  updated_columns = update_columns(all_columns, config_changes)
  ordered_columns = apply_column_order(updated_columns, config_changes)

  hidden = Map.get(config_changes, :hidden_columns, [])
  visible_columns = Enum.reject(ordered_columns, fn col -> col.field in hidden end)

  # state에 runtime config 저장 (hidden_columns만, all_columns는 불필요)
  new_state =
    grid.state
    |> Map.put(:hidden_columns, hidden)
    |> Map.put(:column_order, Map.get(config_changes, :column_order))
    |> Map.delete(:all_columns)  # definition으로 대체

  %{grid | columns: visible_columns, state: new_state}
end
```

#### 변경 4: reset_to_definition/1 추가

```elixir
@doc "Definition 원본으로 Grid 컬럼/옵션을 완전 복원한다."
@spec reset_to_definition(t()) :: t()
def reset_to_definition(%{definition: nil} = grid), do: grid
def reset_to_definition(%{definition: definition} = grid) do
  %{grid |
    columns: normalize_columns(definition.columns),
    options: merge_default_options(definition.options),
    state: grid.state
      |> Map.put(:hidden_columns, [])
      |> Map.put(:column_order, nil)
      |> Map.delete(:all_columns)
  }
end
```

### 1.4 Config Modal 변경

**파일**: `lib/liveview_grid_web/components/grid_config/config_modal.ex`

#### init_column_state 변경

```elixir
defp init_column_state(socket) do
  grid = socket.assigns.grid

  # definition이 있으면 원본 컬럼 사용, 없으면 state 우회 (하위 호환)
  all_columns =
    if grid.definition do
      grid.definition.columns
    else
      Map.get(grid.state, :all_columns, grid.columns)
    end

  # ... 이하 all_columns 기반 초기화 (현재와 동일)
end
```

#### Reset 핸들러 변경

```elixir
# Before: 로컬 상태만 초기화
def handle_event("reset", _params, socket) do
  socket
  |> init_column_state()
  |> then(&{:noreply, &1})
end

# After: definition 기반 완전 복원 옵션
def handle_event("reset", _params, socket) do
  grid = socket.assigns.grid

  # definition.options가 있으면 grid_options도 원본으로
  original_options =
    if grid.definition do
      Map.merge(
        LiveViewGrid.Grid.default_options(),
        grid.definition.options
      )
    else
      socket.assigns.grid_options
    end

  socket
  |> assign(:grid_options, original_options)
  |> init_column_state()
  |> then(&{:noreply, &1})
end
```

### 1.5 update_data/4 호환성

```elixir
# definition 보존 (기존 update_data에 한 줄 추가)
def update_data(grid, data, columns, options) do
  # ... 기존 코드 ...
  updated = %{grid |
    data: data,
    columns: normalize_columns(columns),
    options: merge_default_options(options),
    state: merged_state
  }
  |> Map.put(:data_source, data_source)
  |> Map.put(:definition, Map.get(grid, :definition))  # ← 추가: definition 보존

  # ... 이하 동일
end
```

---

## Phase 3: Preview & Apply

### 3.1 변경사항 Diff 로직

**위치**: `config_modal.ex`에 추가

```elixir
defp compute_changes(socket) do
  grid = socket.assigns.grid
  original_columns =
    if grid.definition, do: grid.definition.columns, else: grid.columns

  current_configs = socket.assigns.column_configs
  current_options = socket.assigns.grid_options
  original_options =
    if grid.definition, do: grid.definition.options, else: grid.options

  column_diffs =
    Enum.flat_map(current_configs, fn {field, config} ->
      original = Enum.find(original_columns, &(&1.field == field)) || %{}
      diff_column(field, original, config)
    end)

  # hidden columns diff
  hidden = socket.assigns.columns_visible
    |> Enum.filter(fn {_, v} -> !v end)
    |> Enum.map(fn {f, _} -> %{type: :hidden, field: f} end)

  option_diffs = diff_options(original_options, current_options)

  %{
    columns: column_diffs,
    hidden: hidden,
    options: option_diffs,
    total: length(column_diffs) + length(hidden) + length(option_diffs)
  }
end

defp diff_column(field, original, current) do
  [:label, :width, :align, :sortable, :filterable, :editable, :formatter]
  |> Enum.filter(fn key ->
    Map.get(original, key) != Map.get(current, key)
  end)
  |> Enum.map(fn key ->
    %{
      type: :column,
      field: field,
      property: key,
      from: Map.get(original, key),
      to: Map.get(current, key)
    }
  end)
end

defp diff_options(original, current) do
  keys = Map.keys(current) |> Enum.uniq()
  Enum.filter(keys, fn k ->
    Map.get(original, k) != Map.get(current, k)
  end)
  |> Enum.map(fn k ->
    %{type: :option, key: k, from: Map.get(original, k), to: Map.get(current, k)}
  end)
end
```

### 3.2 변경사항 요약 UI

**위치**: `config_modal.ex` render 함수 - Modal Footer 위에 추가

```heex
<!-- 변경사항 요약 패널 -->
<%= if @changes.total > 0 do %>
  <div class="px-6 py-3 bg-amber-50 border-t border-amber-200">
    <div class="flex items-center gap-2 mb-2">
      <span class="text-amber-600 font-semibold text-sm">
        변경사항 <%= @changes.total %>건
      </span>
    </div>
    <ul class="text-xs text-gray-600 space-y-1 max-h-24 overflow-y-auto">
      <%= for diff <- @changes.columns do %>
        <li>
          <code><%= diff.field %></code>
          <%= diff.property %>: "<%= diff.from %>" → "<%= diff.to %>"
        </li>
      <% end %>
      <%= for diff <- @changes.hidden do %>
        <li><code><%= diff.field %></code> 컬럼 숨김</li>
      <% end %>
      <%= for diff <- @changes.options do %>
        <li><%= diff.key %>: "<%= diff.from %>" → "<%= diff.to %>"</li>
      <% end %>
    </ul>
  </div>
<% end %>
```

### 3.3 Apply 버튼 상태 제어

```heex
<button
  phx-click="apply_grid_config"
  phx-target={@parent_target}
  phx-value-config={build_config_json(...)}
  class={[
    "px-4 py-2 rounded",
    if @changes.total > 0 do
      "text-white bg-blue-600 hover:bg-blue-700"
    else
      "text-gray-400 bg-gray-200 cursor-not-allowed"
    end
  ]}
  disabled={@changes.total == 0}
>
  Apply (<%= @changes.total %>)
</button>
```

---

## Phase 2: Definition Editor UI (후순위)

### 2.1 파일 구조

```
lib/liveview_grid_web/components/grid_config/
  └── definition_editor.ex        # LiveComponent
```

### 2.2 핵심 이벤트

| 이벤트 | 설명 |
|--------|------|
| `add_column_def` | 컬럼 정의 추가 |
| `remove_column_def` | 컬럼 정의 삭제 |
| `update_column_def` | 컬럼 정의 속성 수정 |
| `update_datasource` | 데이터 소스 설정 변경 |
| `save_definition` | Definition 저장 → Grid 재생성 |
| `import_json` | JSON에서 Definition import |
| `export_json` | Definition을 JSON으로 export |

### 2.3 진입점

- Grid 툴바에 "Define" 버튼 추가 (기존 "설정" 옆)
- 또는 Config Modal Tab 0으로 추가: "Grid Definition"

> Phase 2는 Phase 1 완료 후 별도 PDCA 사이클로 진행 가능

---

## 구현 순서 (Phase 1 중심)

| # | 작업 | 파일 | 예상 |
|---|------|------|------|
| 1 | `GridDefinition` 모듈 생성 | `grid_definition.ex` | 30분 |
| 2 | `Grid` struct에 `definition` 필드 추가 | `grid.ex` @type | 10분 |
| 3 | `Grid.new/1`에서 definition 자동 생성 | `grid.ex` new/1 | 20분 |
| 4 | `update_data/4`에서 definition 보존 | `grid.ex` update_data/4 | 10분 |
| 5 | `apply_config_changes`에서 definition 참조 | `grid.ex` | 30분 |
| 6 | `reset_to_definition/1` 함수 추가 | `grid.ex` | 15분 |
| 7 | `state[:all_columns]` 우회 코드 제거 | `grid.ex` | 10분 |
| 8 | Config Modal `init_column_state` 변경 | `config_modal.ex` | 20분 |
| 9 | Config Modal Reset 핸들러 변경 | `config_modal.ex` | 15분 |
| 10 | 변경사항 Diff + 요약 UI (Phase 3) | `config_modal.ex` | 40분 |
| 11 | Apply 버튼 상태 제어 (Phase 3) | `config_modal.ex` | 10분 |
| 12 | demo_live.ex 호환성 확인 | `demo_live.ex` | 10분 |
| 13 | 테스트 추가/업데이트 | `grid_test.exs` | 40분 |

**합계**: 약 4시간 (Phase 1 + Phase 3 핵심)

---

## 테스트 계획

### GridDefinition 테스트

```elixir
describe "GridDefinition.new/2" do
  test "컬럼에 기본값 머지"
  test "field 누락 시 ArgumentError"
  test "label 누락 시 ArgumentError"
  test "field 중복 시 ArgumentError"
  test "options 전달 및 보존"
end

describe "GridDefinition.get_column/2" do
  test "존재하는 field 조회"
  test "없는 field → nil"
end
```

### Grid + Definition 통합 테스트

```elixir
describe "Grid.new with definition" do
  test "definition 필드가 자동 생성됨"
  test "definition.columns에 원본 보존"
  test "기존 API 호환성 유지"
end

describe "apply_config_changes with definition" do
  test "숨긴 컬럼이 definition에서 복원 가능"
  test "Reset 시 definition 원본으로 복원"
  test "state[:all_columns] 없이 동작"
end

describe "reset_to_definition" do
  test "컬럼 원본 복원"
  test "옵션 원본 복원"
  test "hidden_columns 초기화"
  test "definition nil이면 no-op"
end
```

---

## 마이그레이션 전략 (하위 호환)

1. `definition: nil`인 기존 grid → `state[:all_columns]` 우회 유지
2. `Grid.new`로 새로 생성하는 grid → 자동으로 `definition` 생성
3. 점진적으로 `state[:all_columns]` 코드 제거 (모든 grid가 definition 가진 후)

```elixir
# 안전한 원본 컬럼 조회 (어디서든 사용)
defp all_columns(grid) do
  cond do
    grid.definition -> grid.definition.columns
    grid.state[:all_columns] -> grid.state[:all_columns]
    true -> grid.columns
  end
end
```
