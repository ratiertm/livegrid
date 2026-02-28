# Config Modal Checkbox Crash Fix - Completion Report

> **Feature**: config-modal-checkbox-crash-fix
> **Type**: Critical Bug Fix
> **Date**: 2026-02-28
> **Match Rate**: 100% (verified on both Demo and Builder pages)

---

## 1. Summary

Grid Configuration Modal의 Column Properties 탭에서 Sortable/Filterable/Editable 체크박스를 클릭하면 LiveView 프로세스가 `FunctionClauseError`로 크래시되는 치명적 버그를 수정했습니다.

**영향 범위**: 모든 그리드 (InMemory Demo, DBMS Demo, API Demo, Builder 등)에서 Config Modal의 체크박스 조작 시 발생.

---

## 2. Problem Description

### 사용자 보고 증상
1. Grid Builder에서 그리드 생성
2. ⚙ 설정 → Column Properties 탭 → 컬럼 선택
3. Sortable/Filterable/Editable 체크박스 클릭
4. **모달 사라지고 화면 초기화** → Builder의 경우 만들던 그리드 완전 소실

### Root Cause
```
[error] GenServer #PID<0.3897.0> terminating
** (FunctionClauseError) no function clause matching in
   LiveViewGridWeb.Components.GridConfig.ConfigModal.handle_event/3
    Parameters: %{"field" => "name", "key" => "sortable"}
```

**원인**: checkbox의 `phx-value-value` 속성이 LiveView `phx-click` 이벤트 params에 `"value"` 키를 전달하지 못함. HTML checkbox의 네이티브 `value` 속성과 충돌.

**핸들러 패턴 매치 실패**:
```elixir
# 기존 코드 - "value" 키 필수
def handle_event("update_property", %{"field" => f, "key" => k, "value" => v}, socket)

# 실제 수신 params - "value" 키 없음
%{"field" => "name", "key" => "sortable"}
```

**크래시 전파 메커니즘**:
- ConfigModal (LiveComponent) 크래시 → 부모 LiveView 프로세스 종료
- LiveView 재마운트 → ephemeral assigns 초기화
- Builder의 `dynamic_grids: []` 리셋 → 모든 생성된 그리드 소실

---

## 3. Fix Details

### Fix 1: ConfigModal checkbox crash (Primary)

**파일**: `lib/liveview_grid_web/components/grid_config/config_modal.ex`

**Template 수정** (3곳): `phx-value-value` → `phx-value-val`
```html
<!-- Before -->
phx-value-value={if cfg[:sortable], do: "false", else: "true"}

<!-- After -->
phx-value-val={if cfg[:sortable], do: "false", else: "true"}
```

**Handler 수정** (1곳): 유연한 param 추출
```elixir
# Before - "value" 키 필수 패턴 매치
def handle_event("update_property", %{"field" => f, "key" => k, "value" => v}, socket)

# After - "value" 또는 "val" 키 지원
def handle_event("update_property", %{"field" => f, "key" => k} = params, socket) do
  value = params["value"] || params["val"]
```

### Fix 2: Missing handle_info in BuilderLive (Secondary)

**파일**: `lib/liveview_grid_web/live/builder_live.ex`

```elixir
# Added - ConfigModal close 버튼의 :modal_close 메시지 처리
@impl true
def handle_info(:modal_close, socket), do: {:noreply, socket}
```

---

## 4. Files Modified

| File | Change Type | Description |
|------|------------|-------------|
| `lib/liveview_grid_web/components/grid_config/config_modal.ex` | Bug Fix | `phx-value-value` → `phx-value-val` (3곳), handler 유연화 (1곳) |
| `lib/liveview_grid_web/live/builder_live.ex` | Bug Fix | `:modal_close` handle_info 추가 |

---

## 5. Verification

### Test Results
- **428 tests, 0 failures** (전체 테스트 통과)
- 컴파일 경고 없음 (`--warnings-as-errors`)

### Browser Verification

#### InMemory Demo Page
1. ⚙ 설정 → Column Properties → "이름(name)" 선택
2. Sortable 체크박스 클릭 → ✅ 정상 해제, Changes: 1 표시
3. Filterable 체크박스 클릭 → ✅ 정상 해제, Changes: 2 표시
4. Apply (2) 버튼 활성화 → ✅ 정상
5. 모달 유지, 크래시 없음 → ✅

#### Builder Page
1. "TestGrid" 생성 (Database Schema + DemoUser)
2. ⚙ 설정 → Column Properties → "name" 선택
3. Sortable 체크박스 클릭 → ✅ 정상 해제, Changes: 1 표시
4. Apply (1) 버튼 활성화 → ✅ 정상
5. **그리드 유지** ("1 grid(s) created" 표시) → ✅
6. 서버 프로세스 생존 확인 → ✅

---

## 6. Impact Analysis

| 항목 | 수정 전 | 수정 후 |
|------|--------|--------|
| Checkbox 클릭 | FunctionClauseError 크래시 | 정상 토글 + Changes 추적 |
| Builder 그리드 | 체크박스 클릭 시 소실 | 안전하게 유지 |
| Modal close (Builder) | 미처리 메시지 크래시 위험 | 안전하게 무시 |
| 영향 범위 | 모든 페이지의 Config Modal | 전부 수정됨 |

---

## 7. Lessons Learned

1. **`phx-value-value`는 사용 금지**: LiveView의 `phx-click` + `phx-value-*`에서 `value`라는 이름은 HTML checkbox의 네이티브 `value` 속성과 충돌. `val`, `toggle_value` 등 다른 이름 사용 필요.
2. **LiveComponent 크래시 전파**: 자식 LiveComponent의 `handle_event` 크래시는 부모 LiveView를 함께 죽임. 방어적 패턴 매치(catch-all) 고려 필요.
3. **Ephemeral state 취약성**: Builder의 `dynamic_grids`가 socket assigns에만 존재하여 프로세스 재시작 시 소실. 향후 ETS/DB 영속화 검토.

---

## 8. Statistics

| Metric | Value |
|--------|-------|
| Bug Severity | Critical (데이터 손실) |
| Fix Type | Hotfix (2 files) |
| Lines Changed | ~10 |
| Tests Passing | 428/428 |
| Iterations | 0 (single-pass fix) |
| Backwards Compatibility | 100% |
| Browser Verified | Demo ✅, Builder ✅ |

---

**Report Generated**: 2026-02-28
**Status**: ✅ Complete - Production Ready
