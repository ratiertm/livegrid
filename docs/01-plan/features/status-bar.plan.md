# Status Bar (상태 바)

> **Version**: v0.11
> **Priority**: P1
> **Status**: Plan
> **Feature ID**: FA-004

---

## 목표

Grid 하단에 현재 상태 정보(전체 행 수, 필터된 행 수, 선택된 행 수 등)를 표시하는 Status Bar.
AG Grid의 Status Bar Panel에 해당합니다.

## 요구사항

### FR-01: 상태 데이터 API
- `Grid.status_bar_data/1` — 전체/필터/선택 행 수 등 반환

### FR-02: Status Bar 렌더링
- Footer 아래에 위치
- 좌측: 전체 행 수 / 필터된 행 수
- 우측: 선택된 행 수 / 편집 중인 셀 정보

### FR-03: 옵션
- `show_status_bar: true/false` (기본: false)

## 구현 범위
1. grid.ex: default_options에 show_status_bar, status_bar_data/1 함수
2. grid_component.ex: Status Bar HEEx 렌더링
3. CSS: .lv-grid__status-bar
4. demo_live.ex: 활성화
5. 테스트

## 난이도: ⭐⭐
