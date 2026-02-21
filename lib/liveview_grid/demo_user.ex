defmodule LiveviewGrid.DemoUser do
  @moduledoc """
  Ecto schema for demo users table.
  Used by DBMS demo to showcase Ecto DataSource adapter.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "demo_users" do
    field :name, :string
    field :email, :string
    field :department, :string
    field :age, :integer
    field :salary, :integer
    field :status, :string
    field :join_date, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :department, :age, :salary, :status, :join_date])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> validate_number(:age, greater_than: 0, less_than: 200)
    |> validate_number(:salary, greater_than_or_equal_to: 0)
    |> unique_constraint(:email)
  end
end
