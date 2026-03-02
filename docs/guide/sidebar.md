# Side Bar

그리드 우측에 사이드바를 표시합니다. 컬럼 표시/숨기기와 필터 관리를 제공합니다.

## Enabling

```elixir
# 툴바의 "사이드바" 버튼을 클릭하거나
# 옵션에서 초기 표시 설정
options = %{
  show_sidebar: true
}
```

## Tabs

### Columns Tab

컬럼의 표시/숨기기를 토글합니다:
- 체크박스로 개별 컬럼 표시 제어
- 드래그로 컬럼 순서 변경
- "전체 선택/해제" 버튼

### Filters Tab

현재 적용된 필터 목록을 표시합니다:
- 활성 필터 확인
- 개별 필터 제거
- 전체 필터 초기화

## CSS Classes

```css
.lv-grid__sidebar              /* 사이드바 컨테이너 */
.lv-grid__sidebar-tab           /* 탭 헤더 */
.lv-grid__sidebar-content       /* 탭 내용 */
```

## Behavior

- z-index: `var(--lv-grid-z-sidebar)` (20)
- 기본 너비: 250px (태블릿: 200px)
- 인쇄 시 자동 숨김
- 사이드바 외부 클릭 시 닫히지 않음 (토글 버튼으로만 제어)
