# Column Resize Lock (컬럼 리사이즈 잠금)

> **Version**: v0.11
> **Priority**: P1
> **Status**: Plan
> **Feature ID**: F-914

---

## 목표

특정 컬럼의 너비 조정을 잠금 처리하여 사용자가 실수로 컬럼 크기를 변경하지 못하도록 합니다.
AG Grid의 `resizable: false` 컬럼 옵션에 해당합니다.

## 기존 코드 분석

### 재사용 가능한 자산
1. **`normalize_columns/1`** (`grid.ex:1335-1358`) - 컬럼 기본값 머지
2. **`ColumnResize` JS Hook** (`column-resize.js`) - 드래그 리사이즈 + 더블클릭 자동맞춤
3. **resize-handle 렌더링** (`grid_component.ex:620-626`) - 모든 컬럼에 무조건 렌더링 중

### 현재 동작
- 모든 컬럼에 `.lv-grid__resize-handle` + `ColumnResize` Hook이 무조건 렌더링됨
- 컬럼별 리사이즈 가능 여부를 제어하는 옵션이 없음

## 요구사항

### FR-01: 컬럼별 resizable 옵션
- 컬럼 정의에 `resizable: false` 지정 시 해당 컬럼 너비 조정 불가
- 기본값: `true` (모든 컬럼 리사이즈 가능)

### FR-02: UI 반영
- `resizable: false` 컬럼에는 resize-handle 미렌더링
- 마우스 커서가 col-resize로 변경되지 않음

### FR-03: JS Hook 보호
- `resizable: false` 컬럼의 data 속성으로 JS에서도 제어

## 구현 범위

### 1. grid.ex
- `normalize_columns/1`에 `resizable: true` 기본값 추가

### 2. grid_component.ex
- resize-handle 렌더링 시 `column.resizable` 조건 추가

### 3. demo_live.ex
- ID 컬럼에 `resizable: false` 추가하여 시연

### 4. 테스트
- `resizable` 기본값 테스트
- `resizable: false` 시 동작 확인

## 예상 소요
- 난이도: ⭐ (최소 변경)
- 변경 파일: 3개
