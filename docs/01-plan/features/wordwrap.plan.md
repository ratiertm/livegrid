# F-911 Wordwrap (자동 줄바꿈) - Plan

## 개요
셀 내 텍스트가 컬럼 너비를 초과할 때 자동으로 줄바꿈하고, 행 높이를 자동 조절하는 기능.

## 요구사항

### FR-01: 컬럼별 wordwrap 옵션
- column definition에 `wordwrap` 속성 추가
- 값: `:none` (기본값), `:char`, `:word`
  - `:none` — 줄바꿈 없음 (현재 동작, white-space: nowrap)
  - `:char` — 글자 단위 줄바꿈 (word-break: break-all)
  - `:word` — 단어 단위 줄바꿈 (word-wrap: break-word)

### FR-02: CSS 클래스 적용
- `.lv-grid__cell--wordwrap-char` — 글자 단위 줄바꿈
- `.lv-grid__cell--wordwrap-word` — 단어 단위 줄바꿈
- `white-space: normal`, `overflow-wrap: break-word` 적용

### FR-03: 셀 높이 자동 조절
- wordwrap 적용 시 `min-height`만 유지, `height` 고정 해제
- 행의 높이가 콘텐츠에 맞게 자동 확장

### FR-04: 기존 동작 호환성
- wordwrap 미지정 컬럼은 기존과 동일하게 nowrap + ellipsis 유지
- Virtual Scroll 모드에서는 wordwrap 비활성화 (고정 행 높이 필요)

## 범위
- grid.ex: 컬럼 정의에 wordwrap 옵션 반영
- render_helpers.ex: wordwrap CSS 클래스 헬퍼
- grid_component.ex: HEEx에서 wordwrap 클래스 적용
- body.css: wordwrap CSS 스타일 추가
- demo_live.ex: 데모에서 email 컬럼에 wordwrap 테스트

## 참조
- 넥사크로 2.4: wordwrap (none/char/english) + autosizingtype (row)
- 추가기능목록.md: F-911, P1, HIGH
