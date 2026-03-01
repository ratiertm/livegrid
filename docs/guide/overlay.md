# Overlay System

그리드 위에 Loading, No Data, Error 상태를 오버레이로 표시합니다.

## Overview

데이터 로딩 중이거나 데이터가 없을 때, 또는 오류 발생 시 사용자에게 시각적 피드백을 제공합니다.

## 사용법

```elixir
# 로딩 오버레이 표시
grid = Grid.set_overlay(grid, :loading)
grid = Grid.set_overlay(grid, :loading, "서버에서 데이터를 가져오는 중...")

# 데이터 없음 오버레이
grid = Grid.set_overlay(grid, :no_data, "검색 결과가 없습니다")

# 에러 오버레이
grid = Grid.set_overlay(grid, :error, "네트워크 오류가 발생했습니다")

# 오버레이 해제
grid = Grid.clear_overlay(grid)
# 또는
grid = Grid.set_overlay(grid, nil)
```

## 오버레이 유형

| Type | Icon | Default Message | Style |
|------|------|-----------------|-------|
| `:loading` | Spinner (CSS animation) | "데이터를 불러오는 중..." | 기본 텍스트 색상 |
| `:no_data` | 📭 | "표시할 데이터가 없습니다" | 기본 텍스트 색상 |
| `:error` | ⚠ | "오류가 발생했습니다" | 빨간색 텍스트 |

## 실사용 예시

```elixir
# LiveView에서 비동기 데이터 로드
def mount(_params, _session, socket) do
  grid = Grid.new(data: [], columns: columns)
  grid = Grid.set_overlay(grid, :loading)
  send(self(), :load_data)
  {:ok, assign(socket, grid: grid)}
end

def handle_info(:load_data, socket) do
  case fetch_data() do
    {:ok, []} ->
      grid = socket.assigns.grid
      |> Grid.set_overlay(:no_data)
      {:noreply, assign(socket, grid: grid)}

    {:ok, data} ->
      grid = socket.assigns.grid
      |> Grid.update_data(data, columns)
      |> Grid.clear_overlay()
      {:noreply, assign(socket, grid: grid)}

    {:error, reason} ->
      grid = Grid.set_overlay(socket.assigns.grid, :error, reason)
      {:noreply, assign(socket, grid: grid)}
  end
end
```

## API Reference

| Function | Return | Description |
|----------|--------|-------------|
| `Grid.set_overlay(grid, type)` | `Grid.t()` | 오버레이 표시 (기본 메시지) |
| `Grid.set_overlay(grid, type, message)` | `Grid.t()` | 커스텀 메시지와 함께 오버레이 표시 |
| `Grid.set_overlay(grid, nil)` | `Grid.t()` | 오버레이 해제 |
| `Grid.clear_overlay(grid)` | `Grid.t()` | 오버레이 해제 |

## 스타일 커스터마이징

CSS 변수로 오버레이 스타일을 커스터마이징할 수 있습니다:

```css
.lv-grid__overlay {
  background: rgba(255, 255, 255, 0.85);  /* 배경 투명도 */
  backdrop-filter: blur(2px);              /* 블러 효과 */
}
```
