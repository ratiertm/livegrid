# Find Bar

Grid 상단의 검색 바로 전체 데이터를 실시간 필터링합니다.

## Overview

Find Bar는 모든 컬럼을 대상으로 텍스트 검색을 수행하는 전체 검색 UI입니다. 입력과 동시에 매칭되는 행만 표시됩니다.

## Keyboard Shortcuts

| 단축키 | 동작 |
|--------|------|
| `Enter` | 다음 매칭 행으로 이동 |
| `Shift+Enter` | 이전 매칭 행으로 이동 |
| `Esc` | 검색 닫기 / 검색어 초기화 |

## UI Elements

```
┌──────────────────────────────────┐
│ 🔍 [검색어 입력________] [Clear] │
├──────────────────────────────────┤
│  Grid 데이터 (필터링됨)          │
```

## Event Handler

```elixir
# 검색어 변경 시 자동 호출
handle_event("grid_global_search", %{"value" => search_term}, socket)
```

## Grid State

```elixir
%{
  global_search: ""  # 현재 검색어 (빈 문자열 = 검색 해제)
}
```

## Behavior

- 입력할 때마다 **실시간**으로 필터링됩니다
- **모든 컬럼**의 텍스트를 대상으로 검색합니다
- 대소문자를 **구분하지 않습니다**
- Clear 버튼 또는 `Esc` 키로 검색을 초기화합니다
- 컬럼별 필터와 **동시에** 사용할 수 있습니다

## Related

- [Filtering](./filtering.md) — 컬럼별 상세 필터
- [Keyboard Navigation](./keyboard-navigation.md) — 키보드 조작
- [Grid Options](./grid-options.md) — 검색 바 표시 설정
