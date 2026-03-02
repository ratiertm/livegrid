# Empty Area Fill Plan
> ID: F-909
> Priority: P2
> Phase: 5 (v1.0+)
> Date: 2026-03-02

## 목표
그리드의 데이터 행 아래 빈 영역을 빈 행으로 채웁니다. 일관된 시각적 표현과 드래그 앤 드롭 영역 제공을 위한 기능입니다.

## 구현 범위
- GridConfig에 `fill_empty_area: true | false` (기본값: false) 옵션 추가
- grid_component.ex에서 빈 행 렌더링 로직 구현
- 뷰포트 높이 계산 및 필요한 빈 행 개수 결정
- 빈 행의 높이를 일반 행과 동일하게 설정
- 빈 행 CSS 스타일 (background, border 등)
- 스크롤 시 빈 행 동적 업데이트 (필요시)

## 변경 파일
- `lib/liveview_grid/grid.ex` — fill_empty_area 옵션 추가
- `lib/liveview_grid_web/components/grid_component.ex` — 빈 행 렌더링 로직
- `lib/liveview_grid_web/components/grid_component/render_helpers.ex` — 빈 행 렌더링 헬퍼
- `assets/css/grid/body.css` — 빈 행 CSS 스타일 (`.empty-row`)

## 의존성
없음

## 테스트 계획
- fill_empty_area: true 옵션 활성화 시 빈 행 렌더링 확인
- fill_empty_area: false 옵션 비활성화 시 빈 행 미렌더링 확인
- 데이터 행 개수에 따른 빈 행 개수 계산 정확성
- 뷰포트 크기 변경 시 빈 행 개수 재계산 확인
- 스크롤 시 빈 행 위치 유지 확인
- 데이터 추가/제거 시 빈 행 동적 업데이트 확인
- 다양한 행 높이 설정에서의 빈 행 렌더링 테스트
