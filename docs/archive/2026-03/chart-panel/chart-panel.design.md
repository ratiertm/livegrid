# Chart Panel Design (FA-031)

> **Plan Reference**: `docs/01-plan/features/chart-panel.plan.md`
> **Status**: Design
> **Implementation Steps**: 10

---

## Implementation Steps

### Step 1: Grid state에 chart 필드 추가

**파일**: `lib/liveview_grid/grid.ex` (`initial_state/0`, ~line 1361)

`initial_state/0`의 반환 맵에 차트 관련 키를 추가합니다:

```elixir
defp initial_state do
  %{
    # ... 기존 필드들 ...
    # Per-row Heights (extendsizetype)
    row_heights: %{},
    # FA-031: Chart Panel
    show_chart_panel: false,
    chart_config: %{
      chart_type: :bar,
      category_field: nil,
      value_fields: [],
      aggregation: :sum
    },
    chart_data: nil
  }
end
```

**파일**: `lib/liveview_grid/grid.ex` (`default_options/0`, ~line 1026)

옵션에 `chart_panel` 추가:

```elixir
def default_options do
  %{
    # ... 기존 옵션들 ...
    autofit_type: :none,
    # FA-031: Chart Panel
    chart_panel: false
  }
end
```

---

### Step 2: Chart 데이터 변환/집계 모듈

**파일**: `lib/liveview_grid/chart.ex` (NEW)

그리드 데이터를 차트용 집계 데이터로 변환하는 모듈입니다:

```elixir
defmodule LiveviewGrid.Chart do
  @moduledoc """
  Grid 데이터를 차트 렌더링용 데이터로 변환합니다.
  카테고리별 집계, 정규화, 색상 팔레트 관리를 담당합니다.
  """

  @palette [
    "#4285F4", "#EA4335", "#FBBC04", "#34A853",
    "#FF6D01", "#46BDC6", "#7B61FF", "#F538A0"
  ]

  @type chart_config :: %{
    chart_type: :bar | :line | :pie | :column,
    category_field: atom() | nil,
    value_fields: [atom()],
    aggregation: :sum | :avg | :count | :min | :max
  }

  @type chart_point :: %{
    category: String.t(),
    values: %{atom() => number()},
    color: String.t()
  }

  @type chart_data :: %{
    points: [chart_point()],
    max_value: number(),
    min_value: number(),
    value_fields: [atom()],
    category_field: atom()
  }

  @doc "그리드 데이터로 차트 데이터를 생성합니다."
  @spec prepare_data(list(map()), chart_config()) :: chart_data() | nil
  def prepare_data(data, %{category_field: nil}), do: nil
  def prepare_data(data, %{value_fields: []}), do: nil
  def prepare_data([], _config), do: nil

  def prepare_data(data, config) do
    points =
      data
      |> Enum.group_by(&to_string(Map.get(&1, config.category_field, "N/A")))
      |> Enum.map(fn {category, rows} ->
        values =
          config.value_fields
          |> Enum.map(fn field ->
            nums = rows |> Enum.map(&to_number(Map.get(&1, field, 0)))
            {field, aggregate(nums, config.aggregation)}
          end)
          |> Map.new()

        %{category: category, values: values}
      end)
      |> Enum.sort_by(& &1.category)
      |> Enum.with_index()
      |> Enum.map(fn {point, idx} ->
        Map.put(point, :color, Enum.at(@palette, rem(idx, length(@palette))))
      end)

    all_values = Enum.flat_map(points, fn p -> Map.values(p.values) end)

    %{
      points: points,
      max_value: if(all_values == [], do: 0, else: Enum.max(all_values)),
      min_value: if(all_values == [], do: 0, else: Enum.min(all_values ++ [0])),
      value_fields: config.value_fields,
      category_field: config.category_field
    }
  end

  @doc "숫자 집계 함수"
  @spec aggregate([number()], atom()) :: number()
  def aggregate([], _), do: 0
  def aggregate(nums, :sum), do: Enum.sum(nums)
  def aggregate(nums, :avg), do: Enum.sum(nums) / length(nums)
  def aggregate(nums, :count), do: length(nums)
  def aggregate(nums, :min), do: Enum.min(nums)
  def aggregate(nums, :max), do: Enum.max(nums)

  @doc "색상 팔레트를 반환합니다."
  @spec palette() :: [String.t()]
  def palette, do: @palette

  @doc "값을 숫자로 변환합니다."
  @spec to_number(any()) :: number()
  def to_number(n) when is_number(n), do: n
  def to_number(s) when is_binary(s) do
    case Float.parse(s) do
      {n, _} -> n
      :error -> 0
    end
  end
  def to_number(_), do: 0

  @doc "숫자를 읽기 좋은 형식으로 포맷합니다."
  @spec format_number(number()) :: String.t()
  def format_number(n) when is_float(n) and n == trunc(n), do: Integer.to_string(trunc(n))
  def format_number(n) when is_float(n), do: :erlang.float_to_binary(n, decimals: 1)
  def format_number(n) when is_integer(n) and n >= 10_000 do
    n
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
    |> Enum.join(",")
  end
  def format_number(n), do: to_string(n)
end
```

