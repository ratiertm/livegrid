# UI/UX Improvements Design Document

> **Summary**: Grid CSS 14건 이슈 수정 - 파일별 정확한 변경 전/후 명세
>
> **Project**: LiveView Grid
> **Version**: v0.7
> **Author**: Claude
> **Date**: 2026-02-28
> **Status**: Draft
> **Planning Doc**: [ui-ux-improvements.plan.md](../../01-plan/features/ui-ux-improvements.plan.md)

---

## 1. Overview

### 1.1 Design Goals

1. CSS 하드코딩 색상 0건 달성 (Config Modal 28개 → 0개)
2. WCAG 2.1 AA 색상 대비 충족 (본문 텍스트 4.5:1 이상)
3. 라이트/다크 모드 양쪽 완전 지원
4. 레이아웃 시프트 0건 (border → box-shadow 전환)

### 1.2 Design Principles

- **변수 우선**: 모든 색상/간격은 CSS 변수 참조
- **최소 변경**: 기존 BEM 네이밍, 구조 유지
- **호환성**: 기존 테스트 428건 영향 없음 (CSS-only 변경)

---

## 2. 수정 대상 파일 요약

| # | 파일 | 변경 건수 | FR |
|---|------|:---------:|-----|
| 1 | `variables.css` | 3건 추가 | FR-06, FR-13 |
| 2 | `layout.css` | 1건 수정 | FR-02 |
| 3 | `body.css` | 6건 수정 | FR-01, FR-03, FR-05, FR-06, FR-08, FR-11 |
| 4 | `header.css` | 2건 수정 | FR-07, FR-09 |
| 5 | `toolbar.css` | 1건 추가 | FR-10 |
| 6 | `config-modal.css` | 28건 수정 | FR-04 |
| 7 | `demo_live.ex` (HEEx) | 1건 수정 | FR-14 |

**총 변경: CSS 42건 + HEEx 1건**

---

## 3. 파일별 변경 명세

### 3.1 variables.css — 변수 추가 (FR-06, FR-13)

#### 변경 1: 숫자 셀 전용 클래스 지원을 위한 변수 (없음 - 클래스만 추가)

#### 변경 2: 다크모드 링크 색상 변수 추가

```css
/* ── BEFORE (라인 67 ~ 104 dark theme 블록 내) ── */
/* 링크 전용 변수 없음 */

/* ── AFTER (dark theme 블록 끝에 추가) ── */
.lv-grid[data-theme="dark"] {
  /* ... 기존 변수들 ... */
  --lv-grid-link-color: #90caf9;           /* NEW: 다크모드 링크 색상 */
}
```

#### 변경 3: 라이트모드에도 링크 변수 추가

```css
/* ── AFTER (:root 블록에 추가) ── */
:root,
.lv-grid[data-theme="light"] {
  /* ... 기존 변수들 ... */
  --lv-grid-link-color: var(--lv-grid-primary-dark);  /* NEW: 라이트모드 링크 색상 */
}
```

---

### 3.2 layout.css — max-width 제거 (FR-02)

```css
/* ── BEFORE (라인 13-14) ── */
.lv-grid {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  /* ... */
}

/* ── AFTER ── */
.lv-grid {
  width: 100%;
  /* max-width 제거 — 부모 컨테이너에 위임 */
  /* ... */
}
```

#### 변경: 링크 렌더러 색상 변수화 (layout.css 라인 129)

```css
/* ── BEFORE ── */
.lv-grid__link {
  color: var(--lv-grid-primary-dark);
}

/* ── AFTER ── */
.lv-grid__link {
  color: var(--lv-grid-link-color);
}
```

---

### 3.3 body.css — 6건 수정 (FR-01, FR-03, FR-05, FR-06, FR-08, FR-11)

#### 변경 1: overflow-x (FR-01, 라인 9)

```css
/* ── BEFORE ── */
.lv-grid__body {
  max-height: 600px;
  overflow-y: auto;
  overflow-x: hidden;
}

/* ── AFTER ── */
.lv-grid__body {
  max-height: 600px;
  overflow-y: auto;
  overflow-x: auto;
}
```

