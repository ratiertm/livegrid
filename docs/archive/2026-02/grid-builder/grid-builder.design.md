# Design - Grid Builder (그리드 정의 UI)

> Plan 문서: `docs/01-plan/features/grid-builder.plan.md`

---

## 1. 컴포넌트 아키텍처

```
┌──────────────────────────────────────────────────────┐
│  DemoLive (부모 LiveView)                              │
│  ┌─────────────────────────────────────────────────┐  │
│  │ [+ 새 그리드 만들기] 버튼                         │  │
│  │   → builder_open = true                          │  │
│  └─────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────┐  │
│  │ BuilderModal (LiveComponent)                     │  │
│  │  ├─ Tab 1: GridInfoTab (기본 설정)               │  │
│  │  ├─ Tab 2: ColumnBuilderTab (컬럼 정의)          │  │
│  │  └─ Tab 3: PreviewTab (미리보기)                 │  │
│  └─────────────────────────────────────────────────┘  │
│                     │ create_grid 이벤트               │
│                     ▼                                  │
│  GridDefinition.new(columns, options)                  │
│  Grid.new(columns: ..., options: ..., data: sample)    │
│  → 동적 GridComponent 추가                             │
└──────────────────────────────────────────────────────┘
```

### 파일 구조

```
lib/liveview_grid_web/components/grid_builder/
├── builder_modal.ex          # 메인 모달 LiveComponent (탭 관리, 상태)
├── grid_info_tab.ex          # Tab 1: 기본 설정 (function component)
├── column_builder_tab.ex     # Tab 2: 컬럼 정의 (function component)
└── preview_tab.ex            # Tab 3: 미리보기 (function component)

lib/liveview_grid/
└── sample_data.ex            # 타입별 샘플 데이터 생성기

assets/js/hooks/
└── config-sortable.js        # (기존) Drag-to-reorder 재사용
```

---

## 2. 데이터 모델 (Socket Assigns)

### BuilderModal assigns

```elixir
%{
  # 탭 상태
  active_tab: "info",                    # "info" | "columns" | "preview"

  # Tab 1: 기본 설정
  grid_name: "",                         # "사용자 목록"
  grid_id: "",                           # "users_grid" (auto-generated)
  grid_options: %{
    page_size: 20,
    theme: "light",
    virtual_scroll: false,
    row_height: 40,
    frozen_columns: 0,
    show_row_number: false
  },

  # Tab 2: 컬럼 정의
  columns: [
    # 각 컬럼은 임시 ID로 관리 (순서 보장 + 추가/삭제 추적)
    %{
      temp_id: "col_1",
      field: "name",
      label: "이름",
      type: :string,
      width: 150,
      align: :left,
      sortable: true,
      filterable: false,
      editable: false,
      editor_type: :text,
      editor_options: [],
      formatter: nil,
      formatter_options: %{},
      validators: [],
      renderer: nil,
      renderer_options: %{}
    }
  ],
  selected_column_id: nil,              # 상세 설정 확장 패널용
  next_temp_id: 2,                      # 임시 ID 카운터

  # Tab 3: 미리보기
  preview_data: [],                     # 샘플 데이터
  preview_grid: nil,                    # Grid.new 결과

  # 유효성
  errors: %{}                           # %{grid_name: "필수 항목", columns: "최소 1개"}
}
```

---

## 3. Tab 1 - 기본 설정 (GridInfoTab)

### UI 레이아웃

```
┌──────────────────────────────────────────────────────┐
│  Grid 기본 설정                                       │
│                                                       │
│  그리드 이름 *   [사용자 목록                      ]   │
│  그리드 ID       [users_grid        ] (자동 생성)      │
│                                                       │
│  ── 표시 옵션 ──────────────────────────────────       │
│  페이지 크기     [v 20  ]                              │
│  테마            [v light]                             │
│  행 높이 (px)    [40    ]                              │
│  고정 컬럼 수    [0     ]                              │
│  [x] 행번호 표시                                       │
│  [ ] Virtual Scroll                                    │
└──────────────────────────────────────────────────────┘
```

### 이벤트

| 이벤트 | 파라미터 | 동작 |
|--------|----------|------|
| `update_grid_name` | `%{"value" => name}` | grid_name 갱신 + grid_id 자동 생성 |
| `update_grid_id` | `%{"value" => id}` | grid_id 수동 변경 |
| `update_builder_option` | `%{"key" => k, "value" => v}` | grid_options 맵 갱신 |
| `toggle_builder_option` | `%{"key" => k}` | boolean 옵션 토글 |

