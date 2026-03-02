# Set Filter (체크박스 필터)

> **Version**: v0.12
> **Priority**: P1
> **Status**: Plan
> **Feature ID**: FA-012

---

## 목표

Excel AutoFilter 스타일의 고유값 체크박스 필터.
컬럼 데이터의 고유값 목록을 체크박스로 표시하여 다중 선택 필터링.
AG Grid의 Set Filter (Enterprise)에 해당.

## 요구사항

### FR-01: filter_type: :set 지원
- 컬럼 정의에 `filter_type: :set` 추가
- 고유값 자동 추출

### FR-02: Set Filter UI
- 필터 셀 클릭 시 드롭다운 패널 표시
- 전체 선택 / 전체 해제 버튼
- 값 검색 입력
- 각 고유값에 체크박스

### FR-03: Set Filter 로직
- 선택된 값들만 표시 (OR 조건)
- state.filters에 `%{field => {:set, [values]}}` 형태 저장
- Filter.apply에서 :set 타입 처리

## 구현 범위
1. grid.ex: initial_state에 set_filter_state (open panels), normalize_columns에 set 타입 기본값
2. filter.ex: :set 필터 타입 매칭 로직
3. grid_component.ex: Set Filter 드롭다운 UI
4. event_handlers.ex: set_filter 이벤트 핸들러
5. CSS: .lv-grid__set-filter 스타일
6. 테스트

## 난이도: ⭐⭐⭐
