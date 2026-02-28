# F-930 Row Move (행 드래그 이동) - Plan

## 개요
드래그 앤 드롭으로 행 위치를 변경 (순서 재정렬).

## 요구사항

### FR-01: Grid.move_row/3 API
- `move_row(grid, from_row_id, to_row_id)` — from 행을 to 행 위치로 이동
- 데이터 배열에서 순서 변경

### FR-02: 옵션으로 활성화
- `options.row_reorder: true` 로 활성화
- 기본값 false

### FR-03: JavaScript Drag Hook
- 행 좌측에 드래그 핸들 표시 (호버 시 나타남)
- 드래그 시 고스트 표시 + 드롭 위치 인디케이터
- 드롭 시 LiveView 이벤트 전송

### FR-04: CSS 스타일
- 드래그 핸들 (≡ 아이콘)
- 드래그 중 행 반투명 + 드롭 인디케이터 라인

### FR-05: 서버 이벤트 처리
- `grid_move_row` 이벤트로 from_id, to_id 수신
- Grid.move_row 호출 후 상태 업데이트

## 참조
- 넥사크로 1.17: moveRow(nFromRow, nToRow)
- column-reorder.js: 비슷한 드래그 패턴 참조
