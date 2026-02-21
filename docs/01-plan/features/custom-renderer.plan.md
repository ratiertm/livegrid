# Plan: Custom Cell Renderer (F-300)

> **Feature**: custom-renderer
> **Phase**: Plan
> **Created**: 2026-02-21
> **Status**: Draft

---

## 1. 목표

컬럼 정의에 `renderer` 함수를 지정하여 셀 내용을 커스텀 HEEx 템플릿으로 렌더링하는 기능.
개발자가 상태 뱃지, 아바타, 버튼, 프로그레스바 등 다양한 UI를 셀 안에 표현할 수 있게 한다.

---

## 2. 배경

### 현재 상태
- `render_cell/3` 함수가 셀 렌더링을 담당 (`grid_component.ex:815`)
- 편집 모드(input/select)와 보기 모드(텍스트 출력)만 지원
- 보기 모드는 `Map.get(row, column.field)` 값을 그대로 출력
- 커스텀 렌더링 방법이 없어 모든 셀이 plain text로 표시됨

### 필요성
- 상태 값을 뱃지(badge)로 표현 (예: "활성" → 초록 뱃지, "비활성" → 회색 뱃지)
- 숫자를 포맷팅하여 표시 (예: 30 → "30세")
- 진행률을 프로그레스바로 표시
- 이메일을 `mailto:` 링크로 렌더링
- 아바타/이미지 표시
- 액션 버튼 (편집, 삭제 등) 컬럼

### 설계서 참조
- **기능목록및기능정의서.md** F-300: 커스텀 셀 렌더러 (v0.5, P1, 난이도 ⭐⭐⭐)
- **데이터구조명세서.md** Column 구조: `renderer: function() | nil`
- **API명세서.md**: 커스텀 렌더러 예시 코드 포함

---

## 3. 요구사항

### 3.1 필수 (Must Have)

| ID | 요구사항 | 우선순위 |
|----|---------|---------|
| CR-01 | 컬럼 정의에 `renderer` 옵션 지원 | P0 |
| CR-02 | renderer 함수가 `(row, column) -> HEEx` 시그니처를 따름 | P0 |
| CR-03 | renderer가 nil이면 기존 동작 유지 (plain text) | P0 |
| CR-04 | renderer와 editable이 함께 동작 (보기 모드에서만 renderer 적용) | P0 |
| CR-05 | renderer와 validation 에러 표시가 함께 동작 | P0 |

### 3.2 권장 (Should Have)

| ID | 요구사항 | 우선순위 |
|----|---------|---------|
| CR-06 | 내장 렌더러 프리셋 제공 (badge, link, progress) | P1 |
| CR-07 | 데모 페이지에 커스텀 렌더러 적용 예시 | P1 |

### 3.3 선택 (Nice to Have)

| ID | 요구사항 | 우선순위 |
|----|---------|---------|
| CR-08 | 컬럼 `format` 옵션과 renderer 우선순위 정의 | P2 |

---

## 4. 기술 분석

### 4.1 변경 대상 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/liveview_grid/grid.ex` | `normalize_columns/1`에 renderer 기본값(nil) 추가 |
| `lib/liveview_grid_web/components/grid_component.ex` | `render_cell/3` 함수에 renderer 분기 추가 |
| `lib/liveview_grid/renderers.ex` | **새 파일** - 내장 렌더러 프리셋 모듈 |
| `lib/liveview_grid_web/live/demo_live.ex` | 데모에 renderer 적용 예시 |
| `test/liveview_grid/renderers_test.exs` | **새 파일** - 렌더러 테스트 |
| `assets/css/liveview_grid.css` | 뱃지, 링크 등 렌더러용 CSS |

### 4.2 핵심 설계 결정

**Q1: renderer 함수의 시그니처는?**
- **결정**: `fn row, column, assigns -> HEEx`
- **이유**: row 데이터와 column 정의를 모두 참조할 수 있어야 하고, assigns를 통해 grid 전체 상태에도 접근 가능

**Q2: renderer와 편집 모드의 관계는?**
- **결정**: 편집 모드일 때는 기존 input/select 에디터 사용, 보기 모드에서만 renderer 적용
- **이유**: 편집 UI는 에디터 설정으로 관리, 렌더러는 표시 전용

**Q3: renderer와 validation 에러의 관계는?**
- **결정**: renderer 출력 아래에 에러 메시지 표시 (기존 cell-wrapper 구조 유지)
- **이유**: 검증 에러는 렌더러와 무관하게 항상 표시되어야 함

**Q4: 내장 렌더러 프리셋은?**
- **결정**: `LiveViewGrid.Renderers` 모듈에 `badge/3`, `link/3`, `progress/3` 등 제공
- **이유**: 자주 사용되는 패턴을 함수로 제공하여 개발자 편의성 향상

### 4.3 구현 접근법

```elixir
# 1. 컬럼 정의에서 renderer 사용
%{
  field: :city,
  label: "도시",
  renderer: fn row, _col, _assigns ->
    assigns = %{city: row.city}
    ~H"""
    <span class="lv-grid__badge lv-grid__badge--blue"><%= @city %></span>
    """
  end
}

# 2. 내장 렌더러 프리셋 사용
%{
  field: :city,
  label: "도시",
  renderer: &LiveViewGrid.Renderers.badge(&1, &2, &3,
    colors: %{"서울" => "blue", "부산" => "green"})
}
```

### 4.4 리스크

| 리스크 | 영향 | 대응 |
|--------|------|------|
| renderer 함수에서 에러 발생 시 전체 그리드 크래시 | 높음 | try/rescue로 fallback (plain text) |
| anonymous function이 LiveView assigns에 저장 불가 | 높음 | module + function 방식도 지원 |
| renderer 내 phx-click 등 이벤트 바인딩 | 중간 | phx-target 문서화 필요 |

---

## 5. 테스트 전략

| 테스트 유형 | 항목 |
|-------------|------|
| 단위 테스트 | 내장 렌더러 (badge, link, progress) 출력 검증 |
| 단위 테스트 | renderer nil → plain text 출력 확인 |
| 단위 테스트 | renderer 에러 시 fallback 동작 |
| 통합 테스트 | renderer + editable 조합 (보기/편집 모드 전환) |
| 통합 테스트 | renderer + validation 에러 동시 표시 |
| 브라우저 테스트 | 데모 페이지에서 커스텀 렌더러 시각적 확인 |

---

## 6. 구현 순서

1. `grid.ex` - normalize_columns에 renderer 기본값 추가
2. `grid_component.ex` - render_cell에 renderer 분기 로직
3. `renderers.ex` - 내장 렌더러 프리셋 모듈 생성
4. `liveview_grid.css` - 렌더러용 CSS 스타일
5. `demo_live.ex` - 데모에 renderer 적용
6. 테스트 작성
7. 브라우저 테스트 (Chrome MCP)

---

## 7. 완료 기준

- [ ] renderer 함수로 커스텀 HEEx 렌더링 동작
- [ ] renderer nil일 때 기존 plain text 출력 유지
- [ ] 편집 모드에서는 renderer 무시, 에디터 표시
- [ ] validation 에러와 renderer가 함께 동작
- [ ] 내장 렌더러 최소 2개 (badge, link) 제공
- [ ] 데모 페이지에 적용 예시 확인
- [ ] renderer 에러 시 안전한 fallback
- [ ] 단위 테스트 통과
