# F-310: 다중 조건 필터 - 기술 설계서

> **기능 코드**: F-310
> **작성일**: 2026-02-21
> **Plan 문서**: [advanced-filter.plan.md](../../01-plan/features/advanced-filter.plan.md)

---

## 1. 아키텍처

### 1.1 모듈 구조

```
lib/liveview_grid/
  operations/filter.ex         ← [MODIFY] 다중 조건 + 연산자 지원
  grid.ex                      ← [MODIFY] state 구조 변경 (하위호환)

lib/liveview_grid_web/
  components/grid_component.ex ← [MODIFY] 고급 필터 UI + 이벤트

assets/css/
  liveview_grid.css            ← [MODIFY] 고급 필터 빌더 CSS
```

### 1.2 데이터 흐름

```
[기존 필터 행 입력]                    [고급 필터 빌더]
       │                                    │
       │  grid_filter(field, value)         │  advanced_filter_add/update/remove
       │                                    │
       ▼                                    ▼
  ┌──────────────────────────────────────────────┐
  │  GridComponent: normalize_to_advanced_filter  │
  │  (기존 형식 → 새 형식 자동 변환)               │
  └──────────────────────┬───────────────────────┘
                         │
                         ▼
  ┌──────────────────────────────────────────────┐
  │  Grid State                                   │
  │  advanced_filters: %{                         │
  │    logic: :and,                               │
  │    conditions: [%{field, operator, value}]     │
  │  }                                            │
  └──────────────────────┬───────────────────────┘
                         │
                         ▼
  ┌──────────────────────────────────────────────┐
  │  Filter.apply_advanced(data, advanced_filters)│
  └──────────────────────────────────────────────┘
```

---

## 2. API 설계

### 2.1 Filter 모듈 확장

```elixir
defmodule LiveViewGrid.Filter do
  # 기존 API 유지 (하위 호환)
  def apply(data, filters, columns)     # 기존 단순 필터
  def global_search(data, query, columns)

  # 새 API 추가
  @doc "다중 조건 고급 필터 적용"
  def apply_advanced(data, advanced_filters, columns)
    # advanced_filters: %{logic: :and | :or, conditions: [condition]}
    # condition: %{field: :atom, operator: :atom, value: any}

  @doc "단일 조건 매칭"
  def match_condition?(row, condition, columns)
end
```

### 2.2 연산자 정의

```elixir
# 텍스트 연산자
@text_operators [:contains, :equals, :starts_with, :ends_with, :is_empty, :is_not_empty]

# 숫자 연산자
@number_operators [:eq, :neq, :gt, :lt, :gte, :lte]
```

### 2.3 Grid State 변경

```elixir
# 기존 state (유지)
state = %{
  filters: %{},              # 기존 단순 필터 (필터 행용)
  global_search: "",
  show_filter_row: false,
  # ... 기타

  # 새로 추가
  advanced_filters: %{
    logic: :and,
    conditions: []
  },
  show_advanced_filter: false  # 고급 필터 패널 표시 여부
}
```

### 2.4 GridComponent 이벤트

```elixir
# 고급 필터 패널 토글
def handle_event("toggle_advanced_filter", _params, socket)

# 조건 추가
def handle_event("add_filter_condition", _params, socket)
  # → conditions에 빈 조건 추가: %{field: nil, operator: :contains, value: ""}

# 조건 업데이트
def handle_event("update_filter_condition", %{
  "index" => index,
  "field" => field | "operator" => operator | "value" => value
}, socket)

# 조건 삭제
def handle_event("remove_filter_condition", %{"index" => index}, socket)

# 논리 연산자 변경
def handle_event("change_filter_logic", %{"logic" => "and" | "or"}, socket)

# 필터 적용
def handle_event("apply_advanced_filter", _params, socket)

# 전체 초기화
def handle_event("clear_advanced_filter", _params, socket)
```

---

## 3. 상세 구현 설계

### 3.1 Filter.apply_advanced/3

