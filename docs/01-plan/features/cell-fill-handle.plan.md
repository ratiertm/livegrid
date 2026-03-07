# FA-013 Cell Fill Handle (Excel 자동채움)

## 개요
셀 모서리의 작은 핸들(■)을 드래그하여 인접 셀에 값을 자동 채우는 Excel 스타일 기능.

## 요구사항
- FR-01: 편집 가능한 셀 선택 시 오른쪽 하단에 fill handle(■) 표시
- FR-02: 핸들 드래그로 아래/위 방향 셀 범위 선택
- FR-03: 드래그 중 대상 셀 하이라이트
- FR-04: 드롭 시 소스 셀 값을 대상 셀에 복사
- FR-05: Undo 지원 (일괄 변경 취소)

## 구현 계획
1. JS Hook: CellFillHandle - 드래그 감지 + 범위 계산
2. EventHandler: handle_cell_fill - 값 복사 적용
3. GridComponent: fill handle UI 렌더링
4. CSS: handle 스타일 + 드래그 하이라이트
