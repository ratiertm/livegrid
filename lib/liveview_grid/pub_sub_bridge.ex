defmodule LiveViewGrid.PubSubBridge do
  @moduledoc """
  Grid 실시간 협업을 위한 PubSub 브릿지.

  같은 Grid를 보는 여러 사용자 간 변경사항을 브로드캐스트합니다.
  각 Grid ID별로 독립 토픽을 사용합니다.

  ## 사용법

      # 구독 (LiveView mount 시)
      PubSubBridge.subscribe(grid_id)

      # 브로드캐스트 (이벤트 발생 시)
      PubSubBridge.broadcast_cell_update(grid_id, row_id, field, value, sender_pid)

      # 수신 (handle_info)
      def handle_info({:grid_event, %{type: :cell_updated, ...}}, socket)
  """

  @pubsub LiveviewGrid.PubSub

  @doc "Grid 토픽을 구독합니다."
  @spec subscribe(grid_id :: String.t()) :: :ok | {:error, term()}
  def subscribe(grid_id) do
    Phoenix.PubSub.subscribe(@pubsub, topic(grid_id))
  end

  @doc "Grid 토픽 구독을 해제합니다."
  @spec unsubscribe(grid_id :: String.t()) :: :ok | {:error, term()}
  def unsubscribe(grid_id) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(grid_id))
  end

  @doc "셀 업데이트를 브로드캐스트합니다."
  @spec broadcast_cell_update(String.t(), any(), atom(), any(), pid()) :: :ok | {:error, term()}
  def broadcast_cell_update(grid_id, row_id, field, value, sender_pid) do
    broadcast(grid_id, %{
      type: :cell_updated,
      row_id: row_id,
      field: field,
      value: value,
      sender: sender_pid,
      timestamp: System.monotonic_time(:millisecond)
    })
  end

  @doc "행 추가를 브로드캐스트합니다."
  @spec broadcast_row_added(String.t(), map(), pid()) :: :ok | {:error, term()}
  def broadcast_row_added(grid_id, row, sender_pid) do
    broadcast(grid_id, %{
      type: :row_added,
      row: row,
      sender: sender_pid,
      timestamp: System.monotonic_time(:millisecond)
    })
  end

  @doc "행 삭제를 브로드캐스트합니다."
  @spec broadcast_rows_deleted(String.t(), list(), pid()) :: :ok | {:error, term()}
  def broadcast_rows_deleted(grid_id, row_ids, sender_pid) do
    broadcast(grid_id, %{
      type: :rows_deleted,
      row_ids: row_ids,
      sender: sender_pid,
      timestamp: System.monotonic_time(:millisecond)
    })
  end

  @doc "일괄 저장 완료를 브로드캐스트합니다."
  @spec broadcast_rows_saved(String.t(), pid()) :: :ok | {:error, term()}
  def broadcast_rows_saved(grid_id, sender_pid) do
    broadcast(grid_id, %{
      type: :rows_saved,
      sender: sender_pid,
      timestamp: System.monotonic_time(:millisecond)
    })
  end

  @doc "사용자 편집 위치를 브로드캐스트합니다."
  @spec broadcast_user_editing(String.t(), any(), atom() | nil, String.t(), pid()) :: :ok | {:error, term()}
  def broadcast_user_editing(grid_id, row_id, field, user_name, sender_pid) do
    broadcast(grid_id, %{
      type: :user_editing,
      row_id: row_id,
      field: field,
      user_name: user_name,
      sender: sender_pid,
      timestamp: System.monotonic_time(:millisecond)
    })
  end

  defp topic(grid_id), do: "grid:#{grid_id}"

  defp broadcast(grid_id, payload) do
    Phoenix.PubSub.broadcast(@pubsub, topic(grid_id), {:grid_event, payload})
  end
end