```elixir
def apply_advanced(data, %{logic: logic, conditions: conditions}, columns) do
  # 빈 조건 제거 (field가 nil이거나 value가 빈 것)
  active_conditions = Enum.filter(conditions, fn c ->
    c.field != nil and c.value != "" and c.value != nil
  end)

  if Enum.empty?(active_conditions) do
    data
  else
    column_map = Map.new(columns, fn col -> {col.field, col} end)

    Enum.filter(data, fn row ->
      results = Enum.map(active_conditions, fn condition ->
        match_condition?(row, condition, column_map)
      end)

      case logic do
        :and -> Enum.all?(results)
        :or  -> Enum.any?(results)
      end
    end)
  end
end
```

### 3.2 match_condition?/3

```elixir
defp match_condition?(row, %{field: field, operator: operator, value: value}, column_map) do
  cell_value = Map.get(row, field)
  col = Map.get(column_map, field, %{filter_type: :text})
  filter_type = Map.get(col, :filter_type, :text)

  case filter_type do
    :text -> match_text?(cell_value, operator, value)
    :number -> match_number?(cell_value, operator, value)
    _ -> match_text?(cell_value, operator, value)
  end
end

defp match_text?(nil, :is_empty, _), do: true
defp match_text?("", :is_empty, _), do: true
defp match_text?(_, :is_empty, _), do: false
defp match_text?(nil, :is_not_empty, _), do: false
defp match_text?("", :is_not_empty, _), do: false
defp match_text?(_, :is_not_empty, _), do: true
defp match_text?(nil, _, _), do: false
defp match_text?(cell, :contains, value) do
  String.contains?(String.downcase(to_string(cell)), String.downcase(to_string(value)))
end
defp match_text?(cell, :equals, value) do
  String.downcase(to_string(cell)) == String.downcase(to_string(value))
end
defp match_text?(cell, :starts_with, value) do
  String.starts_with?(String.downcase(to_string(cell)), String.downcase(to_string(value)))
end
defp match_text?(cell, :ends_with, value) do
  String.ends_with?(String.downcase(to_string(cell)), String.downcase(to_string(value)))
end

defp match_number?(nil, _, _), do: false
defp match_number?(cell, operator, value) do
  cell_num = to_number(cell)
  val_num = to_number(value)
  if is_nil(cell_num) or is_nil(val_num), do: false, else:
    case operator do
      :eq  -> cell_num == val_num
      :neq -> cell_num != val_num
      :gt  -> cell_num > val_num
      :lt  -> cell_num < val_num
      :gte -> cell_num >= val_num
      :lte -> cell_num <= val_num
    end
end
```

### 3.3 Grid.ex 변경

```elixir
# initial_state에 추가
defp initial_state do
  %{
    # ... 기존 필드
    advanced_filters: %{logic: :and, conditions: []},
    show_advanced_filter: false
  }
end

# sorted_data에서 advanced_filters 적용
def sorted_data(grid) do
  grid.data
  |> apply_global_search(state.global_search, columns)
  |> apply_filters(state.filters, columns)
  |> apply_advanced_filters(state.advanced_filters, columns)  # 새로 추가
  |> apply_sort(state.sort)
end
```

### 3.4 UI 설계 - 고급 필터 빌더

```
┌─────────────────────────────────────────────────────────────────┐
│ 고급 필터                                          [AND ▼] [X]  │
├─────────────────────────────────────────────────────────────────┤
│ [이름 ▼]    [포함 ▼]     [Alice          ]    [x]              │
│ [나이 ▼]    [큼 ▼]       [30             ]    [x]              │
│ [도시 ▼]    [같음 ▼]     [Seoul          ]    [x]              │
├─────────────────────────────────────────────────────────────────┤
│ [+ 조건 추가]                          [초기화] [적용]          │
└─────────────────────────────────────────────────────────────────┘
```

위치: 필터 행 아래, 그리드 본체 위에 슬라이드 다운으로 표시

---

## 4. CSS 설계

