# Auto-fit Column Width - Plan

## 개요
컬럼 헤더 경계 더블클릭 시 해당 컬럼의 너비를 데이터 내용에 맞게 자동 조절.

## 요구사항

### ACW-01: 더블클릭 이벤트
- 컬럼 리사이즈 핸들 더블클릭 시 auto-fit 실행
- 기존 ColumnResize Hook에 dblclick 핸들러 추가

### ACW-02: 너비 측정 로직
- JS에서 해당 컬럼의 모든 셀 텍스트를 측정
- canvas.measureText 또는 임시 span으로 너비 계산
- header 텍스트 너비도 포함하여 최대값 + padding 적용

### ACW-03: 서버 반영
- 계산된 너비를 phx-event로 서버에 전송
- grid_column_resize 이벤트 재활용

### ACW-04: 최소/최대 제한
- 최소 50px, 최대 500px 제한

## 참조
- 넥사크로 4.10d: autosizingtype col
- 현재: 컬럼 리사이즈(드래그)만 지원