---

### Step 3: SVG 렌더러 모듈

**파일**: `lib/liveview_grid/chart/svg_renderer.ex` (NEW)

Phoenix.Component 기반 SVG 차트 렌더링 모듈입니다:

```elixir
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

  @doc "Bar 차트 (가로 막대)"
  attr :chart_data, :map, required: true
  attr :width, :integer, default: 600
  attr :height, :integer, default: 300
  attr :theme, :string, default: "light"

  def bar_chart(assigns) do
    ~H"""
    <svg viewBox={"0 0 #{@width} #{@height}"} class="lv-grid__chart-svg" xmlns="http://www.w3.org/2000/svg">
      <% plot_w = @width - @padding_left - @padding_right %>
      <% plot_h = @height - @padding_top - @padding_bottom %>
      <% max_val = max(@chart_data.max_value, 1) %>
      <% point_count = length(@chart_data.points) %>
      <% bar_w = if point_count > 0, do: div(plot_w - @bar_gap * (point_count - 1), point_count), else: 0 %>

      <%!-- Grid Lines --%>
      <%= for i <- 0..4 do %>
        <% y = @padding_top + plot_h - div(plot_h * i, 4) %>
        <line x1={@padding_left} y1={y} x2={@width - @padding_right} y2={y}
              stroke={grid_line_color(@theme)} stroke-width="1" stroke-dasharray="4,4" />
        <text x={@padding_left - 8} y={y + 4} text-anchor="end"
              fill={text_color(@theme)} font-size="11">
          <%= Chart.format_number(div(max_val * i, 4)) %>
        </text>
      <% end %>

      <%!-- Bars --%>
      <%= for {point, idx} <- Enum.with_index(@chart_data.points) do %>
        <% first_field = List.first(@chart_data.value_fields) %>
        <% val = Map.get(point.values, first_field, 0) %>
        <% bar_h = if max_val > 0, do: div(plot_h * trunc(val), trunc(max_val)), else: 0 %>
        <% x = @padding_left + idx * (bar_w + @bar_gap) %>
        <% y = @padding_top + plot_h - bar_h %>

        <rect x={x} y={y} width={bar_w} height={bar_h}
              fill={point.color} rx="3" ry="3" class="lv-grid__chart-bar">
          <title><%= point.category %>: <%= Chart.format_number(val) %></title>
        </rect>

        <%!-- Value Label --%>
        <text x={x + div(bar_w, 2)} y={y - 4} text-anchor="middle"
              fill={text_color(@theme)} font-size="10">
          <%= Chart.format_number(val) %>
        </text>

        <%!-- Category Label --%>
        <text x={x + div(bar_w, 2)} y={@height - @padding_bottom + 16} text-anchor="middle"
              fill={text_color(@theme)} font-size="11">
          <%= String.slice(point.category, 0, 8) %>
        </text>
      <% end %>

      <%!-- X축, Y축 --%>
      <line x1={@padding_left} y1={@padding_top + plot_h} x2={@width - @padding_right} y2={@padding_top + plot_h}
            stroke={axis_color(@theme)} stroke-width="1" />
      <line x1={@padding_left} y1={@padding_top} x2={@padding_left} y2={@padding_top + plot_h}
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
    ~H"""
    <svg viewBox={"0 0 #{@width} #{@height}"} class="lv-grid__chart-svg" xmlns="http://www.w3.org/2000/svg">
      <% plot_w = @width - @padding_left - @padding_right %>
      <% plot_h = @height - @padding_top - @padding_bottom %>
      <% max_val = max(@chart_data.max_value, 1) %>
      <% point_count = length(@chart_data.points) %>
      <% step_x = if point_count > 1, do: div(plot_w, point_count - 1), else: plot_w %>

      <%!-- Grid Lines --%>
      <%= for i <- 0..4 do %>
        <% y = @padding_top + plot_h - div(plot_h * i, 4) %>
        <line x1={@padding_left} y1={y} x2={@width - @padding_right} y2={y}
              stroke={grid_line_color(@theme)} stroke-width="1" stroke-dasharray="4,4" />
        <text x={@padding_left - 8} y={y + 4} text-anchor="end"
              fill={text_color(@theme)} font-size="11">
          <%= Chart.format_number(div(max_val * i, 4)) %>
        </text>
      <% end %>

      <%!-- Line path --%>
      <%= for field <- @chart_data.value_fields do %>
        <% field_idx = Enum.find_index(@chart_data.value_fields, &(&1 == field)) || 0 %>
        <% color = Enum.at(Chart.palette(), rem(field_idx, 8)) %>
        <% polyline_points = @chart_data.points
           |> Enum.with_index()
           |> Enum.map(fn {point, idx} ->
             val = Map.get(point.values, field, 0)
             x = @padding_left + idx * step_x
             y = @padding_top + plot_h - (if max_val > 0, do: div(plot_h * trunc(val), trunc(max_val)), else: 0)
             "#{x},#{y}"
           end)
           |> Enum.join(" ") %>

        <polyline points={polyline_points} fill="none" stroke={color} stroke-width="2" />

        <%!-- Data points --%>
        <%= for {point, idx} <- Enum.with_index(@chart_data.points) do %>
          <% val = Map.get(point.values, field, 0) %>
          <% x = @padding_left + idx * step_x %>
          <% y = @padding_top + plot_h - (if max_val > 0, do: div(plot_h * trunc(val), trunc(max_val)), else: 0) %>
          <circle cx={x} cy={y} r="4" fill={color} class="lv-grid__chart-point">
            <title><%= point.category %>: <%= Chart.format_number(val) %></title>
          </circle>
        <% end %>
      <% end %>

      <%!-- Category Labels --%>
      <%= for {point, idx} <- Enum.with_index(@chart_data.points) do %>
        <% x = @padding_left + idx * step_x %>
        <text x={x} y={@height - @padding_bottom + 16} text-anchor="middle"
              fill={text_color(@theme)} font-size="11">
          <%= String.slice(point.category, 0, 8) %>
        </text>
      <% end %>

      <%!-- 축 --%>
      <line x1={@padding_left} y1={@padding_top + plot_h} x2={@width - @padding_right} y2={@padding_top + plot_h}
            stroke={axis_color(@theme)} stroke-width="1" />
      <line x1={@padding_left} y1={@padding_top} x2={@padding_left} y2={@padding_top + plot_h}
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
    ~H"""
    <svg viewBox={"0 0 #{@width} #{@height}"} class="lv-grid__chart-svg" xmlns="http://www.w3.org/2000/svg">
      <% cx = div(@width, 2) %>
      <% cy = div(@height, 2) - 10 %>
      <% r = min(cx, cy) - 30 %>
      <% first_field = List.first(@chart_data.value_fields) %>
      <% total = @chart_data.points
         |> Enum.map(&Map.get(&1.values, first_field, 0))
         |> Enum.sum()
         |> max(1) %>
      <% slices = build_pie_slices(@chart_data.points, first_field, total, cx, cy, r) %>

      <%= for slice <- slices do %>
        <path d={slice.path} fill={slice.color} class="lv-grid__chart-slice">
          <title><%= slice.category %>: <%= Chart.format_number(slice.value) %> (<%= slice.percent %>%)</title>
        </path>
      <% end %>

      <%!-- Legend --%>
      <%= for {point, idx} <- Enum.with_index(@chart_data.points) do %>
        <% ly = @height - 20 + div(idx, 4) * 16 %>
        <% lx = rem(idx, 4) * div(@width, 4) + 10 %>
        <rect x={lx} y={ly} width="10" height="10" fill={point.color} rx="2" />
        <text x={lx + 14} y={ly + 9} fill={text_color(@theme)} font-size="10">
          <%= String.slice(point.category, 0, 6) %>
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

  # module attribute를 함수 호출로 사용하기 위한 래퍼
  defp padding_top, do: @padding_top
  defp padding_right, do: @padding_right
  defp padding_bottom, do: @padding_bottom
  defp padding_left, do: @padding_left
end
```

