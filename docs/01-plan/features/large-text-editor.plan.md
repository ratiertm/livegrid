# Large Text Editor Plan
> ID: FA-045
> Priority: P2
> Phase: 5 (v1.0+)
> Date: 2026-03-02

## 목표
textarea 기반의 대형 텍스트 편집기를 제공합니다. 셀 클릭 시 모달 또는 팝업으로 textarea를 표시하여 긴 텍스트 편집을 용이하게 합니다.

## 구현 범위
- Grid state에 `editing_cell` (map: `%{row: integer, col: integer, value: string}`) 추가
- grid_component.ex에서 편집 모달/팝업 UI 렌더링
- textarea 요소 (크기 조정 가능, 줄 번호 표시 선택적)
- 저장/취소 버튼
- Ctrl+Enter로 저장, Esc로 취소 단축키
- 셀 더블 클릭 또는 F2로 편집 시작
- GridConfig에 large_text_editor 옵션 추가

## 변경 파일
- `lib/liveview_grid/grid.ex` — editing_cell state 추가
- `lib/liveview_grid_web/components/grid_component.ex` — 편집 모달 HEEx, 렌더링 로직
- `lib/liveview_grid_web/components/grid_component/event_handlers.ex` — 편집 이벤트 핸들러
- `assets/css/grid/editor.css` — 신규 파일, 모달/textarea 스타일
- `assets/js/hooks/keyboard-nav.js` — F2, Ctrl+Enter, Esc 단축키

## 의존성
없음

## 테스트 계획
- 셀 더블 클릭 또는 F2로 편집 모달 오픈 확인
- textarea 내 텍스트 입력 및 수정 동작
- Ctrl+Enter로 저장 후 셀 값 업데이트 확인
- Esc로 취소 후 변경사항 폐기 확인
- 모달 백드롭 클릭으로 닫기 동작
- 긴 텍스트 (1000자+) 편집 성능 확인
- 모달 크기 조정 및 반응형 레이아웃 테스트
