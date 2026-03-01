# Find & Highlight (검색 하이라이트)

Ctrl+F로 열리는 검색 바로 그리드 내 모든 셀에서 텍스트를 검색하고 시각적으로 하이라이트합니다.

## Overview

Find & Highlight는 기존 `global_search`(행 필터링)와 다르게 **모든 행을 유지**하면서 매칭 셀만 시각적으로 강조합니다.

| Feature | global_search | Find & Highlight |
|---------|--------------|-----------------|
| 동작 | 매칭 행만 필터링 | 모든 행 유지, 매칭 셀 강조 |
| 활성화 | 검색 입력 시 자동 | Ctrl+F로 토글 |
| UI | 툴바 검색 입력 | 플로팅 검색 바 |

## 사용법

### 키보드 단축키

| 단축키 | 동작 |
|--------|------|
| `Ctrl+F` (Mac: `Cmd+F`) | 검색 바 열기/닫기 |
| `Enter` | 다음 매칭으로 이동 |
| `Shift+Enter` | 이전 매칭으로 이동 |
| `Escape` | 검색 바 닫기 |

### Find Bar UI

검색 바는 그리드 상단에 표시되며 다음 요소로 구성됩니다:

```
[magnifier] [검색 입력 필드] [2/15] [up] [down] [X]
```

- 검색 입력: 실시간 검색 (200ms debounce)
- 카운트: 현재 매칭 위치 / 전체 매칭 수
- 화살표 버튼: 이전/다음 매칭 탐색
- X 버튼: 검색 닫기

### 하이라이트 색상

- **매칭 셀**: 노란색 배경 (`#fff3b0`)
- **현재 매칭**: 주황색 배경 (`#ff9632`, 흰색 텍스트)

## 프로그래밍 API

```elixir
# 매칭 셀 검색 (대소문자 무시)
matches = Grid.find_matches(grid, "서울")
# => [{row_id_1, :city}, {row_id_2, :address}]

# 빈 검색어
Grid.find_matches(grid, "")   # => []
Grid.find_matches(grid, nil)  # => []
```

### 검색 동작

- 대소문자 무시 (case-insensitive)
- 부분 일치 (partial match)
- 모든 표시 컬럼 검색
- nil 값은 건너뜀
- Wrap-around 네비게이션 (마지막 → 첫 번째)

## CSS 커스터마이징

```css
/* 매칭 셀 배경 */
.lv-grid__find-highlight {
  background: #fff3b0 !important;
}

/* 현재 매칭 배경 */
.lv-grid__find-highlight--current {
  background: #ff9632 !important;
  color: #fff !important;
}

/* mark 태그 스타일 */
.lv-grid__find-highlight mark {
  background: #fff3b0;
  color: inherit;
}
```

## Related

- [Keyboard Navigation](./keyboard-navigation.md) -- 키보드 단축키
- [Grid Options](./grid-options.md) -- Grid 설정
- [Filtering](./filtering.md) -- 행 필터링 (global_search)
