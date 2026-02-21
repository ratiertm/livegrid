defmodule LiveViewGrid.Tree do
  @moduledoc """
  Tree Grid operation for LiveView Grid.

  Converts flat data with parent-child relationships into a hierarchical
  display list with expand/collapse support and depth-based indentation.

  Each row must have:
  - An `id` field
  - A parent reference field (e.g., `parent_id`) where `nil` = root node

  Output rows are annotated with:
  - `_tree_depth`: nesting level (0 = root)
  - `_tree_has_children`: boolean
  - `_tree_expanded`: boolean (from expanded state)
  """

  @doc """
  Build a flat display list from tree-structured data.

  ## Parameters
  - `data` - flat list of row maps (each with `id` and `parent_id`)
  - `parent_field` - atom key for parent reference (default: `:parent_id`)
  - `expanded` - map of `row_id => boolean` for expand/collapse state

  ## Returns
  Ordered flat list with tree metadata added to each row.
  """
  @spec build_tree(list(map()), atom(), map()) :: list(map())
  def build_tree(data, parent_field \\ :parent_id, expanded \\ %{}) do
    # Build parent -> children index
    children_map = Enum.group_by(data, &Map.get(&1, parent_field))

    # Start from root nodes (parent_id == nil)
    roots = Map.get(children_map, nil, [])
    build_subtree(roots, children_map, expanded, 0)
  end

  defp build_subtree(nodes, children_map, expanded, depth) do
    nodes
    |> Enum.sort_by(& &1.id)
    |> Enum.flat_map(fn node ->
      children = Map.get(children_map, node.id, [])
      has_children = children != []
      is_expanded = Map.get(expanded, node.id, true)

      annotated = node
        |> Map.put(:_tree_depth, depth)
        |> Map.put(:_tree_has_children, has_children)
        |> Map.put(:_tree_expanded, is_expanded)

      if has_children and is_expanded do
        [annotated | build_subtree(children, children_map, expanded, depth + 1)]
      else
        [annotated]
      end
    end)
  end

  @doc """
  Toggle a tree node's expanded state.
  """
  @spec toggle_node(map(), any()) :: map()
  def toggle_node(expanded, node_id) do
    current = Map.get(expanded, node_id, true)
    Map.put(expanded, node_id, !current)
  end

  @doc """
  Get all descendant IDs of a node (for operations like select-subtree).
  """
  @spec descendant_ids(list(map()), any(), atom()) :: list(any())
  def descendant_ids(data, node_id, parent_field \\ :parent_id) do
    children_map = Enum.group_by(data, &Map.get(&1, parent_field))
    collect_descendants(node_id, children_map)
  end

  defp collect_descendants(node_id, children_map) do
    children = Map.get(children_map, node_id, [])
    child_ids = Enum.map(children, & &1.id)
    child_ids ++ Enum.flat_map(child_ids, &collect_descendants(&1, children_map))
  end
end
