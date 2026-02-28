defmodule LiveviewGridWeb.GridComponent.RenderHelpers do
  @moduledoc """
  GridComponent 렌더링 헬퍼 함수 모듈.

  GridComponent에서 `import`하여 HEEx 템플릿과 렌더링 로직에서 사용합니다.
  컬럼 스타일, 정렬, 필터, 편집, 셀 렌더링 등 UI 관련 유틸리티를 제공합니다.
  """

  use Phoenix.Component

  alias LiveViewGrid.{Grid, Formatter, Pagination}

  # ── Column Width / Style ──

  @doc """
  컬럼 정의의 width 값에 따라 CSS 스타일 문자열을 반환한다. `:auto`이면 flex, 고정값이면 px 단위.
  """
  @spec column_width_style(column :: map()) :: String.t()
  def column_width_style(%{width: :auto}), do: "flex: 1"
  def column_width_style(%{width: width}), do: "width: #{width}px; flex: 0 0 #{width}px"

  @doc """
  그리드 상태의 리사이즈된 너비를 우선 적용하여 컬럼 스타일을 반환한다.
  """
  @spec column_width_style(column :: map(), grid :: map()) :: String.t()
  def column_width_style(column, grid) do
    case Map.get(grid.state.column_widths, column.field) do
      nil -> column_width_style(column)
      w -> "width: #{w}px; flex: 0 0 #{w}px"
    end
  end

  # ── Frozen Column ──

  @doc """
  고정 컬럼의 sticky 위치 스타일을 계산한다. 고정 범위 밖이면 빈 문자열을 반환한다.
  """
  @spec frozen_style(col_idx :: non_neg_integer(), grid :: map()) :: String.t()
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

  @doc """
  고정 컬럼이면 CSS 클래스를 반환한다.
  """
  @spec frozen_class(col_idx :: non_neg_integer(), grid :: map()) :: String.t()
  def frozen_class(col_idx, grid) do
    frozen_count = grid.options.frozen_columns
    if frozen_count > 0 and col_idx < frozen_count do
      "lv-grid__cell--frozen"
    else
      ""
    end
  end

  # ── Multi-level Header (F-910) ──

  @doc """
  컬럼 목록에 header_group이 설정된 컬럼이 있는지 확인한다.
  """
  @spec has_header_groups?(columns :: [map()]) :: boolean()
  def has_header_groups?(columns) do
    Enum.any?(columns, fn col -> col.header_group != nil end)
  end

  @doc """
  컬럼들을 header_group 기준으로 묶어 멀티레벨 헤더 그룹 리스트를 생성한다.
  """
  @spec build_header_groups(columns :: [map()], grid :: map()) :: [map()]
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

  @doc """
  헤더 그룹의 너비 스타일을 반환한다. auto/fixed 조합에 따라 flex 또는 px 스타일을 생성한다.
  """
  @spec header_group_style(group :: map()) :: String.t()
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

  @doc """
  현재 페이지의 행 번호 시작 오프셋을 계산한다.
  """
  @spec row_number_offset(grid :: map()) :: non_neg_integer()
  def row_number_offset(grid) do
    (grid.state.pagination.current_page - 1) * grid.options.page_size
  end

  @doc """
  행 목록에 행 번호를 부여한다. 그룹 헤더 행은 nil 번호를 받는다.
  """
  @spec with_row_numbers(rows :: [map()], offset :: non_neg_integer()) ::
          [{map(), non_neg_integer() | nil}]
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

  @doc """
  현재 정렬 상태에서 해당 필드가 정렬 활성화 상태인지 확인한다.
  """
  @spec sort_active?(sort :: map() | nil, field :: atom()) :: boolean()
  def sort_active?(nil, _field), do: false
  def sort_active?(%{field: sort_field}, field), do: sort_field == field

  @doc """
  정렬 방향에 해당하는 아이콘 문자를 반환한다.
  """
  @spec sort_icon(direction :: :asc | :desc) :: String.t()
  def sort_icon(:asc), do: "▲"
  def sort_icon(:desc), do: "▼"

  @doc """
  다음 클릭 시 적용할 정렬 방향을 계산한다. 현재 asc이면 desc, desc이면 asc.
  """
  @spec next_direction(sort :: map() | nil, field :: atom()) :: String.t()
  def next_direction(nil, _field), do: "asc"
  def next_direction(%{field: sort_field, direction: :asc}, field) when sort_field == field, do: "desc"
  def next_direction(%{field: sort_field, direction: :desc}, field) when sort_field == field, do: "asc"
  def next_direction(_sort, _field), do: "asc"

  # ── Filter ──

  @doc """
  컬럼 목록에 필터 가능한 컬럼이 있는지 확인한다.
  """
  @spec has_filterable_columns?(columns :: [map()]) :: boolean()
  def has_filterable_columns?(columns) do
    Enum.any?(columns, & &1.filterable)
  end

  @doc """
  컬럼 필터 타입에 맞는 placeholder 텍스트를 반환한다.
  """
  @spec filter_placeholder(column :: map()) :: String.t()
  def filter_placeholder(%{filter_type: :number}), do: "예: >30, <=25"
  def filter_placeholder(%{filter_type: :date}), do: "날짜 선택"
  def filter_placeholder(_column), do: "검색..."

  @doc """
  날짜 범위 필터 값에서 from 또는 to 부분을 추출한다. `~`로 구분된 문자열을 파싱한다.
  """
  @spec parse_date_part(value :: String.t() | nil, part :: :from | :to) :: String.t()
  def parse_date_part(nil, _part), do: ""
  def parse_date_part("", _part), do: ""
  def parse_date_part(value, part) when is_binary(value) do
    case String.split(value, "~", parts: 2) do
      [from, to] -> if part == :from, do: from, else: to
      _ -> ""
    end
  end
  def parse_date_part(_, _), do: ""

  @doc """
  컬럼 목록에서 특정 필드의 필터 타입을 조회한다. 없으면 :text를 반환한다.
  """
  @spec get_column_filter_type(columns :: [map()], field :: atom()) :: atom()
  def get_column_filter_type(columns, field) do
    case Enum.find(columns, fn c -> c.field == field end) do
      nil -> :text
      col -> Map.get(col, :filter_type, :text)
    end
  end

  # ── Tree ──

  @doc """
  트리 구조의 들여쓰기 스타일을 반환한다. 첫 번째 컬럼에만 적용된다.
  """
  @spec tree_indent_style(row :: map(), col_idx :: non_neg_integer()) :: String.t()
  def tree_indent_style(%{_tree_depth: depth}, 0) when depth > 0 do
    "padding-left: #{16 + depth * 24}px;"
  end
  def tree_indent_style(_row, _col_idx), do: ""

  # ── Formatting ──

  @doc """
  집계 값을 포맷한다. nil이면 \"-\", 숫자이면 천 단위 구분 포맷을 적용한다.
  """
  @spec format_agg_value(value :: any()) :: String.t()
  def format_agg_value(nil), do: "-"
  def format_agg_value(value) when is_number(value), do: Formatter.format(value, :number)
  def format_agg_value(value), do: to_string(value)

  # ── Editing State ──

  @doc """
  현재 편집 중인 셀이 지정된 row_id와 field와 일치하는지 확인한다.
  """
  @spec editing?(editing :: map() | nil, row_id :: integer(), field :: atom()) :: boolean()
  def editing?(nil, _row_id, _field), do: false
  def editing?(%{row_id: rid, field: f}, row_id, field), do: rid == row_id and f == field

  @doc """
  컬럼 목록에 편집 가능한 컬럼이 있는지 확인한다.
  """
  @spec has_editable_columns?(columns :: [map()]) :: boolean()
  def has_editable_columns?(columns) do
    Enum.any?(columns, & &1.editable)
  end

  # ── Cell Value Parsing ──

  @doc """
  셀 값을 컬럼 타입에 맞게 파싱한다. 숫자/날짜 타입은 자동 변환한다.
  """
  @spec parse_cell_value(value :: any(), column :: map() | nil) :: any()
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

  @doc """
  컬럼 에디터 타입에 맞는 HTML input type을 반환한다.
  """
  @spec editor_input_type(column :: map()) :: String.t()
  def editor_input_type(%{editor_type: :number}), do: "number"
  def editor_input_type(%{editor_type: :date}), do: "date"
  def editor_input_type(%{filter_type: :date}), do: "date"
  def editor_input_type(_column), do: "text"

  @doc """
  날짜 값을 HTML date input용 ISO 8601 문자열로 변환한다.
  """
  @spec format_date_for_input(value :: Date.t() | DateTime.t() | NaiveDateTime.t() | String.t() | nil) ::
          String.t()
  def format_date_for_input(%Date{} = d), do: Date.to_iso8601(d)
  def format_date_for_input(%DateTime{} = dt), do: dt |> DateTime.to_date() |> Date.to_iso8601()
  def format_date_for_input(%NaiveDateTime{} = dt), do: dt |> NaiveDateTime.to_date() |> Date.to_iso8601()
  def format_date_for_input(val) when is_binary(val), do: val
  def format_date_for_input(nil), do: ""
  def format_date_for_input(_), do: ""

  @doc """
  ISO 8601 문자열을 Date 구조체로 파싱한다. 빈 값이면 nil, 파싱 실패 시 원본 반환.
  """
  @spec parse_date_value(value :: String.t() | nil | any()) :: Date.t() | nil | any()
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

  @doc """
  행 상태에 맞는 배지 HTML을 반환한다. :normal이면 빈 문자열, :new/:updated/:deleted이면 배지 렌더링.
  """
  @spec render_status_badge(status :: atom()) :: Phoenix.HTML.safe() | String.t()
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

  @doc """
  셀을 렌더링한다. 컬럼 타입(checkbox/select/text)과 편집 상태에 따라 적절한 렌더링 함수에 위임한다.
  """
  @spec render_cell(assigns :: map(), row :: map(), column :: map()) :: Phoenix.LiveView.Rendered.t()
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

  @doc """
  커스텀 렌더러가 있는 셀을 렌더링한다. 렌더러 실행 오류 시 원시 값으로 폴백한다.
  """
  @spec render_with_renderer(assigns :: map(), row :: map(), column :: map(), cell_error :: String.t() | nil) ::
          Phoenix.LiveView.Rendered.t()
  def render_with_renderer(assigns, row, column, cell_error) do
    rendered_content =
      try do
        column.renderer.(row, column, assigns)
      rescue
        _ -> Phoenix.HTML.raw(to_string(Map.get(row, column.field)))
      end

    cell_style = evaluate_style_expr(column, row)
    cell_align = align_class(column)
    assigns = assign(assigns, row: row, column: column, cell_error: cell_error, rendered_content: rendered_content, cell_style: cell_style, cell_align: cell_align)

    ~H"""
    <div class={"lv-grid__cell-wrapper #{@cell_align} #{if @cell_error, do: "lv-grid__cell-wrapper--error"}"} style={@cell_style}>
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

  @doc """
  기본(plain) 셀을 렌더링한다. Formatter를 통해 값을 포맷하고, 조건부 스타일과 오류를 표시한다.
  """
  @spec render_plain(assigns :: map(), row :: map(), column :: map(), cell_error :: String.t() | nil) ::
          Phoenix.LiveView.Rendered.t()
  def render_plain(assigns, row, column, cell_error) do
    raw_value = Map.get(row, column.field)
    formatted_value = Formatter.format(raw_value, column.formatter)
    cell_style = evaluate_style_expr(column, row)
    cell_align = align_class(column)
    assigns = assign(assigns, row: row, column: column, cell_error: cell_error, formatted_value: formatted_value, cell_style: cell_style, cell_align: cell_align)

    ~H"""
    <div class={"lv-grid__cell-wrapper #{@cell_align} #{if @cell_error, do: "lv-grid__cell-wrapper--error"}"} style={@cell_style}>
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

  # ── Cell Alignment ──

  defp align_class(%{align: :center}), do: "lv-grid__cell--align-center"
  defp align_class(%{align: :right}), do: "lv-grid__cell--align-right"
  defp align_class(_), do: ""

  # ── Conditional Cell Style (F-901) ──

  @doc """
  컬럼의 style_expr 함수를 평가하여 조건부 CSS 스타일을 반환한다. 1인자/2인자 함수를 모두 지원한다.
  """
  @spec evaluate_style_expr(column :: map(), row :: map()) :: String.t() | nil
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

  @doc """
  스타일 맵(%{background: "#fff", color: "red"})을 CSS 문자열로 변환한다.
  """
  @spec style_map_to_css(styles :: map()) :: String.t()
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

  @doc """
  현재 페이지 주변의 표시할 페이지 범위를 계산한다. 현재 페이지 +/- 2 범위.
  """
  @spec page_range_for(total_rows :: non_neg_integer(), current_page :: pos_integer(), page_size :: pos_integer()) ::
          Range.t()
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

  @doc """
  커스텀 CSS 변수 맵을 인라인 스타일 문자열로 변환한다.
  """
  @spec build_custom_css_vars(vars :: map() | nil) :: String.t() | nil
  def build_custom_css_vars(nil), do: nil
  def build_custom_css_vars(vars) when is_map(vars) and map_size(vars) == 0, do: nil
  def build_custom_css_vars(vars) when is_map(vars) do
    vars
    |> Enum.map(fn {key, value} -> "#{key}: #{value}" end)
    |> Enum.join("; ")
  end

  # ── F-941: Summary Number Formatting ──

  @doc """
  요약(Summary) 패널의 숫자를 포맷한다. nil이면 \"-\", float이면 소수점 2자리까지 반올림.
  """
  @spec format_summary_number(value :: number() | nil) :: String.t()
  def format_summary_number(nil), do: "-"
  def format_summary_number(value) when is_integer(value), do: Formatter.format(value, :number)
  def format_summary_number(value) when is_float(value) do
    value
    |> Float.round(2)
    |> Formatter.format(:number)
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
