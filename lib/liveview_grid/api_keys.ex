defmodule LiveviewGrid.ApiKeys do
  @moduledoc """
  Context for managing API keys.
  """
  alias LiveviewGrid.{Repo, ApiKey}
  import Ecto.Query

  def list_api_keys do
    from(k in ApiKey, order_by: [desc: k.inserted_at])
    |> Repo.all()
  end

  def create_api_key(attrs) do
    raw = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    full_key = "lvg_" <> raw
    prefix = "lvg_" <> String.slice(raw, 0, 8) <> "..."

    full_attrs =
      attrs
      |> Map.put(:key, full_key)
      |> Map.put(:prefix, prefix)

    %ApiKey{}
    |> ApiKey.changeset(full_attrs)
    |> Repo.insert()
  end

  def revoke_api_key(id) do
    Repo.get!(ApiKey, id)
    |> ApiKey.changeset(%{status: "revoked"})
    |> Repo.update()
  end

  def delete_api_key(id) do
    Repo.get!(ApiKey, id)
    |> Repo.delete()
  end
end
