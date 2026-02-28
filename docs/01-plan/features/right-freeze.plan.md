# Right Column Freeze - Plan

## 개요
좌측 고정(frozen_columns)에 이어 우측 컬럼 고정 지원.

## 요구사항

### FR-01: frozen_right_columns 옵션
- `options.frozen_right_columns: N` (기본값 0)
- 우측 N개 컬럼을 sticky로 고정

### FR-02: frozen_style/frozen_class 확장
- 우측 고정 컬럼: `position: sticky; right: Xpx; z-index: 2;`
- CSS 클래스: `.lv-grid__cell--frozen-right`

### FR-03: 헤더에도 적용
- 헤더 셀도 우측 고정

### FR-04: CSS
- `.lv-grid__cell--frozen-right` 배경/그림자 스타일

## 참조
- 넥사크로 2.6: band left/right
- 현재 frozen_style/frozen_class: 좌측만 지원
