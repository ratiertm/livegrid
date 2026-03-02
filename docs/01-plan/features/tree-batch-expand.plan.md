# F-961 자식 노드 일괄 펼침 - Plan

> **Feature**: F-961 Tree Batch Expand
> **Phase**: 4 (v0.14)
> **Priority**: P1
> **Difficulty**: ⭐⭐

## 요구사항

### FR-01: 전체 펼침/접기
- `Grid.expand_all_nodes/1` — 모든 트리 노드 펼침
- `Grid.collapse_all_nodes/1` — 모든 트리 노드 접기

### FR-02: 레벨별 펼침
- `Grid.expand_to_level/2` — 특정 depth까지만 펼침
- depth 0 = root만 표시, depth 1 = root + 1단계 자식

### FR-03: UI
- 트리 모드 시 헤더에 "전체 펼침/접기" 버튼
- 이벤트: `grid_expand_all`, `grid_collapse_all`, `grid_expand_to_level`

## 구현 범위
- grid.ex: `expand_all_nodes/1`, `collapse_all_nodes/1`, `expand_to_level/2`
- tree.ex: `all_node_ids/2` 헬퍼 (모든 노드 id 수집)
- event_handlers.ex: 이벤트 핸들러 3개
- grid_component.ex: 트리 컨트롤 버튼

## 테스트
- expand_all / collapse_all 테스트
- expand_to_level 레벨별 테스트
