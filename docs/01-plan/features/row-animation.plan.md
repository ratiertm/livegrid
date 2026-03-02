# Row Animation

> **Version**: v0.13
> **Priority**: P1
> **Status**: Plan
> **Feature ID**: FA-017

---

## 목표

행 삽입/삭제/업데이트 시 슬라이드/페이드 애니메이션 효과.
AG Grid의 Row Animation에 해당.

## 요구사항

### FR-01: 행 삽입 애니메이션
- 새 행 추가 시 fade-in + slide-down 효과
- CSS transition 기반

### FR-02: 행 삭제 애니메이션
- 행 제거 시 fade-out + slide-up 효과

### FR-03: animate_rows 옵션
- `default_options`에 `animate_rows: false` 추가
- 비활성화 시 즉시 렌더링

## 구현 범위
1. grid.ex: animate_rows 옵션
2. CSS: @keyframes row-enter, row-exit 애니메이션
3. grid_component.ex: 행 추가/삭제 시 클래스 토글
4. 테스트

## 난이도: ⭐⭐