---

### Step 4: 이벤트 핸들러 추가

**파일**: `lib/liveview_grid_web/components/grid_component/event_handlers.ex`

차트 관련 이벤트 핸들러를 추가합니다:

```elixir
# FA-031: Chart Panel handlers

@spec handle_toggle_chart(map(), Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
def handle_toggle_chart(_params, socket) do
  grid = socket.assigns.grid
  show = !grid.state.show_chart_panel

  grid =
    if show do
      grid
      |> put_in([:state, :show_chart_panel], true)
      |> maybe_auto_configure_chart()
      |> recalculate_chart_data()
    else
      put_in(grid.state.show_chart_panel, false)
    end

  {:noreply, assign(socket, :grid, grid)}
end

@spec handle_update_chart_config(map(), Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
def handle_update_chart_config(%{"field" => field, "value" => value}, socket) do
  grid = socket.assigns.grid
  config = grid.state.chart_config

  config =
    case field do
      "chart_type" ->
        Map.put(config, :chart_type, String.to_existing_atom(value))

      "category_field" ->
        Map.put(config, :category_field, String.to_existing_atom(value))

      "aggregation" ->
        Map.put(config, :aggregation, String.to_existing_atom(value))

      "toggle_value_field" ->
        field_atom = String.to_existing_atom(value)
        current = config.value_fields
        new_fields =
          if field_atom in current,
            do: List.delete(current, field_atom),
            else: current ++ [field_atom]
        Map.put(config, :value_fields, new_fields)

      _ ->
        config
    end

  grid =
    grid
    |> put_in([:state, :chart_config], config)
    |> recalculate_chart_data()

  {:noreply, assign(socket, :grid, grid)}
end

# 차트 데이터 재계산
defp recalculate_chart_data(grid) do
  alias LiveviewGrid.Chart

  data = LiveviewGrid.Grid.visible_data(grid)
  chart_data = Chart.prepare_data(data, grid.state.chart_config)
  put_in(grid.state.chart_data, chart_data)
end

# 차트 미설정 시 자동 설정 (첫 번째 문자열 컬럼 → category, 첫 번째 숫자 컬럼 → value)
defp maybe_auto_configure_chart(grid) do
  config = grid.state.chart_config

  if is_nil(config.category_field) or config.value_fields == [] do
    columns = LiveviewGrid.Grid.display_columns(grid)

    category =
      Enum.find(columns, fn c ->
        c.field not in [:id, :inserted_at, :updated_at] and
        Map.get(c, :filter_type) != :number and
        Map.get(c, :filter_type) != :date
      end)

    value_cols =
      Enum.filter(columns, fn c ->
        Map.get(c, :filter_type) == :number or Map.get(c, :align) == :right
      end)
      |> Enum.take(2)

    new_config = %{
      config |
      category_field: if(category, do: category.field, else: config.category_field),
      value_fields: if(value_cols != [], do: Enum.map(value_cols, & &1.field), else: config.value_fields)
    }

    put_in(grid.state.chart_config, new_config)
  else
    grid
  end
end
```

