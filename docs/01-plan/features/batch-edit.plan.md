# Batch Edit Plan
> ID: FA-034
> Priority: P2
> Phase: 5 (v1.0+)
> Date: 2026-03-02

## 목표
cell_range로 선택된 다중 셀에 대해 일괄값을 적용합니다. 대량 데이터 편집 작업을 효율화합니다.

## 구현 범위
- Grid state에 `cell_range` (map: `%{start: {row, col}, end: {row, col}}`) 필드 추가
- Grid API `batch_update_cells/3` 함수 구현
- JS Hook에서 shift+click으로 범위 선택 지원
- 범위 선택 UI 피드백 (하이라이트 CSS)
- 배치 업데이트 이벤트 핸들러 추가
- Undo/Redo 스택에 배치 작업 기록

## 변경 파일
- `lib/liveview_grid/grid.ex` — batch_update_cells/3, cell_range state 추가
- `lib/liveview_grid_web/components/grid_component/event_handlers.ex` — 범위 선택/업데이트 핸들러
- `assets/js/hooks/keyboard-nav.js` — shift+click 범위 선택 로직
- `assets/css/grid/body.css` — 선택 범위 하이라이트 스타일

## 의존성
없음

## 테스트 계획
- 셀 범위 선택 (시작점 → 끝점) 정확성 테스트
- batch_update_cells/3로 선택된 범위 내 모든 셀 값 변경 확인
- 범위 선택 UI 하이라이트 정상 표시 여부
- 범위 선택 후 Undo 동작 확인
- 다양한 범위 크기 (1x1, 5x3, 전체 그리드) 테스트
