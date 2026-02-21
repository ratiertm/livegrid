# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :liveview_grid,
  generators: [timestamp_type: :utc_datetime],
  ecto_repos: [LiveviewGrid.Repo]

# SQLite database for demo
config :liveview_grid, LiveviewGrid.Repo,
  database: Path.expand("../liveview_grid_#{config_env()}.db", __DIR__),
  pool_size: 5

# Configures the endpoint
config :liveview_grid, LiveviewGridWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: LiveviewGridWeb.ErrorHTML, json: LiveviewGridWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LiveviewGrid.PubSub,
  live_view: [signing_salt: "dfAyUC1v"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  liveview_grid: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  liveview_grid: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
