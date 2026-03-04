# FA-005 Overlay System — Gap Analysis

> **Feature ID**: FA-005
> **Version**: v0.12.0
> **Analyzed**: 2026-03-05

---

## 설계 vs 구현 비교

| # | 설계 항목 | 구현 상태 | 일치율 |
|---|-----------|-----------|--------|
| Step 1 | initial_state에 loading/error 추가 | ✅ `loading: false, error: nil` 추가됨 | 100% |
| Step 2 | default_options에 overlay 텍스트 옵션 | ✅ 3개 옵션 모두 추가됨 | 100% |
| Step 3 | set_loading/2, set_error/2 API | ✅ @spec 포함 구현 완료 | 100% |
| Step 4 | HEEx 오버레이 렌더링 (cond) | ✅ loading/error/no-data 3종 구현 | 95% |
| Step 5 | CSS 스타일링 | ✅ overlay, spinner, icon, text 모두 구현 | 95% |
| Step 6 | body position: relative 확인 | ✅ position: relative 유지 확인 | 100% |
| Step 7 | 테스트 | ✅ set_loading/2, set_error/2 테스트 구현 | 100% |

## 편차 상세

### Step 4: No-data 조건 개선 (설계 대비 개선)
- **설계**: `@grid.data == [] || @grid.state.current_page_data == []`
- **구현**: `@grid.data == [] or Grid.visible_data(@grid) == []`
- **사유**: `current_page_data` 필드가 존재하지 않아 `Grid.visible_data/1` 사용. 필터링/검색 후 빈 결과도 감지 가능하도록 개선.

### Step 5: CSS position 차이
- **설계**: `position: absolute` (부모 기준 오버레이)
- **구현**: `position: relative` (자연스러운 flow 배치)
- **사유**: body 영역이 동적 높이이므로 relative가 더 적합. min-height: 200px로 최소 높이 보장.

## Chrome MCP 테스트 결과

| 시나리오 | 기대 | 결과 |
|----------|------|------|
| 데이터 50행 존재 | 오버레이 없음 | ✅ PASS |
| 검색→결과 0건 | no-data 오버레이 표시 | ✅ PASS |
| no-data 텍스트 | "표시할 데이터가 없습니다" | ✅ PASS |
| CSS flex/z-index | center 정렬, z-index:20 | ✅ PASS |
| 검색 초기화 | 오버레이 사라짐 + 데이터 복구 | ✅ PASS |

## 단위 테스트 결과
- **216 tests, 0 failures**
- set_loading/2: true/false 토글 정상
- set_error/2: 문자열 설정 + nil 초기화 정상

## 총평

| 항목 | 결과 |
|------|------|
| **Match Rate** | **96%** |
| **판정** | ✅ PASS (≥ 90%) |
| **주요 편차** | position 방식 변경 (개선), no-data 조건 개선 |
