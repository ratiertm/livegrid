defmodule LiveviewGrid.Repo.Migrations.CreateDemoUsers do
  use Ecto.Migration

  def change do
    create table(:demo_users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :department, :string
      add :age, :integer
      add :salary, :integer
      add :status, :string
      add :join_date, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:demo_users, [:email])
    create index(:demo_users, [:department])
    create index(:demo_users, [:name])
  end
end