### grid_id 자동 생성 로직

```elixir
defp generate_grid_id(name) do
  name
  |> String.downcase()
  |> String.replace(~r/[가-힣]+/, fn match ->
    # 한글은 음절 초성 추출 또는 그대로 transliterate
    match
  end)
  |> String.replace(~r/[^a-z0-9\s]/, "")
  |> String.replace(~r/\s+/, "_")
  |> String.trim("_")
  |> case do
    "" -> "grid_#{:rand.uniform(9999)}"
    id -> id <> "_grid"
  end
end
```

---

## 4. Tab 2 - 컬럼 정의 (ColumnBuilderTab)

### UI 레이아웃 - 컬럼 목록

```
┌──────────────────────────────────────────────────────┐
│  컬럼 정의                            [+ 컬럼 추가]   │
│                                                       │
│  ┌─ 컬럼 목록 (ConfigSortable Hook) ──────────────┐  │
│  │ :: [ name   ] [이름  ] [v string] [150px] [x]   │  │
│  │ :: [ email  ] [이메일] [v string] [250px] [ ]   │  │
│  │ :: [ age    ] [나이  ] [v integer][100px] [ ]   │  │
│  │ :: [ active ] [활성  ] [v boolean][ auto] [ ]   │  │
│  └─────────────────────────────────────────────────┘  │
│                                                       │
│  범례: :: = drag handle, [x] = 삭제 버튼              │
│         field명, label, type, width 인라인 편집        │
│                                                       │
│  ┌─ 상세 설정 (selected_column_id 클릭 시 확장) ──┐  │
│  │ ▼ "name" 컬럼 상세 설정                         │  │
│  │                                                  │  │
│  │ ── 속성 ──                                       │  │
│  │ [x] Sortable   [x] Filterable   [ ] Editable    │  │
│  │ Editor Type: [v text]                             │  │
│  │ Align: [v left]                                   │  │
│  │                                                  │  │
│  │ ── Formatter ──                                  │  │
│  │ [v (없음)      ]                                  │  │
│  │                                                  │  │
│  │ ── Validators ──                  [+ 추가]       │  │
│  │ 1. [v required] 메시지: [이름은 필수입니다  ] [x]│  │
│  │ 2. [v min_length] 값: [2] 메시지: [2자 이상 ] [x]│  │
│  │                                                  │  │
│  │ ── Renderer ──                                   │  │
│  │ [v (없음)      ]                                  │  │
│  └──────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

### 이벤트

| 이벤트 | 파라미터 | 동작 |
|--------|----------|------|
| `add_column` | - | 빈 컬럼 추가 (temp_id 자동 부여) |
| `remove_column` | `%{"id" => temp_id}` | 컬럼 삭제 |
| `update_column_field` | `%{"id" => temp_id, "key" => k, "value" => v}` | 컬럼 필드 갱신 |
| `toggle_column_attr` | `%{"id" => temp_id, "key" => k}` | boolean 속성 토글 |
| `select_builder_column` | `%{"id" => temp_id}` | 상세 설정 패널 열기/닫기 |
| `reorder_builder_columns` | `%{"order" => [temp_ids]}` | 순서 변경 (ConfigSortable) |
| `set_column_formatter` | `%{"id" => temp_id, "formatter" => fmt}` | Formatter 선택 |
| `add_column_validator` | `%{"id" => temp_id}` | Validator 추가 |
| `update_column_validator` | `%{"id" => temp_id, "index" => i, ...}` | Validator 수정 |
| `remove_column_validator` | `%{"id" => temp_id, "index" => i}` | Validator 삭제 |
| `set_column_renderer` | `%{"id" => temp_id, "renderer" => r}` | Renderer 선택 |

### 새 컬럼 기본값

```elixir
defp new_column(temp_id) do
  %{
    temp_id: "col_#{temp_id}",
    field: "",
    label: "",
    type: :string,
    width: :auto,
    align: :left,
    sortable: false,
    filterable: false,
    editable: false,
    editor_type: :text,
    editor_options: [],
    formatter: nil,
    formatter_options: %{},
    validators: [],
    renderer: nil,
    renderer_options: %{}
  }
