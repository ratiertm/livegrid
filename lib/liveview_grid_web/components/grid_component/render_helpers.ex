defmodule LiveviewGridWeb.GridComponent.RenderHelpers do
  @moduledoc """
  GridComponent 렌더링 헬퍼 함수 모듈.

  GridComponent에서 `import`하여 HEEx 템플릿과 렌더링 로직에서 사용합니다.
  """

  use Phoenix.Component

  alias LiveViewGrid.{Grid, Formatter, Pagination}

  # ── Column Width / Style ──

  def column_width_style(%{width: :auto}), do: "flex: 1"
  def column_width_style(%{width: width}), do: "width: #{width}px; flex: 0 0 #{width}px"

  # column_widths state에서 리사이즈된 너비 우선 적용
  def column_width_style(column, grid) do
    case Map.get(grid.state.column_widths, column.field) do
      nil -> column_width_style(column)
      w -> "width: #{w}px; flex: 0 0 #{w}px"
    end
  end

  # ── Frozen Column ──

  def frozen_style(col_idx, grid) do
    frozen_count = grid.options.frozen_columns
    if frozen_count > 0 and col_idx < frozen_count do
      row_num_w = if(grid.options.show_row_number, do: 50, else: 0)
      status_w = if(grid.state.show_status_column, do: 60, else: 0)
      base_offset = 90 + row_num_w + status_w
      display_cols = Grid.display_columns(grid)
      prev_width = display_cols
        |> Enum.take(col_idx)
        |> Enum.reduce(0, fn col, acc ->
          w = Map.get(grid.state.column_widths, col.field) || col.width
          case w do
            :auto -> acc + 150
            w when is_integer(w) -> acc + w
          end
        end)
      left = base_offset + prev_width
      "position: sticky; left: #{left}px; z-index: 2; background: inherit;"
    else
      ""
    end
  end

  def frozen_class(col_idx, grid) do
    frozen_count = grid.options.frozen_columns
    if frozen_count > 0 and col_idx < frozen_count do
      "lv-grid__cell--frozen"
    else
      ""
    end
  end

  # ── Multi-level Header (F-910) ──

  def has_header_groups?(columns) do
    Enum.any?(columns, fn col -> col.header_group != nil end)
  end

  def build_header_groups(columns, grid) do
    columns
    |> Enum.with_index()
    |> Enum.chunk_by(fn {col, _idx} -> col.header_group end)
    |> Enum.map(fn chunk ->
      {first_col, _} = hd(chunk)
      group = first_col.header_group
      col_indices = Enum.map(chunk, fn {_, idx} -> idx end)
      widths = Enum.map(chunk, fn {col, _} ->
        case Map.get(grid.state.column_widths, col.field) do
          nil -> col.width
          w -> w
        end
      end)
      has_auto = Enum.any?(widths, &(&1 == :auto))
      total_px = widths |> Enum.reject(&(&1 == :auto)) |> Enum.sum()
      auto_count = Enum.count(widths, &(&1 == :auto))
      %{
        label: group,
        span: length(chunk),
        col_indices: col_indices,
        has_auto: has_auto,
        total_px: total_px,
        auto_count: auto_count
      }
    end)
  end

  def header_group_style(%{has_auto: true, total_px: 0, auto_count: n}) do
    "flex: #{n}"
  end
  def header_group_style(%{has_auto: true, total_px: px, auto_count: n}) do
    "flex: #{n} 0 #{px}px"
  end
  def header_group_style(%{has_auto: false, total_px: px}) do
    "width: #{px}px; flex: 0 0 #{px}px"
  end

  # ── Row Number (F-902) ──

  def row_number_offset(grid) do
    (grid.state.pagination.current_page - 1) * grid.options.page_size
  end

  def with_row_numbers(rows, offset) do
    {result, _} = Enum.reduce(rows, {[], 0}, fn row, {acc, data_idx} ->
      if Map.get(row, :_row_type) == :group_header do
        {[{row, nil} | acc], data_idx}
      else
        {[{row, offset + data_idx + 1} | acc], data_idx + 1}
      end
    end)
    Enum.reverse(result)
  end

  # ── Sort ──

  def sort_active?(nil, _field), do: false
  def sort_active?(%{field: sort_field}, field), do: sort_field == field

  def sort_icon(:asc), do: "▲"
  def sort_icon(:desc), do: "▼"

  def next_direction(nil, _field), do: "asc"
  def next_direction(%{field: sort_field, direction: :asc}, field) when sort_field == field, do: "desc"
  def next_direction(%{field: sort_field, direction: :desc}, field) when sort_field == field, do: "asc"
  def next_direction(_sort, _field), do: "asc"

  # ── Filter ──

  def has_filterable_columns?(columns) do
    Enum.any?(columns, & &1.filterable)
  end

  def filter_placeholder(%{filter_type: :number}), do: "예: >30, <=25"
  def filter_placeholder(%{filter_type: :date}), do: "날짜 선택"
  def filter_placeholder(_column), do: "검색..."

  def parse_date_part(nil, _part), do: ""
  def parse_date_part("", _part), do: ""
  def parse_date_part(value, part) when is_binary(value) do
    case String.split(value, "~", parts: 2) do
      [from, to] -> if part == :from, do: from, else: to
      _ -> ""
    end
  end
  def parse_date_part(_, _), do: ""

  def get_column_filter_type(columns, field) do
    case Enum.find(columns, fn c -> c.field == field end) do
      nil -> :text
      col -> Map.get(col, :filter_type, :text)
    end
  end

  # ── Tree ──

  def tree_indent_style(%{_tree_depth: depth}, 0) when depth > 0 do
    "padding-left: #{16 + depth * 24}px;"
  end
  def tree_indent_style(_row, _col_idx), do: ""

  # ── Formatting ──

  def format_agg_value(nil), do: "-"
  def format_agg_value(value) when is_number(value), do: Formatter.format(value, :number)
  def format_agg_value(value), do: to_string(value)

  # ── Editing State ──

  def editing?(nil, _row_id, _field), do: false
  def editing?(%{row_id: rid, field: f}, row_id, field), do: rid == row_id and f == field

  def has_editable_columns?(columns) do
    Enum.any?(columns, & &1.editable)
  end

  # ── Cell Value Parsing ──

  def parse_cell_value(value, column) do
    cond do
      column && column.editor_type == :number ->
        case Float.parse(value) do
          {num, ""} -> if num == trunc(num), do: trunc(num), else: num
          {num, _} -> if num == trunc(num), do: trunc(num), else: num
          :error -> value
        end
      column && (column.editor_type == :date || column.filter_type == :date) ->
        parse_date_value(value)
      true ->
        value
    end
  end

  def editor_input_type(%{editor_type: :number}), do: "number"
  def editor_input_type(%{editor_type: :date}), do: "date"
  def editor_input_type(%{filter_type: :date}), do: "date"
  def editor_input_type(_column), do: "text"

  def format_date_for_input(%Date{} = d), do: Date.to_iso8601(d)
  def format_date_for_input(%DateTime{} = dt), do: dt |> DateTime.to_date() |> Date.to_iso8601()
  def format_date_for_input(%NaiveDateTime{} = dt), do: dt |> NaiveDateTime.to_date() |> Date.to_iso8601()
  def format_date_for_input(val) when is_binary(val), do: val
  def format_date_for_input(nil), do: ""
  def format_date_for_input(_), do: ""

  def parse_date_value(""), do: nil
  def parse_date_value(nil), do: nil
  def parse_date_value(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> value
    end
  end
  def parse_date_value(value), do: value

  # ── Status Badge ──

  def render_status_badge(:normal), do: ""
  def render_status_badge(:new) do
    Phoenix.HTML.raw(~s(<span class="lv-grid__status-badge lv-grid__status-badge--new">N</span>))
  end
  def render_status_badge(:updated) do
    Phoenix.HTML.raw(~s(<span class="lv-grid__status-badge lv-grid__status-badge--updated">U</span>))
  end
  def render_status_badge(:deleted) do
    Phoenix.HTML.raw(~s(<span class="lv-grid__status-badge lv-grid__status-badge--deleted">D</span>))
  end

  # ── Cell Rendering ──

  def render_cell(assigns, row, column) do
    if column.editor_type == :checkbox do
      checked = Map.get(row, column.field) == true
      assigns = assign(assigns, row: row, column: column, checked: checked)
      ~H"""
      <div class="lv-grid__cell-checkbox">
        <input
          type="checkbox"
          checked={@checked}
          phx-click="cell_checkbox_toggle"
          phx-value-row-id={@row.id}
          phx-value-field={@column.field}
          phx-target={@myself}
          style="width: 18px; height: 18px; cursor: pointer;"
          {unless @column.editable, do: [disabled: true], else: []}
        />
      </div>
      """
    else
      cell_editing = editing?(assigns.grid.state.editing, row.id, column.field)
      row_editing = assigns.grid.state.editing_row == row.id
      is_editing = column.editable && (cell_editing || row_editing)
      row_edit = row_editing && !cell_editing

      if is_editing do
        render_editor(assigns, row, column, row_edit)
      else
        cell_error = Grid.cell_error(assigns.grid, row.id, column.field)

        if column.renderer do
          render_with_renderer(assigns, row, column, cell_error)
        else
          render_plain(assigns, row, column, cell_error)
        end
      end
    end
  end

  defp render_editor(assigns, row, column, row_edit) do
    if column.editor_type == :select do
      assigns = assign(assigns, row: row, column: column, row_edit: row_edit)
      ~H"""
      <select
        phx-value-row-id={@row.id}
        phx-value-field={@column.field}
        phx-target={@myself}
        class="lv-grid__cell-editor"
        id={"editor-#{@row.id}-#{@column.field}"}
        phx-hook="CellEditor"
        data-row-edit={if @row_edit, do: "true"}
        data-field={to_string(@column.field)}
      >
        <%= for {label, value} <- @column.editor_options do %>
          <option value={value} selected={value == to_string(Map.get(@row, @column.field))}>
            <%= label %>
          </option>
        <% end %>
      </select>
      """
    else
      input_type = editor_input_type(column)

      if input_type == "date" do
        render_date_editor(assigns, row, column, row_edit)
      else
        pattern_source = if column.input_pattern, do: Regex.source(column.input_pattern), else: nil
        assigns = assign(assigns, row: row, column: column, pattern_source: pattern_source, row_edit: row_edit)
        ~H"""
        <input
          type={editor_input_type(@column)}
          value={Map.get(@row, @column.field)}
          phx-blur={unless @row_edit, do: "cell_edit_save"}
          phx-keyup={unless @row_edit, do: "cell_keydown"}
          phx-value-row-id={@row.id}
          phx-value-field={@column.field}
          phx-target={@myself}
          class="lv-grid__cell-editor"
          id={"editor-#{@row.id}-#{@column.field}"}
          phx-hook="CellEditor"
          data-input-pattern={@pattern_source}
          data-row-edit={if @row_edit, do: "true"}
          data-field={to_string(@column.field)}
        />
        """
      end
    end
  end

  defp render_date_editor(assigns, row, column, row_edit) do
    cell_val = Map.get(row, column.field)
    date_str = format_date_for_input(cell_val)
    assigns = assign(assigns, row: row, column: column, date_value: date_str, row_edit: row_edit)

    if row_edit do
      ~H"""
      <input
        type="date"
        value={@date_value}
        phx-target={@myself}
        class="lv-grid__cell-editor"
        id={"editor-#{@row.id}-#{@column.field}"}
        phx-hook="CellEditor"
        data-row-edit="true"
        data-field={to_string(@column.field)}
      />
      """
    else
      ~H"""
      <form phx-change="cell_edit_date" phx-target={@myself} style="display: contents;">
        <input type="hidden" name="row-id" value={@row.id} />
        <input type="hidden" name="field" value={@column.field} />
        <input
          type="date"
          name="value"
          value={@date_value}
          phx-blur="cell_edit_save"
          phx-value-row-id={@row.id}
          phx-value-field={@column.field}
          phx-target={@myself}
          class="lv-grid__cell-editor"
          id={"editor-#{@row.id}-#{@column.field}"}
          phx-hook="CellEditor"
        />
      </form>
      """
    end
  end

  def render_with_renderer(assigns, row, column, cell_error) do
    rendered_content =
      try do
        column.renderer.(row, column, assigns)
      rescue
        _ -> Phoenix.HTML.raw(to_string(Map.get(row, column.field)))
      end

    cell_style = evaluate_style_expr(column, row)
    assigns = assign(assigns, row: row, column: column, cell_error: cell_error, rendered_content: rendered_content, cell_style: cell_style)

    ~H"""
    <div class={"lv-grid__cell-wrapper #{if @cell_error, do: "lv-grid__cell-wrapper--error"}"} style={@cell_style}>
      <span
        class={"lv-grid__cell-value #{if @column.editable, do: "lv-grid__cell-value--editable"} #{if @cell_error, do: "lv-grid__cell-value--error"}"}
        id={if @column.editable, do: "cell-#{@row.id}-#{@column.field}"}
        phx-hook={if @column.editable, do: "CellEditable"}
        data-row-id={@row.id}
        data-field={@column.field}
        phx-target={@myself}
        title={@cell_error}
      >
        <%= @rendered_content %>
        <%= if @cell_error do %>
          <span class="lv-grid__cell-error-icon">!</span>
        <% end %>
      </span>
      <%= if @cell_error do %>
        <span class="lv-grid__cell-error-msg"><%= @cell_error %></span>
      <% end %>
    </div>
    """
  end

  def render_plain(assigns, row, column, cell_error) do
    raw_value = Map.get(row, column.field)
    formatted_value = Formatter.format(raw_value, column.formatter)
    cell_style = evaluate_style_expr(column, row)
    assigns = assign(assigns, row: row, column: column, cell_error: cell_error, formatted_value: formatted_value, cell_style: cell_style)

    ~H"""
    <div class={"lv-grid__cell-wrapper #{if @cell_error, do: "lv-grid__cell-wrapper--error"}"} style={@cell_style}>
      <span
        class={"lv-grid__cell-value #{if @column.editable, do: "lv-grid__cell-value--editable"} #{if @cell_error, do: "lv-grid__cell-value--error"}"}
        id={if @column.editable, do: "cell-#{@row.id}-#{@column.field}"}
        phx-hook={if @column.editable, do: "CellEditable"}
        data-row-id={@row.id}
        data-field={@column.field}
        phx-target={@myself}
        title={@cell_error}
      >
        <%= @formatted_value %>
        <%= if @cell_error do %>
          <span class="lv-grid__cell-error-icon">!</span>
        <% end %>
      </span>
      <%= if @cell_error do %>
        <span class="lv-grid__cell-error-msg"><%= @cell_error %></span>
      <% end %>
    </div>
    """
  end

  # ── Conditional Cell Style (F-901) ──

  def evaluate_style_expr(%{style_expr: nil}, _row), do: nil
  def evaluate_style_expr(%{style_expr: expr}, row) when is_function(expr, 1) do
    try do
      case expr.(row) do
        nil -> nil
        styles when is_map(styles) -> style_map_to_css(styles)
        css when is_binary(css) -> css
      end
    rescue
      _ -> nil
    end
  end
  def evaluate_style_expr(%{style_expr: expr} = column, row) when is_function(expr, 2) do
    try do
      case expr.(row, column) do
        nil -> nil
        styles when is_map(styles) -> style_map_to_css(styles)
        css when is_binary(css) -> css
      end
    rescue
      _ -> nil
    end
  end
  def evaluate_style_expr(_, _), do: nil

  def style_map_to_css(styles) do
    styles
    |> Enum.map(fn
      {:background, v} -> "background-color: #{v}"
      {:bg, v} -> "background-color: #{v}"
      {:color, v} -> "color: #{v}"
      {:font_weight, v} -> "font-weight: #{v}"
      {:font_style, v} -> "font-style: #{v}"
      {k, v} -> "#{String.replace(to_string(k), "_", "-")}: #{v}"
    end)
    |> Enum.join("; ")
  end

  # ── Pagination ──

  def page_range_for(total_rows, current_page, page_size) do
    total = Pagination.total_pages(total_rows, page_size)

    if total == 0 do
      1..1
    else
      start = max(1, current_page - 2)
      finish = min(total, current_page + 2)
      start..finish
    end
  end

  # ── CSS Variables ──

  def build_custom_css_vars(nil), do: nil
  def build_custom_css_vars(vars) when is_map(vars) and map_size(vars) == 0, do: nil
  def build_custom_css_vars(vars) when is_map(vars) do
    vars
    |> Enum.map(fn {key, value} -> "#{key}: #{value}" end)
    |> Enum.join("; ")
  end

  # ── F-940: Cell Range Selection ──

  @doc """
  셀이 선택 범위 안에 있는지 확인합니다.
  row_id_to_pos는 %{row_id => position_index} 맵입니다.
  """
  @spec cell_in_range?(map() | nil, any(), integer(), map()) :: boolean()
  def cell_in_range?(nil, _row_id, _col_idx, _row_id_to_pos), do: false

  def cell_in_range?(range, row_id, col_idx, row_id_to_pos) do
    with {:ok, anchor_pos} <- Map.fetch(row_id_to_pos, range.anchor_row_id),
         {:ok, extent_pos} <- Map.fetch(row_id_to_pos, range.extent_row_id),
         {:ok, row_pos} <- Map.fetch(row_id_to_pos, row_id) do
      min_row = min(anchor_pos, extent_pos)
      max_row = max(anchor_pos, extent_pos)
      min_col = min(range.anchor_col_idx, range.extent_col_idx)
      max_col = max(range.anchor_col_idx, range.extent_col_idx)
      row_pos >= min_row and row_pos <= max_row and col_idx >= min_col and col_idx <= max_col
    else
      _ -> false
    end
  end
end
