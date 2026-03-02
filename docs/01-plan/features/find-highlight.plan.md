# Find & Highlight Plan
> ID: FA-044
> Priority: P2
> Phase: 5 (v1.0+)
> Date: 2026-03-02

## 목표
Ctrl+F 검색 UI를 제공하고 매칭된 셀을 하이라이트합니다. 대규모 데이터셋에서 빠른 검색 및 내비게이션을 지원합니다.

## 구현 범위
- Grid state에 `find_text` (string) 및 `find_matches` (list of {row, col, value}) 추가
- 검색 UI (입력박스, 네비게이션 버튼: 이전/다음) 구현
- Grid.find_cells/2 함수로 매칭 셀 검색 (정규식 또는 문자열 매칭)
- 매칭된 셀 하이라이트 CSS class 적용
- 키보드 단축키 (Ctrl+F) 지원
- 검색 결과 네비게이션 (이전/다음 매칭)

## 변경 파일
- `lib/liveview_grid/grid.ex` — find_cells/2, find_text/find_matches state 추가
- `lib/liveview_grid_web/components/grid_component.ex` — 검색 UI 렌더링
- `lib/liveview_grid_web/components/grid_component/event_handlers.ex` — 검색 핸들러
- `lib/liveview_grid_web/components/grid_component/render_helpers.ex` — 하이라이트 마크업
- `assets/js/hooks/keyboard-nav.js` — Ctrl+F 단축키 처리
- `assets/css/grid/body.css` — 검색 결과 하이라이트 스타일

## 의존성
없음

## 테스트 계획
- 검색 텍스트 입력 후 매칭 셀 발견 확인
- 정규식 매칭 테스트 (와일드카드, 특수문자)
- 문자열 매칭 테스트 (대소문자 구분 옵션)
- 이전/다음 네비게이션 동작 확인
- Ctrl+F 단축키로 검색창 포커스 확인
- 검색 결과 없을 때 UI 피드백
- 스크롤 시 현재 매칭 셀 뷰포트 이동 확인
