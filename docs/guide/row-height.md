# Row Height

Grid의 행 높이를 전체 또는 행별로 제어합니다.

## Overview

기본적으로 모든 행은 동일한 높이(40px)로 렌더링됩니다. Auto-fit 모드를 사용하면 Grid 전체 높이가 행 수에 맞게 자동 조절되고, Per-row Height를 사용하면 특정 행만 다른 높이로 설정할 수 있습니다.

## Default Row Height

`options.row_height`로 전체 행의 기본 높이를 설정합니다:

```elixir
options = %{row_height: 48}  # 전체 행 높이 48px (기본: 40)
```

유효 범위는 32 ~ 80 픽셀입니다.

## Auto-fit Type

`autofit_type: :row`를 설정하면 Grid body의 `max-height` 제한이 해제되어 모든 행이 스크롤 없이 표시됩니다:

```elixir
options = %{autofit_type: :row}  # 행 수에 맞게 높이 자동 조절
```

| Mode | 설명 | 스크롤바 |
|------|------|---------|
| `:none` (기본) | 고정 높이 (max-height: 600px) | 있음 |
| `:row` | 행 수에 맞춰 자동 조절 | 없음 |

페이징 없는 소량 데이터 표시에 적합합니다.

## Per-row Height

특정 행만 개별 높이를 설정할 수 있습니다:

```elixir
# 특정 행 높이 설정
grid = Grid.set_row_height(grid, row_id, 80)

# 특정 행 높이 초기화 (기본값으로 복원)
grid = Grid.reset_row_height(grid, row_id)

# 특정 행의 현재 높이 조회
Grid.get_row_height(grid, row_id)
# => 80  (설정값) 또는 40 (기본값)
```

### 동작

- 개별 높이가 설정된 행은 `min-height` inline style이 적용됩니다
- 미설정 행은 `options.row_height` 기본값을 사용합니다
- `state.row_heights`에 `%{row_id => height}` 형태로 저장됩니다

## CSS Classes

| 클래스 | 적용 대상 |
|--------|----------|
| `.lv-grid__body--autofit` | autofit_type=:row일 때 body |

## Options Reference

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `row_height` | integer | 40 | 전체 행 기본 높이 (px) |
| `autofit_type` | `:none \| :row` | `:none` | Grid 높이 자동 조절 |

## Related

- [Wordwrap](./wordwrap.md) — 텍스트 줄바꿈과 높이 확장
- [Grid Options](./grid-options.md) — row_height 옵션
- [Pagination](./pagination.md) — 페이지네이션과 높이
