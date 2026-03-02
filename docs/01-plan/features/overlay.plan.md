# Overlay System (오버레이)

> **Version**: v0.11
> **Priority**: P1
> **Status**: Plan
> **Feature ID**: FA-005

---

## 목표

Grid Body 위에 Loading/NoData/Error 등의 오버레이를 표시합니다.
AG Grid의 Loading Overlay, No Rows Overlay에 해당합니다.

## 요구사항

### FR-01: 오버레이 상태 관리
- state에 `overlay: nil | :loading | :no_data | :error` 추가
- `overlay_message: nil | string` 커스텀 메시지

### FR-02: API
- `set_overlay/2,3` — 오버레이 설정
- `clear_overlay/1` — 오버레이 해제

### FR-03: 자동 오버레이
- 데이터가 비어있으면 자동으로 :no_data 오버레이 표시

### FR-04: UI
- Body 영역 위에 반투명 배경 + 중앙 메시지
- Loading: 스피너 + "데이터를 불러오는 중..."
- NoData: "표시할 데이터가 없습니다"
- Error: 빨간 아이콘 + 에러 메시지

## 구현 범위
1. grid.ex: state + API 함수
2. grid_component.ex: 오버레이 HEEx 렌더링
3. CSS: 오버레이 스타일
4. 테스트
5. demo_live.ex: 빈 데이터 시 자동 표시

## 난이도: ⭐⭐
