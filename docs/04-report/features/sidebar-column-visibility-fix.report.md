# Sidebar 컬럼 숨김/표시 버그 수정 Report

> **Status**: Complete (Bug Fix)
>
> **Project**: LiveView Grid - Phoenix LiveView 기반 상용 그리드 컴포넌트
> **Feature**: 사이드바에서 컬럼명 클릭 시 스크립트 에러 수정
> **Author**: Development Team
> **Completion Date**: 2026-03-02
> **Type**: Bug Fix

---

## 1. Bug Description

### 1.1 증상

사이드바 → 컬럼 탭 → 체크박스(컬럼명) 클릭 시 **스크립트 에러 발생**

### 1.2 Root Cause

템플릿에서 `phx-click="grid_toggle_column_visibility"` 이벤트를 사용하지만,
**해당 이벤트 핸들러가 grid_component.ex에 등록되지 않음**.

```elixir
# grid_component.ex 1782줄 - 템플릿에서 사용
<input type="checkbox" phx-click="grid_toggle_column_visibility" phx-value-field={col.field} />

# grid_component.ex - handle_event 매핑 없음 ❌
# event_handlers.ex - 함수 없음 ❌
```

LiveView가 매칭되지 않는 이벤트를 받으면 프로세스가 크래시하여 스크립트 에러로 표출됨.

### 1.3 관련 코드

- `config_modal.ex:363` — 설정 모달에는 `toggle_column_visibility` 핸들러가 있음 (별도 컴포넌트)
- `event_handlers.ex:491` — `hide_column` 액션에 hidden_columns 처리 로직이 있었으나, 사이드바용이 아님

---

## 2. Fix

### 2.1 grid_component.ex — 이벤트 라우팅 추가

```elixir
@impl true
def handle_event("grid_toggle_column_visibility", params, socket),
  do: EventHandlers.handle_toggle_column_visibility(params, socket)
```

### 2.2 event_handlers.ex — 핸들러 함수 추가

```elixir
def handle_toggle_column_visibility(%{"field" => field_str}, socket) do
  grid = socket.assigns.grid
  field_atom = String.to_existing_atom(field_str)
  hidden = Map.get(grid.state, :hidden_columns, [])

  # 원본 컬럼 목록 보존
  original_columns = get_all_columns(grid)

  new_hidden =
    if field_atom in hidden,
      do: List.delete(hidden, field_atom),
      else: hidden ++ [field_atom]

  visible_columns =
    original_columns
    |> Enum.reject(fn col -> col.field in new_hidden end)

  updated_grid =
    grid
    |> Map.put(:columns, visible_columns)
    |> put_in([:state, :hidden_columns], new_hidden)
    |> put_in([:state, :all_columns], original_columns)

  {:noreply, assign(socket, grid: updated_grid)}
end
```

**핵심 포인트**: `state.all_columns`에 원본 전체 컬럼 목록을 보존하여 숨겼다가 다시 표시할 때 복원 가능.

---

## 3. Files Changed

| File | Changes |
|------|---------|
| `grid_component.ex` | `grid_toggle_column_visibility` → EventHandlers 라우팅 1줄 추가 |
| `event_handlers.ex` | `handle_toggle_column_visibility/2` 함수 + `get_all_columns/1` 헬퍼 추가 |

---

## 4. Verification

| Check | Result |
|-------|--------|
| Compilation | `mix compile --warnings-as-errors` PASS |
| Tests | 88 web tests, 0 failures |
| 컬럼 숨기기 | 사이드바에서 "나이" 체크 해제 → 그리드에서 나이 컬럼 제거됨 ✅ |
| 컬럼 복원 | "나이" 다시 체크 → 그리드에 나이 컬럼 복원됨 ✅ |
| Console Errors | 0건 |
| Server Errors | 0건 |
