# FA-001 Row Pinning — Gap Analysis

> **Feature ID**: FA-001
> **Version**: v0.12.0
> **Analyzed**: 2026-03-05

---

## 설계 vs 구현 비교

| # | 설계 항목 | 구현 상태 | 일치율 |
|---|-----------|-----------|--------|
| Step 1 | pinned_top/pinned_bottom state 필드 | ✅ initial_state에 추가됨 | 100% |
| Step 2 | pin_row/3, unpin_row/2, pinned helpers | ✅ @spec 포함 4개 함수 구현 | 100% |
| Step 3 | visible_data에서 pinned 행 제외 | ✅ all_pinned → Enum.reject | 100% |
| Step 4 | HEEx 상단/하단 pinned 영역 | ✅ render_cell/3 + column_width_style 활용 | 95% |
| Step 5 | CSS 스타일링 | ✅ pinned 배경 + 경계선 + 다크모드 | 100% |
| Step 6 | 데모 Pin 버튼 | ✅ 3개 버튼 + 이벤트 핸들러 + apply_v07_options 연동 | 100% |
| Step 7 | 테스트 | ✅ 6개 테스트 (pin/unpin/move/order/visible_data 제외) | 100% |

## 편차 상세

### Step 4: HEEx 렌더링 방식
- **설계**: 단순한 `cell_style/2`, `render_cell_value/3` 사용 계획
- **구현**: 기존 그리드와 동일한 `render_cell/3`, `column_width_style/2`, `frozen_class/2`, `frozen_style/2` 사용
- **사유**: 단순 함수가 존재하지 않아 기존 렌더링 함수로 통일. 더 높은 일관성 달성.

## Chrome MCP 테스트 결과

| 시나리오 | 기대 | 결과 |
|----------|------|------|
| 첫 행 상단 고정 | pinned-top 1행, 일반 49행 | ✅ PASS |
| 마지막 행 하단 고정 | pinned-bottom 1행, 일반 48행 | ✅ PASS |
| 고정 행 배경색 | #f0f7ff | ✅ PASS (rgb(240,247,255)) |
| 경계선 | 2px solid | ✅ PASS (top/bottom 모두) |
| 고정 해제 | 0개 고정, 50행 복구 | ✅ PASS |

## 단위 테스트 결과
- **222 tests, 0 failures**
- pin_row/3 top/bottom, unpin_row/2, position 변경, 순서 유지, visible_data 제외 모두 정상

## 총평

| 항목 | 결과 |
|------|------|
| **Match Rate** | **99%** |
| **판정** | ✅ PASS (≥ 90%) |
| **주요 개선** | 기존 렌더링 함수 재사용으로 일관성 향상 |
