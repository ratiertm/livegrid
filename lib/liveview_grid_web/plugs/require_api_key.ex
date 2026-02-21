defmodule LiveviewGridWeb.Plugs.RequireApiKey do
  @moduledoc """
  Plug that validates API key authentication on API endpoints.

  Extracts API key from `Authorization: Bearer lvg_xxx` header,
  validates it against the database, and checks permissions/expiration.

  ## Usage in Router

      pipeline :authenticated_api do
        plug :accepts, ["json"]
        plug LiveviewGridWeb.Plugs.RequireApiKey
      end

  ## Permission Levels

  - `read` - GET requests only
  - `read_write` - GET, POST, PUT, PATCH, DELETE
  - `admin` - all operations + management
  """

  import Plug.Conn
  alias LiveviewGrid.ApiKeys

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case extract_api_key(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{
          error: "API key required",
          message: "Provide API key via Authorization: Bearer lvg_xxx header"
        })
        |> halt()

      key_string ->
        case ApiKeys.validate_key(key_string) do
          {:ok, api_key} ->
            if has_permission?(api_key, conn.method) do
              ApiKeys.touch_last_used(api_key.id)
              assign(conn, :api_key, api_key)
            else
              conn
              |> put_status(:forbidden)
              |> Phoenix.Controller.json(%{
                error: "Insufficient permissions",
                message: "Your API key has '#{api_key.permissions}' permission. This operation requires higher access."
              })
              |> halt()
            end

          {:error, :not_found} ->
            conn
            |> put_status(:unauthorized)
            |> Phoenix.Controller.json(%{error: "Invalid API key"})
            |> halt()

          {:error, :revoked} ->
            conn
            |> put_status(:forbidden)
            |> Phoenix.Controller.json(%{error: "API key has been revoked"})
            |> halt()

          {:error, :expired} ->
            conn
            |> put_status(:forbidden)
            |> Phoenix.Controller.json(%{error: "API key has expired"})
            |> halt()
        end
    end
  end

  defp extract_api_key(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> key] -> String.trim(key)
      _ -> nil
    end
  end

  defp has_permission?(%{permissions: "admin"}, _method), do: true
  defp has_permission?(%{permissions: "read_write"}, _method), do: true
  defp has_permission?(%{permissions: "read"}, method) when method in ["GET", "HEAD"], do: true
  defp has_permission?(_, _), do: false
end