---

### Step 5: grid_component.ex에 이벤트 라우팅 추가

**파일**: `lib/liveview_grid_web/components/grid_component.ex` (~line 158 부근, 기존 handle_event 영역)

```elixir
def handle_event("grid_toggle_chart", params, socket),
  do: EventHandlers.handle_toggle_chart(params, socket)

def handle_event("grid_update_chart_config", params, socket),
  do: EventHandlers.handle_update_chart_config(params, socket)
```

---

### Step 6: 툴바에 차트 토글 버튼 추가

**파일**: `lib/liveview_grid_web/components/grid_component.ex` (~line 499, 툴바 separator 앞)

기존 `<span class="lv-grid__toolbar-separator">` 바로 앞에 차트 버튼을 추가합니다:

```heex
<%= if @grid.options.chart_panel do %>
  <button
    class={"lv-grid__toolbar-btn #{if @grid.state.show_chart_panel, do: "lv-grid__toolbar-btn--active"}"}
    phx-click="grid_toggle_chart"
    phx-target={@myself}
    title={if @grid.state.show_chart_panel, do: "차트 숨기기", else: "차트 표시"}
  >
    📊
  </button>
<% end %>
```

---

### Step 7: 차트 패널 렌더링

**파일**: `lib/liveview_grid_web/components/grid_component.ex` (~line 1083, Summary Row 닫힘 `<% end %>` 바로 뒤, Footer 앞)

