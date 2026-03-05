# FA-010 Column Menu — Plan

## 1. 기능 개요
헤더 셀에 드롭다운 메뉴 아이콘을 추가하여, 클릭 시 해당 컬럼에 대한 작업 메뉴를 표시한다.
기존 Context Menu(우클릭)와 달리, Column Menu는 헤더의 3-dot 아이콘을 통해 접근하는 UX.

## 2. 기존 코드 분석
- Context Menu: `show_context_menu` / `hide_context_menu` / `context_menu_action` 이벤트 존재
- Context Menu는 행(row) 기반 우클릭 → 복사/삽입/삭제 등
- Column Menu는 컬럼(column) 헤더 기반 → 정렬/필터/숨기기/고정 등 **별도 기능**

## 3. 구현 범위

### 메뉴 항목
1. **오름차순 정렬** (↑ Sort Ascending) — 기존 `grid_sort` 이벤트 활용
2. **내림차순 정렬** (↓ Sort Descending) — 기존 `grid_sort` 이벤트 활용
3. **정렬 초기화** (✕ Clear Sort) — sort: nil 설정
4. **구분선**
5. **컬럼 고정 (Pin Left)** — 기존 `grid_freeze_to_column` 활용
6. **컬럼 고정 해제 (Unpin)** — freeze 해제
7. **구분선**
8. **컬럼 숨기기 (Hide Column)** — suppress: true 토글

### UI
- 헤더 셀 호버 시 ⋮ (kebab) 아이콘 표시
- 아이콘 클릭 → 드롭다운 메뉴 (position: fixed)
- 메뉴 외부 클릭 → 닫기 (phx-click-away)

## 4. 파일 변경 계획

| 파일 | 변경 내용 |
|------|-----------|
| grid.ex | hide_column/2, show_column/2 함수 추가 |
| grid_component.ex | column_menu assign + 헤더 아이콘 + 메뉴 UI + 이벤트 위임 |
| event_handlers.ex | 4개 핸들러 (toggle, close, action, hide_column) |
| header.css | Column Menu 스타일 |
| grid_test.exs | hide/show column 테스트 |

## 5. 의존성
- 기존 정렬 이벤트 `grid_sort` 재사용
- 기존 컬럼 고정 `grid_freeze_to_column` 재사용
- 컬럼 숨기기는 새로운 기능 (suppress 토글)

## 6. 리스크
- 헤더 셀 공간 제약 → 아이콘은 호버 시에만 표시
- position: fixed 메뉴 → 스크롤 시 위치 추적 필요 없음
- 다크 모드 대응 필수
