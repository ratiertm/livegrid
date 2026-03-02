# FA-014 Master-Detail - Plan

> **Feature**: FA-014 Master-Detail
> **Phase**: 4 (v0.14)
> **Priority**: P1
> **Difficulty**: ⭐⭐⭐

## 요구사항

### FR-01: Detail Row 확장
- 행 좌측 ▶ 토글 버튼으로 상세 패널 열기/닫기
- `enable_master_detail: false` 기본 옵션
- `detail_renderer` 컬럼 옵션 — 커스텀 HEEx 슬롯 또는 함수

### FR-02: Detail 데이터
- Grid.toggle_detail/2 API — row_id로 토글
- state에 `expanded_details: MapSet` 관리
- 상세 패널은 모든 컬럼을 colspan으로 병합한 별도 행

### FR-03: Detail 렌더링
- 확장된 행 바로 아래에 detail row 삽입
- `.lv-grid__detail-row` CSS 클래스
- detail_renderer 함수가 row 데이터를 받아 HEEx 반환

## 구현 범위
- grid.ex: `toggle_detail/2`, `expanded_details` state, `enable_master_detail` option
- grid_component.ex: ▶ 토글 버튼, detail row 렌더링
- event_handlers.ex: `handle_toggle_detail/2`
- CSS: `.lv-grid__detail-row`, `.lv-grid__detail-toggle`

## 테스트
- toggle_detail API 테스트
- expanded_details state 관리 테스트
