defmodule LiveviewGridWeb.CSVController do
  use LiveviewGridWeb, :controller

  def download(conn, %{"data" => data_json, "filename" => filename}) do
    # JSON 파싱
    {:ok, data} = Jason.decode(data_json)
    
    # CSV 생성
    csv_content = generate_csv(data)
    
    # 파일 다운로드
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, csv_content)
  end

  defp generate_csv([]), do: ""
  defp generate_csv([first | _rest] = data) do
    # 헤더 생성
    headers = Map.keys(first) |> Enum.join(",")
    
    # 데이터 행 생성
    rows = Enum.map(data, fn row ->
      Map.values(row)
      |> Enum.map(&to_string/1)
      |> Enum.map(&escape_csv/1)
      |> Enum.join(",")
    end)
    
    # 헤더 + 데이터
    [headers | rows]
    |> Enum.join("\n")
  end

  # CSV 이스케이프 (쉼표, 따옴표 처리)
  defp escape_csv(value) do
    value = to_string(value)
    if String.contains?(value, [",", "\"", "\n"]) do
      "\"#{String.replace(value, "\"", "\"\"")}\""
    else
      value
    end
  end
end
