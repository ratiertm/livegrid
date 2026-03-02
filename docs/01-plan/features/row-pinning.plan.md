# Row Pinning (행 고정)

> **Version**: v0.11
> **Priority**: P0
> **Status**: Plan
> **Feature ID**: FA-001

---

## 목표

특정 행을 Grid 상단 또는 하단에 고정(Pin)하여 스크롤과 무관하게 항상 표시합니다.
AG Grid의 Row Pinning(pinned rows)에 해당합니다.

## 요구사항

### FR-01: 상태 관리
- state에 `pinned_top: []`, `pinned_bottom: []` (row_id 리스트)

### FR-02: API
- `pin_row/3` — 행을 상단/하단에 고정 (position: :top/:bottom)
- `unpin_row/2` — 행 고정 해제

### FR-03: 렌더링
- Body 상단에 pinned_top 행 렌더링 (sticky)
- Body 하단에 pinned_bottom 행 렌더링 (sticky)
- 고정된 행은 일반 Body에서 제외

### FR-04: 컨텍스트 메뉴 연동
- "행 상단 고정" / "행 하단 고정" / "고정 해제" 항목

### FR-05: 스타일
- 고정 행 배경색 구분 (약간 다른 배경)
- 고정 행과 일반 행 사이 구분선

## 구현 범위
1. grid.ex: state + API
2. grid_component.ex: Pinned 행 렌더링 섹션
3. event_handlers.ex: 컨텍스트 메뉴 핸들러
4. CSS: pinned row 스타일
5. 테스트
6. demo_live.ex: 초기 고정 행 예시

## 난이도: ⭐⭐⭐
