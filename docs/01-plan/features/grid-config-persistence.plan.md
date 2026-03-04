# Plan: Grid Config Persistence (설정 저장/불러오기)

## 1. 개요

Grid Builder로 생성한 그리드+컬럼 설정을 JSON 파일로 **내보내기(Export)**하고, 저장된 JSON을 **불러오기(Import)**하여 동일한 그리드를 즉시 재생성하는 기능.

### 현재 상태
- Grid Builder는 3-Tab UI (Grid Info → Column Builder → Preview)로 그리드 생성
- 생성된 그리드는 LiveView socket assigns(`dynamic_grids`)에만 존재 → **페이지 이탈 시 소멸**
- Config Modal에서 런타임 설정 변경 가능하나, 역시 세션 한정
- `export.ex`에 Excel/CSV 데이터 내보내기는 있으나, **설정(메타데이터) 내보내기는 미구현**

### 해결할 문제
1. Builder로 복잡한 컬럼(formatter, validator, renderer 포함) 정의 후 페이지 이탈하면 설정 유실
2. 동일 설정을 반복 생성해야 하는 비효율
3. 팀원 간 그리드 설정 공유 불가

## 2. 기능 범위

### FR-01: 설정 내보내기 (Export)
- Builder로 생성된 그리드의 설정을 JSON 파일로 다운로드
- 포함 항목: grid_name, grid_id, columns(전체 속성), options, data_source_type
- **데이터(rows) 미포함** — 설정(스키마)만 저장
- 파일명: `{grid_id}_config.json`

### FR-02: 설정 불러오기 (Import)
- JSON 파일 업로드로 그리드 설정 복원
- 검증: 필수 필드, 컬럼 구조, 옵션 유효성
- 복원 후 즉시 그리드 생성 (기존 Builder 생성 흐름 재활용)

### FR-03: Builder 내 Export/Import UI
- Builder 페이지(`BuilderLive`)에 Export/Import 버튼 추가
- Export: 각 생성된 그리드 카드에 "Export Config" 버튼
- Import: 상단에 "Import Config" 버튼 → 파일 업로드

### 범위 제외 (Out of Scope)
- DB 저장 (향후 확장)
- 설정 버전 관리 / 히스토리
- Config Modal 런타임 변경분의 Export (Builder 원본만 대상)

## 3. 기술 분석

### 직렬화(Serialization) 과제
| 항목 | 현재 형태 | JSON 변환 방법 |
|------|-----------|---------------|
| field | atom (`:name`) | string (`"name"`) |
| type | atom (`:string`) | string (`"string"`) |
| align | atom (`:left`) | string (`"left"`) |
| width | integer or `:auto` | integer or `"auto"` |
| formatter | atom or nil | string or null |
| validators | `[{:required, msg}, {:min, val, msg}]` | `[{"type":"required","message":msg}]` |
| renderer | function (closure) | `{"type":"badge","options":{...}}` |
| editor_type | atom | string |
| editor_options | list | list |

**핵심 난이도: renderer**
- 현재 renderer는 `LiveViewGrid.Renderers.badge(colors: %{...})` 같은 함수 클로저
- 클로저는 직렬화 불가 → renderer spec(type + options)으로 변환 필요
- BuilderHelpers.build_renderer/2가 이미 spec → 함수 변환을 수행하므로, **역변환 로직** 필요

### 기존 코드 활용
- `BuilderHelpers.build_definition_params/1` — 이미 assigns → 정규화된 params 변환
- `BuilderHelpers.validator_map_to_tuple/1` — validator map ↔ tuple 변환 (역변환 추가 필요)
- `config_modal.ex` — validator 직렬화 로직 참고 (lines 647-649)
- 기존 `push_event(socket, "download_file", payload)` 패턴 — 파일 다운로드에 활용

### 영향 파일
| 파일 | 변경 내용 |
|------|-----------|
| `lib/liveview_grid/grid_config_serializer.ex` | **신규** — 직렬화/역직렬화 모듈 |
| `lib/liveview_grid_web/live/builder_live.ex` | Import/Export 이벤트 핸들러 추가 |
| `lib/liveview_grid_web/live/builder_live.ex` (render) | Export/Import UI 버튼 추가 |
| `assets/js/app.js` | 파일 업로드 Hook (Import용) |
| `test/liveview_grid/grid_config_serializer_test.exs` | **신규** — 직렬화 테스트 |
| `test/liveview_grid_web/live/builder_live_test.exs` | Export/Import 통합 테스트 |

## 4. JSON 스키마 (안)

```json
{
  "version": "1.0",
  "exported_at": "2026-03-04T12:00:00Z",
  "grid_name": "사원 목록",
  "grid_id": "employee_list",
  "data_source_type": "sample",
  "selected_schema": null,
  "selected_table": null,
  "options": {
    "page_size": 20,
    "theme": "light",
    "virtual_scroll": false,
    "row_height": 40,
    "frozen_columns": 0,
    "show_row_number": false,
    "show_header": true,
    "show_footer": true
  },
  "columns": [
    {
      "field": "name",
      "label": "이름",
      "type": "string",
      "width": 150,
      "align": "left",
      "sortable": true,
      "filterable": true,
      "editable": false,
      "editor_type": "text",
      "editor_options": [],
      "formatter": null,
      "validators": [
        {"type": "required", "message": "필수 입력"}
      ],
      "renderer": null
    },
    {
      "field": "status",
      "label": "상태",
      "type": "string",
      "width": 100,
      "align": "center",
      "sortable": true,
      "filterable": true,
      "editable": false,
      "editor_type": "text",
      "editor_options": [],
      "formatter": null,
      "validators": [],
      "renderer": {
        "type": "badge",
        "options": {"colors": {"Active": "green", "Inactive": "red"}}
      }
    }
  ]
}
```

## 5. 구현 순서

1. **GridConfigSerializer 모듈** — serialize/1, deserialize/1 + 테스트
2. **Export 기능** — BuilderLive 이벤트 + JSON 다운로드
3. **Import 기능** — 파일 업로드 Hook + 검증 + 그리드 생성
4. **UI** — Export/Import 버튼 렌더링
5. **통합 테스트** — round-trip (Export → Import → 동일 그리드 확인)

## 6. 성공 기준

- [ ] Builder로 생성한 그리드 설정을 JSON으로 Export 가능
- [ ] Export한 JSON을 Import하여 동일한 그리드 재생성 가능
- [ ] 컬럼의 formatter, validator, renderer가 Export/Import 후 정상 동작
- [ ] 잘못된 JSON Import 시 명확한 에러 메시지 표시
- [ ] 기존 Builder/Config Modal 기능에 영향 없음
- [ ] GridConfigSerializer 단위 테스트 통과 (serialize ↔ deserialize round-trip)
