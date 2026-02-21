defmodule LiveviewGridWeb.Hooks do
  @moduledoc """
  LiveView on_mount hooks for dashboard layout.
  """
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:assign_current_path, _params, _session, socket) do
    socket = assign(socket, :current_path, "/")

    if connected?(socket) do
      {:cont,
       attach_hook(socket, :current_path_hook, :handle_params, fn _params, uri, socket ->
         path = URI.parse(uri).path
         {:cont, assign(socket, :current_path, path)}
       end)}
    else
      {:cont, socket}
    end
  end
end
