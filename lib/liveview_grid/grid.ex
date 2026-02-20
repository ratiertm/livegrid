defmodule LiveViewGrid.Grid do
  @moduledoc """
  Grid 인스턴스 생성 및 관리
  
  프로토타입 v0.1-alpha: 최소 기능만 구현
  """

  @type t :: %{
    id: String.t(),
    data: list(map()),
    columns: list(map()),
    state: map(),
    options: map()
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
    data = Keyword.fetch!(opts, :data)
    columns = Keyword.fetch!(opts, :columns)
    options = Keyword.get(opts, :options, %{})
    id = Keyword.get(opts, :id, generate_id())

    %{
      id: id,
      data: data,
      columns: normalize_columns(columns),
      state: initial_state(),
      options: merge_default_options(options)
    }
  end

  @doc """
  기존 Grid의 state를 보존하면서 data/columns/options만 갱신.
  LiveComponent의 update/2에서 부모 재렌더링 시 사용.
  """
  @spec update_data(grid :: t(), data :: list(map()), columns :: list(map()), options :: map()) :: t()
  def update_data(grid, data, columns, options) do
    %{grid |
      data: data,
      columns: normalize_columns(columns),
      options: merge_default_options(options)
    }
    |> put_in([:state, :pagination, :total_rows], length(data))
  end

  @doc """
  화면에 표시할 데이터 (정렬 + 페이징 적용)
  """
  @spec visible_data(grid :: t()) :: list(map())
  def visible_data(%{data: data, columns: columns, state: state, options: options}) do
    searched = apply_global_search(data, state.global_search, columns)
    filtered = apply_filters(searched, state.filters, columns)
    sorted = apply_sort(filtered, state.sort)

    # Virtual Scrolling 사용 시
    if options.virtual_scroll do
      apply_virtual_scroll(sorted, state.scroll_offset, options)
    else
      apply_pagination(sorted, state.pagination, options.page_size)
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
    |> apply_sort(state.sort)
  end

  @doc """
  필터 적용 후 데이터 개수 (footer에 표시할 건수)
  """
  @spec filtered_count(grid :: t()) :: non_neg_integer()
  def filtered_count(%{data: data, columns: columns, state: state}) do
    has_search = state.global_search != ""
    has_filters = map_size(state.filters) > 0

    if has_search or has_filters do
      data
      |> apply_global_search(state.global_search, columns)
      |> apply_filters(state.filters, columns)
      |> length()
    else
      length(data)
    end
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

  @doc "모든 행 상태를 초기화합니다."
  @spec clear_row_statuses(grid :: t()) :: t()
  def clear_row_statuses(grid) do
    put_in(grid.state.row_statuses, %{})
  end

  @doc "상태별 행 개수를 반환합니다."
  @spec status_counts(grid :: t()) :: map()
  def status_counts(grid) do
    grid.state.row_statuses
    |> Enum.group_by(fn {_id, status} -> status end)
    |> Enum.map(fn {status, rows} -> {status, length(rows)} end)
    |> Map.new()
  end

  # Private functions

  defp generate_id do
    "grid_" <> (:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower))
  end

  defp normalize_columns(columns) do
    Enum.map(columns, fn col ->
      Map.merge(%{
        width: :auto,
        sortable: false,
        filterable: false,
        filter_type: :text,
        editable: false,
        editor_type: :text,
        align: :left
      }, col)
    end)
  end

  defp initial_state do
    %{
      sort: nil,
      filters: %{},
      global_search: "",
      show_filter_row: false,
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
      row_statuses: %{},
      show_status_column: true
    }
  end

  defp merge_default_options(options) do
    Map.merge(%{
      page_size: 20,
      show_header: true,
      show_footer: true,
      virtual_scroll: false,
      virtual_buffer: 5,
      row_height: 40,
      debug: false
    }, options)
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

  defp apply_sort(data, nil), do: data
  defp apply_sort(data, %{field: field, direction: direction}) do
    LiveViewGrid.Sorting.sort(data, field, direction)
  end

  defp apply_pagination(data, pagination, page_size) do
    LiveViewGrid.Pagination.paginate(data, pagination.current_page, page_size)
  end

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
end
