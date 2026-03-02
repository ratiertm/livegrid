# Column Hover Plan
> ID: FA-037
> Priority: P2
> Phase: 5 (v1.0+)
> Date: 2026-03-02

## 목표
마우스 호버 시 해당 컬럼 전체를 하이라이트합니다. 사용자가 열을 시각적으로 추적하기 쉽도록 합니다.

## 구현 범위
- JS Hook `ColumnHover` 생성 (app.js에 추가)
- 마우스 오버/아웃 이벤트 리스너 등록
- 컬럼 인덱스 추출 및 해당 컬럼의 모든 셀에 CSS class 토글
- 호버 하이라이트 CSS 스타일 (background-color, box-shadow 등)
- 스크롤 중 호버 상태 유지

## 변경 파일
- `assets/js/app.js` — ColumnHover Hook 추가
- `assets/js/hooks/keyboard-nav.js` — 호버 이벤트 통합 (필요시)
- `assets/css/grid/body.css` — 호버 하이라이트 스타일 (`.column-hover`)

## 의존성
없음

## 테스트 계획
- 마우스 호버 시 해당 컬럼 하이라이트 적용 확인
- 호버 해제 시 하이라이트 제거 확인
- 스크롤 중 호버 상태 유지 여부 확인
- 여러 컬럼 순차 호버 시 정상 동작 확인
- 모바일/터치 환경에서의 동작 (선택적)
