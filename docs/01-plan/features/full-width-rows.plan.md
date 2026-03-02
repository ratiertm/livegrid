# Full-Width Rows Plan
> ID: FA-036
> Priority: P2
> Phase: 5 (v1.0+)
> Date: 2026-03-02

## 목표
`_row_type: :full_width` 속성을 가진 행이 모든 컬럼 너비를 사용합니다. 공지사항, 배너, 구분선 등의 UI 요소에 활용됩니다.

## 구현 범위
- 행 데이터에 선택적 `_row_type` 필드 지원 (`:normal` | `:full_width`)
- grid_component.ex에서 `:full_width` 행에 대한 조건부 렌더링 분기
- 전체 너비 행의 CSS 스타일 (colspan, grid 병합 등)
- 전체 너비 행 컨텐츠 커스터마이징 (예: 템플릿/슬롯)
- GridConfig에 full_width_row_height 옵션 추가

## 변경 파일
- `lib/liveview_grid_web/components/grid_component.ex` — 전체 너비 행 렌더링 로직
- `lib/liveview_grid_web/components/grid_component/render_helpers.ex` — full_width 행 헬퍼 함수
- `assets/css/grid/body.css` — 전체 너비 행 CSS 스타일

## 의존성
없음

## 테스트 계획
- `:full_width` 행이 모든 컬럼 너비를 차지하는지 확인
- 일반 행과 전체 너비 행 혼합 렌더링 테스트
- 전체 너비 행의 높이 옵션 동작 확인
- 스크롤 시 전체 너비 행 위치 유지 확인
- 다양한 컬럼 개수에서 전체 너비 적용 테스트
