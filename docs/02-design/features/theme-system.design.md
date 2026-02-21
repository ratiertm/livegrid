# F-200: 테마 시스템 - 기술 설계서

> **기능 코드**: F-200
> **작성일**: 2026-02-21
> **Plan 문서**: [theme-system.plan.md](../../01-plan/features/theme-system.plan.md)

---

## 1. 아키텍처

### 1.1 모듈 구조

```
assets/css/
  liveview_grid.css            ← [MODIFY] 변수 확장 + Dark 테마 + 하드코딩 교체

lib/liveview_grid/
  grid.ex                      ← [MODIFY] options에 theme 추가

lib/liveview_grid_web/
  components/grid_component.ex ← [MODIFY] data-theme 속성 렌더링
  live/demo_live.ex            ← [MODIFY] 테마 토글 UI
```

### 1.2 데이터 흐름

```
[개발자 options]          [데모 토글 버튼]
      │                        │
      │  theme: "dark"         │  toggle_theme 이벤트
      │                        │
      ▼                        ▼
  ┌────────────────────────────────┐
  │  Grid options.theme            │
  │  "light" (기본) | "dark"       │
  └─────────────┬──────────────────┘
                │
                ▼
  ┌────────────────────────────────┐
  │  <div class="lv-grid"          │
  │       data-theme={@theme}>     │
  └─────────────┬──────────────────┘
                │
                ▼
  ┌────────────────────────────────┐
  │  CSS 변수 자동 적용             │
  │  .lv-grid[data-theme="dark"]   │
  └────────────────────────────────┘
```

---

## 2. API 설계

### 2.1 Grid options 변경

```elixir
# 기존 options에 theme 추가
options = %{
  page_size: 20,
  theme: "light"  # "light" | "dark" (기본: "light")
}
```

### 2.2 GridComponent 변경

```elixir
# render에서 data-theme 속성 추가
<div class="lv-grid" data-theme={@grid.options[:theme] || "light"}>
```

### 2.3 데모 이벤트

```elixir
# 테마 토글
def handle_event("toggle_theme", _params, socket)
```

---

## 3. CSS 변수 설계

### 3.1 확장 변수 목록 (Light)

```css
:root,
.lv-grid[data-theme="light"] {
  /* ── 기본 색상 (기존 유지) ── */
  --lv-grid-primary: #2196f3;
  --lv-grid-primary-dark: #1976d2;
  --lv-grid-primary-light: #e3f2fd;
  --lv-grid-bg: #ffffff;
  --lv-grid-text: #333333;
  --lv-grid-text-secondary: #555555;
  --lv-grid-border: #e0e0e0;
  --lv-grid-hover: #f5f5f5;
  --lv-grid-selected: #e3f2fd;

  /* ── 배경 계층 ── */
  --lv-grid-bg-secondary: #fafafa;
  --lv-grid-bg-tertiary: #f8f9fa;
  --lv-grid-bg-input: #ffffff;

  /* ── 텍스트 계층 ── */
  --lv-grid-text-muted: #999999;
  --lv-grid-text-disabled: #aaaaaa;
  --lv-grid-text-placeholder: #666666;

  /* ── 보더 계층 ── */
  --lv-grid-border-light: #f0f0f0;
  --lv-grid-border-input: #dddddd;

  /* ── 시맨틱 색상 ── */
  --lv-grid-danger: #f44336;
  --lv-grid-danger-dark: #d32f2f;
  --lv-grid-danger-light: #ffebee;
  --lv-grid-danger-hover: #e53935;
  --lv-grid-success: #4caf50;
  --lv-grid-success-dark: #43a047;
  --lv-grid-success-light: #e8f5e9;
  --lv-grid-warning: #ff9800;
  --lv-grid-warning-light: #fff3e0;

  /* ── 기타 ── */
  --lv-grid-shadow: rgba(0, 0, 0, 0.08);
  --lv-grid-overlay: rgba(0, 0, 0, 0.05);
  --lv-grid-scrollbar-thumb: #bdbdbd;
  --lv-grid-disabled-bg: #f5f5f5;

  /* ── 스페이싱/폰트 (불변) ── */
  --lv-grid-space-2: 8px;
  --lv-grid-space-3: 12px;
  --lv-grid-space-4: 16px;
  --lv-grid-font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --lv-grid-font-size-sm: 13px;
  --lv-grid-font-size-md: 14px;
}
```

### 3.2 Dark 테마 변수

