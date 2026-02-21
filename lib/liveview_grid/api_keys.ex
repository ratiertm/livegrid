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

  @doc "Validate an API key string. Returns {:ok, api_key} or {:error, reason}."
  def validate_key(key_string) do
    case Repo.get_by(ApiKey, key: key_string) do
      nil ->
        {:error, :not_found}

      %ApiKey{status: "revoked"} ->
        {:error, :revoked}

      %ApiKey{expires_at: expires_at} = api_key when not is_nil(expires_at) ->
        if DateTime.compare(expires_at, DateTime.utc_now()) == :lt do
          {:error, :expired}
        else
          {:ok, api_key}
        end

      %ApiKey{} = api_key ->
        {:ok, api_key}
    end
  end

  @doc "Update last_used_at timestamp for an API key."
  def touch_last_used(id) do
    case Repo.get(ApiKey, id) do
      nil -> :ok
      api_key ->
        api_key
        |> ApiKey.changeset(%{last_used_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> Repo.update()
    end
  end
end
