# Side-Bar Plan
> ID: FA-030
> Priority: P2
> Phase: 5 (v1.0+)
> Date: 2026-03-02

## 목표
토글 사이드바를 통해 컬럼 표시/숨기기 및 필터 관리 패널을 제공합니다. 사용자가 그리드 인터페이스를 커스터마이징할 수 있는 기능입니다.

## 구현 범위
- Grid state에 `sidebar_open` (boolean) 및 `sidebar_tab` (atom: `:columns` | `:filters`) 추가
- grid_component.ex에 사이드바 HEEx 템플릿 추가 (컬럼 목록, 필터 관리)
- 사이드바 토글 버튼 UI 구현
- 사이드바 CSS 스타일 (assets/css/grid/sidebar.css) 작성
- 컬럼 가시성 토글 이벤트 핸들러 추가
- 필터 패널 UI 렌더링

## 변경 파일
- `lib/liveview_grid/grid.ex` — grid state 필드 추가
- `lib/liveview_grid_web/components/grid_component.ex` — 사이드바 HEEx, 토글 로직
- `assets/css/grid/sidebar.css` — 신규 파일, 사이드바 스타일
- `assets/css/liveview_grid.css` — 통합 import

## 의존성
없음

## 테스트 계획
- 사이드바 열기/닫기 상태 토글 테스트
- 컬럼 가시성 변경 시 그리드 재렌더링 확인
- 탭 전환 (`:columns` → `:filters`) 동작 확인
- CSS 레이아웃 반응형 테스트 (모바일/태블릿/데스크톱)
