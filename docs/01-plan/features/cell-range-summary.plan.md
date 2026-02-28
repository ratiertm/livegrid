# F-941: Cell Range Summary (선택 영역 합계)

> **Version**: v0.8
> **Priority**: P1
> **Status**: Plan

---

## 목표

셀 범위를 선택했을 때 하단 상태바에 **합계(Sum), 평균(Avg), 개수(Count), 최소(Min), 최대(Max)** 를 실시간으로 표시합니다.

## 요구사항

1. 셀 범위 선택 시 (F-940 기반) 숫자형 셀의 통계 자동 계산
2. 상태바(Status Bar)를 Grid 하단 Footer에 표시
3. 계산 항목: Sum, Avg, Count, Min, Max
4. 비숫자 셀은 Count만 계산
5. 셀 범위 해제 시 상태바 숨김

## 구현 범위

### Backend (Elixir)
- `Grid.cell_range_summary/1` - 범위 내 값 추출 + 통계 계산
- 숫자 값만 필터링하여 sum/avg/min/max 계산
- 전체 셀 count도 포함

### Frontend (HEEx Template)
- `grid_component.ex` 하단 Footer에 상태바 렌더링
- cell_range가 nil이 아닐 때만 표시
- 포맷팅: 천단위 구분자 적용

## 의존성

- F-940 (Cell Range Selection) ✅ 구현 완료
- Formatter 모듈 ✅ 구현 완료

## 구현 순서

1. `Grid.cell_range_summary/1` 함수 추가
2. `RenderHelpers`에 상태바 렌더링 헬퍼 추가
3. `grid_component.ex` render 함수에 상태바 UI 추가
4. CSS 스타일링
5. 테스트 작성
