# Grid State Save/Restore

> **Version**: v0.13
> **Priority**: P0
> **Status**: Plan
> **Feature ID**: FA-002

---

## 목표

그리드 전체 상태(정렬, 필터, 페이지네이션, 컬럼 순서/너비/숨김 등)를 저장하고 복원.
localStorage 또는 서버 측 저장 지원. AG Grid의 Grid State에 해당.

## 요구사항

### FR-01: 상태 직렬화
- `Grid.get_state/1` — 현재 상태를 직렬화 가능한 맵으로 반환
- 포함: sort, filters, pagination, column_order, hidden_columns, global_search

### FR-02: 상태 복원
- `Grid.restore_state/2` — 직렬화된 맵으로 상태 복원
- 부분 복원 지원 (sort만, filters만 등)

### FR-03: 클라이언트 저장
- JS Hook으로 localStorage에 저장/복원
- grid ID 기반 키 사용

## 구현 범위
1. grid.ex: get_state/1, restore_state/2 API
2. app.js: GridStatePersist Hook (localStorage)
3. grid_component.ex: save/restore 이벤트 핸들러
4. 테스트

## 난이도: ⭐⭐
