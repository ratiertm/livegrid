import Config

# Test database (SQLite sandbox)
config :liveview_grid, LiveviewGrid.Repo,
  database: Path.expand("../liveview_grid_test.db", __DIR__),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :liveview_grid, LiveviewGridWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "yXj5ZvbRboWmTbVeXwZffkFowYgrU0cJyOrCUKa91ymrKl1TBlUfDCHZUAMfNRKY",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true
