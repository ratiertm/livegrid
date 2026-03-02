defmodule LiveViewGrid.Locale do
  @moduledoc """
  Grid UI 텍스트 다국어 지원 (FA-021).

  ## 지원 언어
  - `:ko` (한국어, 기본값)
  - `:en` (영어)
  - `:ja` (일본어)

  ## 사용법

      iex> Locale.t(:search_placeholder, :ko)
      "전체 검색..."

      iex> Locale.t(:search_placeholder, :en)
      "Search all..."

      iex> Locale.t(:search_placeholder, :ko, %{search_placeholder: "검색하기"})
      "검색하기"
  """

  @translations %{
    ko: %{
      search_placeholder: "전체 검색...",
      filter_placeholder: "필터...",
      no_data: "데이터가 없습니다",
      loading: "로딩 중...",
      error: "오류가 발생했습니다",
      total_rows: "전체",
      filtered: "필터됨",
      selected: "선택됨",
      page_of: "페이지",
      add_row: "+ 추가",
      settings: "설정",
      undo: "↩",
      redo: "↪",
      sort_asc: "오름차순 정렬",
      sort_desc: "내림차순 정렬",
      hide_column: "컬럼 숨기기",
      autofit_width: "자동 너비 맞춤",
      clear_filter: "필터 초기화",
      select_all: "전체 선택",
      deselect_all: "전체 해제",
      rows_unit: "행",
      name_filter: "이름 필터...",
      number_filter: "숫자 필터...",
      status: "상태",
      subtotal: "소계",
      expand_all: "전체 펼침",
      collapse_all: "전체 접기",
      print: "인쇄",
      detail: "상세",
      sidebar: "사이드바",
      find: "찾기",
      find_placeholder: "텍스트 검색...",
      batch_edit: "일괄 편집",
      large_text_edit: "텍스트 편집"
    },
    en: %{
      search_placeholder: "Search all...",
      filter_placeholder: "Filter...",
      no_data: "No data available",
      loading: "Loading...",
      error: "An error occurred",
      total_rows: "Total",
      filtered: "Filtered",
      selected: "Selected",
      page_of: "Page",
      add_row: "+ Add",
      settings: "Settings",
      undo: "↩",
      redo: "↪",
      sort_asc: "Sort Ascending",
      sort_desc: "Sort Descending",
      hide_column: "Hide Column",
      autofit_width: "Auto-fit Width",
      clear_filter: "Clear Filter",
      select_all: "Select All",
      deselect_all: "Deselect All",
      rows_unit: "rows",
      name_filter: "Filter...",
      number_filter: "Number filter...",
      status: "Status",
      subtotal: "Subtotal",
      expand_all: "Expand All",
      collapse_all: "Collapse All",
      print: "Print",
      detail: "Detail",
      sidebar: "Sidebar",
      find: "Find",
      find_placeholder: "Search text...",
      batch_edit: "Batch Edit",
      large_text_edit: "Edit Text"
    },
    ja: %{
      search_placeholder: "全体検索...",
      filter_placeholder: "フィルター...",
      no_data: "データがありません",
      loading: "読み込み中...",
      error: "エラーが発生しました",
      total_rows: "合計",
      filtered: "フィルター済み",
      selected: "選択済み",
      page_of: "ページ",
      add_row: "+ 追加",
      settings: "設定",
      undo: "↩",
      redo: "↪",
      sort_asc: "昇順ソート",
      sort_desc: "降順ソート",
      hide_column: "列を隠す",
      autofit_width: "幅の自動調整",
      clear_filter: "フィルタークリア",
      select_all: "全選択",
      deselect_all: "全解除",
      rows_unit: "行",
      name_filter: "フィルター...",
      number_filter: "数値フィルター...",
      status: "状態",
      subtotal: "小計",
      expand_all: "全展開",
      collapse_all: "全折畳",
      print: "印刷",
      detail: "詳細",
      sidebar: "サイドバー",
      find: "検索",
      find_placeholder: "テキスト検索...",
      batch_edit: "一括編集",
      large_text_edit: "テキスト編集"
    }
  }

  @doc """
  키에 해당하는 번역 텍스트를 반환한다.

  ## Parameters
    - key: 번역 키 (atom)
    - locale: 언어 코드 (:ko, :en, :ja)
    - overrides: 커스텀 텍스트 오버라이드 맵 (옵션)

  ## Examples

      iex> Locale.t(:loading, :en)
      "Loading..."

      iex> Locale.t(:loading, :ko, %{loading: "불러오는 중..."})
      "불러오는 중..."
  """
  @spec t(key :: atom(), locale :: atom(), overrides :: map()) :: String.t()
  def t(key, locale \\ :ko, overrides \\ %{}) do
    case Map.get(overrides, key) do
      nil ->
        locale_map = Map.get(@translations, locale, @translations[:ko])
        Map.get(locale_map, key, to_string(key))
      text ->
        text
    end
  end

  @doc "지원되는 로케일 목록"
  @spec supported_locales() :: list(atom())
  def supported_locales, do: Map.keys(@translations)
end
