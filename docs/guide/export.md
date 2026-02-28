# Export

Grid 데이터를 Excel(.xlsx) 또는 CSV 파일로 내보냅니다.

## Overview

툴바의 Export 버튼을 클릭하여 데이터를 다운로드합니다. 전체 데이터, 현재 페이지, 선택된 행 중 범위를 선택할 수 있습니다.

## Excel Export

```elixir
# 프로그래밍 방식
{:ok, {filename, binary}} = LiveViewGrid.Export.to_xlsx(
  data,
  columns,
  sheet_name: "Users"
)
```

### Features

- 컬럼 헤더 자동 스타일링 (굵은 글꼴)
- 컬럼 너비 자동 계산
- UTF-8 한글 지원
- Elixlsx 라이브러리 기반

## CSV Export

```elixir
csv_string = LiveViewGrid.Export.to_csv(data, columns)
```

### Features

- UTF-8 BOM 포함 (Excel 한글 호환)
- 따옴표/쉼표 이스케이프 처리
- 컬럼 label을 헤더로 사용

## Export Scope

| 범위 | 설명 |
|------|------|
| All | 필터 적용된 전체 데이터 |
| Visible | 현재 페이지의 보이는 데이터 |
| Selected | 체크박스로 선택된 행만 |

## Related

- [Selection](./selection.md) — 행 선택 후 내보내기
- [Formatters](./formatters.md) — 내보내기 시 포맷 적용