```css
.lv-grid[data-theme="dark"] {
  /* ── 기본 색상 ── */
  --lv-grid-primary: #64b5f6;
  --lv-grid-primary-dark: #42a5f5;
  --lv-grid-primary-light: #1a2332;
  --lv-grid-bg: #1e1e1e;
  --lv-grid-text: #e0e0e0;
  --lv-grid-text-secondary: #b0b0b0;
  --lv-grid-border: #333333;
  --lv-grid-hover: #2a2a2a;
  --lv-grid-selected: #1a2332;

  /* ── 배경 계층 ── */
  --lv-grid-bg-secondary: #252525;
  --lv-grid-bg-tertiary: #2c2c2c;
  --lv-grid-bg-input: #2a2a2a;

  /* ── 텍스트 계층 ── */
  --lv-grid-text-muted: #888888;
  --lv-grid-text-disabled: #666666;
  --lv-grid-text-placeholder: #888888;

  /* ── 보더 계층 ── */
  --lv-grid-border-light: #2a2a2a;
  --lv-grid-border-input: #444444;

  /* ── 시맨틱 색상 ── */
  --lv-grid-danger: #ef5350;
  --lv-grid-danger-dark: #e53935;
  --lv-grid-danger-light: #3d1f1f;
  --lv-grid-danger-hover: #f44336;
  --lv-grid-success: #66bb6a;
  --lv-grid-success-dark: #4caf50;
  --lv-grid-success-light: #1b3a1b;
  --lv-grid-warning: #ffa726;
  --lv-grid-warning-light: #3d2e1a;

  /* ── 기타 ── */
  --lv-grid-shadow: rgba(0, 0, 0, 0.3);
  --lv-grid-overlay: rgba(255, 255, 255, 0.05);
  --lv-grid-scrollbar-thumb: #555555;
  --lv-grid-disabled-bg: #333333;
}
```

---

## 4. 하드코딩 교체 매핑

### 4.1 색상 → 변수 매핑

| 하드코딩 색상 | 변수 |
|-------------|------|
| `#fafafa` | `var(--lv-grid-bg-secondary)` |
| `#f8f9fa` | `var(--lv-grid-bg-tertiary)` |
| `#f5f5f5` | `var(--lv-grid-disabled-bg)` |
| `#f0f0f0` | `var(--lv-grid-border-light)` |
| `#ddd`, `#dddddd` | `var(--lv-grid-border-input)` |
| `#ccc` | `var(--lv-grid-border)` |
| `#999` | `var(--lv-grid-text-muted)` |
| `#aaa` | `var(--lv-grid-text-disabled)` |
| `#666` | `var(--lv-grid-text-placeholder)` |
| `#333` | `var(--lv-grid-text)` |
| `#1976d2` | `var(--lv-grid-primary-dark)` |
| `#e3f2fd` | `var(--lv-grid-primary-light)` |
| `#f44336` | `var(--lv-grid-danger)` |
| `#d32f2f` | `var(--lv-grid-danger-dark)` |
| `#ffebee` | `var(--lv-grid-danger-light)` |
| `#e53935` | `var(--lv-grid-danger-hover)` |
| `#4caf50` | `var(--lv-grid-success)` |
| `#43a047` | `var(--lv-grid-success-dark)` |
| `#e8f5e9` | `var(--lv-grid-success-light)` |
| `#ff9800` | `var(--lv-grid-warning)` |
| `#fff3e0` | `var(--lv-grid-warning-light)` |
| `#bdbdbd` | `var(--lv-grid-scrollbar-thumb)` |
| `#e0e0e0` | `var(--lv-grid-border)` |
| `white` | `var(--lv-grid-bg)` |

### 4.2 교체 제외 항목

- **뱃지 프리셋 색상** (`.lv-grid__badge--blue`, `--green` 등): 시맨틱 고정값이므로 유지
- **프로그레스바 프리셋 색상**: 시맨틱 고정값
- 이미 `var()` 사용하는 부분: 변경 불필요

---

## 5. UI 설계

### 5.1 데모 페이지 테마 토글

```
┌──────────────────────────────────────┐
│ 🌗 테마: [Light] [Dark]              │
└──────────────────────────────────────┘
```

위치: 데모 페이지 상단, 데이터 개수 선택 옆

---

## 6. 테스트 시나리오

| ID | 시나리오 | 예상 결과 |
|----|---------|----------|
| T-01 | Light 테마 (기본) | 기존과 시각적 동일 |
| T-02 | Dark 테마 전환 | 어두운 배경, 밝은 텍스트 |
| T-03 | 테마 토글 | 깜빡임 없이 즉시 전환 |
| T-04 | 고급 필터 Dark | 패널 배경/텍스트 가독성 |
| T-05 | 셀 편집 Dark | 입력 필드 가독성 |
| T-06 | Export 버튼 Dark | 버튼 스타일 정상 |
| T-07 | 뱃지/프로그레스 Dark | 색상 대비 유지 |
| T-08 | 기존 API 호환 | theme 미지정 시 Light |

---

## 7. 파일 변경 목록

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `assets/css/liveview_grid.css` | MODIFY | 변수 확장 + Dark 테마 + 하드코딩 교체 |
| `lib/liveview_grid/grid.ex` | MODIFY | options에 theme 기본값 추가 |
| `lib/liveview_grid_web/components/grid_component.ex` | MODIFY | data-theme 속성 렌더링 |
| `lib/liveview_grid_web/live/demo_live.ex` | MODIFY | 테마 토글 UI + 이벤트 |
