defmodule LiveviewGridWeb.GridLive do
  use LiveviewGridWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # 샘플 데이터 (나중에 외부 소스에서 가져오도록)
    data = [
      %{id: 1, name: "Apple Inc.", ticker: "AAPL", price: 150.25, change: 2.3},
      %{id: 2, name: "Microsoft", ticker: "MSFT", price: 380.50, change: -1.2},
      %{id: 3, name: "NVIDIA", ticker: "NVDA", price: 875.00, change: 15.7},
      %{id: 4, name: "Tesla", ticker: "TSLA", price: 195.30, change: -3.5},
      %{id: 5, name: "Amazon", ticker: "AMZN", price: 155.80, change: 0.8},
    ]

    columns = [
      %{key: :id, label: "ID", width: "80px", sortable: true},
      %{key: :ticker, label: "티커", width: "100px", sortable: true},
      %{key: :name, label: "회사명", width: "200px", sortable: true},
      %{key: :price, label: "가격", width: "120px", sortable: true, align: "right"},
      %{key: :change, label: "변동률(%)", width: "120px", sortable: true, align: "right"},
    ]

    {:ok,
     socket
     |> assign(:data, data)
     |> assign(:columns, columns)
     |> assign(:sort_by, nil)
     |> assign(:sort_direction, :asc)
     |> assign(:selected_rows, MapSet.new())}
  end

  @impl true
  def handle_event("sort", %{"column" => column_key}, socket) do
    column_key = String.to_existing_atom(column_key)
    
    # 토글 정렬 방향
    sort_direction =
      if socket.assigns.sort_by == column_key do
        if socket.assigns.sort_direction == :asc, do: :desc, else: :asc
      else
        :asc
      end

    sorted_data = sort_data(socket.assigns.data, column_key, sort_direction)

    {:noreply,
     socket
     |> assign(:data, sorted_data)
     |> assign(:sort_by, column_key)
     |> assign(:sort_direction, sort_direction)}
  end

  @impl true
  def handle_event("toggle_row", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected = socket.assigns.selected_rows

    selected =
      if MapSet.member?(selected, id) do
        MapSet.delete(selected, id)
      else
        MapSet.put(selected, id)
      end

    {:noreply, assign(socket, :selected_rows, selected)}
  end

  defp sort_data(data, column_key, direction) do
    sorted =
      Enum.sort_by(data, fn row -> Map.get(row, column_key) end, fn a, b ->
        if direction == :asc, do: a <= b, else: a >= b
      end)

    sorted
  end

  defp format_value(value) when is_float(value) do
    :erlang.float_to_binary(value, decimals: 2)
  end

  defp format_value(value), do: to_string(value)

  defp change_color(change) when change > 0, do: "text-green-600"
  defp change_color(change) when change < 0, do: "text-red-600"
  defp change_color(_), do: "text-gray-600"
end