```heex
<!-- FA-031: Chart Panel -->
<%= if @grid.options.chart_panel && @grid.state.show_chart_panel do %>
  <div class="lv-grid__chart-panel">
    <div class="lv-grid__chart-controls">
      <div class="lv-grid__chart-control-group">
        <label class="lv-grid__chart-label">차트</label>
        <select
          phx-change="grid_update_chart_config"
          phx-target={@myself}
          name="value"
          class="lv-grid__chart-select"
        >
          <input type="hidden" name="field" value="chart_type" />
          <option value="bar" selected={@grid.state.chart_config.chart_type == :bar}>Bar</option>
          <option value="column" selected={@grid.state.chart_config.chart_type == :column}>Column</option>
          <option value="line" selected={@grid.state.chart_config.chart_type == :line}>Line</option>
          <option value="pie" selected={@grid.state.chart_config.chart_type == :pie}>Pie</option>
        </select>
      </div>

      <div class="lv-grid__chart-control-group">
        <label class="lv-grid__chart-label">카테고리 (X축)</label>
        <select
          phx-change="grid_update_chart_config"
          phx-target={@myself}
          name="value"
          class="lv-grid__chart-select"
        >
          <input type="hidden" name="field" value="category_field" />
          <option value="">선택...</option>
          <%= for col <- Grid.display_columns(@grid), col.field not in [:id] do %>
            <option value={col.field} selected={@grid.state.chart_config.category_field == col.field}>
              <%= col.label %>
            </option>
          <% end %>
        </select>
      </div>

      <div class="lv-grid__chart-control-group">
        <label class="lv-grid__chart-label">집계</label>
        <select
          phx-change="grid_update_chart_config"
          phx-target={@myself}
          name="value"
          class="lv-grid__chart-select"
        >
          <input type="hidden" name="field" value="aggregation" />
          <option value="sum" selected={@grid.state.chart_config.aggregation == :sum}>합계</option>
          <option value="avg" selected={@grid.state.chart_config.aggregation == :avg}>평균</option>
          <option value="count" selected={@grid.state.chart_config.aggregation == :count}>개수</option>
          <option value="min" selected={@grid.state.chart_config.aggregation == :min}>최소</option>
          <option value="max" selected={@grid.state.chart_config.aggregation == :max}>최대</option>
        </select>
      </div>

      <div class="lv-grid__chart-control-group">
        <label class="lv-grid__chart-label">값 (Y축)</label>
        <div class="lv-grid__chart-value-fields">
          <%= for col <- Grid.display_columns(@grid),
                  Map.get(col, :filter_type) == :number or Map.get(col, :align) == :right do %>
            <label class="lv-grid__chart-checkbox-label">
              <input
                type="checkbox"
                checked={col.field in @grid.state.chart_config.value_fields}
                phx-click="grid_update_chart_config"
                phx-target={@myself}
                phx-value-field="toggle_value_field"
                phx-value-value={col.field}
              />
              <%= col.label %>
            </label>
          <% end %>
        </div>
      </div>
    </div>

    <div class="lv-grid__chart-body">
      <%= if @grid.state.chart_data do %>
        <%= case @grid.state.chart_config.chart_type do %>
          <% :bar -> %>
            <LiveviewGrid.Chart.SvgRenderer.bar_chart
              chart_data={@grid.state.chart_data}
              width={600}
              height={300}
              theme={@grid.options.theme}
            />
          <% :column -> %>
            <LiveviewGrid.Chart.SvgRenderer.bar_chart
              chart_data={@grid.state.chart_data}
              width={600}
              height={300}
              theme={@grid.options.theme}
            />
          <% :line -> %>
            <LiveviewGrid.Chart.SvgRenderer.line_chart
              chart_data={@grid.state.chart_data}
              width={600}
              height={300}
              theme={@grid.options.theme}
            />
          <% :pie -> %>
            <LiveviewGrid.Chart.SvgRenderer.pie_chart
              chart_data={@grid.state.chart_data}
              width={300}
              height={300}
              theme={@grid.options.theme}
            />
          <% _ -> %>
            <LiveviewGrid.Chart.SvgRenderer.bar_chart
              chart_data={@grid.state.chart_data}
              width={600}
              height={300}
              theme={@grid.options.theme}
            />
        <% end %>
      <% else %>
        <div class="lv-grid__chart-empty">
          <p>카테고리와 값 컬럼을 선택하세요</p>
        </div>
      <% end %>
    </div>
  </div>
<% end %>
```

