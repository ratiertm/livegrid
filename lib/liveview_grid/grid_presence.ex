defmodule LiveViewGrid.GridPresence do
  @moduledoc """
  Grid별 접속 사용자 추적 (Phoenix.Presence 기반).

  ## 사용법

      # LiveView mount 시
      GridPresence.track_user(socket, grid_id, user_id, %{name: "Alice"})

      # 접속자 수 조회
      GridPresence.list_users(grid_id)
  """

  use Phoenix.Presence,
    otp_app: :liveview_grid,
    pubsub_server: LiveviewGrid.PubSub

  @doc "사용자를 Grid에 등록합니다."
  @spec track_user(Phoenix.Socket.t() | pid(), String.t(), String.t(), map()) :: {:ok, binary()} | {:error, term()}
  def track_user(pid_or_socket, grid_id, user_id, meta \\ %{}) do
    track(pid_or_socket, topic(grid_id), user_id, Map.merge(%{
      online_at: System.system_time(:second),
      editing: nil
    }, meta))
  end

  @doc "사용자의 편집 위치를 업데이트합니다."
  @spec update_editing(pid(), String.t(), String.t(), map()) :: {:ok, binary()} | {:error, term()}
  def update_editing(pid, grid_id, user_id, editing_info) do
    update(pid, topic(grid_id), user_id, fn meta ->
      Map.put(meta, :editing, editing_info)
    end)
  end

  @doc "Grid에 접속 중인 사용자 목록을 반환합니다."
  @spec list_users(String.t()) :: list(map())
  def list_users(grid_id) do
    list(topic(grid_id))
    |> Enum.map(fn {user_id, %{metas: metas}} ->
      %{user_id: user_id, meta: List.first(metas)}
    end)
  end

  @doc "Grid에 접속 중인 사용자 수를 반환합니다."
  @spec user_count(String.t()) :: non_neg_integer()
  def user_count(grid_id) do
    list(topic(grid_id)) |> map_size()
  end

  defp topic(grid_id), do: "grid_presence:#{grid_id}"
end
