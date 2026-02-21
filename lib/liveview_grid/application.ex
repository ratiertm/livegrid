defmodule LiveviewGrid.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LiveviewGridWeb.Telemetry,
      LiveviewGrid.Repo,
      {DNSCluster, query: Application.get_env(:liveview_grid, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LiveviewGrid.PubSub},
      # Start a worker by calling: LiveviewGrid.Worker.start_link(arg)
      # {LiveviewGrid.Worker, arg},
      # Start to serve requests, typically the last entry
      LiveviewGridWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveviewGrid.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveviewGridWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
