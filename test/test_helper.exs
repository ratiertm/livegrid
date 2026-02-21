ExUnit.start()

# Setup Ecto sandbox for DB tests
Ecto.Adapters.SQL.Sandbox.mode(LiveviewGrid.Repo, :manual)
