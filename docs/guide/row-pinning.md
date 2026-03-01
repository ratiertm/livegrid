# Row Pinning (행 고정)

특정 행을 그리드 상단 또는 하단에 고정하여 스크롤해도 항상 보이게 합니다.

## Overview

Row Pinning은 중요한 행(합계, 기준 행 등)을 항상 화면에 표시할 때 사용합니다.

## 사용법

### 1. Context Menu (UI)

행을 우클릭하면 Context Menu에 고정 옵션이 나타납니다:

- **↑ 상단 고정** — 행을 그리드 상단에 고정
- **↓ 하단 고정** — 행을 그리드 하단에 고정
- **고정 해제** — 이미 고정된 행의 고정을 해제

### 2. 프로그래밍 API

```elixir
# 상단에 고정
grid = Grid.pin_rows(grid, [row_id], :top)

# 하단에 고정
grid = Grid.pin_rows(grid, [row_id], :bottom)

# 여러 행 동시에 고정
grid = Grid.pin_rows(grid, [1, 3, 5], :top)

# 고정 해제
grid = Grid.unpin_rows(grid, [row_id])

# 고정 상태 확인
Grid.pinned?(grid, row_id)  # :top | :bottom | false

# 고정된 행 데이터 조회
Grid.pinned_top_rows(grid)     # [%{id: 1, ...}, ...]
Grid.pinned_bottom_rows(grid)  # [%{id: 5, ...}, ...]
```

## 동작 방식

- 고정된 행은 파란색 배경으로 구분됩니다
- 상단 고정: 파란색 하단 보더로 영역 구분
- 하단 고정: 파란색 상단 보더로 영역 구분
- 📌 아이콘으로 고정 상태 표시
- ✕ 버튼(hover 시 표시)으로 고정 해제 가능
- 같은 행을 다른 위치로 고정 시 자동 이동 (top → bottom)
- Status Bar가 활성화되어 있으면 고정 행 수가 표시됩니다

## API Reference

| Function | Return | Description |
|----------|--------|-------------|
| `Grid.pin_rows(grid, ids, :top \| :bottom)` | `Grid.t()` | 행을 상단/하단에 고정 |
| `Grid.unpin_rows(grid, ids)` | `Grid.t()` | 행 고정 해제 |
| `Grid.pinned?(grid, id)` | `:top \| :bottom \| false` | 고정 상태 확인 |
| `Grid.pinned_top_rows(grid)` | `[map()]` | 상단 고정 행 목록 |
| `Grid.pinned_bottom_rows(grid)` | `[map()]` | 하단 고정 행 목록 |
