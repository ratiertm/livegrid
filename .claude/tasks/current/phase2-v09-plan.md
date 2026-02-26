# Phase 2 (v0.9) 편집 고도화

> 시작일: 2026-02-25

## 목표
편집 경험 고도화 6개 기능 구현 (기존 grid.state.editing 단일 셀 패턴 확장)

## 범위
### 포함
- F-935 정렬 시 null 처리
- F-902 행번호 컬럼
- F-905 Checkbox 컬럼
- F-922 입력 제한 (정규식)
- F-920 행 단위 편집 모드
- F-700 Undo/Redo

### 제외 (건드리지 않을 것)
- Phase 1 기능 변경
- grid_component.ex 분할 리팩토링 (Phase 2 완료 후 별도 진행)

## 진행 상황

| 순서 | ID | 기능명 | 난이도 | 상태 | 완료일 |
|------|----|--------|--------|------|--------|
| 1 | F-935 | 정렬 시 null 처리 | ⭐ | ✅ 완료 | 02-25 |
| 2 | F-902 | 행번호 컬럼 | ⭐ | ✅ 완료 | 02-25 |
| 3 | F-905 | Checkbox 컬럼 | ⭐⭐ | ✅ 완료 | 02-25 |
| 4 | F-922 | 입력 제한 (정규식) | ⭐⭐ | ✅ 완료 | 02-25 |
| 5 | F-920 | 행 단위 편집 모드 | ⭐⭐⭐ | ✅ 완료 | 02-25 |
| 6 | F-700 | Undo/Redo | ⭐⭐⭐ | ✅ 완료 | 02-25 |

## 완료된 기능 요약

### F-935 정렬 시 null 처리
- `sorting.ex`: Enum.split_with로 nil 분리 후 nulls_position에 따라 앞/뒤 배치
- `grid.ex`: normalize_columns에 `nulls: :last` 기본값, apply_sort/3으로 컬럼별 nulls 전달

### F-902 행번호 컬럼
- `grid.ex`: merge_default_options에 `show_row_number: false`
- `grid_component.ex`: 헤더/바디/필터에 행번호 셀, with_row_numbers/2 + row_number_offset/1 헬퍼
- `liveview_grid.css`: .lv-grid__cell--row-number 스타일

### F-905 Checkbox 컬럼
- `grid_component.ex`: render_cell에서 editor_type == :checkbox 분기 (항상 체크박스 렌더링)
- `grid_component.ex`: cell_checkbox_toggle 이벤트 핸들러 (클릭 즉시 토글)
- `liveview_grid.css`: .lv-grid__cell-checkbox 스타일
- `demo_live.ex`: active 필드 + checkbox 컬럼 추가

### F-922 입력 제한 (정규식)
- `grid.ex`: normalize_columns에 `input_pattern`, `max_length` 옵션 추가
- `grid_component.ex`: 편집 input에 `data-pattern`, `maxlength` 속성 전달
- `app.js`: CellEditor Hook에서 정규식 기반 실시간 입력 필터링 (불일치 시 이전 값 복원)

### F-920 행 단위 편집 모드
- `grid.ex`: `editing_row` state 추가, 행 편집 진입/저장/취소 함수
- `grid_component.ex`: 행 편집 모드 렌더링 (연필 아이콘 → 전체 셀 편집), row_edit_save/cancel 이벤트
- `app.js`: RowEditor Hook (Tab 이동, Enter 저장, Esc 취소)
- `liveview_grid.css`: `.lv-grid__row--editing` 스타일

### F-700 Undo/Redo
- `grid.ex`: `edit_history: []`, `redo_stack: []` state + `push_edit_history/2`, `undo/1`, `redo/1` 함수 (최대 50건)
- `grid_component.ex`: grid_undo/grid_redo 이벤트 핸들러 + 툴바 Undo/Redo 버튼 (↩ ↪)
- `app.js`: GridKeyboardNav에 Ctrl+Z/Y 단축키 핸들링
- `liveview_grid.css`: `.lv-grid__undo-btn`, `.lv-grid__redo-btn` 스타일

## 최종 파일 현황

| 파일 | 줄 수 | 변경 내용 |
|------|-------|-----------|
| `grid.ex` | 805줄 | normalize_columns, state 확장, undo/redo 함수 |
| `grid_component.ex` | 2,303줄 | 행번호/체크박스/행편집/입력제한/undo/redo 렌더링 + 이벤트 |
| `sorting.ex` | - | nil 값 정렬 처리 |
| `liveview_grid.css` | 1,367줄 | 행번호/체크박스/행편집/undo/redo 스타일 |
| `app.js` | 1,022줄 | 입력 필터링, Ctrl+Z/Y, 행편집 Tab/RowEditor Hook |
| `demo_live.ex` | 766줄 | 데모에 전체 Phase 2 기능 적용 |

## 검증 결과
- `mix compile --warnings-as-errors` → **통과**
- `mix test` → **255개 전체 통과**, 0 failures
- 콘솔 에러: **0개**
- 기능별 시각적 검증: **모두 완료**

## 완료 조건
- [x] 6개 기능 전체 구현
- [x] 컴파일 에러 0개
- [x] 255개 테스트 통과
- [x] 콘솔 에러 0개
- [x] Preview + Chrome MCP 시각적 확인

**→ Phase 2 (v0.9) 완료. 전체 42개 기능 구현 100% 완료.**
