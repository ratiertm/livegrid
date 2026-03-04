# Design: Grid Config Persistence (설정 저장/불러오기)

> Plan 참조: `docs/01-plan/features/grid-config-persistence.plan.md`

## 1. 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────┐
│  BuilderLive (UI Layer)                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │ Export Button │  │ Import Button│  │ Grid Cards        │  │
│  │ (per grid)   │  │ (header)     │  │ (dynamic_grids)   │  │
│  └──────┬───────┘  └──────┬───────┘  └───────────────────┘  │
│         │                 │                                  │
│  ┌──────▼─────────────────▼──────────────────────────────┐  │
│  │ handle_event("export_config", %{"id" => grid_id})     │  │
│  │ handle_event("import_config", %{"json" => json_str})  │  │
│  └──────┬─────────────────┬──────────────────────────────┘  │
└─────────┼─────────────────┼─────────────────────────────────┘
          │                 │
┌─────────▼─────────────────▼─────────────────────────────────┐
│  GridConfigSerializer (Business Logic)                       │
│                                                              │
│  serialize(grid_map) → {:ok, json_string}                    │
│  deserialize(json_string) → {:ok, definition_params}         │
│                             {:error, errors}                 │
│                                                              │
│  Internal:                                                   │
│  - serialize_column/1     (column map → JSON-safe map)       │
│  - deserialize_column/1   (JSON map → column map w/ atoms)   │
│  - serialize_validator/1  (tuple → map)                      │
│  - deserialize_validator/1(map → tuple)                      │
│  - serialize_renderer/1   (function → spec map)              │
│  - deserialize_renderer/1 (spec map → function)              │
└──────────────────────────────────────────────────────────────┘
          │                 │
┌─────────▼─────────────────▼─────────────────────────────────┐
│  JS Layer                                                    │
│  - download.js: 기존 phx:download_file 이벤트 재활용         │
│  - config-import.js: 신규 Hook (JSON 파일 읽기 → pushEvent)  │
└──────────────────────────────────────────────────────────────┘
```

## 2. 모듈 설계

### 2.1 GridConfigSerializer (`lib/liveview_grid/grid_config_serializer.ex`)

신규 모듈. 비즈니스 로직 레이어에 위치 (웹 레이어가 아닌 `lib/liveview_grid/`).

```elixir
defmodule LiveViewGrid.GridConfigSerializer do
  @moduledoc """
  Grid 설정의 직렬화/역직렬화.
  Builder로 생성된 grid 설정을 JSON으로 변환하고, JSON에서 복원한다.
  """

  @config_version "1.0"

  @spec serialize(map()) :: {:ok, String.t()} | {:error, String.t()}
  # grid_map = %{id, name, columns, options, source_type, ...} (BuilderLive의 dynamic_grid 항목)
  # → JSON string 반환

  @spec deserialize(String.t()) :: {:ok, map()} | {:error, list(String.t())}
  # JSON string → {:ok, definition_params} (BuilderLive의 build_grid에 전달 가능한 형태)
  # 검증 실패 시 {:error, ["에러메시지1", "에러메시지2"]}
end
```

#### 직렬화 흐름 (serialize/1)

```
grid_map (dynamic_grids의 한 항목)
  │
  ├─ grid_name, grid_id, source_type 추출
  │
  ├─ options: atom key → string key 변환
  │
  ├─ columns: 각 컬럼에 대해 serialize_column/1
  │   ├─ field: atom → string
  │   ├─ type, align, editor_type: atom → string
  │   ├─ width: :auto → "auto", integer → integer
  │   ├─ formatter: atom → string, nil → null
  │   ├─ validators: 각 tuple → serialize_validator/1
  │   │   ├─ {:required, msg} → %{"type" => "required", "message" => msg}
  │   │   ├─ {:min, val, msg} → %{"type" => "min", "value" => val, "message" => msg}
  │   │   ├─ {:max, val, msg} → %{"type" => "max", "value" => val, "message" => msg}
  │   │   ├─ {:min_length, val, msg} → %{"type" => "min_length", "value" => val, "message" => msg}
  │   │   ├─ {:max_length, val, msg} → %{"type" => "max_length", "value" => val, "message" => msg}
  │   │   └─ {:pattern, regex, msg} → %{"type" => "pattern", "value" => Regex.source(regex), "message" => msg}
  │   ├─ renderer: serialize_renderer/1
  │   │   ├─ nil → null
  │   │   ├─ function → 메타데이터 추출 (아래 상세)
  │   └─ header_group, input_pattern, style_expr: 있으면 포함
  │
  ├─ version: "1.0", exported_at: UTC ISO8601
  │
  └─ Jason.encode!(pretty: true)
