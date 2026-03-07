# F-961 자식 노드 일괄 펼침 (Tree Expand All)

> **Feature ID**: F-961
> **Version**: v0.15.0
> **Priority**: P1
> **Source**: 넥사크로 참조
> **Created**: 2026-03-06

---

## 1. 개요

트리 그리드에서 전체 노드 또는 특정 레벨까지 일괄 펼침/접기 기능을 제공한다.
현재는 개별 노드 클릭으로만 expand/collapse가 가능하며, 대규모 트리에서 비효율적이다.

## 2. 요구사항

### FR (Functional Requirements)

| ID | 요구사항 | 우선순위 |
|----|----------|----------|
| FR-01 | `expand_all/1` - 모든 노드 펼침 | P0 |
| FR-02 | `collapse_all/1` - 모든 노드 접기 | P0 |
| FR-03 | `expand_to_level/2` - 특정 레벨까지 펼침 (예: depth 2까지) | P1 |
| FR-04 | `expand_node_recursive/2` - 특정 노드와 모든 자손 펼침 | P1 |
| FR-05 | 툴바 UI 버튼 (전체 펼침/접기 아이콘) | P1 |
| FR-06 | 이벤트 핸들러 연동 (grid_expand_all, grid_collapse_all, grid_expand_to_level) | P0 |

### NFR (Non-Functional Requirements)

| ID | 요구사항 |
|----|----------|
| NFR-01 | 기존 toggle_tree_node 동작 유지 (하위 호환성) |
| NFR-02 | 1000+ 노드에서도 즉시 반응 |
| NFR-03 | 기존 테스트 전부 통과 |

## 3. 현재 상태 분석

### 있는 것
- `Tree.build_tree/3` - 트리 구조 변환
- `Tree.toggle_node/2` - 개별 노드 토글
- `Tree.descendant_ids/3` - 자손 ID 수집
- `Grid.toggle_tree_node/2` - Grid 레벨 토글
- `grid_toggle_tree_node` 이벤트 핸들러
- Advanced Demo 트리 데모 (조직도 15행)

### 없는 것
- expand_all / collapse_all 함수
- expand_to_level 함수
- 일괄 펼침/접기 UI 버튼
- 해당 이벤트 핸들러

## 4. 구현 계획

### Step 1: Tree 모듈 함수 추가
- `Tree.expand_all/2` - 모든 노드 ID를 expanded map에 true로 설정
- `Tree.collapse_all/0` - expanded map을 빈 맵으로 초기화
- `Tree.expand_to_level/3` - 특정 depth까지만 expanded true
- `Tree.expand_node_recursive/3` - 특정 노드 + 자손 모두 펼침

### Step 2: Grid 모듈 래퍼 함수 추가
- `Grid.expand_all_tree_nodes/1`
- `Grid.collapse_all_tree_nodes/1`
- `Grid.expand_tree_to_level/2`

### Step 3: EventHandlers 이벤트 추가
- `grid_expand_all` 이벤트
- `grid_collapse_all` 이벤트
- `grid_expand_to_level` 이벤트 (params: level)

### Step 4: 툴바 UI 버튼 추가
- 트리 모드일 때만 표시
- 펼침 아이콘 (⊞) / 접기 아이콘 (⊟)
- 레벨 선택 드롭다운 (옵션)

### Step 5: 테스트 작성
- Tree 모듈 단위 테스트 (expand_all, collapse_all, expand_to_level)
- 통합 테스트 (Chrome MCP 시각적 검증)

## 5. 영향 범위

| 파일 | 변경 내용 |
|------|-----------|
| `lib/liveview_grid/operations/tree.ex` | expand_all, collapse_all, expand_to_level, expand_node_recursive 함수 추가 |
| `lib/liveview_grid/grid.ex` | expand_all_tree_nodes, collapse_all_tree_nodes, expand_tree_to_level 래퍼 |
| `lib/liveview_grid_web/components/grid_component/event_handlers.ex` | 3개 이벤트 핸들러 |
| `lib/liveview_grid_web/components/grid_component.ex` | 툴바 UI 버튼 |
| `test/liveview_grid/operations/tree_test.exs` | 단위 테스트 |

## 6. 검증 계획

- [ ] `mix compile --warnings-as-errors` 통과
- [ ] `mix test` 전체 통과
- [ ] Chrome MCP로 Advanced Demo 트리에서:
  - 전체 펼침 버튼 클릭 → 15행 모두 표시
  - 전체 접기 버튼 클릭 → 루트(CEO)만 표시
  - 레벨 2까지 펼침 → CEO + 본부까지만 표시
