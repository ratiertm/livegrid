# Column State Save/Restore

> **Version**: v0.13
> **Priority**: P1
> **Status**: Plan
> **Feature ID**: FA-016

---

## 목표

컬럼별 상태(너비, 순서, 표시 여부, 정렬, 고정)를 개별 저장/복원.
AG Grid의 Column State API에 해당.

## 요구사항

### FR-01: 컬럼 상태 추출
- `Grid.get_column_state/1` — 컬럼별 상태 맵 리스트 반환
- 포함: field, width, visible, sort, order_index

### FR-02: 컬럼 상태 적용
- `Grid.apply_column_state/2` — 컬럼 상태 리스트로 복원
- 누락 컬럼은 기본값 유지

## 구현 범위
1. grid.ex: get_column_state/1, apply_column_state/2 API
2. 테스트

## 난이도: ⭐⭐