```

#### Renderer 직렬화 전략

renderer는 함수(클로저)이므로 직접 직렬화 불가. **Builder가 생성한 그리드에는 renderer_spec을 함께 저장**하는 전략 채택.

```elixir
# BuilderLive의 build_grid 시 renderer_spec을 컬럼에 추가 저장
# 예: %{renderer: fn(val, row) -> ... end, renderer_spec: %{type: "badge", options: %{colors: %{...}}}}
```

**변경점**: `BuilderHelpers.build_renderer/2`에서 renderer 함수를 생성할 때, 동시에 `:renderer_spec` 키도 컬럼에 저장.

이를 통해:
- serialize 시: `renderer_spec`를 JSON으로 변환 (간단)
- deserialize 시: `renderer_spec`를 `BuilderHelpers.build_renderer/2`에 전달하여 함수 재생성

**대안 (renderer_spec 없는 경우)**: renderer가 있지만 renderer_spec이 없는 컬럼은 renderer를 null로 직렬화하고, Import 시 경고 메시지 표시.

#### 역직렬화 흐름 (deserialize/1)

```
JSON string
  │
  ├─ Jason.decode! → map
  │
  ├─ 검증 (validate_config/1)
  │   ├─ version 확인 (호환성)
  │   ├─ grid_name: 비어있지 않은 string
  │   ├─ grid_id: 비어있지 않은 string
  │   ├─ columns: 비어있지 않은 list
  │   ├─ 각 column: field(필수), label(필수), type(유효값)
  │   └─ options: map (선택)
  │
  ├─ columns: 각 컬럼에 대해 deserialize_column/1
  │   ├─ field: string → atom (String.to_atom — 외부 입력이지만 제한된 범위)
  │   ├─ type, align, editor_type: string → atom
  │   ├─ width: "auto" → :auto, integer → integer
  │   ├─ formatter: string → atom, null → nil
  │   ├─ validators: 각 map → BuilderHelpers.validator_map_to_tuple/1 재활용
  │   ├─ renderer: deserialize_renderer/1
  │   │   └─ spec map → BuilderHelpers.build_renderer/2 호출
  │   └─ editor_options: list 그대로
  │
  ├─ options: string key → atom key 변환 + 타입 검증
  │
  └─ {:ok, definition_params} 반환
      %{grid_name, grid_id, columns, options, data_source_type, selected_schema, selected_table}
```

#### 보안: atom 생성 제한

외부 JSON에서 atom 생성 시 DoS 위험. 허용 목록(allowlist) 적용:

```elixir
@allowed_types ~w(string integer float boolean date datetime)a
@allowed_aligns ~w(left center right)a
@allowed_editor_types ~w(text number select checkbox date)a
@allowed_formatters ~w(number currency percent date datetime phone)a

defp safe_to_atom(value, allowed_list) do
  atom = String.to_existing_atom(value)
  if atom in allowed_list, do: {:ok, atom}, else: {:error, "invalid value: #{value}"}
rescue
  ArgumentError -> {:error, "unknown value: #{value}"}
end
```

field 이름은 `String.to_atom/1` 사용하되, 최대 50자 + 영숫자+언더스코어 패턴 검증으로 제한.

### 2.2 BuilderLive 변경 (`lib/liveview_grid_web/live/builder_live.ex`)

#### 새 이벤트 핸들러

```elixir
# Export: 특정 그리드의 설정을 JSON 다운로드
def handle_event("export_config", %{"id" => grid_id}, socket)
  # 1. dynamic_grids에서 grid_id로 찾기
  # 2. GridConfigSerializer.serialize(grid_map)
  # 3. push_event(socket, "download_file", %{
  #      content: Base.encode64(json),
  #      filename: "#{grid_id}_config.json",
  #      mime_type: "application/json"
  #    })

