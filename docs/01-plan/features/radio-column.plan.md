# Radio Column Plan
> ID: F-906
> Priority: P2
> Phase: 5 (v1.0+)
> Date: 2026-03-02

## 목표
그룹 내 단일 선택(radio button) 컬럼을 제공합니다. 여러 선택지 중 하나만 선택할 수 있는 기능입니다.

## 구현 범위
- Column config에 `filter_type: :radio` 또는 `renderer: :radio` 옵션 추가
- renderers.ex에 radio 렌더러 구현
- radio 옵션 목록 정의 (Column config의 `options` 필드)
- 라디오 버튼 UI 렌더링 (HEEx)
- 라디오 버튼 선택 이벤트 핸들러
- 선택된 값 저장 및 그리드 상태 업데이트
- GridConfig에 radio 스타일 옵션 추가 (인라인/블록 등)

## 변경 파일
- `lib/liveview_grid/renderers.ex` — radio 렌더러 추가
- `lib/liveview_grid_web/components/grid_component/render_helpers.ex` — radio 렌더링 헬퍼
- `lib/liveview_grid_web/components/grid_component/event_handlers.ex` — radio 선택 이벤트 핸들러
- `assets/css/grid/renderers.css` — radio 버튼 스타일

## 의존성
없음

## 테스트 계획
- radio 렌더러가 정상적으로 렌더링되는지 확인
- 라디오 버튼 클릭 시 값 변경 확인
- 다중 행에서 독립적으로 라디오 선택 확인
- options 설정에 따른 라디오 버튼 목록 표시 확인
- 선택된 값 그리드 상태 반영 확인
- 다양한 옵션 개수 (2개, 5개, 10개) 테스트
- 인라인/블록 레이아웃 스타일 테스트
