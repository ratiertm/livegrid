defmodule LiveViewGrid.Renderers do
  @moduledoc """
  Built-in cell renderer presets.

  Each function returns a renderer function with signature:
    (row :: map(), column :: map(), assigns :: map()) -> Phoenix.LiveView.Rendered.t()

  ## Usage

      %{field: :city, label: "City",
        renderer: LiveViewGrid.Renderers.badge(
          colors: %{"Seoul" => "blue", "Busan" => "green"}
        )}
  """
  use Phoenix.Component

  @doc """
  Render value as a colored badge.

  ## Options
    - `colors` - %{value_string => color_name} mapping
    - `default_color` - fallback color (default: "gray")

  Available colors: blue, green, red, yellow, gray, purple
  """
  @spec badge(opts :: keyword()) :: (map(), map(), map() -> Phoenix.LiveView.Rendered.t())
  def badge(opts \\ []) do
    colors = Keyword.get(opts, :colors, %{})
    default_color = Keyword.get(opts, :default_color, "gray")

    fn row, column, _assigns ->
      value = Map.get(row, column.field)
      color = Map.get(colors, to_string(value), default_color)
      assigns = %{value: value, color: color}

      ~H"""
      <span class={"lv-grid__badge lv-grid__badge--#{@color}"}><%= @value %></span>
      """
    end
  end

  @doc """
  Render value as a clickable link.

  ## Options
    - `prefix` - URL prefix (e.g. "mailto:", "tel:")
    - `target` - link target (e.g. "_blank")
    - `href` - custom URL function `fn(row, column) -> url`
  """
  @spec link(opts :: keyword()) :: (map(), map(), map() -> Phoenix.LiveView.Rendered.t())
  def link(opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "")
    target = Keyword.get(opts, :target, nil)
    href_fn = Keyword.get(opts, :href, nil)

    fn row, column, _assigns ->
      value = Map.get(row, column.field)
      url = if href_fn, do: href_fn.(row, column), else: "#{prefix}#{value}"
      assigns = %{value: value, url: url, target: target}

      ~H"""
      <a href={@url} target={@target} class="lv-grid__link"><%= @value %></a>
      """
    end
  end

  @doc """
  Render number as a progress bar.

  ## Options
    - `max` - maximum value (default: 100)
    - `color` - bar color: "blue", "green", "red", "yellow" (default: "blue")
    - `show_value` - show numeric text (default: true)
  """
  @spec progress(opts :: keyword()) :: (map(), map(), map() -> Phoenix.LiveView.Rendered.t())
  def progress(opts \\ []) do
    max_val = Keyword.get(opts, :max, 100)
    color = Keyword.get(opts, :color, "blue")
    show_value = Keyword.get(opts, :show_value, true)

    fn row, column, _assigns ->
      value = Map.get(row, column.field) || 0
      numeric = if is_number(value), do: value, else: 0
      pct = min(100, round(numeric / max(max_val, 1) * 100))
      assigns = %{value: value, pct: pct, color: color, show_value: show_value}

      ~H"""
      <div class="lv-grid__progress">
        <div class="lv-grid__progress-track">
          <div class={"lv-grid__progress-fill lv-grid__progress-fill--#{@color}"} style={"width: #{@pct}%"}></div>
        </div>
        <%= if @show_value do %>
          <span class="lv-grid__progress-text"><%= @value %></span>
        <% end %>
      </div>
      """
    end
  end

  @doc """
  F-906: Render value as a radio button group.

  ## Options
    - options: list of {value, label} tuples
    - name: radio group name (default: column field)

  ## Example

      %{field: :priority, renderer: LiveViewGrid.Renderers.radio(
        options: [{"high", "High"}, {"medium", "Med"}, {"low", "Low"}]
      )}
  """
  @spec radio(opts :: keyword()) :: function()
  def radio(opts \\ []) do
    radio_options = Keyword.get(opts, :options, [])

    fn row, column, _assigns ->
      value = Map.get(row, column.field)
      name = "radio_#{row.id}_#{column.field}"
      assigns = %{value: value, radio_options: radio_options, name: name, row_id: row.id, field: column.field}

      ~H"""
      <div class="lv-grid__radio-group">
        <%= for {opt_val, opt_label} <- @radio_options do %>
          <label class="lv-grid__radio-label">
            <input type="radio" name={@name} value={opt_val} checked={to_string(@value) == to_string(opt_val)} class="lv-grid__radio-input" />
            <span><%= opt_label %></span>
          </label>
        <% end %>
      </div>
      """
    end
  end
end
