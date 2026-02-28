defmodule LiveViewGrid.GridDefinition do
  @moduledoc """
  Grid의 원본 정의(Blueprint).

  Runtime Config(컬럼 숨기기, 속성 변경 등)와 분리된 불변 원본.
  Config Modal의 Reset, 컬럼 복원 등의 기준점이 된다.
  """

  @type column_def :: %{
    field: atom(),
    label: String.t(),
    type: :string | :integer | :float | :boolean | :date | :datetime,
    width: integer() | :auto,
    align: :left | :center | :right,
    sortable: boolean(),
    filterable: boolean(),
    filter_type: atom(),
    editable: boolean(),
    editor_type: atom(),
    editor_options: list(),
    formatter: atom() | nil,
    formatter_options: map(),
    validators: list(),
    renderer: atom() | nil,
    header_group: String.t() | nil,
    input_pattern: String.t() | nil,
    style_expr: term(),
    nulls: :first | :last,
    required: boolean()
  }

  @type t :: %{
    columns: [column_def()],
    options: map()
  }

  @column_defaults %{
    type: :string,
    width: :auto,
    align: :left,
    sortable: false,
    filterable: false,
    filter_type: :text,
    editable: false,
    editor_type: :text,
    editor_options: [],
    formatter: nil,
    formatter_options: %{},
    validators: [],
    renderer: nil,
    header_group: nil,
    input_pattern: nil,
    style_expr: nil,
    nulls: :last,
    required: false,
    summary: nil
  }

  @doc """
  컬럼 정의 리스트와 옵션으로 GridDefinition을 생성한다.

  각 컬럼에 기본값을 머지하고, field/label 필수 검증을 수행한다.
  """
  @spec new(columns :: [map()], options :: map()) :: t()
  def new(columns, options \\ %{}) when is_list(columns) do
    normalized = Enum.map(columns, &normalize_column_def/1)
    validate!(normalized)
    %{columns: normalized, options: options}
  end

  @doc "Definition에서 특정 field의 컬럼 정의를 조회한다."
  @spec get_column(t(), atom()) :: column_def() | nil
  def get_column(%{columns: columns}, field) do
    Enum.find(columns, &(&1.field == field))
  end

  @doc "Definition의 전체 field 목록을 반환한다."
  @spec fields(t()) :: [atom()]
  def fields(%{columns: columns}), do: Enum.map(columns, & &1.field)

  @doc "Definition의 컬럼 수를 반환한다."
  @spec column_count(t()) :: non_neg_integer()
  def column_count(%{columns: columns}), do: length(columns)

  # -- Private --

  defp normalize_column_def(col) do
    Map.merge(@column_defaults, col)
  end

  defp validate!(columns) do
    Enum.each(columns, fn col ->
      unless Map.has_key?(col, :field) and is_atom(col.field) do
        raise ArgumentError, "컬럼에 :field (atom) 필수: #{inspect(col)}"
      end

      unless Map.has_key?(col, :label) and is_binary(col.label) do
        raise ArgumentError, "컬럼에 :label (string) 필수: #{inspect(col)}"
      end
    end)

    fields = Enum.map(columns, & &1.field)

    if length(fields) != length(Enum.uniq(fields)) do
      raise ArgumentError, "컬럼 field 중복 불가: #{inspect(fields)}"
    end
  end
end
