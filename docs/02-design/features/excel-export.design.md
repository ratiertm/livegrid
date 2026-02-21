# F-510: Excel Export 기술 설계서

> **기능 코드**: F-510
> **작성일**: 2026-02-21
> **Plan 문서**: [excel-export.plan.md](../../01-plan/features/excel-export.plan.md)

---

## 1. 아키텍처

### 1.1 모듈 구조

```
lib/liveview_grid/
  export.ex                    ← [NEW] Excel/CSV 생성 핵심 로직

lib/liveview_grid_web/
  components/grid_component.ex ← [MODIFY] export 이벤트 + UI 버튼
  live/demo_live.ex            ← [MODIFY] Excel Export 핸들러

assets/js/
  app.js                       ← [MODIFY] 파일 다운로드 Hook

mix.exs                        ← [MODIFY] elixlsx 의존성 추가
```

### 1.2 데이터 흐름

```
[GridComponent]                    [Parent LiveView]              [Export Module]
     │                                    │                              │
     │  export_excel(type)                │                              │
     ├──send(:grid_export_excel)──────────>│                              │
     │                                    │  Export.to_xlsx(data,cols)   │
     │                                    ├─────────────────────────────>│
     │                                    │      {:ok, binary}           │
     │                                    │<─────────────────────────────┤
     │   push_event("download_file")      │                              │
     │<───────────────────────────────────┤                              │
     │                                    │                              │
     │  [JS Hook: Base64→Blob→Download]   │                              │
     ▼                                    │                              │
```

---

## 2. API 설계

### 2.1 Export 모듈

```elixir
defmodule LiveViewGrid.Export do
  @moduledoc """
  그리드 데이터를 Excel/CSV 형식으로 변환하는 모듈.
  """

  @doc """
  데이터를 Excel (.xlsx) 바이너리로 변환.

  ## Parameters
    - data: 행 데이터 리스트 [%{field: value, ...}, ...]
    - columns: 컬럼 정의 리스트 [%{field: :atom, label: "표시명"}, ...]
    - opts: 옵션 키워드 리스트
      - :sheet_name - 시트 이름 (기본: "Sheet1")
      - :header_style - 헤더 스타일 적용 여부 (기본: true)

  ## Returns
    {:ok, binary} | {:error, reason}

  ## Examples
      {:ok, xlsx_binary} = Export.to_xlsx(data, columns)
      {:ok, xlsx_binary} = Export.to_xlsx(data, columns, sheet_name: "사용자 목록")
  """
  def to_xlsx(data, columns, opts \\ [])

  @doc """
  데이터를 CSV 문자열로 변환 (UTF-8 BOM 포함).

  ## Parameters
    - data: 행 데이터 리스트
    - columns: 컬럼 정의 리스트

  ## Returns
    binary (CSV 문자열)
  """
  def to_csv(data, columns)
end
```

### 2.2 GridComponent 이벤트

```elixir
# 새 이벤트 핸들러
def handle_event("export_excel", %{"type" => type}, socket)
  # type: "all" | "filtered" | "selected"
  # → send(self(), {:grid_export_excel, type, data, columns})

def handle_event("export_csv", %{"type" => type}, socket)
  # type: "all" | "filtered" | "selected"
  # → send(self(), {:grid_export_csv, type, data, columns})
```

### 2.3 Parent LiveView 핸들러

```elixir
# Parent가 구현해야 하는 handle_info
def handle_info({:grid_export_excel, type, data, columns}, socket)
  # 1. type에 따라 데이터 선택 (all/filtered/selected)
  # 2. Export.to_xlsx(data, columns) 호출
  # 3. push_event("download_file", %{...}) 로 다운로드 트리거
```

---

## 3. 상세 구현 설계

### 3.1 Export.to_xlsx/3 구현

```elixir
def to_xlsx(data, columns, opts \\ []) do
  sheet_name = Keyword.get(opts, :sheet_name, "Sheet1")
  header_style = Keyword.get(opts, :header_style, true)

  # 1. 헤더 행 생성
  headers = Enum.map(columns, fn col ->
    if header_style do
      [col.label, bold: true, bg_color: "#4472C4", font_color: "#FFFFFF"]
    else
      col.label
    end
  end)

  # 2. 데이터 행 생성
  rows = Enum.map(data, fn row ->
    Enum.map(columns, fn col ->
      value = Map.get(row, col.field)
      format_cell_value(value)
    end)
  end)

  # 3. 워크북 생성
  workbook = %Elixlsx.Workbook{
    sheets: [
      %Elixlsx.Sheet{
        name: sheet_name,
        rows: [headers | rows],
        col_widths: generate_col_widths(columns)
      }
    ]
  }

  # 4. 바이너리로 변환
  Elixlsx.write_to_memory(workbook, "export.xlsx")
end
```

### 3.2 셀 값 포맷팅

```elixir
defp format_cell_value(nil), do: ""
defp format_cell_value(value) when is_integer(value), do: value
defp format_cell_value(value) when is_float(value), do: value
defp format_cell_value(value) when is_boolean(value), do: if(value, do: "O", else: "X")
defp format_cell_value(value), do: to_string(value)
```

