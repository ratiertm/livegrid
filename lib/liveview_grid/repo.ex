defmodule LiveviewGrid.Repo do
  @moduledoc """
  Ecto Repo for the LiveView Grid demo application.
  Uses SQLite for lightweight, zero-configuration database.
  """
  use Ecto.Repo,
    otp_app: :liveview_grid,
    adapter: Ecto.Adapters.SQLite3
end
