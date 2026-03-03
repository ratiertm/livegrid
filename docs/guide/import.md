# Import (Excel/CSV/TSV)

CSV, TSV 파일을 Grid로 가져옵니다.

## Overview

파일을 선택하면 브라우저에서 파싱 후 Grid에 자동으로 데이터가 추가됩니다. 구분자(쉼표/탭)는 자동 감지됩니다.

## Enabling Import

`FileImport` Hook을 사용하는 file input을 추가합니다:

```heex
<input
  type="file"
  accept=".csv,.tsv,.txt"
  phx-hook="FileImport"
  id="grid-import"
  data-target={@grid_id}
/>
```

## Handling Import Events

서버에서 import 이벤트를 처리합니다:

```elixir
def handle_event("import_file", %{"headers" => headers, "data" => data_rows}, socket) do
  # headers: ["name", "age", "city"]
  # data_rows: [["Alice", "28", "Seoul"], ["Bob", "35", "Busan"]]

  rows = Enum.map(data_rows, fn row ->
    headers
    |> Enum.zip(row)
    |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)
  end)

  grid = Enum.reduce(rows, socket.assigns.grid, &Grid.add_row(&2, &1))
  {:noreply, assign(socket, grid: grid)}
end
```

## Supported Formats

| 포맷 | 확장자 | 구분자 |
|------|--------|--------|
| CSV | `.csv` | 쉼표 (`,`) |
| TSV | `.tsv`, `.txt` | 탭 (`\t`) |

## Behavior

- 첫 번째 행은 **헤더**로 인식됩니다
- 구분자는 파일 내용을 분석하여 자동 감지합니다
- 따옴표로 감싼 필드(`"value"`)를 올바르게 처리합니다
- 값의 앞뒤 공백은 자동 제거됩니다

## Related

- [Export](./export.md) — Excel/CSV 내보내기
- [Row Data](./row-data.md) — 데이터 바인딩
- [CRUD Operations](./crud-operations.md) — 행 추가/삭제