```css
/* 고급 필터 빌더 패널 */
.lv-grid__advanced-filter {
  background: #f8f9fa;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 16px;
  margin: 8px 0;
}

.lv-grid__advanced-filter-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  font-weight: 600;
  font-size: 14px;
}

.lv-grid__advanced-filter-logic {
  display: inline-flex;
  gap: 4px;
}

.lv-grid__advanced-filter-logic-btn {
  padding: 2px 10px;
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  background: white;
}
.lv-grid__advanced-filter-logic-btn--active {
  background: #1976d2;
  color: white;
  border-color: #1976d2;
}

/* 조건 행 */
.lv-grid__filter-condition {
  display: flex;
  gap: 8px;
  align-items: center;
  margin-bottom: 8px;
}

.lv-grid__filter-condition select,
.lv-grid__filter-condition input {
  padding: 6px 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 13px;
}

.lv-grid__filter-condition select { flex: 0 0 140px; }
.lv-grid__filter-condition input { flex: 1; }

.lv-grid__filter-condition-remove {
  background: none;
  border: none;
  color: #999;
  cursor: pointer;
  font-size: 16px;
  padding: 4px 8px;
}
.lv-grid__filter-condition-remove:hover { color: #e53935; }

/* 하단 액션 */
.lv-grid__advanced-filter-actions {
  display: flex;
  justify-content: space-between;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #e0e0e0;
}

.lv-grid__filter-add-btn {
  background: none;
  border: 1px dashed #999;
  border-radius: 4px;
  padding: 6px 16px;
  font-size: 13px;
  cursor: pointer;
  color: #666;
}
.lv-grid__filter-add-btn:hover { border-color: #1976d2; color: #1976d2; }

.lv-grid__filter-apply-btn {
  background: #1976d2;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 6px 20px;
  font-size: 13px;
  cursor: pointer;
}
.lv-grid__filter-apply-btn:hover { background: #1565c0; }

.lv-grid__filter-reset-btn {
  background: white;
  border: 1px solid #ccc;
  border-radius: 4px;
  padding: 6px 16px;
  font-size: 13px;
  cursor: pointer;
}

/* 활성 필터 뱃지 */
.lv-grid__filter-badge {
  background: #e53935;
  color: white;
  border-radius: 50%;
  font-size: 10px;
  min-width: 16px;
  height: 16px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-left: 4px;
}
```

---

## 5. 테스트 시나리오

| ID | 시나리오 | 예상 결과 |
|----|---------|----------|
| T-01 | 단일 조건: 이름 contains "Alice" | Alice 포함 행만 표시 |
| T-02 | 단일 조건: 나이 > 30 | 나이 30 초과 행만 표시 |
| T-03 | AND 조건: 이름 contains "A" AND 도시 equals "Seoul" | 두 조건 모두 만족 |
| T-04 | OR 조건: 도시 equals "Seoul" OR 도시 equals "Busan" | 둘 중 하나 만족 |
| T-05 | 조건 추가 → 3개 조건 | 모든 조건 표시, 필터 적용 |
| T-06 | 조건 삭제 (X 버튼) | 해당 조건만 제거 |
| T-07 | 전체 초기화 | 모든 조건 제거, 전체 데이터 |
| T-08 | 기존 필터 행 호환 | 필터 행 입력 시 기존대로 동작 |
| T-09 | 뱃지에 활성 조건 수 표시 | 숫자 뱃지 표시 |
| T-10 | 빈 조건 무시 | 값 없는 조건은 필터에 포함 안 됨 |

---

## 6. 파일 변경 목록

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `lib/liveview_grid/operations/filter.ex` | MODIFY | apply_advanced/3, match_condition 추가 |
| `lib/liveview_grid/grid.ex` | MODIFY | state 구조 + sorted_data 파이프라인 |
| `lib/liveview_grid_web/components/grid_component.ex` | MODIFY | 고급 필터 UI + 이벤트 핸들러 |
| `assets/css/liveview_grid.css` | MODIFY | 고급 필터 빌더 CSS |