# Import: JSON 파일 내용을 받아 그리드 생성
def handle_event("import_config", %{"json" => json_str}, socket)
  # 1. GridConfigSerializer.deserialize(json_str)
  # 2. {:ok, params} → build_grid(params) 호출 → dynamic_grids에 추가
  # 3. {:error, errors} → flash 에러 메시지
```

#### build_grid 재사용

deserialize 결과의 `definition_params`를 기존 `build_grid/6`에 바로 전달:

```elixir
defp import_grid(params, socket) do
  %{grid_name: name, grid_id: id, columns: cols, options: opts} = params
  ds_type = Map.get(params, :data_source_type, "sample")
  new_grid = build_grid(id, name, cols, opts, ds_type, params)
  grids = socket.assigns.dynamic_grids ++ [new_grid]
  # ...
end
```

### 2.3 BuilderHelpers 변경 (`builder_helpers.ex`)

#### renderer_spec 저장 추가

`build_renderer/2` 수정: renderer 함수 생성 시 `:renderer_spec`도 함께 저장.

```elixir
# 변경 전
def build_renderer(base, %{renderer: "badge", renderer_options: opts}) do
  # ... colors 파싱 ...
  Map.put(base, :renderer, LiveViewGrid.Renderers.badge(colors: colors))
end

# 변경 후
def build_renderer(base, %{renderer: "badge", renderer_options: opts}) do
  # ... colors 파싱 ...
  base
  |> Map.put(:renderer, LiveViewGrid.Renderers.badge(colors: colors))
  |> Map.put(:renderer_spec, %{type: "badge", options: %{colors: colors}})
