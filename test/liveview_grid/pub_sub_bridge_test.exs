defmodule LiveViewGrid.PubSubBridgeTest do
  use ExUnit.Case, async: true

  alias LiveViewGrid.PubSubBridge

  setup do
    grid_id = "test_grid_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
    PubSubBridge.subscribe(grid_id)
    %{grid_id: grid_id}
  end

  describe "broadcast_cell_update/5" do
    test "broadcasts cell update event", %{grid_id: grid_id} do
      PubSubBridge.broadcast_cell_update(grid_id, 1, :name, "Alice", self())

      assert_receive {:grid_event, %{
        type: :cell_updated,
        row_id: 1,
        field: :name,
        value: "Alice",
        sender: _pid,
        timestamp: _ts
      }}
    end
  end

  describe "broadcast_row_added/3" do
    test "broadcasts row added event", %{grid_id: grid_id} do
      row = %{id: 99, name: "New User"}
      PubSubBridge.broadcast_row_added(grid_id, row, self())

      assert_receive {:grid_event, %{
        type: :row_added,
        row: ^row,
        sender: _pid
      }}
    end
  end

  describe "broadcast_rows_deleted/3" do
    test "broadcasts rows deleted event", %{grid_id: grid_id} do
      PubSubBridge.broadcast_rows_deleted(grid_id, [1, 2, 3], self())

      assert_receive {:grid_event, %{
        type: :rows_deleted,
        row_ids: [1, 2, 3],
        sender: _pid
      }}
    end
  end

  describe "broadcast_rows_saved/2" do
    test "broadcasts rows saved event", %{grid_id: grid_id} do
      PubSubBridge.broadcast_rows_saved(grid_id, self())

      assert_receive {:grid_event, %{
        type: :rows_saved,
        sender: _pid
      }}
    end
  end

  describe "broadcast_user_editing/5" do
    test "broadcasts user editing location", %{grid_id: grid_id} do
      PubSubBridge.broadcast_user_editing(grid_id, 1, :name, "Alice", self())

      assert_receive {:grid_event, %{
        type: :user_editing,
        row_id: 1,
        field: :name,
        user_name: "Alice",
        sender: _pid
      }}
    end
  end

  describe "unsubscribe/1" do
    test "stops receiving events after unsubscribe", %{grid_id: grid_id} do
      PubSubBridge.unsubscribe(grid_id)
      PubSubBridge.broadcast_cell_update(grid_id, 1, :name, "Bob", self())
      refute_receive {:grid_event, _}, 100
    end
  end
end
