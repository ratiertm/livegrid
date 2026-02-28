# Pagination & Virtual Scroll

Grid는 두 가지 데이터 탐색 모드를 제공합니다: 페이지네이션과 가상 스크롤.

## Pagination (기본 모드)

데이터를 페이지 단위로 나누어 표시합니다.

```elixir
options = %{
  page_size: 20,        # 페이지당 행 수 (기본: 20)
  show_footer: true     # 페이지네이션 UI 표시
}
```

### 페이지 크기 변경

Footer의 드롭다운에서 사용자가 직접 변경할 수 있습니다:

- 50개, 100개, 200개, 300개, 400개, 500개

### 페이지 네비게이션

- `<` / `>` 버튼으로 이전/다음 페이지
- 페이지 번호 버튼으로 직접 이동
- 현재 페이지 주변 ±2 범위 표시

## Virtual Scroll

10,000행 이상의 대용량 데이터에 적합합니다. viewport 영역의 행만 실제 DOM으로 렌더링합니다.

```elixir
options = %{
  virtual_scroll: true,
  row_height: 40,       # 행 높이 (px, 필수)
  virtual_buffer: 5     # 버퍼 행 수 (기본: 5)
}
```

### 동작 원리

1. 전체 데이터의 높이를 계산 (`행 수 x row_height`)
2. 스크롤 위치에 따라 보이는 영역의 행만 렌더링
3. 버퍼 행을 추가하여 스크롤 시 깜빡임 방지
4. `VirtualScroll` JS Hook이 스크롤 이벤트를 처리

### 성능 특성

| 데이터 크기 | 실제 DOM 노드 | 메모리 사용 |
|------------|--------------|------------|
| 1,000행 | ~20개 | 낮음 |
| 100,000행 | ~20개 | 낮음 |
| 1,000,000행 | ~20개 | 낮음 |

> Virtual Scroll은 행 수에 관계없이 일정한 DOM 노드 수를 유지합니다.

## Grid State

```elixir
# 현재 페이지 정보
grid.state.pagination.current_page  # => 1
grid.state.pagination.total_rows    # => 500

# Virtual Scroll 오프셋
grid.state.scroll_offset  # => 42
```

## Related

- [Row Data](./row-data.md) — 데이터 크기별 권장 모드
- [Grid Options](./grid-options.md) — page_size, virtual_scroll 등
