# FA-011 Floating Filters - Gap Analysis

> **Feature**: FA-011 Floating Filters
> **Date**: 2026-03-01
> **Match Rate**: 95%

## 요구사항 매칭

| # | 요구사항 | 구현 | 상태 |
|---|---------|------|------|
| FR-01 | floating_filter 옵션 | default_options에 floating_filter: false 추가 | ✅ |
| FR-02 | 컬럼별 floating_filter | normalize_columns에 floating_filter: nil 추가, floating_filter_enabled? 헬퍼 | ✅ |
| FR-03 | 기존 필터 행과 공존 | show_filter_row 토글과 독립 렌더링 | ✅ |

## 코드 검증

| 항목 | 결과 |
|------|------|
| mix test (grid_test.exs) | ✅ 247/247 통과 |
| Preview 콘솔 에러 | ✅ 0개 |
| Floating Filter 표시 | ✅ 항상 표시 |
| 필터 입력 동작 | ✅ phx-keyup/phx-change 연동 |

## Match Rate: 95%
- -3%: AG Grid의 커스텀 Floating Filter 컴포넌트(숫자 범위, 날짜 범위 등) 미지원
- -2%: Floating Filter와 Column Filter 연동 (필터 아이콘 표시) 미구현
