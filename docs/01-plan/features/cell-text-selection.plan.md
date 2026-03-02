# Cell Text Selection (셀 텍스트 선택)

> **Version**: v0.11
> **Priority**: P1
> **Status**: Plan
> **Feature ID**: FA-020

---

## 목표

Grid 셀 내부 텍스트를 마우스로 드래그하여 선택/복사할 수 있도록 합니다.
AG Grid의 `enableCellTextSelection` 옵션에 해당합니다.

## 현재 상태
- `.lv-grid__cell`에 `user-select: none` 적용 → 텍스트 선택 불가
- `.lv-grid--selecting` 클래스로 드래그 중 텍스트 선택 방지

## 요구사항

### FR-01: 옵션
- `enable_cell_text_selection: true/false` (기본: false)
- true일 때 셀 텍스트 마우스 드래그 선택 가능

### FR-02: CSS 변경
- 옵션 활성화 시 셀에 `user-select: text` 적용

### FR-03: 셀 범위 선택과의 공존
- 텍스트 선택 모드에서는 셀 드래그 범위 선택을 비활성화

## 구현 범위
1. grid.ex: `default_options`에 `enable_cell_text_selection: false`
2. grid_component.ex: 옵션에 따라 grid에 CSS 클래스 추가
3. CSS: `.lv-grid--text-selectable .lv-grid__cell { user-select: text }`
4. keyboard-nav.js: 텍스트 선택 모드일 때 셀 드래그 방지
5. demo_live.ex: 옵션 토글 데모

## 난이도: ⭐