### 3.3 컬럼 너비 자동 계산

```elixir
defp generate_col_widths(columns) do
  columns
  |> Enum.with_index(1)
  |> Enum.map(fn {col, idx} ->
    width = case col[:width] do
      w when is_integer(w) -> max(10, div(w, 7))  # 픽셀 → 문자 단위 근사
      _ -> 15  # 기본 너비
    end
    {idx, width}
  end)
  |> Map.new()
end
```

### 3.4 JS 다운로드 Hook

```javascript
// app.js에 추가
Hooks.DownloadFile = {
  mounted() {
    this.handleEvent("download_file", ({content, filename, mime_type}) => {
      // Base64 → Blob → Download
      const byteCharacters = atob(content)
      const byteNumbers = new Array(byteCharacters.length)
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i)
      }
      const byteArray = new Uint8Array(byteNumbers)
      const blob = new Blob([byteArray], {type: mime_type})

      const url = URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = filename
      a.click()
      URL.revokeObjectURL(url)
    })
  }
}
```

### 3.5 GridComponent UI (Export 버튼)

```
┌─────────────────────────────────────────────────────────────────┐
│ [헤더 행 ...]                                                    │
│                                                                  │
│ 📥 Export: [CSV ▼] [Excel ▼]                                     │
│    └ 전체 데이터     └ 전체 데이터                                  │
│    └ 필터 결과       └ 필터 결과                                    │
│    └ 선택된 행       └ 선택된 행                                    │
│                                                                  │
│ [Footer: 페이지네이션]                                            │
└─────────────────────────────────────────────────────────────────┘
```

**Export 버튼 위치**: GridComponent의 footer 영역 왼쪽에 배치.

---

## 4. CSS 설계

```css
/* Export 버튼 영역 */
.lv-grid__export { display: flex; align-items: center; gap: 8px; }
.lv-grid__export-btn {
  padding: 4px 12px;
  border: 1px solid #ccc;
  border-radius: 4px;
  background: white;
  cursor: pointer;
  font-size: 12px;
  font-weight: 600;
  transition: all 0.2s;
}
.lv-grid__export-btn:hover { background: #f5f5f5; border-color: #999; }
.lv-grid__export-btn--excel { color: #217346; border-color: #217346; }
.lv-grid__export-btn--excel:hover { background: #e8f5e9; }
.lv-grid__export-btn--csv { color: #1565c0; border-color: #1565c0; }
.lv-grid__export-btn--csv:hover { background: #e3f2fd; }

/* Export 드롭다운 */
.lv-grid__export-dropdown {
  position: absolute;
  bottom: 100%;
  left: 0;
  background: white;
  border: 1px solid #ddd;
  border-radius: 4px;
  box-shadow: 0 -2px 8px rgba(0,0,0,0.1);
  min-width: 160px;
  z-index: 100;
}
.lv-grid__export-dropdown-item {
  padding: 8px 16px;
  cursor: pointer;
  font-size: 13px;
}
.lv-grid__export-dropdown-item:hover { background: #f5f5f5; }
```

---

## 5. 테스트 시나리오

| ID | 시나리오 | 예상 결과 |
|----|---------|----------|
| T-01 | 전체 데이터 Excel 다운로드 | .xlsx 파일 다운로드, 모든 행 포함 |
| T-02 | 필터된 데이터 Excel 다운로드 | 필터 결과만 포함 |
| T-03 | 한글 데이터 Excel 확인 | 한글 깨짐 없음 |
| T-04 | 헤더 스타일 확인 | 굵게 + 파란 배경 |
| T-05 | 1,000행 Export 성능 | < 2초 |
| T-06 | 빈 데이터 Export | 헤더만 포함된 파일 |
| T-07 | CSV Export 기존 기능 유지 | 기존과 동일하게 동작 |
| T-08 | Export 버튼 UI 표시 | footer에 깔끔하게 표시 |

---

## 6. 기존 코드와의 호환

### 6.1 기존 CSV Export 유지

기존 `demo_live.ex`의 CSV Export 로직은 유지하되, 새로운 `Export` 모듈로 리팩토링한다.
- 기존: `demo_live.ex` 내 `generate_csv/1`
- 변경: `LiveViewGrid.Export.to_csv/2` 호출

### 6.2 GridComponent 변경 최소화

Export 이벤트는 GridComponent가 Parent에 메시지를 보내는 방식으로 구현.
Parent LiveView가 실제 데이터 소스를 알고 있으므로 적절한 데이터를 Export 모듈에 전달.

---

## 7. 파일 변경 목록

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `mix.exs` | MODIFY | elixlsx 의존성 추가 |
| `lib/liveview_grid/export.ex` | NEW | Excel/CSV 생성 모듈 |
| `lib/liveview_grid_web/components/grid_component.ex` | MODIFY | export 이벤트 + UI |
| `assets/css/liveview_grid.css` | MODIFY | Export 버튼 CSS |
| `assets/js/app.js` | MODIFY | 다운로드 Hook |
| `lib/liveview_grid_web/live/demo_live.ex` | MODIFY | Excel Export 핸들러 |
