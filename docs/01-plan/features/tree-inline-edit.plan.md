# F-964 트리 내 편집 - Plan

> **Feature**: F-964 Tree Inline Edit
> **Phase**: 4 (v0.14)
> **Priority**: P1
> **Difficulty**: ⭐⭐

## 요구사항

### FR-01: 트리 모드 편집 지원
- 트리 모드에서도 기존 인라인 편집 동작
- editable: true 컬럼만 편집 가능
- 편집 시 _tree_depth, _tree_has_children 등 메타데이터 보존

### FR-02: 트리 편집 API
- 기존 `update_cell/4` 트리 모드 호환
- 트리 노드 편집 후 부모-자식 관계 유지
- row_statuses :updated 마킹

### FR-03: 트리 편집 이벤트
- 기존 `grid_save_cell` 이벤트 트리 모드 호환
- 편집 완료 후 트리 구조 재빌드 (필요 시)

## 구현 범위
- grid.ex: update_cell 트리 호환 확인, tree 메타데이터 strip/restore
- event_handlers.ex: save_cell 이벤트에서 tree 모드 처리
- grid_component.ex: 트리 행 편집 UI 렌더링

## 테스트
- 트리 모드 update_cell 테스트
- 편집 후 부모-자식 관계 유지 테스트
