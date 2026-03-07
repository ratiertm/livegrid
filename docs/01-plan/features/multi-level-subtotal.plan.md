# F-963 다단계 소계 (Multi-Level Subtotal)

## 개요
그룹핑 시 각 그룹 끝에 소계(subtotal) 행을 표시하고, 다단계 그룹의 각 레벨별로 독립적인 소계를 제공한다.

## 요구사항
- FR-01: 그룹 끝에 소계 행 표시 (각 그룹의 마지막에 subtotal row 추가)
- FR-02: 다단계 그룹 시 각 레벨별 독립 소계 (부서 소계, 부서+직급 소계)
- FR-03: 총계(Grand Total) 행 지원 (그리드 맨 하단)
- FR-04: subtotal 옵션 on/off 토글
- FR-05: 소계 행 전용 스타일링

## 구현 계획
1. `grouping.ex` - `group_data/4`에 subtotal 행 생성 로직 추가
2. `grid.ex` - subtotals 옵션 관리
3. `grid_component.ex` - subtotal 행 렌더링
4. `render_helpers.ex` - subtotal 행 번호 처리
5. CSS - subtotal 행 스타일
6. 테스트 작성
