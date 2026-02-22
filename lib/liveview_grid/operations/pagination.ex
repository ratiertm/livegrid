defmodule LiveViewGrid.Pagination do
  @moduledoc """
  Grid 페이지네이션.

  데이터를 페이지 단위로 슬라이싱하고, 총 페이지 수를 계산합니다.
  `Grid.visible_data/1`에서 내부적으로 호출됩니다.

  Virtual Scroll이 활성화된 경우 이 모듈 대신 viewport 기반
  부분 렌더링이 적용됩니다 (`options.virtual_scroll: true`).
  """

  @doc """
  페이지별 데이터 슬라이싱
  
  ## Examples
  
      iex> data = Enum.map(1..100, &%{id: &1})
      iex> Pagination.paginate(data, 1, 20)
      [%{id: 1}, %{id: 2}, ..., %{id: 20}]
  """
  @spec paginate(data :: list(), page :: pos_integer(), page_size :: pos_integer()) :: list()
  def paginate(data, page, page_size) when is_list(data) and page > 0 and page_size > 0 do
    start_index = (page - 1) * page_size
    Enum.slice(data, start_index, page_size)
  end

  @doc """
  총 페이지 수 계산
  
  ## Examples
  
      iex> Pagination.total_pages(100, 20)
      5
      
      iex> Pagination.total_pages(101, 20)
      6
  """
  @spec total_pages(total_rows :: non_neg_integer(), page_size :: pos_integer()) :: non_neg_integer()
  def total_pages(0, _page_size), do: 0
  def total_pages(total_rows, page_size) when total_rows > 0 and page_size > 0 do
    ceil(total_rows / page_size)
  end
end