end
```

### Formatter 선택 목록

Config Modal Tab 3 패턴 재사용. 선택 가능한 formatter:

```elixir
@formatter_options [
  {"(없음)", ""},
  {"숫자 (1,000)", "number"},
  {"통화 - 원화 (₩1,000)", "currency"},
  {"통화 - 달러 ($1,000.00)", "dollar"},
  {"백분율 (85.6%)", "percent"},
  {"날짜 (2026-02-28)", "date"},
  {"날짜+시간", "datetime"},
  {"시간", "time"},
  {"상대시간 (3일 전)", "relative_time"},
  {"불리언 (예/아니오)", "boolean"},
  {"파일크기 (1.2 MB)", "filesize"},
  {"말줄임 (...)", "truncate"},
  {"대문자", "uppercase"},
  {"소문자", "lowercase"},
  {"마스킹 (***)", "mask"}
]
```

### Validator UI

각 validator는 타입별로 다른 입력 필드:

```elixir
@validator_types [
  {"필수 입력", "required"},
  {"최솟값", "min"},
  {"최댓값", "max"},
  {"최소 길이", "min_length"},
  {"최대 길이", "max_length"},
  {"패턴 (정규식)", "pattern"}
]

# Validator → 튜플 변환
defp validator_map_to_tuple(%{type: "required", message: msg}),
  do: {:required, msg}
defp validator_map_to_tuple(%{type: "min", value: v, message: msg}),
  do: {:min, v, msg}
defp validator_map_to_tuple(%{type: "max", value: v, message: msg}),
  do: {:max, v, msg}
defp validator_map_to_tuple(%{type: "min_length", value: v, message: msg}),
  do: {:min_length, v, msg}
defp validator_map_to_tuple(%{type: "max_length", value: v, message: msg}),
  do: {:max_length, v, msg}
defp validator_map_to_tuple(%{type: "pattern", value: v, message: msg}),
  do: {:pattern, Regex.compile!(v), msg}