end
```

link, progress renderer도 동일 패턴 적용.

### 2.4 JS Hook — ConfigImport (`assets/js/hooks/config-import.js`)

기존 `FileImport` Hook 패턴 참조. JSON 파일 전용.

```javascript
export const ConfigImport = {
  mounted() {
    this.el.addEventListener("click", () => {
      const input = document.createElement("input")
      input.type = "file"
      input.accept = ".json"
      input.style.display = "none"
      input.addEventListener("change", (e) => {
        const file = e.target.files[0]
        if (!file) { input.remove(); return }
        const reader = new FileReader()
        reader.onload = (ev) => {
          const json = ev.target.result
          this.pushEvent("import_config", { json })
          input.remove()
        }
        reader.readAsText(file, "UTF-8")
      })
      document.body.appendChild(input)
      input.click()
    })
  }
}
```

`app.js`에 Hook 등록:

```javascript
import {ConfigImport} from "./hooks/config-import"
// ...
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ..., ConfigImport }
})
```

### 2.5 다운로드 처리

기존 `download.js`의 `phx:download_file` 이벤트를 그대로 재활용.
JSON은 텍스트이므로 Base64 인코딩 후 전송:

```elixir
push_event(socket, "download_file", %{
  content: Base.encode64(json_string),
  filename: "#{grid_id}_config.json",
  mime_type: "application/json"
})
```

## 3. UI 설계

### 3.1 BuilderLive 헤더 영역

```
┌──────────────────────────────────────────────────────────────┐
│  🏗️ Grid Builder                                            │
│  Define columns, validators, formatters and create new grids │
│                                                              │
│  [📥 Import Config]  [+ Create New Grid]                     │
└──────────────────────────────────────────────────────────────┘
```

- "Import Config" 버튼: `phx-hook="ConfigImport"` — 클릭 시 파일 선택 다이얼로그
- 기존 "Create New Grid" 버튼 왼쪽에 배치

### 3.2 그리드 카드 헤더

```
┌──────────────────────────────────────────────────────────────┐
│  📊 사원 목록  [Grid Builder]  [🔗 DB]                       │
│                                    [📤 Export]  [Delete]     │
└──────────────────────────────────────────────────────────────┘
```

- "Export" 버튼: `phx-click="export_config" phx-value-id={dg.id}`
- 기존 "Delete" 버튼 왼쪽에 배치

## 4. JSON 스키마 v1.0

Plan에서 정의한 스키마를 확정. `@config_version "1.0"`.

```json
{
  "version": "1.0",
  "exported_at": "2026-03-04T12:00:00Z",
  "grid_name": "string (required)",
  "grid_id": "string (required)",
  "data_source_type": "sample | schema | table",
  "selected_schema": "string | null",
  "selected_table": "string | null",
  "options": {
    "page_size": "integer (1-100000)",
    "theme": "light | dark | custom",
    "virtual_scroll": "boolean",
    "row_height": "integer (32-80)",
    "frozen_columns": "integer (>= 0)",
    "show_row_number": "boolean",
    "show_header": "boolean",
    "show_footer": "boolean"
  },
  "columns": [
    {
      "field": "string (required, snake_case)",
      "label": "string (required)",
      "type": "string | integer | float | boolean | date | datetime",
      "width": "integer | \"auto\"",
      "align": "left | center | right",
      "sortable": "boolean",
      "filterable": "boolean",
      "editable": "boolean",
      "editor_type": "text | number | select | checkbox | date",
      "editor_options": "array",
      "formatter": "string | null",
      "formatter_options": "object",
      "validators": [
        {"type": "required | min | max | min_length | max_length | pattern", "value": "optional", "message": "string"}
      ],
      "renderer": {
        "type": "badge | link | progress",
        "options": "object (type-specific)"
      },
      "header_group": "string | null",
      "summary": "string | null"
    }
  ]
}
```

## 5. 검증 규칙

| 항목 | 규칙 | 에러 메시지 |
|------|------|-------------|
| version | "1.0" 존재 | "지원하지 않는 설정 버전입니다" |
| grid_name | 비어있지 않은 문자열 | "그리드 이름이 필요합니다" |
| grid_id | 비어있지 않은 문자열, 영소문자+숫자+_ | "유효하지 않은 그리드 ID입니다" |
| columns | 1개 이상의 배열 | "최소 1개 컬럼이 필요합니다" |
| column.field | 비어있지 않은 문자열, 50자 이내 | "컬럼 field가 필요합니다" |
| column.label | 비어있지 않은 문자열 | "컬럼 label이 필요합니다" |
| column.type | 허용 목록 내 | "유효하지 않은 컬럼 타입: {type}" |
| field 중복 | 고유해야 함 | "중복된 field가 있습니다: {field}" |
| JSON 파싱 | 유효한 JSON | "유효하지 않은 JSON 파일입니다" |
| 파일 크기 | JS에서 1MB 제한 | "파일이 너무 큽니다 (최대 1MB)" |

## 6. 구현 순서 (우선순위)

| 순서 | 작업 | 파일 | 예상 규모 |
|------|------|------|-----------|
| 1 | GridConfigSerializer 모듈 | `grid_config_serializer.ex` (신규) | ~200줄 |
| 2 | GridConfigSerializer 테스트 | `grid_config_serializer_test.exs` (신규) | ~200줄 |
| 3 | BuilderHelpers renderer_spec 추가 | `builder_helpers.ex` (수정) | ~10줄 |
| 4 | ConfigImport JS Hook | `config-import.js` (신규) + `app.js` (수정) | ~30줄 |
| 5 | BuilderLive Export/Import 이벤트 | `builder_live.ex` (수정) | ~40줄 |
| 6 | BuilderLive UI (Export/Import 버튼) | `builder_live.ex` render (수정) | ~20줄 |
| 7 | 통합 테스트 | `builder_live_test.exs` (수정) | ~50줄 |

**총 예상**: 신규 ~430줄 + 기존 수정 ~70줄

## 7. 테스트 전략

### 단위 테스트 (GridConfigSerializer)
- `serialize/1`: 모든 컬럼 속성 타입 변환 확인
- `deserialize/1`: 유효한 JSON → 정확한 params 복원
- round-trip: `serialize → deserialize → 원본과 동일`
- 에러 케이스: 빈 JSON, 필수 필드 누락, 잘못된 타입, 중복 field
- renderer 직렬화: badge/link/progress 각각 round-trip
- validator 직렬화: required/min/max/pattern 각각 round-trip
- 보안: 허용 목록 외 atom 변환 시도 시 에러

### 통합 테스트 (BuilderLive)
- Export 버튼 클릭 → download_file 이벤트 전송 확인
- Import → 그리드 생성 확인 (dynamic_grids에 추가)
- 잘못된 JSON Import → 에러 flash 표시
