defmodule LiveviewGrid.ApiKey do
  @moduledoc """
  Ecto schema for API keys.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "api_keys" do
    field :name, :string
    field :key, :string
    field :prefix, :string
    field :status, :string, default: "active"
    field :permissions, :string, default: "read"
    field :last_used_at, :utc_datetime
    field :expires_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:name, :key, :prefix, :status, :permissions, :last_used_at, :expires_at])
    |> validate_required([:name, :key, :prefix])
    |> validate_inclusion(:status, ["active", "revoked"])
    |> validate_inclusion(:permissions, ["read", "read_write", "admin"])
    |> unique_constraint(:key)
  end
end
