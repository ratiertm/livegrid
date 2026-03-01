defmodule LiveViewGrid.Grid do
  @moduledoc """
  Grid 인스턴스 생성 및 관리.

  `LiveViewGrid.Grid`는 그리드의 데이터, 컬럼, 상태(state), 옵션을 하나의 맵으로 관리합니다.
  Phoenix LiveView의 `assign`에 저장하고, 이벤트 핸들러에서 상태를 업데이트하는 방식으로 동작합니다.

  ## 기능 요약

  - **정렬/필터/페이지네이션** - InMemory 파이프라인 또는 DataSource 위임
  - **CRUD** - `add_row/3`, `update_cell/4`, `delete_rows/2` + 행 상태 추적
  - **셀 검증** - `validate_cell/3` + validators 체인
  - **Virtual Scroll** - 대용량 데이터 대응 (viewport 기반 부분 렌더링)
  - **컬럼 리사이즈/리오더** - `resize_column/3`, `reorder_columns/2`
  - **Grouping** - 다중 필드 그룹핑 + 집계 (sum, avg, count, min, max)
  - **Tree Grid** - 계층 데이터 + expand/collapse
  - **Pivot Table** - 행/열 차원 + 동적 컬럼 생성

  ## 기본 사용법

      grid = Grid.new(
        data: users,
        columns: [
          %{field: :name, label: "이름", sortable: true, editable: true,
            validators: [{:required, "필수 입력"}]},
          %{field: :salary, label: "급여", formatter: :currency, align: :right}
        ],
        options: %{page_size: 20, theme: "default"}
      )

  ## DataSource 연동

      # Ecto (DB)
      grid = Grid.new(
        columns: columns,
        data_source: {LiveViewGrid.DataSource.Ecto,
          %{repo: MyApp.Repo, query: from(u in User)}}
      )

      # REST API
      grid = Grid.new(
        columns: columns,
        data_source: {LiveViewGrid.DataSource.Rest,
          %{base_url: "https://api.example.com/users"}}
      )

  ## CRUD 워크플로우

      grid
      |> Grid.add_row(%{name: "", email: ""})           # :new 상태
      |> Grid.update_cell(row_id, :name, "Alice")       # :updated 상태
      |> Grid.validate_cell(row_id, :name)              # 검증 실행
      |> Grid.delete_rows([row_id])                     # :deleted 마킹

      Grid.changed_rows(grid)  # => [%{row: %{...}, status: :updated}, ...]

  ## Grouping

      grid
      |> Grid.set_group_by([:department, :team])
      |> Grid.set_group_aggregates(%{salary: :sum, age: :avg})

  ## Tree Grid

      Grid.set_tree_mode(grid, true, :parent_id)

  ## Pivot Table

      Grid.pivot_transform(grid, %{
        row_fields: [:department],
        col_field: :quarter,
        value_field: :revenue,
        aggregate: :sum
      })
  """

  alias LiveViewGrid.{GridDefinition, Grouping, Tree, Pivot}

  @max_edit_history 50

  @type t :: %{
    id: String.t(),
    data: list(map()),
    columns: list(map()),
    definition: GridDefinition.t() | nil,
    state: map(),
    options: map(),
    data_source: {module(), map()} | nil
  }

  @doc """
  Grid 생성
  
  ## Examples
  
      iex> Grid.new(
      ...>   data: [%{id: 1, name: "Alice"}],
      ...>   columns: [%{field: :name, label: "이름"}]
      ...> )
      %{id: "grid_...", data: [...], ...}
  """
  @spec new(opts :: keyword()) :: t()
  def new(opts) do
    data = Keyword.get(opts, :data, [])
    columns = Keyword.fetch!(opts, :columns)
    options = Keyword.get(opts, :options, %{})
    id = Keyword.get(opts, :id, generate_id())
    data_source = Keyword.get(opts, :data_source, nil)

    normalized_columns = normalize_columns(columns)

    # Definition: 원본 컬럼 + 옵션 보존 (Blueprint)
    definition = GridDefinition.new(columns, options)

    grid = %{
      id: id,
      data: data,
      columns: normalized_columns,
      definition: definition,
      state: initial_state(),
      options: merge_default_options(options),
      data_source: data_source
    }

    # data_source가 설정된 경우 초기 데이터를 fetch
    if data_source do
      refresh_from_source(grid)
    else
      grid
    end
  end

  @doc """
  DataSource에서 데이터를 다시 가져와 Grid를 갱신합니다.
  data_source가 nil이면 그대로 반환합니다.
  """
  @spec refresh_from_source(grid :: t()) :: t()
  def refresh_from_source(%{data_source: nil} = grid), do: grid
  def refresh_from_source(%{data_source: {module, config}} = grid) do
    {rows, total_count, _filtered_count} =
      module.fetch_data(config, grid.state, grid.options, grid.columns)

    %{grid | data: rows}
    |> put_in([:state, :pagination, :total_rows], total_count)
  end

  @doc """
  기존 Grid의 state를 보존하면서 data/columns/options만 갱신.
  LiveComponent의 update/2에서 부모 재렌더링 시 사용.
  """
  @spec update_data(grid :: t(), data :: list(map()), columns :: list(map()), options :: map()) :: t()
  def update_data(grid, data, columns, options) do
    # 기존 state에 누락된 키를 initial_state 기본값으로 보충
    # (hot-reload 시 이전 state에 새 키가 없을 수 있음)
    merged_state = Map.merge(initial_state(), grid.state)

    # data_source 보존 (기존 grid에 있으면 유지)
    data_source = Map.get(grid, :data_source)

    updated = %{grid |
      data: data,
      columns: normalize_columns(columns),
      options: merge_default_options(options),
      state: merged_state
    }
    |> Map.put(:data_source, data_source)
    |> Map.put(:definition, Map.get(grid, :definition))

    # data_source가 있으면 total_rows를 length(data)로 덮어쓰지 않음
    # (data_source 모드에서 data는 빈 리스트이므로 0이 되어 페이지네이션이 사라짐)
    if data_source do
      updated
    else
      put_in(updated, [:state, :pagination, :total_rows], length(data))
    end
  end

  @doc """
  컬럼 너비를 업데이트합니다. 최소 50px.
  """
  @spec resize_column(grid :: t(), field :: atom(), width :: pos_integer()) :: t()
  def resize_column(grid, field, width) when is_atom(field) and is_integer(width) and width >= 50 do
    put_in(grid.state.column_widths, Map.put(grid.state.column_widths, field, width))
  end

  @doc """
  컬럼 표시 순서를 변경합니다. order는 field atom 리스트.
  """
  @spec reorder_columns(grid :: t(), order :: list(atom())) :: t()
  def reorder_columns(grid, order) when is_list(order) do
    put_in(grid.state.column_order, order)
  end

  # ── FA-016: Column State Save/Restore ──

  @doc """
  컬럼 상태(너비, 순서, 숨김)를 추출합니다.

  ## Returns

      %{
        column_widths: %{name: 150, email: 200},
        column_order: [:name, :email, :id],
        hidden_columns: [:age]
      }
  """
  @spec export_column_state(grid :: t()) :: map()
  def export_column_state(%{state: state}) do
    %{
      column_widths: Map.get(state, :column_widths, %{}),
      column_order: Map.get(state, :column_order),
      hidden_columns: Map.get(state, :hidden_columns, [])
    }
  end

  @doc """
  컬럼 상태를 복원합니다. 존재하는 컬럼 필드만 적용합니다.

  ## Parameters
    - grid: 대상 Grid
    - column_state: `export_column_state/1`에서 반환된 맵
  """
  @spec import_column_state(grid :: t(), column_state :: map()) :: t()
  def import_column_state(grid, column_state) when is_map(column_state) do
    valid_fields = MapSet.new(Enum.map(grid.columns, & &1.field))

    # column_widths: 존재하는 필드만
    widths = column_state
      |> Map.get(:column_widths, %{})
      |> Enum.filter(fn {field, _} -> MapSet.member?(valid_fields, field) end)
      |> Map.new()

    # column_order: 존재하는 필드만
    order = case Map.get(column_state, :column_order) do
      nil -> nil
      list when is_list(list) ->
        filtered = Enum.filter(list, &MapSet.member?(valid_fields, &1))
        if filtered == [], do: nil, else: filtered
    end

    # hidden_columns: 존재하는 필드만
    hidden = column_state
      |> Map.get(:hidden_columns, [])
      |> Enum.filter(&MapSet.member?(valid_fields, &1))

    grid
    |> put_in([:state, :column_widths], widths)
    |> put_in([:state, :column_order], order)
    |> put_in([:state, :hidden_columns], hidden)
  end

  # ── FA-002: Grid State Save/Restore ──

  @doc """
  전체 Grid 상태를 저장 가능한 형태로 추출합니다.
  """
  @spec save_state(grid :: t()) :: map()
  def save_state(grid) do
    LiveViewGrid.StatePersistence.export_state(grid)
  end

  @doc """
  저장된 상태를 Grid에 복원합니다.
  """
  @spec restore_state(grid :: t(), state_map :: map()) :: t()
  def restore_state(grid, state_map) when is_map(state_map) do
    LiveViewGrid.StatePersistence.import_state(grid, state_map)
  end

  @doc """
  표시 순서대로 컬럼을 반환합니다.
  column_order가 nil이면 원래 순서, 설정되면 해당 순서대로 반환.
  frozen 컬럼은 항상 맨 앞에 유지합니다.
  """
  @spec display_columns(grid :: t()) :: list(map())
  def display_columns(%{state: state, columns: columns} = grid) do
    hidden = Map.get(state, :hidden_columns, [])

    ordered = case state do
      %{column_order: nil} -> columns
      %{column_order: order} ->
        frozen_count = Map.get(grid.options, :frozen_columns, 0)
        frozen = Enum.take(columns, frozen_count)
        frozen_fields = MapSet.new(Enum.map(frozen, & &1.field))
        non_frozen_order = Enum.reject(order, &MapSet.member?(frozen_fields, &1))

        reordered = Enum.map(non_frozen_order, fn field ->
          Enum.find(columns, fn c -> c.field == field end)
        end)
        |> Enum.reject(&is_nil/1)

        frozen ++ reordered
    end

    # FA-010: hidden_columns 필터링
    if hidden == [] do
      ordered
    else
      hidden_set = MapSet.new(hidden)
      Enum.reject(ordered, fn col -> MapSet.member?(hidden_set, col.field) end)
    end
  end

  # ── FA-044: Find & Highlight ──

  @doc """
  모든 표시 데이터에서 검색어와 일치하는 셀 좌표를 반환합니다.
  대소문자 무시. 빈 검색어는 빈 리스트 반환.

  ## Returns

      [{row_id, field}, ...]
  """
  @spec find_matches(grid :: t(), search_text :: String.t()) :: list({integer(), atom()})
  def find_matches(_grid, ""), do: []
  def find_matches(_grid, nil), do: []
  def find_matches(grid, search_text) when is_binary(search_text) do
    downcased = String.downcase(search_text)
    cols = display_columns(grid)
    data = visible_data(grid)

    for row <- data,
        col <- cols,
        value = Map.get(row, col.field),
        value != nil,
        cell_text = to_string(value) |> String.downcase(),
        String.contains?(cell_text, downcased) do
      {Map.get(row, :id), col.field}
    end
  end

  @doc """
  화면에 표시할 데이터 (정렬 + 페이징 적용)

  data_source가 설정된 경우 adapter를 통해 데이터를 가져옵니다.
  설정되지 않은 경우 기존 InMemory 파이프라인을 사용합니다.
  """
  @spec visible_data(grid :: t()) :: list(map())
  def visible_data(%{data_source: {module, config}, state: state, options: options, columns: columns}) do
    {rows, _total, _filtered} = module.fetch_data(config, state, options, columns)
    rows
  end
  def visible_data(%{data: data, columns: columns, state: state, options: options}) do
    searched = apply_global_search(data, state.global_search, columns)
    filtered = apply_filters(searched, state.filters, columns)
    advanced = apply_advanced_filters(filtered, state.advanced_filters, columns)
    with_new = ensure_new_rows_included(advanced, data, state.row_statuses)
    sorted = apply_sort(with_new, state.sort, columns)

    # v0.7: Grouping / Tree 적용 (pagination 전에)
    structured = apply_data_structuring(sorted, state)

    # Virtual Scrolling 사용 시
    if options.virtual_scroll do
      apply_virtual_scroll(structured, state.scroll_offset, options)
    else
      apply_pagination(structured, state.pagination, options.page_size)
    end
  end

  @doc """
  Virtual Scroll용 전체 데이터 (정렬만 적용)
  """
  @spec sorted_data(grid :: t()) :: list(map())
  def sorted_data(%{data: data, columns: columns, state: state}) do
    data
    |> apply_global_search(state.global_search, columns)
    |> apply_filters(state.filters, columns)
    |> apply_advanced_filters(state.advanced_filters, columns)
    |> ensure_new_rows_included(data, state.row_statuses)
    |> apply_sort(state.sort, columns)
  end

  @doc """
  필터 적용 후 데이터 개수 (footer에 표시할 건수)

  data_source가 설정된 경우 adapter에서 filtered_count를 가져옵니다.
  """
  @spec filtered_count(grid :: t()) :: non_neg_integer()
  def filtered_count(%{data_source: {module, config}, state: state, options: options, columns: columns}) do
    {_rows, _total, filtered} = module.fetch_data(config, state, options, columns)
    filtered
  end
  def filtered_count(%{data: data, columns: columns, state: state}) do
    has_search = state.global_search != ""
    has_filters = map_size(state.filters) > 0
    has_advanced = length(Map.get(state, :advanced_filters, %{conditions: []})[:conditions] || []) > 0

    if has_search or has_filters or has_advanced do
      data
      |> apply_global_search(state.global_search, columns)
      |> apply_filters(state.filters, columns)
      |> apply_advanced_filters(Map.get(state, :advanced_filters, %{logic: :and, conditions: []}), columns)
      |> ensure_new_rows_included(data, state.row_statuses)
      |> length()
    else
      length(data)
    end
  end

  @doc """
  Summary Row 집계 결과를 반환합니다.
  컬럼에 summary가 지정된 필드만 집계합니다.
  필터/검색 적용 후 데이터 기준.

  ## Returns
    - `%{field => value}` 맵 (summary 지정 컬럼만 포함)
    - summary 지정 컬럼이 없으면 빈 맵 `%{}`
  """
  @spec summary_data(grid :: t()) :: map()
  def summary_data(%{columns: columns} = grid) do
    aggregates =
      columns
      |> Enum.filter(& &1.summary)
      |> Map.new(& {&1.field, &1.summary})

    if map_size(aggregates) == 0 do
      %{}
    else
      data = filtered_data(grid)
      Grouping.compute_aggregates(data, aggregates)
    end
  end

  # ── F-904: Cell Merge API ──

  @doc """
  셀 병합 영역을 등록합니다.

  ## Parameters
  - grid: Grid 맵
  - merge_spec: `%{row_id: any, col_field: atom, rowspan: integer, colspan: integer}`

  ## Returns
  - `{:ok, grid}` 또는 `{:error, reason}`
  """
  @spec merge_cells(grid :: t(), merge_spec :: map()) :: {:ok, t()} | {:error, String.t()}
  def merge_cells(grid, %{row_id: row_id, col_field: col_field} = spec) do
    rowspan = Map.get(spec, :rowspan, 1)
    colspan = Map.get(spec, :colspan, 1)

    if rowspan < 1 or colspan < 1 do
      {:error, "rowspan and colspan must be >= 1"}
    else
      col_fields = display_columns(grid) |> Enum.map(& &1.field)
      col_start_idx = Enum.find_index(col_fields, &(&1 == col_field))

      cond do
        is_nil(col_start_idx) ->
          {:error, "column #{col_field} not found"}

        col_start_idx + colspan > length(col_fields) ->
          {:error, "colspan exceeds column count"}

        rowspan == 1 and colspan == 1 ->
          {:error, "merge must span more than one cell"}

        has_merge_overlap?(grid, row_id, col_field, rowspan, colspan) ->
          {:error, "merge region overlaps with existing merge"}

        frozen_boundary_crossed?(grid, col_start_idx, colspan) ->
          {:error, "merge cannot cross frozen column boundary"}

        true ->
          region = %{rowspan: rowspan, colspan: colspan}
          new_regions = Map.put(grid.state.merge_regions, {row_id, col_field}, region)
          {:ok, put_in(grid.state.merge_regions, new_regions)}
      end
    end
  end

  @doc "특정 셀 병합을 해제합니다."
  @spec unmerge_cells(grid :: t(), row_id :: any(), col_field :: atom()) :: t()
  def unmerge_cells(grid, row_id, col_field) do
    new_regions = Map.delete(grid.state.merge_regions, {row_id, col_field})
    put_in(grid.state.merge_regions, new_regions)
  end

  @doc "모든 병합을 해제합니다."
  @spec clear_all_merges(grid :: t()) :: t()
  def clear_all_merges(grid) do
    put_in(grid.state.merge_regions, %{})
  end

  @doc "전체 병합 영역 목록을 반환합니다."
  @spec merge_regions(grid :: t()) :: map()
  def merge_regions(grid), do: grid.state.merge_regions

  @doc "특정 셀이 병합(원점 또는 피병합)에 포함되는지 확인합니다."
  @spec merged?(grid :: t(), row_id :: any(), col_field :: atom()) :: boolean()
  def merged?(grid, row_id, col_field) do
    Map.has_key?(grid.state.merge_regions, {row_id, col_field}) or
      merge_origin(grid, row_id, col_field) != nil
  end

  @doc """
  특정 셀이 다른 병합에 의해 가려지는 경우 원점 셀 정보를 반환합니다.
  가려지는 셀이면 `{:origin, row_id, col_field}`, 아니면 `nil`.
  """
  @spec merge_origin(grid :: t(), row_id :: any(), col_field :: atom()) :: nil | tuple()
  def merge_origin(grid, row_id, col_field) do
    skip_map = build_merge_skip_map(grid)
    Map.get(skip_map, {row_id, col_field})
  end

  @doc false
  @spec build_merge_skip_map(grid :: t()) :: map()
  def build_merge_skip_map(%{state: %{merge_regions: regions}} = _grid) when map_size(regions) == 0 do
    %{}
  end
  def build_merge_skip_map(grid) do
    display_cols = display_columns(grid)
    col_fields = Enum.map(display_cols, & &1.field)
    visible = visible_data(grid)
    row_ids = Enum.map(visible, &Map.get(&1, :id))

    Enum.reduce(grid.state.merge_regions, %{}, fn {{origin_row_id, origin_col_field}, %{rowspan: rs, colspan: cs}}, acc ->
      origin_col_idx = Enum.find_index(col_fields, &(&1 == origin_col_field))
      origin_row_idx = Enum.find_index(row_ids, &(&1 == origin_row_id))

      if is_nil(origin_col_idx) or is_nil(origin_row_idx) do
        acc
      else
        for r_offset <- 0..(rs - 1),
            c_offset <- 0..(cs - 1),
            not (r_offset == 0 and c_offset == 0),
            r_idx = origin_row_idx + r_offset,
            c_idx = origin_col_idx + c_offset,
            r_idx < length(row_ids),
            c_idx < length(col_fields),
            reduce: acc do
          inner_acc ->
            target_row_id = Enum.at(row_ids, r_idx)
            target_col_field = Enum.at(col_fields, c_idx)
            Map.put(inner_acc, {target_row_id, target_col_field}, {:origin, origin_row_id, origin_col_field})
        end
      end
    end)
  end

  # ── F-930: Row Move ──

  @doc "행을 from_row_id 위치에서 to_row_id 위치 앞으로 이동합니다."
  @spec move_row(t(), any(), any()) :: t()
  def move_row(grid, from_row_id, to_row_id) when from_row_id == to_row_id, do: grid
  def move_row(grid, from_row_id, to_row_id) do
    data = grid.data
    from_row = Enum.find(data, &(&1.id == from_row_id))

    if from_row do
      without_from = Enum.reject(data, &(&1.id == from_row_id))
      to_idx = Enum.find_index(without_from, &(&1.id == to_row_id)) || length(without_from)
      new_data = List.insert_at(without_from, to_idx, from_row)
      %{grid | data: new_data}
    else
      grid
    end
  end

  # ── Per-row Height (extendsizetype) ──

  @doc "특정 행의 높이를 설정합니다."
  @spec set_row_height(t(), any(), pos_integer()) :: t()
  def set_row_height(grid, row_id, height) when is_integer(height) and height > 0 do
    row_heights = Map.put(grid.state.row_heights, row_id, height)
    %{grid | state: %{grid.state | row_heights: row_heights}}
  end

  @doc "특정 행의 높이를 초기화합니다 (기본 row_height 사용)."
  @spec reset_row_height(t(), any()) :: t()
  def reset_row_height(grid, row_id) do
    row_heights = Map.delete(grid.state.row_heights, row_id)
    %{grid | state: %{grid.state | row_heights: row_heights}}
  end

  @doc "특정 행의 실제 높이를 반환합니다 (개별 설정 또는 기본값)."
  @spec get_row_height(t(), any()) :: pos_integer()
  def get_row_height(grid, row_id) do
    Map.get(grid.state.row_heights, row_id, grid.options.row_height)
  end

  # ── Dynamic Freeze ──

  @doc "고정 컬럼 수를 동적으로 변경합니다."
  @spec set_frozen_columns(t(), non_neg_integer()) :: t()
  def set_frozen_columns(grid, count) when is_integer(count) and count >= 0 do
    max_cols = length(grid.columns)
    count = min(count, max_cols)
    %{grid | options: %{grid.options | frozen_columns: count}}
  end

  # ── Dataset Merge (appendData) ──

  @doc "외부 데이터를 현재 Grid 데이터에 병합(추가)합니다."
  @spec append_data(t(), [map()]) :: t()
  def append_data(grid, new_rows) when is_list(new_rows) do
    %{grid | data: grid.data ++ new_rows}
  end

  @doc """
  Virtual Scroll 시 렌더링 시작 위치 (px)
  buffer를 고려한 실제 start_index 기반 오프셋
  """
  @spec virtual_offset_top(grid :: t()) :: non_neg_integer()
  def virtual_offset_top(%{data: []} = _grid), do: 0
  def virtual_offset_top(%{state: state, options: options}) do
    buffer = Map.get(options, :virtual_buffer, 5)
    start_index = max(0, state.scroll_offset - buffer)
    start_index * options.row_height
  end

  @doc """
  특정 행의 특정 필드 값을 업데이트합니다.
  row_id가 없는 경우 원본 데이터를 그대로 반환합니다.
  """
  @spec update_cell(grid :: t(), row_id :: any(), field :: atom(), value :: any()) :: t()
  def update_cell(grid, row_id, field, value) do
    updated_data = Enum.map(grid.data, fn row ->
      if row.id == row_id, do: Map.put(row, field, value), else: row
    end)

    # 자동으로 :updated 마킹 (단, :new인 행은 :new 유지)
    current_status = Map.get(grid.state.row_statuses, row_id)
    updated_statuses = if current_status == :new do
      grid.state.row_statuses
    else
      Map.put(grid.state.row_statuses, row_id, :updated)
    end

    %{grid | data: updated_data}
    |> put_in([:state, :row_statuses], updated_statuses)
  end

  @doc "특정 행의 상태를 조회합니다."
  @spec row_status(grid :: t(), row_id :: any()) :: :normal | :new | :updated | :deleted
  def row_status(grid, row_id) do
    Map.get(grid.state.row_statuses, row_id, :normal)
  end

  @doc "특정 행의 상태를 설정합니다. :normal이면 맵에서 제거합니다."
  @spec mark_row_status(grid :: t(), row_id :: any(), status :: atom()) :: t()
  def mark_row_status(grid, row_id, :normal) do
    put_in(grid.state.row_statuses, Map.delete(grid.state.row_statuses, row_id))
  end
  def mark_row_status(grid, row_id, status) when status in [:new, :updated, :deleted] do
    put_in(grid.state.row_statuses, Map.put(grid.state.row_statuses, row_id, status))
  end

  @doc "모든 행 상태를 초기화합니다. :deleted 행은 데이터에서 제거합니다."
  @spec clear_row_statuses(grid :: t()) :: t()
  def clear_row_statuses(grid) do
    # :deleted 마킹된 행을 data에서 제거
    deleted_ids = grid.state.row_statuses
      |> Enum.filter(fn {_id, status} -> status == :deleted end)
      |> Enum.map(fn {id, _} -> id end)
      |> MapSet.new()

    updated_data = if MapSet.size(deleted_ids) > 0 do
      Enum.reject(grid.data, fn row -> MapSet.member?(deleted_ids, row.id) end)
    else
      grid.data
    end

    %{grid | data: updated_data}
    |> put_in([:state, :row_statuses], %{})
    |> put_in([:state, :pagination, :total_rows], length(updated_data))
  end

  @doc "상태별 행 개수를 반환합니다."
  @spec status_counts(grid :: t()) :: map()
  def status_counts(grid) do
    grid.state.row_statuses
    |> Enum.group_by(fn {_id, status} -> status end)
    |> Enum.map(fn {status, rows} -> {status, length(rows)} end)
    |> Map.new()
  end

  @doc """
  변경된 행 데이터를 상태와 함께 반환합니다.
  저장 시 부모 LiveView에 전달할 데이터로 사용합니다.

  ## Returns
      [%{row: %{id: 1, name: "Alice"}, status: :updated}, ...]
  """
  @spec changed_rows(grid :: t()) :: list(map())
  def changed_rows(grid) do
    grid.state.row_statuses
    |> Enum.map(fn {row_id, status} ->
      row = Enum.find(grid.data, fn r -> r.id == row_id end)
      %{row: row, status: status}
    end)
    |> Enum.filter(fn %{row: row} -> row != nil end)
  end

  @doc "변경사항이 있는지 확인합니다."
  @spec has_changes?(grid :: t()) :: boolean()
  def has_changes?(grid) do
    map_size(grid.state.row_statuses) > 0
  end

  # ── v0.7: Grouping API ──

  @doc "그룹핑 필드를 설정합니다."
  @spec set_group_by(grid :: t(), fields :: list(atom())) :: t()
  def set_group_by(grid, fields) when is_list(fields) do
    grid
    |> put_in([:state, :group_by], fields)
    |> put_in([:state, :group_expanded], %{})
    |> put_in([:state, :pagination, :current_page], 1)
  end

  @doc "그룹 집계 함수를 설정합니다."
  @spec set_group_aggregates(grid :: t(), aggregates :: map()) :: t()
  def set_group_aggregates(grid, aggregates) when is_map(aggregates) do
    put_in(grid.state.group_aggregates, aggregates)
  end

  @doc "그룹 expand/collapse를 토글합니다."
  @spec toggle_group(grid :: t(), group_key :: String.t()) :: t()
  def toggle_group(grid, group_key) do
    updated = Grouping.toggle_group(grid.state.group_expanded, group_key)
    put_in(grid.state.group_expanded, updated)
  end

  # ── v0.7: Tree Grid API ──

  @doc "트리 모드를 설정합니다."
  @spec set_tree_mode(grid :: t(), enabled :: boolean(), parent_field :: atom()) :: t()
  def set_tree_mode(grid, enabled, parent_field \\ :parent_id) do
    grid
    |> put_in([:state, :tree_mode], enabled)
    |> put_in([:state, :tree_parent_field], parent_field)
    |> put_in([:state, :tree_expanded], %{})
  end

  @doc "트리 노드 expand/collapse를 토글합니다."
  @spec toggle_tree_node(grid :: t(), node_id :: any()) :: t()
  def toggle_tree_node(grid, node_id) do
    updated = Tree.toggle_node(grid.state.tree_expanded, node_id)
    put_in(grid.state.tree_expanded, updated)
  end

  # ── v0.7: Pivot Table API ──

  @doc """
  피벗 테이블 설정을 적용하고 변환된 {columns, rows}를 반환합니다.
  config: %{row_fields: [...], col_field: :field, value_field: :field, aggregate: :sum}
  """
  @spec pivot_transform(grid :: t(), config :: map()) :: {list(map()), list(map())}
  def pivot_transform(%{data: data, columns: columns, state: state}, config) do
    searched = apply_global_search(data, state.global_search, columns)
    filtered = apply_filters(searched, state.filters, columns)
    advanced = apply_advanced_filters(filtered, state.advanced_filters, columns)
    Pivot.transform(advanced, config)
  end

  # ── 셀 검증 (Validation) ──

  @doc """
  특정 셀의 값을 검증하고 결과를 cell_errors에 저장합니다.
  검증 실패 시 에러 메시지를 저장하고, 성공 시 에러를 제거합니다.
  """
  @spec validate_cell(grid :: t(), row_id :: any(), field :: atom()) :: t()
  def validate_cell(grid, row_id, field) do
    column = Enum.find(grid.columns, fn c -> c.field == field end)
    row = Enum.find(grid.data, fn r -> r.id == row_id end)
    value = if row, do: Map.get(row, field), else: nil
    validators = if column, do: Map.get(column, :validators, []), else: []

    error = run_validators(value, validators)

    cell_errors = if error do
      Map.put(grid.state.cell_errors, {row_id, field}, error)
    else
      Map.delete(grid.state.cell_errors, {row_id, field})
    end

    put_in(grid.state.cell_errors, cell_errors)
  end

  @doc "특정 셀의 에러 메시지를 조회합니다. 에러 없으면 nil."
  @spec cell_error(grid :: t(), row_id :: any(), field :: atom()) :: String.t() | nil
  def cell_error(grid, row_id, field) do
    Map.get(grid.state.cell_errors, {row_id, field})
  end

  @doc "검증 에러가 있는지 확인합니다."
  @spec has_errors?(grid :: t()) :: boolean()
  def has_errors?(grid) do
    map_size(grid.state.cell_errors) > 0
  end

  @doc "검증 에러 개수를 반환합니다."
  @spec error_count(grid :: t()) :: non_neg_integer()
  def error_count(grid) do
    map_size(grid.state.cell_errors)
  end

  @doc "모든 셀 에러를 초기화합니다."
  @spec clear_cell_errors(grid :: t()) :: t()
  def clear_cell_errors(grid) do
    put_in(grid.state.cell_errors, %{})
  end

  # 검증 규칙을 순서대로 실행하여 첫 번째 에러 메시지 반환 (에러 없으면 nil)
  defp run_validators(_value, []), do: nil
  defp run_validators(value, [{:required, msg} | rest]) do
    if value == nil or value == "" do
      msg
    else
      run_validators(value, rest)
    end
  end
  defp run_validators(value, [{:min, min_val, msg} | rest]) do
    if is_number(value) and value < min_val do
      msg
    else
      run_validators(value, rest)
    end
  end
  defp run_validators(value, [{:max, max_val, msg} | rest]) do
    if is_number(value) and value > max_val do
      msg
    else
      run_validators(value, rest)
    end
  end
  defp run_validators(value, [{:min_length, len, msg} | rest]) do
    if is_binary(value) and String.length(value) < len do
      msg
    else
      run_validators(value, rest)
    end
  end
  defp run_validators(value, [{:max_length, len, msg} | rest]) do
    if is_binary(value) and String.length(value) > len do
      msg
    else
      run_validators(value, rest)
    end
  end
  defp run_validators(value, [{:pattern, regex, msg} | rest]) do
    if is_binary(value) and not Regex.match?(regex, value) do
      msg
    else
      run_validators(value, rest)
    end
  end
  defp run_validators(value, [{:custom, fun, msg} | rest]) do
    if not fun.(value) do
      msg
    else
      run_validators(value, rest)
    end
  end
  defp run_validators(value, [_ | rest]), do: run_validators(value, rest)

  @doc """
  새 행을 추가합니다. 임시 ID(음수)를 자동 부여하고 :new 상태로 마킹합니다.
  position이 :top이면 맨 앞, :bottom이면 맨 뒤에 추가합니다.
  """
  @spec add_row(grid :: t(), defaults :: map(), position :: :top | :bottom) :: t()
  def add_row(grid, defaults \\ %{}, position \\ :top) do
    temp_id = next_temp_id(grid)
    new_row = Map.merge(defaults, %{id: temp_id})

    updated_data = case position do
      :top -> [new_row | grid.data]
      :bottom -> grid.data ++ [new_row]
    end

    %{grid | data: updated_data}
    |> put_in([:state, :row_statuses], Map.put(grid.state.row_statuses, temp_id, :new))
    |> put_in([:state, :pagination, :total_rows], length(updated_data))
  end

  @doc """
  선택된 행들을 삭제 마킹합니다. (:deleted 상태로 변경)
  :new 상태인 행은 데이터에서 완전히 제거합니다.
  """
  @spec delete_rows(grid :: t(), row_ids :: list(any())) :: t()
  def delete_rows(grid, row_ids) do
    Enum.reduce(row_ids, grid, fn row_id, acc ->
      current_status = Map.get(acc.state.row_statuses, row_id)

      if current_status == :new do
        # :new 행은 데이터에서 완전 제거
        updated_data = Enum.reject(acc.data, fn r -> r.id == row_id end)
        updated_statuses = Map.delete(acc.state.row_statuses, row_id)
        updated_selection = List.delete(acc.state.selection.selected_ids, row_id)

        %{acc | data: updated_data}
        |> put_in([:state, :row_statuses], updated_statuses)
        |> put_in([:state, :selection, :selected_ids], updated_selection)
        |> put_in([:state, :pagination, :total_rows], length(updated_data))
      else
        # 기존 행은 :deleted 마킹
        acc
        |> put_in([:state, :row_statuses], Map.put(acc.state.row_statuses, row_id, :deleted))
      end
    end)
  end

  # ── F-700: Undo/Redo API ──

  @doc """
  편집 기록을 히스토리에 추가합니다. redo_stack은 초기화됩니다.
  최대 #{@max_edit_history}건까지 보관합니다.

  ## 액션 타입
      {:update_cell, row_id, field, old_value, new_value}
      {:update_row, row_id, %{field => old_value, ...}, %{field => new_value, ...}}
  """
  @spec push_edit_history(grid :: t(), action :: tuple()) :: t()
  def push_edit_history(grid, action) do
    history = [action | grid.state.edit_history]
      |> Enum.take(@max_edit_history)

    grid
    |> put_in([:state, :edit_history], history)
    |> put_in([:state, :redo_stack], [])
  end

  @doc "마지막 편집을 되돌립니다. 히스토리가 비어있으면 그대로 반환합니다."
  @spec undo(grid :: t()) :: t()
  def undo(grid) do
    case grid.state.edit_history do
      [] -> grid
      [action | rest] ->
        grid
        |> apply_undo_action(action)
        |> put_in([:state, :edit_history], rest)
        |> put_in([:state, :redo_stack], [action | grid.state.redo_stack])
    end
  end

  @doc "되돌린 편집을 다시 적용합니다. redo_stack이 비어있으면 그대로 반환합니다."
  @spec redo(grid :: t()) :: t()
  def redo(grid) do
    case grid.state.redo_stack do
      [] -> grid
      [action | rest] ->
        grid
        |> apply_redo_action(action)
        |> put_in([:state, :redo_stack], rest)
        |> put_in([:state, :edit_history], [action | grid.state.edit_history])
    end
  end

  @doc "되돌리기 가능 여부를 확인합니다."
  @spec can_undo?(grid :: t()) :: boolean()
  def can_undo?(grid), do: grid.state.edit_history != []

  @doc "다시하기 가능 여부를 확인합니다."
  @spec can_redo?(grid :: t()) :: boolean()
  def can_redo?(grid), do: grid.state.redo_stack != []

  @doc """
  Grid-level settings (options)를 Grid 구조체에 적용합니다.

  ConfigModal의 Tab 4 (Grid Settings)에서 전달받은 옵션 변경 사항을 검증하고
  Grid.options에 병합합니다.

  - page_size: 1 ~ 100,000 (정수)
  - theme: "light" | "dark" | "custom"
  - virtual_scroll: boolean
  - row_height: 32 ~ 80 (픽셀)
  - frozen_columns: 0 ~ 컬럼 수
  - show_row_number: boolean
  - show_header: boolean
  - show_footer: boolean
  - debug_mode: boolean

  ## Examples

      iex> Grid.apply_grid_settings(grid, %{"page_size" => 50, "theme" => "dark"})
      {:ok, %Grid{options: %{page_size: 50, theme: "dark", ...}}}

      iex> Grid.apply_grid_settings(grid, %{"page_size" => 200_000})
      {:error, "Invalid page_size: must be between 1 and 100000"}

  """
  @spec apply_grid_settings(grid :: t(), options_changes :: map()) ::
          {:ok, t()} | {:error, String.t()}
  def apply_grid_settings(grid, options_changes) when is_map(options_changes) do
    normalized = normalize_option_keys(options_changes)

    case validate_grid_options(normalized, grid) do
      :ok ->
        new_options = Map.merge(grid.options, normalized)
        {:ok, %{grid | options: new_options}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def apply_grid_settings(_grid, nil), do: {:error, "options_changes must be a map"}

  # option key 문자열을 atom으로 정규화
  defp normalize_option_keys(options) when is_map(options) do
    Map.new(options, fn {k, v} ->
      key = if is_binary(k), do: String.to_atom(k), else: k
      {key, v}
    end)
  end

  # 각 옵션 값을 검증 (유효하지 않으면 {:error, reason} 반환)
  defp validate_grid_options(options, grid) do
    try do
      Enum.each(options, fn {key, value} ->
        case key do
          :page_size ->
            unless is_integer(value) and value > 0 and value <= 100_000 do
              raise "Invalid page_size: must be between 1 and 100000"
            end

          :theme ->
            unless is_binary(value) and value in ["light", "dark", "custom"] do
              raise "Invalid theme: must be 'light', 'dark', or 'custom'"
            end

          :virtual_scroll ->
            unless is_boolean(value) do
              raise "Invalid virtual_scroll: must be boolean"
            end

          :row_height ->
            unless is_integer(value) and value >= 32 and value <= 80 do
              raise "Invalid row_height: must be between 32 and 80 pixels"
            end

          :frozen_columns ->
            max_cols = length(grid.columns)

            unless is_integer(value) and value >= 0 and value <= max_cols do
              raise "Invalid frozen_columns: must be between 0 and #{max_cols}"
            end

          :show_row_number ->
            unless is_boolean(value) do
              raise "Invalid show_row_number: must be boolean"
            end

          :show_header ->
            unless is_boolean(value) do
              raise "Invalid show_header: must be boolean"
            end

          :show_footer ->
            unless is_boolean(value) do
              raise "Invalid show_footer: must be boolean"
            end

          :debug_mode ->
            unless is_boolean(value) do
              raise "Invalid debug_mode: must be boolean"
            end

          _ ->
            # 알 수 없는 키는 무시 (하위 호환성)
            :ok
        end
      end)

      :ok
    rescue
      e in RuntimeError -> {:error, e.message}
    end
  end

  @doc """
  사용자가 설정한 컬럼 설정 변경 사항을 Grid에 적용합니다.

  Config Modal에서 전달받은 설정 변경 사항을 검증하고 Grid에 적용합니다.
  - 컬럼 속성 변경 (label, width, align, sortable, filterable, editable)
  - 포매터 및 검증자 설정
  - 컬럼 표시/숨김 및 순서 변경

  ## Examples

      iex> config_changes = %{
      ...>   "columns" => [
      ...>     %{"field" => "name", "label" => "이름", "width" => 200}
      ...>   ],
      ...>   "column_order" => [:name, :email]
      ...> }
      iex> Grid.apply_config_changes(grid, config_changes)
      %{...}
  """
  @spec apply_config_changes(grid :: t(), config_changes :: map()) :: t()
  def apply_config_changes(grid, config_changes) do
    config_changes = normalize_config_changes(config_changes)

    # definition.columns = 숨긴 컬럼 포함 전체 원본
    all_columns = all_columns(grid)
    validate_columns_list!(config_changes, all_columns)

    # 전체 컬럼에 속성 변경 적용
    updated_columns = update_columns(all_columns, config_changes)

    # 순서 적용 (숨기기 전)
    ordered_columns = apply_column_order(updated_columns, config_changes)

    # hidden_columns 정보 추출
    hidden = Map.get(config_changes, :hidden_columns, [])

    # 보이는 컬럼만 grid.columns에 설정
    visible_columns = Enum.reject(ordered_columns, fn col -> col.field in hidden end)

    # state에 runtime config 저장
    new_state =
      grid.state
      |> Map.put(:hidden_columns, hidden)
      |> Map.put(:column_order, Map.get(config_changes, :column_order))

    # runtime 변경을 state[:all_columns]에 항상 저장 (modal 재오픈 시 참조)
    new_state = Map.put(new_state, :all_columns, ordered_columns)

    %{grid | columns: visible_columns, state: new_state}
  end

  @doc "Definition 원본으로 Grid 컬럼/옵션을 완전 복원한다."
  @spec reset_to_definition(t()) :: t()
  def reset_to_definition(%{definition: nil} = grid), do: grid
  def reset_to_definition(%{definition: definition} = grid) do
    %{grid |
      columns: normalize_columns(definition.columns),
      options: merge_default_options(definition.options),
      state: grid.state
        |> Map.put(:hidden_columns, [])
        |> Map.put(:column_order, nil)
        |> Map.delete(:all_columns)
    }
  end

  @doc "Grid의 기본 옵션 맵을 반환한다."
  @spec default_options() :: map()
  def default_options do
    %{
      page_size: 20,
      show_header: true,
      show_footer: true,
      virtual_scroll: false,
      virtual_buffer: 5,
      row_height: 40,
      frozen_columns: 0,
      debug: false,
      theme: "light",
      show_row_number: false,
      show_summary: false,
      autofit_type: :none,
      # FA-004: Status Bar
      show_status_bar: false,
      # FA-011: Floating Filters (always visible filter row)
      floating_filter: false,
      # FA-037: Column Hover Highlight
      column_hover_highlight: false,
      # FA-002: Grid State Persistence (localStorage 자동 저장/복원)
      state_persistence: false
    }
  end

  # 안전한 원본 컬럼 조회 (definition → state[:all_columns] → grid.columns)
  defp all_columns(grid) do
    cond do
      grid.state[:all_columns] -> grid.state[:all_columns]
      grid.definition -> normalize_columns(grid.definition.columns)
      true -> grid.columns
    end
  end

  # Config 변경 사항 정규화 (문자열 키를 기존 형식으로 변환)
  defp normalize_config_changes(config_changes) when is_map(config_changes) do
    config_changes
    |> Enum.reduce(%{}, fn
      {"columns", columns}, acc when is_list(columns) ->
        normalized_columns =
          columns
          |> Enum.map(&normalize_column_config/1)
        Map.put(acc, :columns, normalized_columns)

      {"column_order", order}, acc when is_list(order) ->
        # 문자열을 atom으로 변환
        normalized_order = Enum.map(order, fn
          field when is_atom(field) -> field
          field when is_binary(field) -> String.to_atom(field)
        end)
        Map.put(acc, :column_order, normalized_order)

      {"hidden_columns", hidden}, acc when is_list(hidden) ->
        normalized_hidden = Enum.map(hidden, fn
          field when is_atom(field) -> field
          field when is_binary(field) -> String.to_atom(field)
        end)
        Map.put(acc, :hidden_columns, normalized_hidden)

      {key, value}, acc ->
        # 알려지지 않은 키는 그대로 유지
        Map.put(acc, String.to_atom(key), value)
    end)
  end

  # 개별 컬럼 설정 정규화
  defp normalize_column_config(column) when is_map(column) do
    Enum.reduce(column, %{}, fn
      {"field", field}, acc ->
        field = if is_atom(field), do: field, else: String.to_atom(field)
        Map.put(acc, :field, field)

      {"label", label}, acc ->
        Map.put(acc, :label, label)

      {"width", width}, acc when is_integer(width) ->
        Map.put(acc, :width, width)

      {"align", align}, acc ->
        align = if is_atom(align), do: align, else: String.to_atom(align)
        Map.put(acc, :align, align)

      {"sortable", sortable}, acc when is_boolean(sortable) ->
        Map.put(acc, :sortable, sortable)

      {"filterable", filterable}, acc when is_boolean(filterable) ->
        Map.put(acc, :filterable, filterable)

      {"editable", editable}, acc when is_boolean(editable) ->
        Map.put(acc, :editable, editable)

      {"formatter", formatter}, acc ->
        formatter = if is_atom(formatter), do: formatter, else: String.to_atom(formatter)
        Map.put(acc, :formatter, formatter)

      {"formatter_options", options}, acc when is_map(options) ->
        Map.put(acc, :formatter_options, options)

      {"validators", validators}, acc when is_list(validators) ->
        deserialized =
          validators
          |> Enum.map(&deserialize_validator/1)
          |> Enum.reject(&is_nil/1)
        Map.put(acc, :validators, deserialized)

      {_key, _value}, acc ->
        acc
    end)
  end

  # JSON map → validator tuple 역직렬화
  defp deserialize_validator(%{"type" => "required", "message" => msg}), do: {:required, msg}
  defp deserialize_validator(%{"type" => "min", "value" => val, "message" => msg}), do: {:min, val, msg}
  defp deserialize_validator(%{"type" => "max", "value" => val, "message" => msg}), do: {:max, val, msg}
  defp deserialize_validator(%{"type" => "pattern", "message" => msg}), do: {:pattern, ~r/.*/, msg}
  defp deserialize_validator(tuple) when is_tuple(tuple), do: tuple
  defp deserialize_validator(_), do: nil

  # 컬럼 존재 여부 및 유효성 검증 (전체 컬럼 리스트 기준)
  defp validate_columns_list!(config_changes, all_columns) do
    case Map.get(config_changes, :columns) do
      nil ->
        :ok

      columns when is_list(columns) ->
        all_fields = Enum.map(all_columns, & &1.field)

        Enum.each(columns, fn column ->
          field = Map.get(column, :field)

          unless field && Enum.member?(all_fields, field) do
            raise "컬럼 필드가 존재하지 않습니다: #{inspect(field)}"
          end
        end)
    end
  end

  # Grid의 컬럼 속성 업데이트
  defp update_columns(columns, config_changes) do
    case Map.get(config_changes, :columns) do
      nil ->
        columns

      config_columns when is_list(config_columns) ->
        # 각 컬럼의 설정을 맵으로 변환 (field -> config)
        config_map = Map.new(config_columns, &{&1.field, &1})

        Enum.map(columns, fn column ->
          case Map.get(config_map, column.field) do
            nil ->
              column

            config ->
              # 설정에서 주어진 속성만 업데이트
              column
              |> update_if_present(config, :label)
              |> update_if_present(config, :width)
              |> update_if_present(config, :align)
              |> update_if_present(config, :sortable)
              |> update_if_present(config, :filterable)
              |> update_if_present(config, :editable)
              |> update_if_present(config, :formatter)
              |> update_if_present(config, :formatter_options)
              |> update_if_present(config, :validators)
          end
        end)
    end
  end

  # 컬럼 속성이 설정에 존재하면 업데이트 (없으면 유지)
  defp update_if_present(column, config, key) do
    case Map.get(config, key) do
      nil -> column
      value -> Map.put(column, key, value)
    end
  end

  # 컬럼 순서만 적용 (숨기기는 apply_config_changes에서 처리)
  defp apply_column_order(columns, config_changes) do
    case Map.get(config_changes, :column_order) do
      nil ->
        columns

      order when is_list(order) ->
        field_to_column = Map.new(columns, &{&1.field, &1})

        Enum.map(order, fn field ->
          Map.get(field_to_column, field)
        end)
        |> Enum.reject(&is_nil/1)
    end
  end

  # Undo: 이전 값으로 복원 (히스토리 추가 없이 데이터만 변경)
  defp apply_undo_action(grid, {:update_cell, row_id, field, old_value, _new_value}) do
    update_cell_data_only(grid, row_id, field, old_value)
  end
  defp apply_undo_action(grid, {:update_row, row_id, old_values, _new_values}) do
    Enum.reduce(old_values, grid, fn {field, value}, acc ->
      update_cell_data_only(acc, row_id, field, value)
    end)
  end
  defp apply_undo_action(grid, {:insert_row, row_id, _row_data}) do
    updated_data = Enum.reject(grid.data, fn row -> row.id == row_id end)
    %{grid | data: updated_data}
    |> put_in([:state, :row_statuses], Map.delete(grid.state.row_statuses, row_id))
    |> put_in([:state, :pagination, :total_rows], length(updated_data))
  end

  # Redo: 새 값으로 재적용 (히스토리 추가 없이 데이터만 변경)
  defp apply_redo_action(grid, {:update_cell, row_id, field, _old_value, new_value}) do
    update_cell_data_only(grid, row_id, field, new_value)
  end
  defp apply_redo_action(grid, {:update_row, row_id, _old_values, new_values}) do
    Enum.reduce(new_values, grid, fn {field, value}, acc ->
      update_cell_data_only(acc, row_id, field, value)
    end)
  end
  defp apply_redo_action(grid, {:insert_row, row_id, row_data}) do
    updated_data = grid.data ++ [row_data]
    %{grid | data: updated_data}
    |> put_in([:state, :row_statuses], Map.put(grid.state.row_statuses, row_id, :new))
    |> put_in([:state, :pagination, :total_rows], length(updated_data))
  end

  # 데이터만 업데이트 (row_statuses, edit_history 변경 없이)
  defp update_cell_data_only(grid, row_id, field, value) do
    updated_data = Enum.map(grid.data, fn row ->
      if row.id == row_id, do: Map.put(row, field, value), else: row
    end)
    %{grid | data: updated_data}
  end

  @doc """
  다음 임시 ID를 생성합니다. (음수로 자동 감소)
  """
  def next_temp_id(grid) do
    existing_ids = Enum.map(grid.data, & &1.id)
    min_id = Enum.min(existing_ids, fn -> 0 end)
    if min_id > 0, do: -1, else: min_id - 1
  end

  # ── F-940: Cell Range Selection ──

  @doc """
  셀 범위 선택을 설정합니다.
  range는 %{anchor_row_id, anchor_col_idx, extent_row_id, extent_col_idx} 맵입니다.
  """
  @spec set_cell_range(t(), map() | nil) :: t()
  def set_cell_range(grid, nil), do: put_in(grid.state.cell_range, nil)
  def set_cell_range(grid, range) when is_map(range), do: put_in(grid.state.cell_range, range)

  @doc "셀 범위 선택을 해제합니다."
  @spec clear_cell_range(t()) :: t()
  def clear_cell_range(grid), do: put_in(grid.state.cell_range, nil)

  # ── F-941: Cell Range Summary ──

  @doc """
  셀 범위 내 값들의 통계를 계산합니다.
  반환값: %{count: N, numeric_count: N, sum: N, avg: N, min: N, max: N} 또는 nil
  """
  @spec cell_range_summary(grid :: t()) :: map() | nil
  def cell_range_summary(%{state: %{cell_range: nil}}), do: nil
  def cell_range_summary(grid) do
    range = grid.state.cell_range
    visible_data = visible_data(grid)
    display_cols = display_columns(grid)

    row_ids = Enum.map(visible_data, & &1.id)
    anchor_pos = Enum.find_index(row_ids, &(&1 == range.anchor_row_id))
    extent_pos = Enum.find_index(row_ids, &(&1 == range.extent_row_id))

    if anchor_pos && extent_pos do
      min_row = min(anchor_pos, extent_pos)
      max_row = max(anchor_pos, extent_pos)
      min_col = min(range.anchor_col_idx, range.extent_col_idx)
      max_col = max(range.anchor_col_idx, range.extent_col_idx)

      values =
        for row_pos <- min_row..max_row,
            col_idx <- min_col..max_col do
          row = Enum.at(visible_data, row_pos)
          col = Enum.at(display_cols, col_idx)
          if row && col, do: Map.get(row, col.field), else: nil
        end
        |> Enum.reject(&is_nil/1)

      numbers = values
        |> Enum.filter(&is_number/1)

      count = length(values)
      numeric_count = length(numbers)

      if numeric_count > 0 do
        %{
          count: count,
          numeric_count: numeric_count,
          sum: Enum.sum(numbers),
          avg: Enum.sum(numbers) / numeric_count,
          min: Enum.min(numbers),
          max: Enum.max(numbers)
        }
      else
        %{count: count, numeric_count: 0, sum: nil, avg: nil, min: nil, max: nil}
      end
    else
      nil
    end
  end

  # Private functions

  defp generate_id do
    "grid_" <> (:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower))
  end

  defp normalize_columns(columns) do
    Enum.map(columns, fn col ->
      Map.merge(%{
        type: :string,
        width: :auto,
        sortable: false,
        filterable: false,
        filter_type: :text,
        editable: false,
        editor_type: :text,
        editor_options: [],
        validators: [],
        input_pattern: nil,
        renderer: nil,
        formatter: nil,
        formatter_options: %{},
        align: :left,
        style_expr: nil,
        header_group: nil,
        nulls: :last,
        required: false,
        summary: nil,
        # FA-022: Resize Lock per Column
        resizable: true,
        # FA-020: Cell Text Selection
        text_selectable: false,
        # FA-011: Floating Filter (per-column control)
        floating_filter: true
      }, col)
    end)
  end

  defp initial_state do
    %{
      sort: nil,
      filters: %{},
      global_search: "",
      show_filter_row: false,
      advanced_filters: %{logic: :and, conditions: []},
      show_advanced_filter: false,
      pagination: %{
        current_page: 1,
        total_rows: 0
      },
      selection: %{
        selected_ids: [],
        select_all: false
      },
      scroll_offset: 0,
      editing: nil,
      editing_row: nil,
      row_statuses: %{},
      cell_errors: %{},
      show_status_column: true,
      column_widths: %{},
      column_order: nil,
      # v0.7: Grouping
      group_by: [],
      group_expanded: %{},
      group_aggregates: %{},
      # v0.7: Tree Grid
      tree_mode: false,
      tree_parent_field: :parent_id,
      tree_expanded: %{},
      # v0.7: Pivot Table
      pivot_config: nil,
      # F-700: Undo/Redo
      edit_history: [],
      redo_stack: [],
      # F-940: Cell Range Selection
      cell_range: nil,
      # F-904: Cell Merge
      merge_regions: %{},
      # Per-row Heights (extendsizetype)
      row_heights: %{},
      # FA-001: Row Pinning (상단/하단 고정 행)
      pinned_top_ids: [],
      pinned_bottom_ids: [],
      # FA-005: Overlay System
      overlay: nil,
      # FA-010: Column Menu
      column_menu: nil,
      hidden_columns: [],
      # FA-012: Set Filter
      set_filter_open: nil,
      # FA-044: Find & Highlight
      find_text: "",
      find_matches: [],
      find_current_index: 0,
      show_find_bar: false
    }
  end

  defp merge_default_options(options) do
    Map.merge(default_options(), options)
  end

  # F-904: 병합 영역 겹침 검사
  defp has_merge_overlap?(grid, new_row_id, new_col_field, new_rowspan, new_colspan) do
    col_fields = display_columns(grid) |> Enum.map(& &1.field)
    row_ids = visible_data(grid) |> Enum.map(&Map.get(&1, :id))

    new_col_idx = Enum.find_index(col_fields, &(&1 == new_col_field)) || 0
    new_row_idx = Enum.find_index(row_ids, &(&1 == new_row_id)) || 0

    new_cells = for r <- new_row_idx..(new_row_idx + new_rowspan - 1),
                    c <- new_col_idx..(new_col_idx + new_colspan - 1),
                    into: MapSet.new(), do: {r, c}

    Enum.any?(grid.state.merge_regions, fn {{origin_row_id, origin_col_field}, %{rowspan: rs, colspan: cs}} ->
      if origin_row_id == new_row_id and origin_col_field == new_col_field do
        false
      else
        origin_col_idx = Enum.find_index(col_fields, &(&1 == origin_col_field)) || 0
        origin_row_idx = Enum.find_index(row_ids, &(&1 == origin_row_id)) || 0

        existing = for r <- origin_row_idx..(origin_row_idx + rs - 1),
                       c <- origin_col_idx..(origin_col_idx + cs - 1),
                       into: MapSet.new(), do: {r, c}

        MapSet.size(MapSet.intersection(new_cells, existing)) > 0
      end
    end)
  end

  # F-904: frozen 컬럼 경계 초과 검사
  defp frozen_boundary_crossed?(grid, col_start_idx, colspan) do
    frozen = grid.options.frozen_columns
    if frozen > 0 do
      col_end_idx = col_start_idx + colspan - 1
      col_start_idx < frozen and col_end_idx >= frozen
    else
      false
    end
  end

  # F-800-INSERT(B): :new 행이 필터에 걸려 사라지지 않도록 보장
  defp ensure_new_rows_included(filtered_data, original_data, row_statuses) do
    new_ids = for {id, :new} <- row_statuses, into: MapSet.new(), do: id

    if MapSet.size(new_ids) == 0 do
      filtered_data
    else
      filtered_ids = MapSet.new(Enum.map(filtered_data, & &1.id))
      missing_new_ids = MapSet.difference(new_ids, filtered_ids)

      if MapSet.size(missing_new_ids) == 0 do
        filtered_data
      else
        Enum.filter(original_data, fn r ->
          MapSet.member?(filtered_ids, r.id) or MapSet.member?(missing_new_ids, r.id)
        end)
      end
    end
  end

  # F-950: 필터/검색 적용 후 전체 데이터 (페이지네이션 전)
  defp filtered_data(%{data_source: {_mod, _cfg}, data: data}), do: data
  defp filtered_data(%{data: data, columns: columns, state: state}) do
    data
    |> apply_global_search(state.global_search, columns)
    |> apply_filters(state.filters, columns)
    |> apply_advanced_filters(state.advanced_filters, columns)
    |> ensure_new_rows_included(data, state.row_statuses)
  end

  defp apply_global_search(data, "", _columns), do: data
  defp apply_global_search(data, nil, _columns), do: data
  defp apply_global_search(data, query, columns) do
    LiveViewGrid.Filter.global_search(data, query, columns)
  end

  defp apply_filters(data, filters, _columns) when map_size(filters) == 0, do: data
  defp apply_filters(data, filters, columns) do
    LiveViewGrid.Filter.apply(data, filters, columns)
  end

  defp apply_advanced_filters(data, %{conditions: conditions} = adv, columns)
       when is_list(conditions) and length(conditions) > 0 do
    LiveViewGrid.Filter.apply_advanced(data, adv, columns)
  end
  defp apply_advanced_filters(data, _, _columns), do: data

  defp apply_sort(data, nil, _columns), do: data
  defp apply_sort(data, %{field: field, direction: direction}, columns) do
    nulls_position = case Enum.find(columns, fn c -> c.field == field end) do
      %{nulls: pos} -> pos
      _ -> :last
    end
    LiveViewGrid.Sorting.sort(data, field, direction, nulls_position)
  end

  defp apply_pagination(data, pagination, page_size) do
    LiveViewGrid.Pagination.paginate(data, pagination.current_page, page_size)
  end

  # v0.7: Grouping / Tree 구조화 적용
  defp apply_data_structuring(data, %{group_by: group_by, group_expanded: expanded, group_aggregates: aggregates})
       when is_list(group_by) and length(group_by) > 0 do
    Grouping.group_data(data, group_by, expanded, aggregates)
  end
  defp apply_data_structuring(data, %{tree_mode: true, tree_parent_field: parent_field, tree_expanded: expanded}) do
    Tree.build_tree(data, parent_field, expanded)
  end
  defp apply_data_structuring(data, _state), do: data

  defp apply_virtual_scroll([], _scroll_offset, _options), do: []
  defp apply_virtual_scroll(data, scroll_offset, options) do
    total_rows = length(data)
    row_height = options.row_height
    buffer = options.virtual_buffer

    # 화면에 보이는 행 수 계산
    viewport_height = Map.get(options, :viewport_height, 600)
    visible_rows = div(viewport_height, row_height)

    # 시작 인덱스 (스크롤 오프셋 기반)
    start_index = max(0, scroll_offset - buffer)

    # 끝 인덱스 (버퍼 포함)
    end_index = min(total_rows - 1, scroll_offset + visible_rows + buffer)

    # 범위 유효성 검사
    if start_index >= total_rows or end_index < start_index do
      []
    else
      data
      |> Enum.slice(start_index..end_index//1)
      |> Enum.with_index(start_index)
      |> Enum.map(fn {row, idx} -> Map.put(row, :_virtual_index, idx) end)
    end
  end

  # ────────────────────────────────────────────────
  # FA-001: Row Pinning (상단/하단 행 고정)
  # ────────────────────────────────────────────────

  @doc """
  지정된 행들을 상단 또는 하단에 고정한다.

  ## Parameters
    - `grid` - Grid 인스턴스
    - `row_ids` - 고정할 행 ID 리스트
    - `position` - `:top` 또는 `:bottom`

  ## Examples

      grid = Grid.pin_rows(grid, [1, 2], :top)
      grid = Grid.pin_rows(grid, [5], :bottom)
  """
  @spec pin_rows(t(), list(any()), :top | :bottom) :: t()
  def pin_rows(grid, row_ids, :top) do
    current = grid.state.pinned_top_ids
    new_ids = Enum.uniq(current ++ row_ids)
    # 상단 고정에 추가되면 하단에서 제거
    bottom = grid.state.pinned_bottom_ids -- row_ids
    grid
    |> put_in([:state, :pinned_top_ids], new_ids)
    |> put_in([:state, :pinned_bottom_ids], bottom)
  end

  def pin_rows(grid, row_ids, :bottom) do
    current = grid.state.pinned_bottom_ids
    new_ids = Enum.uniq(current ++ row_ids)
    top = grid.state.pinned_top_ids -- row_ids
    grid
    |> put_in([:state, :pinned_bottom_ids], new_ids)
    |> put_in([:state, :pinned_top_ids], top)
  end

  @doc """
  행 고정을 해제한다.

  ## Parameters
    - `grid` - Grid 인스턴스
    - `row_ids` - 고정 해제할 행 ID 리스트
  """
  @spec unpin_rows(t(), list(any())) :: t()
  def unpin_rows(grid, row_ids) do
    grid
    |> put_in([:state, :pinned_top_ids], grid.state.pinned_top_ids -- row_ids)
    |> put_in([:state, :pinned_bottom_ids], grid.state.pinned_bottom_ids -- row_ids)
  end

  @doc "상단 고정 행 데이터를 반환한다."
  @spec pinned_top_rows(t()) :: list(map())
  def pinned_top_rows(%{state: %{pinned_top_ids: ids}}) when ids == [], do: []
  def pinned_top_rows(%{data: data, state: %{pinned_top_ids: ids}}) do
    Enum.filter(data, fn row -> Map.get(row, :id) in ids end)
  end

  @doc "하단 고정 행 데이터를 반환한다."
  @spec pinned_bottom_rows(t()) :: list(map())
  def pinned_bottom_rows(%{state: %{pinned_bottom_ids: ids}}) when ids == [], do: []
  def pinned_bottom_rows(%{data: data, state: %{pinned_bottom_ids: ids}}) do
    Enum.filter(data, fn row -> Map.get(row, :id) in ids end)
  end

  @doc "행이 고정 상태인지 확인한다."
  @spec pinned?(t(), any()) :: :top | :bottom | false
  def pinned?(grid, row_id) do
    cond do
      row_id in grid.state.pinned_top_ids -> :top
      row_id in grid.state.pinned_bottom_ids -> :bottom
      true -> false
    end
  end

  # ────────────────────────────────────────────────
  # FA-005: Overlay System (Loading/No Data/Error)
  # ────────────────────────────────────────────────

  @doc """
  오버레이 상태를 설정한다.

  ## Parameters
    - `grid` - Grid 인스턴스
    - `type` - `:loading`, `:no_data`, `:error`, 또는 `nil` (해제)
    - `message` - 표시할 메시지 (선택)

  ## Examples

      grid = Grid.set_overlay(grid, :loading)
      grid = Grid.set_overlay(grid, :error, "데이터를 불러올 수 없습니다")
      grid = Grid.set_overlay(grid, nil)  # 해제
  """
  @spec set_overlay(t(), atom() | nil, String.t() | nil) :: t()
  def set_overlay(grid, type, message \\ nil)
  def set_overlay(grid, nil, _message) do
    put_in(grid.state.overlay, nil)
  end

  def set_overlay(grid, type, message) when type in [:loading, :no_data, :error] do
    put_in(grid.state.overlay, %{type: type, message: message})
  end

  @doc "오버레이를 해제한다."
  @spec clear_overlay(t()) :: t()
  def clear_overlay(grid), do: put_in(grid.state.overlay, nil)

  # ── FA-010: Column Menu ──

  @doc "컬럼을 숨긴다."
  @spec hide_column(t(), atom()) :: t()
  def hide_column(grid, field) when is_atom(field) do
    hidden = grid.state[:hidden_columns] || []
    if field in hidden do
      grid
    else
      put_in(grid.state[:hidden_columns], [field | hidden])
    end
  end

  @doc "숨겨진 컬럼을 다시 표시한다."
  @spec show_column(t(), atom()) :: t()
  def show_column(grid, field) when is_atom(field) do
    hidden = grid.state[:hidden_columns] || []
    put_in(grid.state[:hidden_columns], List.delete(hidden, field))
  end

  @doc "숨겨진 컬럼 목록을 반환한다."
  @spec hidden_columns(t()) :: [atom()]
  def hidden_columns(grid) do
    grid.state[:hidden_columns] || []
  end
end
