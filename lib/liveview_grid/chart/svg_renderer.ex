defmodule LiveviewGrid.Chart.SvgRenderer do
  @moduledoc """
  서버사이드 SVG 차트 렌더링.
  Phoenix.Component로 HEEx 템플릿을 통해 SVG를 직접 생성합니다.
  """
  use Phoenix.Component
  alias LiveviewGrid.Chart

  # SVG 레이아웃 상수
  @padding_top 20
  @padding_right 20
  @padding_bottom 40
  @padding_left 60
  @bar_gap 4

  @doc "Bar 차트 (세로 막대)"
  attr :chart_data, :map, required: true
  attr :width, :integer, default: 600
  attr :height, :integer, default: 300
  attr :theme, :string, default: "light"

  def bar_chart(assigns) do
    plot_w = assigns.width - @padding_left - @padding_right
    plot_h = assigns.height - @padding_top - @padding_bottom
    max_val = max(assigns.chart_data.max_value, 1)
    point_count = length(assigns.chart_data.points)
    bar_w = if point_count > 0, do: div(plot_w - @bar_gap * max(point_count - 1, 0), point_count), else: 0

    grid_lines =
      for i <- 0..4 do
        y = @padding_top + plot_h - div(plot_h * i, 4)
        label = Chart.format_number(round(max_val * i / 4))
        %{y: y, label: label}
      end

    bars =
      assigns.chart_data.points
      |> Enum.with_index()
      |> Enum.map(fn {point, idx} ->
        first_field = List.first(assigns.chart_data.value_fields)
        val = Map.get(point.values, first_field, 0)
        bar_h = if max_val > 0, do: round(plot_h * val / max_val), else: 0
        x = @padding_left + idx * (bar_w + @bar_gap)
        y = @padding_top + plot_h - bar_h

        %{
          x: x, y: y, width: bar_w, height: bar_h,
          color: point.color, category: point.category,
          label: Chart.format_number(val),
          cat_x: x + div(bar_w, 2),
          cat_y: assigns.height - @padding_bottom + 16,
          val_y: y - 4
        }
      end)

    assigns =
      assigns
      |> assign(:plot_w, plot_w)
      |> assign(:plot_h, plot_h)
      |> assign(:grid_lines, grid_lines)
      |> assign(:bars, bars)
      |> assign(:p_left, @padding_left)
      |> assign(:p_top, @padding_top)
      |> assign(:p_right, @padding_right)

    ~H"""
    <svg viewBox={"0 0 #{@width} #{@height}"} class="lv-grid__chart-svg" xmlns="http://www.w3.org/2000/svg">
      <%!-- Grid Lines --%>
      <%= for gl <- @grid_lines do %>
        <line x1={@p_left} y1={gl.y} x2={@width - @p_right} y2={gl.y}
              stroke={grid_line_color(@theme)} stroke-width="1" stroke-dasharray="4,4" />
        <text x={@p_left - 8} y={gl.y + 4} text-anchor="end"
              fill={text_color(@theme)} font-size="11"><%= gl.label %></text>
      <% end %>

      <%!-- Bars --%>
      <%= for bar <- @bars do %>
        <rect x={bar.x} y={bar.y} width={bar.width} height={bar.height}
              fill={bar.color} rx="3" ry="3" class="lv-grid__chart-bar">
          <title><%= bar.category %>: <%= bar.label %></title>
        </rect>
        <text x={bar.cat_x} y={bar.val_y} text-anchor="middle"
              fill={text_color(@theme)} font-size="10"><%= bar.label %></text>
        <text x={bar.cat_x} y={bar.cat_y} text-anchor="middle"
              fill={text_color(@theme)} font-size="11"><%= String.slice(bar.category, 0, 8) %></text>
      <% end %>

      <%!-- Axes --%>
      <line x1={@p_left} y1={@p_top + @plot_h} x2={@width - @p_right} y2={@p_top + @plot_h}
            stroke={axis_color(@theme)} stroke-width="1" />
      <line x1={@p_left} y1={@p_top} x2={@p_left} y2={@p_top + @plot_h}
            stroke={axis_color(@theme)} stroke-width="1" />
    </svg>
    """
  end

  @doc "Line 차트 (꺾은선)"
  attr :chart_data, :map, required: true
  attr :width, :integer, default: 600
  attr :height, :integer, default: 300
  attr :theme, :string, default: "light"

  def line_chart(assigns) do
    plot_w = assigns.width - @padding_left - @padding_right
    plot_h = assigns.height - @padding_top - @padding_bottom
    max_val = max(assigns.chart_data.max_value, 1)
    point_count = length(assigns.chart_data.points)
    step_x = if point_count > 1, do: div(plot_w, point_count - 1), else: plot_w

    grid_lines =
      for i <- 0..4 do
        y = @padding_top + plot_h - div(plot_h * i, 4)
        label = Chart.format_number(round(max_val * i / 4))
        %{y: y, label: label}
      end

    lines =
      assigns.chart_data.value_fields
      |> Enum.with_index()
      |> Enum.map(fn {field, field_idx} ->
        color = Enum.at(Chart.palette(), rem(field_idx, 8))

        points =
          assigns.chart_data.points
          |> Enum.with_index()
          |> Enum.map(fn {point, idx} ->
            val = Map.get(point.values, field, 0)
            x = @padding_left + idx * step_x
            y = @padding_top + plot_h - (if max_val > 0, do: round(plot_h * val / max_val), else: 0)
            %{x: x, y: y, category: point.category, label: Chart.format_number(val)}
          end)

        polyline = points |> Enum.map(fn p -> "#{p.x},#{p.y}" end) |> Enum.join(" ")
        %{color: color, points: points, polyline: polyline, field: field}
      end)

    cat_labels =
      assigns.chart_data.points
      |> Enum.with_index()
      |> Enum.map(fn {point, idx} ->
        %{x: @padding_left + idx * step_x, category: point.category}
      end)

    assigns =
      assigns
      |> assign(:plot_w, plot_w)
      |> assign(:plot_h, plot_h)
      |> assign(:grid_lines, grid_lines)
      |> assign(:lines, lines)
      |> assign(:cat_labels, cat_labels)
      |> assign(:p_left, @padding_left)
      |> assign(:p_top, @padding_top)
      |> assign(:p_right, @padding_right)
      |> assign(:p_bottom, @padding_bottom)

    ~H"""
    <svg viewBox={"0 0 #{@width} #{@height}"} class="lv-grid__chart-svg" xmlns="http://www.w3.org/2000/svg">
      <%!-- Grid Lines --%>
      <%= for gl <- @grid_lines do %>
        <line x1={@p_left} y1={gl.y} x2={@width - @p_right} y2={gl.y}
              stroke={grid_line_color(@theme)} stroke-width="1" stroke-dasharray="4,4" />
        <text x={@p_left - 8} y={gl.y + 4} text-anchor="end"
              fill={text_color(@theme)} font-size="11"><%= gl.label %></text>
      <% end %>

      <%!-- Lines --%>
      <%= for line <- @lines do %>
        <polyline points={line.polyline} fill="none" stroke={line.color} stroke-width="2" />
        <%= for pt <- line.points do %>
          <circle cx={pt.x} cy={pt.y} r="4" fill={line.color} class="lv-grid__chart-point">
            <title><%= pt.category %>: <%= pt.label %></title>
          </circle>
        <% end %>
      <% end %>

      <%!-- Category Labels --%>
      <%= for cl <- @cat_labels do %>
        <text x={cl.x} y={@height - @p_bottom + 16} text-anchor="middle"
              fill={text_color(@theme)} font-size="11"><%= String.slice(cl.category, 0, 8) %></text>
      <% end %>

      <%!-- Axes --%>
      <line x1={@p_left} y1={@p_top + @plot_h} x2={@width - @p_right} y2={@p_top + @plot_h}
            stroke={axis_color(@theme)} stroke-width="1" />
      <line x1={@p_left} y1={@p_top} x2={@p_left} y2={@p_top + @plot_h}
            stroke={axis_color(@theme)} stroke-width="1" />
    </svg>
    """
  end

  @doc "Pie 차트"
  attr :chart_data, :map, required: true
  attr :width, :integer, default: 300
  attr :height, :integer, default: 300
  attr :theme, :string, default: "light"

  def pie_chart(assigns) do
    cx = div(assigns.width, 2)
    cy = div(assigns.height, 2) - 10
    r = min(cx, cy) - 30
    first_field = List.first(assigns.chart_data.value_fields)

    total =
      assigns.chart_data.points
      |> Enum.map(&Map.get(&1.values, first_field, 0))
      |> Enum.sum()
      |> max(1)

    slices = build_pie_slices(assigns.chart_data.points, first_field, total, cx, cy, r)

    legend =
      assigns.chart_data.points
      |> Enum.with_index()
      |> Enum.map(fn {point, idx} ->
        ly = assigns.height - 20 + div(idx, 4) * 16
        lx = rem(idx, 4) * div(assigns.width, 4) + 10
        %{x: lx, y: ly, color: point.color, category: point.category}
      end)

    assigns =
      assigns
      |> assign(:slices, slices)
      |> assign(:legend, legend)

    ~H"""
    <svg viewBox={"0 0 #{@width} #{@height}"} class="lv-grid__chart-svg" xmlns="http://www.w3.org/2000/svg">
      <%= for slice <- @slices do %>
        <path d={slice.path} fill={slice.color} class="lv-grid__chart-slice">
          <title><%= slice.category %>: <%= Chart.format_number(slice.value) %> (<%= slice.percent %>%)</title>
        </path>
      <% end %>

      <%!-- Legend --%>
      <%= for lg <- @legend do %>
        <rect x={lg.x} y={lg.y} width="10" height="10" fill={lg.color} rx="2" />
        <text x={lg.x + 14} y={lg.y + 9} fill={text_color(@theme)} font-size="10">
          <%= String.slice(lg.category, 0, 6) %>
        </text>
      <% end %>
    </svg>
    """
  end

  # Pie 슬라이스 경로 계산
  defp build_pie_slices(points, field, total, cx, cy, r) do
    {slices, _} =
      Enum.reduce(points, {[], 0}, fn point, {acc, start_angle} ->
        val = Map.get(point.values, field, 0)
        sweep = val / total * 360
        end_angle = start_angle + sweep
        percent = Float.round(val / total * 100, 1)

        path = pie_arc_path(cx, cy, r, start_angle, end_angle)

        slice = %{
          path: path,
          color: point.color,
          category: point.category,
          value: val,
          percent: percent
        }

        {[slice | acc], end_angle}
      end)

    Enum.reverse(slices)
  end

  defp pie_arc_path(cx, cy, r, start_deg, end_deg) do
    s_rad = (start_deg - 90) * :math.pi() / 180
    e_rad = (end_deg - 90) * :math.pi() / 180

    x1 = cx + r * :math.cos(s_rad)
    y1 = cy + r * :math.sin(s_rad)
    x2 = cx + r * :math.cos(e_rad)
    y2 = cy + r * :math.sin(e_rad)

    large_arc = if end_deg - start_deg > 180, do: 1, else: 0

    "M #{cx} #{cy} L #{Float.round(x1, 2)} #{Float.round(y1, 2)} A #{r} #{r} 0 #{large_arc} 1 #{Float.round(x2, 2)} #{Float.round(y2, 2)} Z"
  end

  # 테마별 색상
  defp text_color("dark"), do: "#ccc"
  defp text_color(_), do: "#333"

  defp grid_line_color("dark"), do: "#444"
  defp grid_line_color(_), do: "#e5e7eb"

  defp axis_color("dark"), do: "#666"
  defp axis_color(_), do: "#9ca3af"
end
