# FA-020 Cell Text Selection

> **Feature ID**: FA-020
> **Version**: v0.12.0
> **Priority**: P1
> **Source**: AG Grid [C]
> **Created**: 2026-03-05

---

## 1. 개요

셀 내부 텍스트를 마우스 드래그로 선택하여 복사할 수 있는 기능.
Grid 옵션에 `text_selectable: true` 설정 시 활성화.

## 2. 요구사항

### FR-01: Grid 옵션 추가
- `text_selectable` 옵션 (기본값: `false`)
- `true` 시 셀 텍스트 드래그 선택 허용

### FR-02: CSS 적용
- `text_selectable: true` → `.lv-grid--text-selectable` 클래스 추가
- 해당 클래스에 `user-select: text; cursor: text;` 적용
- `.lv-grid__cell-value` 내부 텍스트만 선택 가능 (셀 패딩 영역 제외)

### FR-03: 데모 페이지
- `demo_live.ex`에서 `text_selectable: true` 설정

## 3. 영향 범위

| 파일 | 변경 유형 |
|------|----------|
| `lib/liveview_grid/grid.ex` | 옵션 기본값 |
| `lib/liveview_grid_web/components/grid_component.ex` | 클래스 조건부 |
| `assets/css/grid/body.css` | CSS 규칙 |
| `lib/liveview_grid_web/live/demo_live.ex` | 데모 적용 |
