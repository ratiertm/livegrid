defmodule LiveviewGrid.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys) do
      add :name, :string, null: false
      add :key, :string, null: false
      add :prefix, :string, null: false
      add :status, :string, default: "active"
      add :permissions, :string, default: "read"
      add :last_used_at, :utc_datetime
      add :expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:api_keys, [:key])
    create index(:api_keys, [:status])
  end
end