#### 변경 2: overflow-x virtual (라인 16-17)

```css
/* ── BEFORE ── */
.lv-grid__body--virtual {
  height: 600px;
  overflow-y: scroll;
  overflow-x: hidden;
}

/* ── AFTER ── */
.lv-grid__body--virtual {
  height: 600px;
  overflow-y: scroll;
  overflow-x: auto;
}
```

#### 변경 3: 셀 텍스트 색상 (FR-03, 라인 46)

```css
/* ── BEFORE ── */
.lv-grid__cell {
  /* ... */
  color: var(--lv-grid-text-secondary);
  /* ... */
}

/* ── AFTER ── */
.lv-grid__cell {
  /* ... */
  color: var(--lv-grid-text);
  /* ... */
}
```

#### 변경 4: 선택 행 border-left → box-shadow (FR-05, 라인 29-32)

```css
/* ── BEFORE ── */
.lv-grid__row--selected {
  background: var(--lv-grid-selected);
  border-left: 3px solid var(--lv-grid-primary);
}

/* ── AFTER ── */
.lv-grid__row--selected {
  background: var(--lv-grid-selected);
  box-shadow: inset 3px 0 0 var(--lv-grid-primary);
}
```

#### 변경 5: 편집 가능 셀 시각적 힌트 (FR-08, 라인 61-68)

```css
/* ── BEFORE ── */
.lv-grid__cell-value--editable {
  cursor: pointer;
  padding: 2px 4px;
  border-radius: 2px;
  transition: background 0.15s ease;
  min-height: var(--lv-grid-cell-content-h);
  display: inline-block;
}

/* ── AFTER ── */
.lv-grid__cell-value--editable {
  cursor: pointer;
  padding: 2px 4px;
  border-radius: 2px;
  border-bottom: 1px dashed var(--lv-grid-border-input);
  transition: background 0.15s ease, border-color 0.15s ease;
  min-height: var(--lv-grid-cell-content-h);
  display: inline-block;
}

.lv-grid__cell-value--editable:hover {
  background: var(--lv-grid-warning-light);
  border-bottom-color: var(--lv-grid-primary);
}
```

#### 변경 6: 삭제 행 투명도 조정 (FR-11, 라인 308)

```css
/* ── BEFORE ── */
.lv-grid__row--deleted {
  opacity: 0.5;
  text-decoration: line-through;
  background: var(--lv-grid-danger-light);
}

/* ── AFTER ── */
.lv-grid__row--deleted {
  opacity: 0.6;
  text-decoration: line-through;
  background: var(--lv-grid-danger-light);
}
```

#### 변경 7: 숫자 셀 tabular-nums (FR-06, 기존 라인 201-207 근처에 추가)

```css
/* ── NEW (body.css 끝에 추가) ── */
.lv-grid__cell--numeric {
  font-variant-numeric: tabular-nums;
  text-align: right;
}
```

> **Note**: `grid_component.ex`에서 type이 `:integer`, `:float`, `:number`인 컬럼에 이 클래스 자동 부여 필요. 단, HEEx 렌더링 로직은 Do 단계에서 확인.

---

### 3.4 header.css — 2건 수정 (FR-07, FR-09)

#### 변경 1: 헤더 배경 구분 강화 (FR-07, 라인 8-9)

```css
/* ── BEFORE ── */
.lv-grid__header {
  display: flex;
  background: var(--lv-grid-bg-secondary);
  border-bottom: 2px solid var(--lv-grid-border);
  /* ... */
}

/* ── AFTER ── */
.lv-grid__header {
  display: flex;
  background: var(--lv-grid-bg-tertiary);
  border-bottom: 2px solid var(--lv-grid-border);
  /* ... */
}
```

