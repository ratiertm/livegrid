defmodule LiveviewGridWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use LiveviewGridWeb, :controller` and
  `use LiveviewGridWeb, :live_view`.
  """
  use LiveviewGridWeb, :html

  embed_templates "layouts/*"

  alias Phoenix.LiveView.JS

  def toggle_sidebar do
    %JS{}
    |> JS.toggle(to: "#sidebar-backdrop", in: "fade-in", out: "fade-out")
    |> JS.toggle_class("-translate-x-full", to: "#sidebar")
  end

  attr :path, :string, required: true
  attr :current_path, :string, required: true
  attr :label, :string, required: true
  attr :icon, :string, required: true

  def sidebar_link(assigns) do
    active = assigns.current_path == assigns.path
    assigns = assign(assigns, :active, active)

    ~H"""
    <a
      href={@path}
      class={[
        "flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors mb-0.5",
        @active && "bg-blue-50 text-blue-700",
        !@active && "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
      ]}
    >
      <.sidebar_icon name={@icon} active={@active} />
      <%= @label %>
    </a>
    """
  end

  attr :name, :string, required: true
  attr :active, :boolean, default: false

  defp sidebar_icon(%{name: "memory"} = assigns) do
    ~H"""
    <svg class={icon_class(@active)} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2z" />
    </svg>
    """
  end

  defp sidebar_icon(%{name: "database"} = assigns) do
    ~H"""
    <svg class={icon_class(@active)} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
    </svg>
    """
  end

  defp sidebar_icon(%{name: "globe"} = assigns) do
    ~H"""
    <svg class={icon_class(@active)} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
    </svg>
    """
  end

  defp sidebar_icon(%{name: "palette"} = assigns) do
    ~H"""
    <svg class={icon_class(@active)} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
    </svg>
    """
  end

  defp sidebar_icon(%{name: "key"} = assigns) do
    ~H"""
    <svg class={icon_class(@active)} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
    </svg>
    """
  end

  defp sidebar_icon(%{name: "book"} = assigns) do
    ~H"""
    <svg class={icon_class(@active)} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
    </svg>
    """
  end

  defp sidebar_icon(%{name: "chart"} = assigns) do
    ~H"""
    <svg class={icon_class(@active)} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" />
    </svg>
    """
  end

  defp icon_class(true), do: "w-5 h-5 text-blue-600 flex-shrink-0"
  defp icon_class(false), do: "w-5 h-5 text-gray-400 flex-shrink-0"
end
