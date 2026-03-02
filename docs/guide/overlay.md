# Overlay

그리드 위에 loading, no_data, error 상태를 오버레이로 표시합니다.

## API

```elixir
# 로딩 오버레이 표시
grid = Grid.set_overlay(grid, :loading)

# 메시지와 함께 표시
grid = Grid.set_overlay(grid, :loading, "데이터를 불러오는 중...")

# 데이터 없음 오버레이
grid = Grid.set_overlay(grid, :no_data, "표시할 데이터가 없습니다")

# 에러 오버레이
grid = Grid.set_overlay(grid, :error, "데이터 로드 실패")

# 오버레이 제거
grid = Grid.clear_overlay(grid)
```

## Overlay Types

| Type | Icon | Default Message | CSS Class |
|------|------|----------------|-----------|
| `:loading` | Spinner | "Loading..." | `.lv-grid__overlay` |
| `:no_data` | - | "No data" | `.lv-grid__overlay--no_data` |
| `:error` | Error icon | "Error" | `.lv-grid__overlay--error` |

## CSS Structure

```css
.lv-grid__overlay              /* 전체 오버레이 배경 */
.lv-grid__overlay-inner        /* 중앙 정렬 컨테이너 */
.lv-grid__overlay-spinner      /* 로딩 스피너 (CSS animation) */
.lv-grid__overlay-text         /* 메시지 텍스트 */
.lv-grid__overlay-icon         /* 아이콘 */
.lv-grid__overlay-icon--error  /* 에러 아이콘 (빨간색) */
```

## Behavior

- 오버레이 표시 중에는 그리드 인터랙션 차단 (`pointer-events: all`)
- z-index: `var(--lv-grid-z-overlay)` (100)
- 로딩 스피너: CSS `@keyframes lv-grid-spin` 애니메이션
