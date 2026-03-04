# F-914 컬럼 리사이즈 제한 (Column Resize Lock)

> **Feature ID**: F-914
> **Version**: v0.12.0
> **Priority**: P1
> **Source**: 넥사크로 참조
> **Created**: 2026-03-05

---

## 1. 개요

특정 컬럼의 리사이즈를 비활성화하는 옵션을 추가합니다.
컬럼 정의에 `resizable: false`를 설정하면 해당 컬럼의 리사이즈 핸들이 숨겨지고,
드래그/더블클릭으로 너비를 변경할 수 없습니다.

## 2. 요구사항

### FR-01: 컬럼 옵션 추가
- 컬럼 정의에 `resizable` 키 추가 (기본값: `true`)
- `resizable: false` 시 리사이즈 차단

### FR-02: 리사이즈 핸들 숨김
- `resizable: false` 컬럼에서 리사이즈 핸들(`.lv-grid__resize-handle`) 미렌더링

### FR-03: JS 훅 가드
- `column-resize.js` 훅에서 `resizable` 속성 체크
- `resizable: false` 컬럼은 mousedown/dblclick 이벤트 무시

### FR-04: 서버 사이드 가드
- `Grid.resize_column/3`에서 `resizable` 확인
- `resizable: false` 컬럼은 리사이즈 요청 무시

### FR-05: Config Modal 연동
- Grid Config Modal의 Column Properties에 `Resizable` 체크박스 표시
- 체크 해제 시 `resizable: false` 적용

### FR-06: 데모 페이지 적용
- `demo_live.ex`에서 최소 1개 컬럼에 `resizable: false` 설정
- 리사이즈 불가능 컬럼 시각적 확인 가능

## 3. 영향 범위

| 파일 | 변경 유형 |
|------|----------|
| `lib/liveview_grid/grid.ex` | 컬럼 기본값 + resize_column 가드 |
| `lib/liveview_grid_web/components/grid_component.ex` | 핸들 조건부 렌더링 |
| `assets/js/hooks/column-resize.js` | resizable 체크 |
| `lib/liveview_grid_web/live/demo_live.ex` | 데모 컬럼 설정 |
| `test/liveview_grid/grid_test.exs` | 테스트 추가 |

## 4. 테스트 계획

- [ ] `resizable: true` (기본값) 컬럼 리사이즈 정상 동작
- [ ] `resizable: false` 컬럼 리사이즈 차단 확인
- [ ] `Grid.resize_column/3` 서버 사이드 가드 테스트
- [ ] 리사이즈 핸들 미렌더링 확인 (Chrome MCP)
- [ ] 더블클릭 자동 맞춤 차단 확인

## 5. 비기능 요구사항

- 기존 그리드 동작에 영향 없음 (기본값 `true`)
- 하위 호환성 100% 유지
