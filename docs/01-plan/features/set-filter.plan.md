# FA-012 Set Filter (Excel AutoFilter 스타일)

> **Feature ID**: FA-012
> **Version**: v0.13.0
> **Priority**: P1
> **Created**: 2026-03-05

## 요구사항

### FR-01: 고유값 체크박스 필터 UI
- 컬럼 필터 행에서 `filter_type: :set` 컬럼에 체크박스 드롭다운 표시
- 해당 컬럼의 모든 고유값을 자동 추출하여 체크박스 목록 생성
- 전체 선택/해제 버튼 제공

### FR-02: 선택 기반 필터링
- 체크된 값만 데이터에 표시 (선택된 값 기준 필터)
- 기존 텍스트/숫자 필터와 동시 적용 가능 (AND 조건)
- 필터 적용 후 상태바에 필터 상태 반영

### FR-03: 검색 기능
- 고유값이 많을 때 목록 내 검색 입력 제공
- 검색 결과만 체크박스 목록에 표시

### FR-04: 기존 필터 시스템 연동
- `Filter.apply/3`에 set 필터 타입 추가
- `grid.state.filters`에 set 필터 값 저장 (리스트 형태)
- 고급 필터(Advanced Filter)와 병행 가능

## 영향 범위
- `filter.ex`: `:set` filter_type 매칭 로직 추가
- `grid.ex`: set_filter 상태 관리 (고유값 목록, 선택된 값)
- `grid_component.ex`: filter-row에 Set Filter 드롭다운 UI
- `event_handlers.ex`: set filter 이벤트 핸들러
- `body.css`: Set Filter 드롭다운 스타일
- `demo_live.ex`: set filter 데모 컬럼 추가
- `grid_test.exs`: set filter 테스트

## 추천 구현 순서
1. filter.ex에 `:set` 필터 매칭 로직
2. grid.ex에 set filter 상태 헬퍼
3. grid_component.ex에 Set Filter 드롭다운 UI
4. event_handlers.ex에 이벤트 핸들러
5. CSS 스타일링
6. 데모 + 테스트
