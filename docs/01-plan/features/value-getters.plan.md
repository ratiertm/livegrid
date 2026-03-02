# Value Getters/Setters

> **Version**: v0.13
> **Priority**: P1
> **Status**: Plan
> **Feature ID**: FA-015

---

## 목표

컬럼 정의에 value_getter/value_setter 함수를 지정하여 가상 컬럼(계산 컬럼) 지원.
AG Grid의 Value Getters/Setters에 해당.

## 요구사항

### FR-01: value_getter
- 컬럼에 `value_getter: fn row -> ... end` 설정
- 셀 렌더링 시 row 데이터 대신 함수 결과 사용
- 정렬/필터에도 value_getter 결과 사용

### FR-02: value_setter
- 컬럼에 `value_setter: fn row, value -> ... end` 설정
- 셀 편집 시 value_setter로 값 저장

### FR-03: value_formatter (기존 formatter와 통합)
- 기존 Formatter 모듈과 공존

## 구현 범위
1. grid.ex: normalize_columns에 value_getter/value_setter 기본값
2. grid_component.ex: 셀 렌더링 시 value_getter 적용
3. filter.ex, sorting.ex: value_getter 적용
4. 테스트

## 난이도: ⭐⭐
