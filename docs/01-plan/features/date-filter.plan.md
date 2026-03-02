# Date Filter Enhancement (날짜 필터 강화)

> **Version**: v0.12
> **Priority**: P0
> **Status**: Plan
> **Feature ID**: FA-003

---

## 목표

기존 날짜 필터(from~to range)에 Quick Preset 버튼과 개별 Clear 기능을 추가하여 UX 강화.
AG Grid의 Date Filter에 해당.

## 현재 상태 (이미 구현됨)
- filter_type: :date 지원
- from~to 범위 필터 UI (input[type=date])
- 날짜 연산자 (eq, before, after, between, is_empty, is_not_empty)

## 추가 요구사항

### FR-01: Quick Preset 버튼
- 날짜 필터 셀에 프리셋 드롭다운 추가
- 프리셋: 오늘, 최근 7일, 이번 달, 지난 달, 올해
- 프리셋 선택 시 from~to 자동 설정

### FR-02: 개별 Clear 버튼
- 각 날짜 필터 셀에 ✕ 버튼 추가
- 클릭 시 해당 컬럼 필터만 초기화

### FR-03: 날짜 필터 요약 표시
- from~to 설정 시 "3/1 ~ 3/15" 형태 요약 표시

## 구현 범위
1. grid_component.ex: Date Filter UI 강화 (preset dropdown, clear button)
2. event_handlers.ex: date_filter_preset 이벤트 핸들러
3. CSS: 프리셋 드롭다운 스타일
4. 테스트

## 난이도: ⭐⭐
