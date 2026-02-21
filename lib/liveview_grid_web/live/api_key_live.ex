defmodule LiveviewGridWeb.ApiKeyLive do
  @moduledoc """
  API Key 관리 페이지
  """
  use Phoenix.LiveView

  alias LiveviewGrid.ApiKeys

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       api_keys: ApiKeys.list_api_keys(),
       show_create_form: false,
       new_key_name: "",
       new_key_permissions: "read",
       just_created_key: nil
     )}
  end

  @impl true
  def handle_event("toggle_create_form", _params, socket) do
    {:noreply, assign(socket, show_create_form: !socket.assigns.show_create_form, just_created_key: nil)}
  end

  @impl true
  def handle_event("create_key", %{"name" => name, "permissions" => permissions}, socket) do
    case ApiKeys.create_api_key(%{name: name, permissions: permissions}) do
      {:ok, api_key} ->
        {:noreply,
         assign(socket,
           api_keys: ApiKeys.list_api_keys(),
           just_created_key: api_key.key,
           show_create_form: false,
           new_key_name: "",
           new_key_permissions: "read"
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "API Key 생성에 실패했습니다.")}
    end
  end

  @impl true
  def handle_event("revoke_key", %{"id" => id}, socket) do
    case ApiKeys.revoke_api_key(String.to_integer(id)) do
      {:ok, _} ->
        {:noreply, assign(socket, api_keys: ApiKeys.list_api_keys())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "폐기에 실패했습니다.")}
    end
  end

  @impl true
  def handle_event("delete_key", %{"id" => id}, socket) do
    case ApiKeys.delete_api_key(String.to_integer(id)) do
      {:ok, _} ->
        {:noreply, assign(socket, api_keys: ApiKeys.list_api_keys(), just_created_key: nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "삭제에 실패했습니다.")}
    end
  end

  @impl true
  def handle_event("dismiss_created_key", _params, socket) do
    {:noreply, assign(socket, just_created_key: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="padding: 24px; max-width: 1200px; margin: 0 auto;">
      <!-- Header -->
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
        <div>
          <h1 style="margin: 0; font-size: 24px; font-weight: 700; color: #1a1a1a;">API Key Management</h1>
          <p style="margin: 4px 0 0; color: #666; font-size: 14px;">API 키를 생성하고 관리합니다</p>
        </div>
        <button
          phx-click="toggle_create_form"
          style="padding: 10px 20px; background: #2563eb; color: white; border: none; border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer;"
        >
          + 새 키 생성
        </button>
      </div>

      <!-- Created Key Banner -->
      <%= if @just_created_key do %>
        <div style="margin-bottom: 20px; padding: 16px 20px; background: #ecfdf5; border: 1px solid #6ee7b7; border-radius: 10px;">
          <div style="display: flex; justify-content: space-between; align-items: flex-start;">
            <div>
              <div style="font-weight: 600; color: #065f46; font-size: 14px; margin-bottom: 6px;">
                API Key가 생성되었습니다
              </div>
              <div style="font-size: 12px; color: #047857; margin-bottom: 10px;">
                이 키는 다시 표시되지 않습니다. 안전한 곳에 복사해 두세요.
              </div>
              <div style="display: flex; align-items: center; gap: 8px;">
                <code style="padding: 8px 12px; background: white; border: 1px solid #a7f3d0; border-radius: 6px; font-size: 13px; color: #065f46; font-family: monospace; word-break: break-all;">
                  <%= @just_created_key %>
                </code>
              </div>
            </div>
            <button
              phx-click="dismiss_created_key"
              style="padding: 4px 8px; background: none; border: none; color: #6ee7b7; font-size: 18px; cursor: pointer;"
            >
              &times;
            </button>
          </div>
        </div>
      <% end %>

      <!-- Create Form -->
      <%= if @show_create_form do %>
        <div style="margin-bottom: 24px; padding: 20px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px;">
          <h3 style="margin: 0 0 16px; font-size: 16px; font-weight: 600; color: #334155;">새 API Key 생성</h3>
          <form phx-submit="create_key" style="display: flex; gap: 12px; align-items: flex-end; flex-wrap: wrap;">
            <div style="flex: 1; min-width: 200px;">
              <label style="display: block; font-size: 12px; font-weight: 600; color: #64748b; margin-bottom: 4px;">이름</label>
              <input
                type="text"
                name="name"
                value={@new_key_name}
                placeholder="예: Production API Key"
                required
                style="width: 100%; padding: 8px 12px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px; box-sizing: border-box;"
              />
            </div>
            <div style="min-width: 160px;">
              <label style="display: block; font-size: 12px; font-weight: 600; color: #64748b; margin-bottom: 4px;">권한</label>
              <select
                name="permissions"
                style="width: 100%; padding: 8px 12px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px; background: white; box-sizing: border-box;"
              >
                <option value="read" selected={@new_key_permissions == "read"}>Read Only</option>
                <option value="read_write" selected={@new_key_permissions == "read_write"}>Read & Write</option>
                <option value="admin" selected={@new_key_permissions == "admin"}>Admin</option>
              </select>
            </div>
            <div style="display: flex; gap: 8px;">
              <button
                type="submit"
                style="padding: 8px 20px; background: #2563eb; color: white; border: none; border-radius: 6px; font-size: 14px; font-weight: 600; cursor: pointer;"
              >
                생성
              </button>
              <button
                type="button"
                phx-click="toggle_create_form"
                style="padding: 8px 16px; background: white; color: #64748b; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px; cursor: pointer;"
              >
                취소
              </button>
            </div>
          </form>
        </div>
      <% end %>

      <!-- API Keys Table -->
      <div style="background: white; border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden;">
        <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
          <thead>
            <tr style="background: #f8fafc; border-bottom: 1px solid #e2e8f0;">
              <th style="padding: 12px 16px; text-align: left; font-weight: 600; color: #475569;">이름</th>
              <th style="padding: 12px 16px; text-align: left; font-weight: 600; color: #475569;">API Key</th>
              <th style="padding: 12px 16px; text-align: left; font-weight: 600; color: #475569;">권한</th>
              <th style="padding: 12px 16px; text-align: left; font-weight: 600; color: #475569;">상태</th>
              <th style="padding: 12px 16px; text-align: left; font-weight: 600; color: #475569;">생성일</th>
              <th style="padding: 12px 16px; text-align: center; font-weight: 600; color: #475569;">Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= if Enum.empty?(@api_keys) do %>
              <tr>
                <td colspan="6" style="padding: 40px; text-align: center; color: #94a3b8;">
                  <div style="font-size: 32px; margin-bottom: 8px;">🔑</div>
                  <div>API Key가 없습니다. 새 키를 생성해 보세요.</div>
                </td>
              </tr>
            <% else %>
              <%= for key <- @api_keys do %>
                <tr style="border-bottom: 1px solid #f1f5f9;">
                  <td style="padding: 12px 16px; font-weight: 500; color: #1e293b;">
                    <%= key.name %>
                  </td>
                  <td style="padding: 12px 16px;">
                    <code style="padding: 2px 8px; background: #f1f5f9; border-radius: 4px; font-size: 12px; color: #475569; font-family: monospace;">
                      <%= key.prefix %>
                    </code>
                  </td>
                  <td style="padding: 12px 16px;">
                    <span style={"padding: 2px 10px; border-radius: 12px; font-size: 12px; font-weight: 500; #{permission_style(key.permissions)}"}>
                      <%= permission_label(key.permissions) %>
                    </span>
                  </td>
                  <td style="padding: 12px 16px;">
                    <span style={"padding: 2px 10px; border-radius: 12px; font-size: 12px; font-weight: 500; #{status_style(key.status)}"}>
                      <%= status_label(key.status) %>
                    </span>
                  </td>
                  <td style="padding: 12px 16px; color: #64748b; font-size: 13px;">
                    <%= Calendar.strftime(key.inserted_at, "%Y-%m-%d %H:%M") %>
                  </td>
                  <td style="padding: 12px 16px; text-align: center;">
                    <div style="display: flex; gap: 6px; justify-content: center;">
                      <%= if key.status == "active" do %>
                        <button
                          phx-click="revoke_key"
                          phx-value-id={key.id}
                          style="padding: 4px 12px; background: #fef3c7; color: #92400e; border: 1px solid #fcd34d; border-radius: 4px; font-size: 12px; cursor: pointer;"
                        >
                          Revoke
                        </button>
                      <% end %>
                      <button
                        phx-click="delete_key"
                        phx-value-id={key.id}
                        data-confirm="정말 이 API Key를 삭제하시겠습니까?"
                        style="padding: 4px 12px; background: #fef2f2; color: #991b1b; border: 1px solid #fca5a5; border-radius: 4px; font-size: 12px; cursor: pointer;"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>

      <!-- Info -->
      <div style="margin-top: 20px; padding: 16px; background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px;">
        <div style="font-size: 13px; color: #1e40af; font-weight: 600; margin-bottom: 6px;">API Key 사용 방법</div>
        <div style="font-size: 13px; color: #3b82f6; line-height: 1.6;">
          <code style="background: #dbeafe; padding: 2px 6px; border-radius: 3px;">Authorization: Bearer YOUR_API_KEY</code>
          헤더를 포함하여 API를 호출하세요.
        </div>
      </div>
    </div>
    """
  end

  defp permission_label("read"), do: "Read"
  defp permission_label("read_write"), do: "Read & Write"
  defp permission_label("admin"), do: "Admin"
  defp permission_label(_), do: "Unknown"

  defp permission_style("read"), do: "background: #eff6ff; color: #1d4ed8;"
  defp permission_style("read_write"), do: "background: #f0fdf4; color: #15803d;"
  defp permission_style("admin"), do: "background: #fef3c7; color: #92400e;"
  defp permission_style(_), do: "background: #f1f5f9; color: #475569;"

  defp status_style("active"), do: "background: #f0fdf4; color: #15803d;"
  defp status_style("revoked"), do: "background: #fef2f2; color: #991b1b;"
  defp status_style(_), do: "background: #f1f5f9; color: #475569;"

  defp status_label("active"), do: "Active"
  defp status_label("revoked"), do: "Revoked"
  defp status_label(other), do: other
end