---

### Step 8: CSS 스타일 추가

**파일**: `assets/css/grid/chart.css` (NEW)

```css
/* ========================================
   LiveView Grid - Chart Panel (FA-031)
   ======================================== */

.lv-grid__chart-panel {
  border-top: 2px solid var(--lv-grid-border);
  background: var(--lv-grid-bg);
  padding: 16px;
}

.lv-grid__chart-controls {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--lv-grid-border);
}

.lv-grid__chart-control-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.lv-grid__chart-label {
  font-size: 11px;
  font-weight: 600;
  color: var(--lv-grid-text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.lv-grid__chart-select {
  padding: 4px 8px;
  border: 1px solid var(--lv-grid-border-input);
  border-radius: 4px;
  font-size: 12px;
  font-family: var(--lv-grid-font-family);
  color: var(--lv-grid-text);
  background: var(--lv-grid-bg-input);
  cursor: pointer;
  min-width: 80px;
}

.lv-grid__chart-select:focus {
  outline: none;
  border-color: var(--lv-grid-primary);
  box-shadow: 0 0 0 2px rgba(33, 150, 243, 0.15);
}

.lv-grid__chart-value-fields {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.lv-grid__chart-checkbox-label {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: var(--lv-grid-text);
  cursor: pointer;
}

.lv-grid__chart-checkbox-label input[type="checkbox"] {
  width: 14px;
  height: 14px;
  cursor: pointer;
}

.lv-grid__chart-body {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 200px;
}

.lv-grid__chart-svg {
  width: 100%;
  max-width: 600px;
  height: auto;
}

.lv-grid__chart-bar,
.lv-grid__chart-slice {
  transition: opacity 0.2s ease;
  cursor: pointer;
}

.lv-grid__chart-bar:hover,
.lv-grid__chart-slice:hover {
  opacity: 0.8;
}

.lv-grid__chart-point {
  transition: r 0.2s ease;
  cursor: pointer;
}

.lv-grid__chart-point:hover {
  r: 6;
}

.lv-grid__chart-empty {
  text-align: center;
  padding: 40px;
  color: var(--lv-grid-text-disabled);
  font-size: 14px;
}

/* Toolbar active state */
.lv-grid__toolbar-btn--active {
  background: var(--lv-grid-primary-light);
  color: var(--lv-grid-primary);
  border-radius: 4px;
}
```

---

### Step 9: CSS import 및 데모 페이지 연동

**9a. CSS import 추가**

**파일**: `assets/css/liveview_grid.css` 또는 메인 CSS 파일에 chart.css import 추가:

```css
@import "./grid/chart.css";
```

**9b. 데모 페이지에 차트 옵션 추가**

**파일**: `lib/liveview_grid_web/live/dbms_demo_live.ex` (또는 `demo_live.ex`)

Grid.new 호출 시 `chart_panel: true` 옵션 추가:

```elixir
grid = Grid.new(
  data: data,
  columns: columns,
  options: %{
    # ... 기존 옵션 ...
    chart_panel: true
  }
)
```

---

### Step 10: 테스트 작성

**파일**: `test/liveview_grid/chart_test.exs` (NEW)

