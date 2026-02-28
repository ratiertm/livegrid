defmodule LiveViewGrid.Export do
  @moduledoc """
  그리드 데이터를 Excel (.xlsx) 및 CSV 형식으로 변환하는 모듈.

  ## Usage

      # Excel Export
      {:ok, {_filename, xlsx_binary}} = Export.to_xlsx(data, columns)

      # CSV Export
      csv_string = Export.to_csv(data, columns)
  """

  alias Elixlsx.{Workbook, Sheet}

  @doc """
  데이터를 Excel (.xlsx) 바이너리로 변환.

  ## Parameters
    - data: 행 데이터 리스트 `[%{field: value, ...}, ...]`
    - columns: 컬럼 정의 리스트 `[%{field: :atom, label: "표시명"}, ...]`
    - opts: 옵션 키워드 리스트
      - `:sheet_name` - 시트 이름 (기본: "Sheet1")
      - `:header_style` - 헤더 스타일 적용 여부 (기본: true)

  ## Returns
    `{:ok, {filename, binary}}` | `{:error, reason}`

  ## Examples

      {:ok, {_name, binary}} = Export.to_xlsx(users, columns)
      {:ok, {_name, binary}} = Export.to_xlsx(users, columns, sheet_name: "사용자")
  """
  @spec to_xlsx(data :: [map()], columns :: [map()], opts :: keyword()) ::
          {:ok, {String.t(), binary()}} | {:error, any()}
  def to_xlsx(data, columns, opts \\ []) do
    sheet_name = Keyword.get(opts, :sheet_name, "Sheet1")
    header_style = Keyword.get(opts, :header_style, true)

    # 1. 헤더 행 생성
    headers = build_headers(columns, header_style)

    # 2. 데이터 행 생성
    rows = build_data_rows(data, columns)

    # 3. 컬럼 너비 계산
    col_widths = generate_col_widths(columns)

    # 4. 워크북 생성
    sheet = %Sheet{
      name: sheet_name,
      rows: [headers | rows],
      col_widths: col_widths
    }

    workbook = %Workbook{sheets: [sheet]}

    # 5. 바이너리로 변환
    Elixlsx.write_to_memory(workbook, "export.xlsx")
  end

  @doc """
  데이터를 CSV 문자열로 변환 (UTF-8 BOM 포함).

  ## Parameters
    - data: 행 데이터 리스트
    - columns: 컬럼 정의 리스트

  ## Returns
    binary (CSV 문자열, UTF-8 BOM 포함)
  """
  @spec to_csv(data :: [map()], columns :: [map()]) :: binary()
  def to_csv(data, columns) do
    # UTF-8 BOM (Excel에서 한글 깨짐 방지)
    bom = <<0xEF, 0xBB, 0xBF>>

    # 헤더
    header_line =
      columns
      |> Enum.map(& &1.label)
      |> Enum.map(&escape_csv/1)
      |> Enum.join(",")

    # 데이터 행
    data_lines =
      Enum.map(data, fn row ->
        columns
        |> Enum.map(fn col -> Map.get(row, col.field) end)
        |> Enum.map(&format_csv_value/1)
        |> Enum.map(&escape_csv/1)
        |> Enum.join(",")
      end)

    csv_content = [header_line | data_lines] |> Enum.join("\n")

    bom <> csv_content
  end

  # ── Private: Excel ──

  defp build_headers(columns, true) do
    Enum.map(columns, fn col ->
      [col.label, bold: true, bg_color: "#4472C4", font_color: "#FFFFFF"]
    end)
  end

  defp build_headers(columns, false) do
    Enum.map(columns, fn col -> col.label end)
  end

  defp build_data_rows(data, columns) do
    Enum.map(data, fn row ->
      Enum.map(columns, fn col ->
        value = Map.get(row, col.field)
        format_cell_value(value)
      end)
    end)
  end

  defp format_cell_value(nil), do: ""
  defp format_cell_value(value) when is_integer(value), do: value
  defp format_cell_value(value) when is_float(value), do: value
  defp format_cell_value(true), do: "O"
  defp format_cell_value(false), do: "X"
  defp format_cell_value(value), do: to_string(value)

  defp generate_col_widths(columns) do
    columns
    |> Enum.with_index(1)
    |> Enum.map(fn {col, idx} ->
      width =
        case Map.get(col, :width) do
          w when is_integer(w) and w > 0 -> max(10, div(w, 7))
          _ -> 15
        end

      {idx, width}
    end)
    |> Map.new()
  end

  # ── Private: CSV ──

  defp format_csv_value(nil), do: ""
  defp format_csv_value(true), do: "O"
  defp format_csv_value(false), do: "X"
  defp format_csv_value(value), do: to_string(value)

  defp escape_csv(value) do
    str = to_string(value)

    if String.contains?(str, [",", "\"", "\n", "\r"]) do
      "\"#{String.replace(str, "\"", "\"\"")}\""
    else
      str
    end
  end
end
