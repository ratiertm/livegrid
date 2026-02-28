# Tree Grid

계층적 부모-자식 관계의 데이터를 트리 구조로 표시합니다.

## Overview

Tree Grid는 `parent_id` 필드를 기반으로 행 간의 부모-자식 관계를 표현합니다. 들여쓰기와 접기/펼치기 컨트롤을 제공합니다.

## Enabling Tree Mode

```elixir
grid = Grid.set_tree_mode(grid, true, :parent_id)
```

### Data Structure

```elixir
data = [
  %{id: 1, name: "회사", parent_id: nil},
  %{id: 2, name: "개발팀", parent_id: 1},
  %{id: 3, name: "프론트엔드", parent_id: 2},
  %{id: 4, name: "백엔드", parent_id: 2},
  %{id: 5, name: "영업팀", parent_id: 1}
]
```

### Visual Structure

```
▼ 회사
  ▼ 개발팀
      프론트엔드
      백엔드
  ▶ 영업팀
```

## Expand / Collapse

```elixir
# 노드 접기/펼치기
grid = Grid.toggle_tree_node(grid, node_id)
```

- ▶ 클릭: 자식 노드 펼침
- ▼ 클릭: 자식 노드 접기
- 재귀적으로 모든 하위 노드에 영향

## Related

- [Grouping](./grouping.md) — 필드 기반 그룹핑
- [Pivot Table](./pivot-table.md) — 피벗 변환