```

### Renderer 선택 목록

```elixir
@renderer_options [
  {"(없음)", ""},
  {"Badge (색상 라벨)", "badge"},
  {"Link (클릭 링크)", "link"},
  {"Progress Bar (진행률)", "progress"}
]
```

Renderer별 옵션 입력:
- **badge**: "값:색상" 쌍 입력 (동적 추가/삭제). 색상: blue, green, red, yellow, gray, purple
- **link**: prefix (text), target (select: _blank, _self)
- **progress**: max (number), color (select: blue, green, red, yellow), show_value (checkbox)

---

## 5. Tab 3 - 미리보기 (PreviewTab)

### UI 레이아웃

```
┌──────────────────────────────────────────────────────┐
│  미리보기                                              │
│                                                       │
│  ┌─ 샘플 데이터 옵션 ─────────────────────────────┐  │
│  │ 행 수: [v 5]   [새로고침]                       │  │
│  └─────────────────────────────────────────────────┘  │
│                                                       │
│  ┌─ 실제 그리드 렌더링 ───────────────────────────┐  │
│  │  ID │ 이름      │ 이메일            │ 나이      │  │
│  │─────┼───────────┼──────────────────┼──────────│  │
│  │  1  │ Alice Kim │ alice@example.com│ 32       │  │
│  │  2  │ Bob Lee   │ bob@example.com  │ 28       │  │
│  │  3  │ Eve Park  │ eve@example.com  │ 45       │  │
│  └─────────────────────────────────────────────────┘  │
│                                                       │
│  ┌─ 검증 상태 ─────────────────────────────────────┐  │
│  │ ✅ 그리드 이름: "사용자 목록"                     │  │
│  │ ✅ 컬럼 수: 4개                                   │  │
│  │ ✅ 모든 필드명 유효                                │  │
│  │ ⚠️ 중복 필드명 없음                               │  │
│  └─────────────────────────────────────────────────┘  │
│                                                       │
│  ┌─ 코드 미리보기 (접기/펼치기) ──────────────────┐  │
│  │ %{field: :name, label: "이름", type: :string,  │  │
│  │   sortable: true, validators: [{:required, ...}]│ │
│  │ ...                                             │  │
│  └─────────────────────────────────────────────────┘  │
│                                                       │
│                                        [그리드 생성]   │
└──────────────────────────────────────────────────────┘
```

### 이벤트

| 이벤트 | 파라미터 | 동작 |
|--------|----------|------|
| `refresh_preview` | - | 샘플 데이터 재생성 + Grid.new 실행 |
| `update_sample_count` | `%{"count" => n}` | 샘플 행 수 변경 |
| `create_grid` | - | 최종 검증 → 부모에 GridDefinition 전달 |
| `toggle_code_preview` | - | 코드 미리보기 패널 열기/닫기 |

---

## 6. SampleData 모듈

```elixir
defmodule LiveViewGrid.SampleData do
  @moduledoc """
  컬럼 타입에 따라 샘플 데이터를 생성한다.
  Grid Builder 미리보기에서 사용.
  """

  @spec generate(columns :: [map()], count :: pos_integer()) :: [map()]
  def generate(columns, count \\ 5) do
    for i <- 1..count do
      row = %{id: i}
      Enum.reduce(columns, row, fn col, acc ->
        Map.put(acc, String.to_atom(col.field), sample_value(col.type, i))
      end)
    end
  end

  defp sample_value(:string, i), do: "Sample #{i}"
  defp sample_value(:integer, i), do: i * 10 + :rand.uniform(90)
  defp sample_value(:float, i), do: Float.round(i * 10.5 + :rand.uniform() * 100, 2)
  defp sample_value(:boolean, i), do: rem(i, 2) == 0
  defp sample_value(:date, i) do
    Date.add(Date.utc_today(), -i * 7)
  end
  defp sample_value(:datetime, i) do
    NaiveDateTime.add(NaiveDateTime.utc_now(), -i * 86400)
  end
  defp sample_value(_, i), do: "Value #{i}"
end
```

---

## 7. 최종 생성 플로우

### create_grid 이벤트 처리

```elixir
# BuilderModal
def handle_event("create_grid", _params, socket) do
  case validate_builder(socket) do
    {:ok, definition_params} ->
      send(self(), {:grid_builder_create, definition_params})
      {:noreply, socket}

    {:error, errors} ->
      {:noreply, assign(socket, :errors, errors)}
  end
end

defp validate_builder(socket) do
  errors = %{}

  errors = if socket.assigns.grid_name == "",
    do: Map.put(errors, :grid_name, "그리드 이름을 입력하세요"),
    else: errors

  errors = if socket.assigns.columns == [],
    do: Map.put(errors, :columns, "최소 1개 컬럼이 필요합니다"),
    else: errors

  # 빈 field명 체크
  empty_fields = Enum.filter(socket.assigns.columns, &(&1.field == ""))
  errors = if empty_fields != [],
    do: Map.put(errors, :field, "모든 컬럼에 Field Name이 필요합니다"),
    else: errors

  # 중복 field명 체크
  fields = Enum.map(socket.assigns.columns, & &1.field)
  errors = if length(fields) != length(Enum.uniq(fields)),
    do: Map.put(errors, :duplicate, "중복된 Field Name이 있습니다"),
    else: errors

  if errors == %{} do
    {:ok, build_definition_params(socket)}
  else
    {:error, errors}
  end
end
```

### 부모 LiveView (DemoLive) 처리

```elixir
# DemoLive
def handle_info({:grid_builder_create, params}, socket) do
  %{
    grid_name: grid_name,
    grid_id: grid_id,
    columns: columns,
    options: options
  } = params

  # GridDefinition 기반 Grid 생성
  sample_data = LiveViewGrid.SampleData.generate(columns, 10)

  new_grid = %{
    id: grid_id,
    name: grid_name,
    columns: columns,
    options: options,
    data: sample_data
  }

  grids = socket.assigns.dynamic_grids ++ [new_grid]

  {:noreply, assign(socket,
    dynamic_grids: grids,
    builder_open: false
  )}
end
```

---

## 8. 컬럼 빌드 → GridDefinition 변환

```elixir
defp build_definition_params(socket) do
  columns =
    socket.assigns.columns
    |> Enum.map(fn col ->
      base = %{
        field: String.to_atom(col.field),
        label: col.label,
        type: col.type,
        width: col.width,
        align: col.align,
        sortable: col.sortable,
        filterable: col.filterable,
        editable: col.editable,
        editor_type: col.editor_type,
        editor_options: col.editor_options
      }

      # Formatter
      base = if col.formatter,
        do: Map.put(base, :formatter, col.formatter),
        else: base

      # Validators: map → tuple 변환
      base = if col.validators != [] do
        tuples = Enum.map(col.validators, &validator_map_to_tuple/1)
        Map.put(base, :validators, tuples)
      else
        base
      end

      # Renderer: preset 빌드
      base = case col.renderer do
        "badge" ->
          colors = Map.get(col.renderer_options, :colors, %{})
          Map.put(base, :renderer, LiveViewGrid.Renderers.badge(colors: colors))
        "link" ->
          opts = col.renderer_options
          Map.put(base, :renderer, LiveViewGrid.Renderers.link(
            prefix: Map.get(opts, :prefix, ""),
            target: Map.get(opts, :target, nil)
          ))
        "progress" ->
          opts = col.renderer_options
          Map.put(base, :renderer, LiveViewGrid.Renderers.progress(
            max: Map.get(opts, :max, 100),
            color: Map.get(opts, :color, "blue")
          ))
        _ -> base
      end

      base
    end)

  %{
    grid_name: socket.assigns.grid_name,
    grid_id: socket.assigns.grid_id,
    columns: columns,
    options: socket.assigns.grid_options
  }
end
```

---

## 9. 구현 순서 (Step-by-Step)

### Step 1: BuilderModal 셸 + Tab 1
1. `grid_builder/builder_modal.ex` — LiveComponent, mount/update/render, 탭 전환
2. `grid_builder/grid_info_tab.ex` — 기본 설정 form (function component)
3. DemoLive에 `builder_open` assign + "+ 새 그리드 만들기" 버튼
4. 모달 열기/닫기 동작 확인

### Step 2: Tab 2 - 컬럼 기본 입력
1. `grid_builder/column_builder_tab.ex` — 컬럼 목록 테이블
2. 컬럼 추가/삭제 이벤트
3. 인라인 편집 (field, label, type, width)
4. ConfigSortable Hook으로 drag-to-reorder
5. sortable/filterable/editable 체크박스

### Step 3: Tab 2 - 컬럼 상세 설정
1. 컬럼 클릭 → 확장 패널 (selected_column_id)
2. Formatter 드롭다운 (16종)
3. Validator 추가/수정/삭제 UI (7종)
4. Renderer 선택 + 옵션 입력 (3종)
5. Editor Type 연동

### Step 4: Tab 3 - 미리보기 + 생성
1. `sample_data.ex` — 타입별 샘플 데이터 생성
2. `grid_builder/preview_tab.ex` — 실시간 미리보기
3. 검증 상태 표시 (이름, 컬럼 수, 중복 체크)
4. 코드 미리보기 (Elixir 코드 생성)
5. "그리드 생성" 버튼 → 부모 전달

### Step 5: DemoLive 통합
1. `dynamic_grids` assign 관리
2. 생성된 그리드 렌더링 (for loop)
3. 동적 그리드 삭제 버튼

---

## 10. 주요 제약사항

| 항목 | 제약 | 이유 |
|------|------|------|
| Field Name | 영문+숫자+언더스코어만 | Atom 변환 안전성 |
| Renderer | 내장 3종만 | 커스텀 함수 UI 불가 |
| Pattern Validator | 간단한 regex만 | 복잡한 regex는 오류 위험 |
| Data Source | 미지원 (샘플 데이터만) | Ecto/REST 연결은 추후 |
| 저장 | 메모리만 (세션 종료 시 소멸) | DB 저장은 추후 |
| style_expr | 미지원 | 함수 정의 UI 불가 |
| header_group | 미지원 | v2에서 추가 가능 |

---

## 11. 테스트 계획

| 테스트 | 대상 | 검증 내용 |
|--------|------|----------|
| SampleData 단위 | sample_data.ex | 타입별 데이터 생성 정확성 |
| 검증 로직 | builder_modal.ex | 빈 이름, 빈 컬럼, 중복 field 에러 |
| 컬럼 CRUD | builder_modal.ex | 추가/삭제/수정 후 상태 일관성 |
| Validator 변환 | builder_modal.ex | map → tuple 정확성 |
| Renderer 빌드 | builder_modal.ex | preset 함수 정확한 호출 |
| 통합 | demo_live.ex | 생성 → 렌더링 → 동작 확인 |
