defmodule LiveViewGrid.TreeTest do
  use ExUnit.Case, async: true

  alias LiveViewGrid.Tree

  @tree_data [
    %{id: 1, parent_id: nil, name: "CEO"},
    %{id: 2, parent_id: 1, name: "개발본부"},
    %{id: 3, parent_id: 1, name: "경영본부"},
    %{id: 4, parent_id: 2, name: "백엔드팀"},
    %{id: 5, parent_id: 2, name: "프론트팀"},
    %{id: 6, parent_id: 3, name: "인사팀"},
    %{id: 7, parent_id: 4, name: "김개발"},
    %{id: 8, parent_id: 4, name: "이서버"}
  ]

  describe "expand_all/2" do
    test "모든 부모 노드를 펼침 상태로 반환" do
      result = Tree.expand_all(@tree_data)

      assert result[1] == true   # CEO (자식 있음)
      assert result[2] == true   # 개발본부 (자식 있음)
      assert result[3] == true   # 경영본부 (자식 있음)
      assert result[4] == true   # 백엔드팀 (자식 있음)
      assert Map.has_key?(result, 7) == false  # 김개발 (리프노드)
      assert Map.has_key?(result, 8) == false  # 이서버 (리프노드)
    end

    test "빈 데이터에서는 빈 맵 반환" do
      assert Tree.expand_all([]) == %{}
    end
  end

  describe "collapse_all/2" do
    test "모든 부모 노드를 접힌 상태로 반환" do
      result = Tree.collapse_all(@tree_data)

      assert result[1] == false
      assert result[2] == false
      assert result[3] == false
      assert result[4] == false
      assert Map.has_key?(result, 7) == false  # 리프노드 제외
    end

    test "collapse_all 후 build_tree하면 루트만 보임" do
      expanded = Tree.collapse_all(@tree_data)
      tree = Tree.build_tree(@tree_data, :parent_id, expanded)

      assert length(tree) == 1
      assert hd(tree).name == "CEO"
    end
  end

  describe "expand_to_level/3" do
    test "레벨 0: 루트만 펼침 (자식 표시하지만 손자는 안 보임)" do
      expanded = Tree.expand_to_level(@tree_data, 0)

      # 루트(depth 0)는 접힘 → 루트 자식은 안 보임
      assert expanded[1] == false
    end

    test "레벨 1: 루트 펼치고 1단계 자식까지 표시" do
      expanded = Tree.expand_to_level(@tree_data, 1)

      assert expanded[1] == true   # CEO 펼침
      assert expanded[2] == false  # 개발본부 접힘
      assert expanded[3] == false  # 경영본부 접힘
    end

    test "레벨 2: 2단계까지 표시" do
      expanded = Tree.expand_to_level(@tree_data, 2)

      assert expanded[1] == true   # CEO 펼침
      assert expanded[2] == true   # 개발본부 펼침
      assert expanded[3] == true   # 경영본부 펼침
      assert expanded[4] == false  # 백엔드팀 접힘
    end

    test "레벨 10: 모든 노드 펼침" do
      expanded = Tree.expand_to_level(@tree_data, 10)

      assert expanded[1] == true
      assert expanded[2] == true
      assert expanded[3] == true
      assert expanded[4] == true
    end
  end

  describe "expand_node_recursive/4" do
    test "특정 노드와 모든 자손을 펼침" do
      # 먼저 전부 접은 상태에서 시작
      expanded = Tree.collapse_all(@tree_data)
      result = Tree.expand_node_recursive(expanded, @tree_data, 2)

      assert result[2] == true   # 개발본부 펼침
      assert result[4] == true   # 백엔드팀 펼침 (2의 자손)
      assert result[1] == false  # CEO는 여전히 접힘
      assert result[3] == false  # 경영본부는 여전히 접힘
    end

    test "리프 노드에 대해 호출해도 에러 없음" do
      expanded = %{}
      result = Tree.expand_node_recursive(expanded, @tree_data, 7)

      assert result[7] == true
    end
  end

  describe "build_tree와 통합" do
    test "expand_all 후 모든 행이 표시됨" do
      expanded = Tree.expand_all(@tree_data)
      tree = Tree.build_tree(@tree_data, :parent_id, expanded)

      assert length(tree) == 8
    end

    test "expand_to_level(1) 후 루트 + 1단계 자식만 표시" do
      expanded = Tree.expand_to_level(@tree_data, 1)
      tree = Tree.build_tree(@tree_data, :parent_id, expanded)

      # CEO + 개발본부 + 경영본부 = 3
      assert length(tree) == 3
      names = Enum.map(tree, & &1.name)
      assert "CEO" in names
      assert "개발본부" in names
      assert "경영본부" in names
    end
  end
end