```elixir
defmodule LiveviewGrid.ChartTest do
  use ExUnit.Case, async: true

  alias LiveviewGrid.Chart

  @sample_data [
    %{id: 1, name: "Alice", department: "개발", age: 30, salary: 5000},
    %{id: 2, name: "Bob", department: "개발", age: 25, salary: 4500},
    %{id: 3, name: "Carol", department: "영업", age: 35, salary: 5500},
    %{id: 4, name: "Dave", department: "영업", age: 28, salary: 4800},
    %{id: 5, name: "Eve", department: "기획", age: 32, salary: 5200}
  ]

  @config %{
    chart_type: :bar,
    category_field: :department,
    value_fields: [:salary],
    aggregation: :sum
  }

  describe "prepare_data/2" do
    test "카테고리별 집계 데이터 생성" do
      result = Chart.prepare_data(@sample_data, @config)

      assert result != nil
      assert length(result.points) == 3  # 개발, 기획, 영업
      assert result.max_value > 0
    end

    test "다중 value_fields 집계" do
      config = %{@config | value_fields: [:salary, :age]}
      result = Chart.prepare_data(@sample_data, config)

      first_point = hd(result.points)
      assert Map.has_key?(first_point.values, :salary)
      assert Map.has_key?(first_point.values, :age)
    end

    test "category_field가 nil이면 nil 반환" do
      assert Chart.prepare_data(@sample_data, %{@config | category_field: nil}) == nil
    end

    test "value_fields가 빈 리스트이면 nil 반환" do
      assert Chart.prepare_data(@sample_data, %{@config | value_fields: []}) == nil
    end

    test "빈 데이터이면 nil 반환" do
      assert Chart.prepare_data([], @config) == nil
    end
  end

  describe "aggregate/2" do
    test "sum" do
      assert Chart.aggregate([10, 20, 30], :sum) == 60
    end

    test "avg" do
      assert Chart.aggregate([10, 20, 30], :avg) == 20.0
    end

    test "count" do
      assert Chart.aggregate([10, 20, 30], :count) == 3
    end

    test "min" do
      assert Chart.aggregate([10, 20, 30], :min) == 10
    end

    test "max" do
      assert Chart.aggregate([10, 20, 30], :max) == 30
    end

    test "빈 리스트는 0 반환" do
      assert Chart.aggregate([], :sum) == 0
    end
  end

  describe "to_number/1" do
    test "정수" do
      assert Chart.to_number(42) == 42
    end

    test "실수" do
      assert Chart.to_number(3.14) == 3.14
    end

    test "문자열 숫자" do
      assert Chart.to_number("100") == 100.0
    end

    test "비숫자 문자열" do
      assert Chart.to_number("abc") == 0
    end

    test "nil" do
      assert Chart.to_number(nil) == 0
    end
  end

  describe "format_number/1" do
    test "천 단위 구분자" do
      assert Chart.format_number(12345) == "12,345"
    end

    test "소수점" do
      assert Chart.format_number(3.14) == "3.1"
    end

    test "정수형 실수" do
      assert Chart.format_number(5.0) == "5"
    end
  end
end
```

---

## Verification Checklist

- [ ] `mix compile --warnings-as-errors` 통과
- [ ] `mix test` 전체 통과 (기존 테스트 + 신규 ~15)
- [ ] 툴바에 📊 버튼 표시됨 (chart_panel: true일 때)
- [ ] 차트 패널 토글 (show/hide) 동작
- [ ] Bar 차트 SVG 렌더링 정상
- [ ] Line 차트 SVG 렌더링 정상
- [ ] Pie 차트 SVG 렌더링 정상
- [ ] 카테고리/값 컬럼 변경 시 차트 업데이트
- [ ] 집계 방식 변경 시 차트 업데이트
- [ ] 필터 적용 후 차트 데이터 반영
- [ ] 다크 모드에서 차트 색상 정상
- [ ] 빈 데이터일 때 empty state 표시

## Implementation Order

1. Step 1 → Grid state/options 확장 (기반)
2. Step 2 → Chart 데이터 모듈 (핵심 로직)
3. Step 3 → SVG 렌더러 (시각화)
4. Step 4 → 이벤트 핸들러 (인터랙션)
5. Step 5 → grid_component 이벤트 라우팅
6. Step 6 → 툴바 버튼
7. Step 7 → 차트 패널 렌더링
8. Step 8 → CSS 스타일
9. Step 9 → CSS import + 데모 연동
10. Step 10 → 테스트
