# CRUD Operations

Grid는 행 추가, 수정, 삭제, 일괄 저장을 지원합니다. 변경 사항은 즉시 반영되지 않고 "저장" 시 일괄 처리됩니다.

## Overview

CRUD 워크플로우:
1. 행 추가/수정/삭제 (로컬 상태 변경)
2. 변경 사항 확인 (`has_changes?`)
3. 저장 버튼 클릭 → DataSource에 반영

## Add Row

```elixir
# 상단에 추가
grid = Grid.add_row(grid, %{name: "", email: ""}, :top)

# 하단에 추가 (기본)
grid = Grid.add_row(grid, %{name: "", email: ""})
```

- 임시 ID 자동 생성 (`temp_1`, `temp_2`, ...)
- 행 상태: `:new` (초록색 표시)
- 편집 모드 자동 진입

## Update Cell

더블클릭 또는 F2로 셀 편집 후 Enter로 저장:

```elixir
grid = Grid.update_cell(grid, row_id, :name, "New Name")
```

- 행 상태: `:updated` (주황색 표시)
- Undo/Redo 이력에 기록

## Delete Rows

선택된 행을 삭제 대기 상태로 표시합니다:

```elixir
grid = Grid.delete_rows(grid, [row_id_1, row_id_2])
```

- 행 상태: `:deleted` (빨간색 취소선)
- 실제 삭제는 "저장" 시 처리

## Save Changes

모든 변경 사항을 DataSource에 일괄 반영합니다:

```elixir
# 변경된 행 조회
Grid.changed_rows(grid)
# => [
#   %{row: %{id: "temp_1", ...}, status: :new},
#   %{row: %{id: 5, ...}, status: :updated},
#   %{row: %{id: 3, ...}, status: :deleted}
# ]

# 미저장 변경 확인
Grid.has_changes?(grid)  # => true
```

### DataSource별 저장 동작

| DataSource | :new | :updated | :deleted |
|------------|------|----------|----------|
| InMemory | 로컬 추가 | 로컬 수정 | 로컬 제거 |
| Ecto | INSERT | UPDATE | DELETE |
| REST | POST | PUT/PATCH | DELETE |

## Discard Changes

모든 변경 사항을 취소합니다:

```elixir
grid = Grid.clear_row_statuses(grid)
```

## Import (Excel/CSV)

Excel 또는 CSV 파일에서 데이터를 가져옵니다:

1. 파일 드래그 & 드롭 또는 파일 선택
2. 컬럼 매핑 UI (파일 컬럼 → Grid 컬럼)
3. 미리보기 확인
4. 가져오기 실행

## Paste (Excel)

Excel에서 복사한 데이터를 Grid에 붙여넣기:

- `Ctrl+V` 또는 컨텍스트 메뉴의 "붙여넣기"
- 탭 구분 텍스트 자동 파싱
- 여러 행/열 동시 붙여넣기 지원

## Related

- [Cell Editing](./cell-editing.md) — 셀 편집 & 검증
- [Row Editing](./row-editing.md) — 행 단위 편집
- [Data Sources](./data-sources.md) — DataSource별 저장
- [Selection](./selection.md) — 행 선택 후 삭제