> `--lv-grid-bg-tertiary`는 라이트 `#f8f9fa`, 다크 `#2c2c2c` — 기존 `--lv-grid-bg-secondary` (#fafafa)보다 약간 더 진함.

#### 변경 2: 필터 placeholder 크기 (FR-09, 라인 158-161)

```css
/* ── BEFORE ── */
.lv-grid__filter-input::placeholder {
  color: var(--lv-grid-text-disabled);
  font-size: 11px;
}

/* ── AFTER ── */
.lv-grid__filter-input::placeholder {
  color: var(--lv-grid-text-disabled);
  font-size: 12px;
}
```

---

### 3.5 toolbar.css — 1건 추가 (FR-10)

#### 변경: 버튼 그룹 간 구분자 추가

```css
/* ── NEW (toolbar.css 끝에 추가) ── */

/* 툴바 영역 간 구분자 */
.lv-grid__toolbar-separator {
  width: 1px;
  height: 24px;
  background: var(--lv-grid-border);
  flex-shrink: 0;
}
```

> **Note**: `grid_component.ex` HEEx에서 `__action-area`와 `__save-area` 사이에 `<span class="lv-grid__toolbar-separator" />` 삽입 필요. Do 단계에서 확인.

---

### 3.6 config-modal.css — 전면 CSS 변수화 (FR-04)

**원칙**: 모든 하드코딩 색상을 기존 `--lv-grid-*` 변수로 교체

| 라인 | Before (하드코딩) | After (CSS 변수) |
|:----:|-------------------|------------------|
| 17 | `#e0e0e0` | `var(--lv-grid-border)` |
| 30 | `#333` | `var(--lv-grid-text)` |
| 47 | `#555` | `var(--lv-grid-text-secondary)` |
| 54 | `#ccc` | `var(--lv-grid-border-input)` |
| 63 | `#2196f3` | `var(--lv-grid-primary)` |
| 74 | `#f9f9f9` | `var(--lv-grid-bg-tertiary)` |
| 76 | `#e8e8e8` | `var(--lv-grid-border-light)` |
| 87 | `#444` | `var(--lv-grid-text-secondary)` |
| 94 | `#2196f3` | `var(--lv-grid-primary)` |
| 102 | `#e0e0e0` | `var(--lv-grid-border)` |
| 105 | `#2196f3` | `var(--lv-grid-primary)` |
| 113 | `#2196f3` | `var(--lv-grid-primary)` |
| 122 | `#2196f3` | `var(--lv-grid-primary)` |
| 132 | `#666` | `var(--lv-grid-text-placeholder)` |
| 139 | `#f0f0f0` | `var(--lv-grid-disabled-bg)` |
| 149 | `#777` | `var(--lv-grid-text-muted)` |
| 170 | `#ffffff` | `var(--lv-grid-bg)` |
| 171 | `#ddd` | `var(--lv-grid-border-input)` |
| 172 | `#333` | `var(--lv-grid-text)` |
| 176 | `#333333` | `var(--lv-grid-bg, #1e1e1e)` |
| 177 | `#555` | `var(--lv-grid-border-input)` |
| 178 | `#fff` | `var(--lv-grid-text, #e0e0e0)` |
| 182 | `#f5f5f5` | `var(--lv-grid-disabled-bg)` |
| 183 | `#999` | `var(--lv-grid-text-muted)` |
| 184 | `#333` | `var(--lv-grid-text)` |
| 193 | `#f9f9f9` | `var(--lv-grid-bg-tertiary)` |
| 201 | `#e0e0e0` | `var(--lv-grid-border)` |
| 204 | `#555` | `var(--lv-grid-text-secondary)` |
| 208 | `#4caf50` | `var(--lv-grid-success)` |

> **theme-preview 특수 처리**: `.preview-box--light`와 `.preview-box--dark`는 테마 미리보기 전용이므로, 해당 클래스에만 하드코딩 유지 (의도적으로 라이트/다크를 보여주는 용도).

---

### 3.7 demo_live.ex — 디버그 바 조건 분기 (FR-14)

```elixir
# ── BEFORE (디버그 바 항상 표시) ──
<div style="background: #fff3cd; padding: 4px 12px; ...">
  전체 데이터 <%= @total_count %>개 | ...
</div>

# ── AFTER (Mix.env() 기반 조건 분기) ──
<%= if Mix.env() == :dev do %>
  <div style="background: #fff3cd; padding: 4px 12px; ...">
    전체 데이터 <%= @total_count %>개 | ...
  </div>
<% end %>
```

> **Note**: `Mix.env()`는 컴파일 타임 매크로이므로 프로덕션 빌드에서 자동 제거됨.

---

## 4. 구현 순서

### Phase A: P0 Quick Wins (예상 25분)

| Step | FR | 파일 | 작업 |
|:----:|:---:|------|------|
| 1 | FR-01 | `body.css` | `overflow-x: hidden` → `auto` (2곳) |
| 2 | FR-02 | `layout.css` | `max-width: 1200px` + `margin: 0 auto` 제거 |
| 3 | FR-03 | `body.css` | `.lv-grid__cell` 색상 → `--lv-grid-text` |
| 4 | FR-04 | `config-modal.css` | 28개 하드코딩 → CSS 변수 (가장 큰 작업) |

### Phase B: P1 Refinements (예상 30분)

| Step | FR | 파일 | 작업 |
|:----:|:---:|------|------|
| 5 | FR-05 | `body.css` | `border-left` → `box-shadow: inset` |
| 6 | FR-06 | `body.css` | `.lv-grid__cell--numeric` 클래스 추가 |
| 7 | FR-07 | `header.css` | 헤더 배경 `--bg-tertiary` 변경 |
| 8 | FR-08 | `body.css` | 편집 셀 `border-bottom: 1px dashed` |
| 9 | FR-09 | `header.css` | 필터 placeholder `12px` |
| 10 | FR-10 | `toolbar.css` | separator 클래스 추가 |
| 11 | FR-11 | `body.css` | 삭제 행 `opacity: 0.6` |
| 12 | FR-12 | 배지 HEEx | 도시 배지 다크모드 (검토 후 결정) |
| 13 | FR-13 | `variables.css` + `layout.css` | 링크 색상 변수 |
| 14 | FR-14 | `demo_live.ex` | 디버그 바 조건 분기 |

### Phase C: 검증

| Step | 작업 | 도구 |
|:----:|------|------|
| 15 | `mix test` 전체 실행 | ExUnit |
| 16 | 라이트 모드 캡처 비교 | Chrome Preview |
| 17 | 다크 모드 캡처 비교 | Chrome Preview |
| 18 | Config Modal 다크모드 캡처 | Chrome Preview |

---

## 5. 검증 체크리스트

### 5.1 CSS 하드코딩 잔여 확인

```bash
# config-modal.css에 #hex 색상 잔여 확인 (theme-preview 제외)
grep -n '#[0-9a-fA-F]\{3,6\}' assets/css/grid/config-modal.css | grep -v 'preview-box'
# 기대 결과: 0건 (또는 preview-box 관련만)
```

### 5.2 overflow-x 확인

```bash
grep -n 'overflow-x.*hidden' assets/css/grid/body.css
# 기대 결과: 0건
```

### 5.3 시각 검증 시나리오

1. **라이트 모드 기본**: 셀 텍스트 진해짐 (#333), 헤더 구분 명확
2. **다크 모드 기본**: 모든 텍스트/배경 정상
3. **다크 모드 Config Modal**: 배경/텍스트/체크박스/슬라이더 정상
4. **행 선택**: border 시프트 없이 파란색 표시
5. **삭제 마킹**: 투명도 적절, 텍스트 읽기 가능
6. **편집 셀**: 점선 보더로 편집 가능 힌트 확인
7. **가로 스크롤**: 컬럼 많을 때 수평 스크롤바 표시

---

## 6. 위험 관리

| 위험 | 대응 |
|------|------|
| Config Modal preview-box 하드코딩 유지 시 혼동 | 주석으로 "의도적 하드코딩" 명시 |
| `--bg-tertiary` 헤더 변경으로 그룹 헤더와 충돌 | `advanced.css` 그룹 헤더도 동일 변수 사용 → 일관성 유지 |
| 숫자 셀 클래스 자동 부여 HEEx 변경 필요 | Do 단계에서 `grid_component.ex` 렌더 함수 확인 |
| separator HEEx 삽입 위치 | Do 단계에서 `event_handlers.ex` toolbar 렌더 함수 확인 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-28 | Initial draft — 14 FR, 42 CSS changes, 1 HEEx change | Claude |
