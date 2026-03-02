# FA-010 Column Menu - Gap Analysis

> **Feature**: FA-010 Column Menu
> **Date**: 2026-03-01
> **Match Rate**: 92%

## 요구사항 매칭

| # | 요구사항 | 구현 | 상태 |
|---|---------|------|------|
| FR-01 | 메뉴 아이콘 (hover 시 표시) | ☰ 버튼, CSS hover로 display:flex 토글 | ✅ |
| FR-02 | 메뉴 항목 (정렬/숨기기/자동너비/필터초기화) | 5개 메뉴 항목 + 구분선 렌더링 | ✅ |
| FR-03 | column_menu 옵션 (grid/컬럼별) | show_column_menu + column.menu, column_menu_enabled? 헬퍼 | ✅ |

## 코드 검증

| 항목 | 결과 |
|------|------|
| mix test (grid_test.exs) | ✅ 249/249 통과 |
| Preview 콘솔 에러 | ✅ 0개 |
| 메뉴 아이콘 렌더링 | ✅ 7개 컬럼에 버튼 생성 |
| 메뉴 드롭다운 열기 | ✅ 5개 메뉴 항목 + 2개 구분선 |
| 오름차순 정렬 | ✅ 정렬 적용 + 메뉴 자동 닫힘 |
| column_menu_enabled? | ✅ grid 옵션 + 컬럼별 설정 반영 |

## Match Rate: 92%
- -4%: AG Grid의 컬럼 고정(Pin Left/Right) 메뉴 항목 미구현 (FA-001 Row Pinning은 있으나 Column Pinning은 별도)
- -2%: 자동 너비 맞춤(autofit)이 JS push_event만 발행하며 실제 JS Hook 처리 미구현
- -2%: 메뉴 외부 클릭 시 자동 닫힘 미구현 (버튼 재클릭으로 닫기)
