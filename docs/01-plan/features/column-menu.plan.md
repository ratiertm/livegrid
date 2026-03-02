# Column Menu (컬럼 헤더 메뉴)

> **Version**: v0.12
> **Priority**: P1
> **Status**: Plan
> **Feature ID**: FA-010

---

## 목표

헤더 셀에 드롭다운 메뉴 아이콘을 추가하여 컬럼별 빠른 작업 접근.
AG Grid의 Column Menu에 해당.

## 요구사항

### FR-01: 메뉴 아이콘
- 각 헤더 셀에 ☰ (햄버거) 아이콘 표시
- hover 시에만 표시 (또는 항상 표시 옵션)

### FR-02: 메뉴 항목
- 오름차순 정렬 / 내림차순 정렬
- 컬럼 고정 (왼쪽/오른쪽) / 고정 해제
- 컬럼 숨기기
- 자동 너비 맞춤
- 필터 초기화 (해당 컬럼)

### FR-03: column_menu 옵션
- `default_options`에 `show_column_menu: true` 추가
- 컬럼별 `menu: false`로 비활성화 가능

## 구현 범위
1. grid.ex: default_options에 show_column_menu, initial_state에 column_menu_open
2. grid_component.ex: 헤더에 메뉴 아이콘 + 드롭다운 렌더링
3. event_handlers.ex: column_menu 이벤트 핸들러들
4. CSS: .lv-grid__column-menu 스타일
5. demo_live.ex: 옵션 활성화
6. 테스트

## 난이도: ⭐⭐
