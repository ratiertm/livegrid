# Auto-fit Height & Per-row Height - Plan

## 개요
Grid 높이 자동 조정(autofittype)과 행별 개별 높이(extendsizetype) 지원.

## 요구사항

### AH-01: autofit_type 옵션
- `options.autofit_type: :none | :row` (기본값 :none)
- `:row` — 행 수에 맞춰 Grid body 높이 자동 조정 (max-height 제거, 스크롤바 없음)
- 페이징 없는 소량 데이터 표시에 적합

### AH-02: per_row_heights 상태
- `state.row_heights: %{row_id => height_px}`
- 특정 행만 개별 높이 설정 가능
- 미설정 행은 options.row_height 기본값 사용

### AH-03: set_row_height API
- `Grid.set_row_height(grid, row_id, height)` — 특정 행 높이 설정
- `Grid.reset_row_height(grid, row_id)` — 특정 행 높이 초기화

### AH-04: CSS
- autofit_type=:row 일 때 body에 `.lv-grid__body--autofit` 클래스
- 행별 높이가 다를 때 inline style로 min-height 적용

## 참조
- 넥사크로 1.14: autofittype (none/row/col/both)
- 넥사크로 2.2: extendsizetype (none/row)
- 현재: 고정 row_height(40px) + max-height: 600px
