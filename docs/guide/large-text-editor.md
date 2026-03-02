# Large Text Editor

긴 텍스트를 편집할 때 셀 내부 대신 모달 textarea를 사용합니다.

## API

```elixir
# 큰 텍스트 편집 시작
grid = Grid.start_large_text_edit(grid, row_id, :description)

# 편집 내용 저장
grid = Grid.save_large_text_edit(grid, "새로운 긴 텍스트 내용...")

# 편집 취소
grid = Grid.cancel_large_text_edit(grid)
```

## Column Configuration

```elixir
%{
  field: :description,
  label: "설명",
  editable: true,
  editor_type: :large_text  # 또는 컬럼 메뉴에서 자동 감지
}
```

## Features

- 모달 형태의 textarea 에디터
- 여러 줄 텍스트 입력 지원
- 저장(Save) / 취소(Cancel) 버튼
- ESC 키로 취소
- 기존 텍스트 자동 로드

## State

```elixir
grid.state.large_text_editing
# => %{row_id: 1, field: :description, value: "현재 텍스트"}
# => nil (편집 중 아닐 때)
```

## CSS Classes

```css
.lv-grid__large-text-overlay   /* 모달 배경 */
.lv-grid__large-text-editor    /* 에디터 컨테이너 */
.lv-grid__large-text-textarea  /* textarea 입력 */
.lv-grid__large-text-actions   /* 저장/취소 버튼 영역 */
```
