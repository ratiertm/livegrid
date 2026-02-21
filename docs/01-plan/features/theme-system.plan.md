# F-200: 테마 시스템 (Dark Mode) - 계획서

> **기능 코드**: F-200
> **작성일**: 2026-02-21
> **우선순위**: P1
> **난이도**: 3/5

---

## 1. 목표

CSS 변수 기반 테마 시스템을 구현하여 **Light/Dark 모드 전환**과
**커스텀 테마** 지원. 사용자가 런타임에 테마를 변경할 수 있고,
개발자가 커스텀 테마를 정의할 수 있는 확장 가능한 구조 제공.

---

## 2. 현재 상태 분석

### 2.1 CSS 변수 현황

| 항목 | 현재 구현 |
|------|----------|
| CSS 변수 | `:root`에 7개 색상 + 3개 스페이싱 + 2개 폰트 변수 정의 |
| 변수 활용율 | 컨테이너, 헤더, 테이블 등 핵심 요소에서 변수 사용 |
| 하드코딩 색상 | ~90개 이상의 하드코딩된 HEX 색상 존재 |
| 테마 전환 | 미지원 |

### 2.2 개선 필요 사항

1. **하드코딩 색상 → CSS 변수 전환**: 약 90개 하드코딩 색상을 변수로 변환
2. **Dark 테마 정의**: Dark 모드용 색상 팔레트 필요
3. **테마 전환 메커니즘**: data 속성 또는 class 기반 테마 전환
4. **데모 페이지 토글**: 사용자가 테마를 전환할 수 있는 UI

---

## 3. 요구사항

### 3.1 기능 요구사항

| ID | 요구사항 | 우선순위 |
|----|---------|---------:|
| R-01 | Light 테마 (기본, 현재와 동일) | P0 |
| R-02 | Dark 테마 | P0 |
| R-03 | 런타임 테마 전환 (토글 버튼) | P0 |
| R-04 | CSS 변수 기반 테마링 (확장 가능) | P0 |
| R-05 | 하드코딩 색상 → CSS 변수 전환 | P0 |
| R-06 | 커스텀 테마 정의 가능 (개발자 API) | P1 |
| R-07 | 데모 페이지에 테마 토글 UI | P0 |
| R-08 | 시스템 설정 자동 감지 (prefers-color-scheme) | P2 |

### 3.2 비기능 요구사항

| ID | 요구사항 |
|----|---------:|
| NR-01 | 테마 전환 시 깜빡임 없음 (CSS-only 전환) |
| NR-02 | 기존 Light 테마 시각적 변경 없음 |
| NR-03 | 하위호환: theme 미지정 시 기본 Light |

---

## 4. 구현 전략

### 4.1 테마 메커니즘

**방식**: `data-theme` 속성 기반

```html
<!-- Light (기본) -->
<div class="lv-grid" data-theme="light">...</div>

<!-- Dark -->
<div class="lv-grid" data-theme="dark">...</div>
```

### 4.2 CSS 변수 확장

**현재 변수 (7개) → 확장 (약 25개)**

```css
:root, .lv-grid[data-theme="light"] {
  /* 기존 유지 */
  --lv-grid-primary: #2196f3;
  --lv-grid-bg: #ffffff;
  --lv-grid-text: #333333;
  --lv-grid-border: #e0e0e0;
  --lv-grid-hover: #f5f5f5;
  --lv-grid-selected: #e3f2fd;

  /* 새로 추가 */
  --lv-grid-bg-secondary: #fafafa;
  --lv-grid-bg-tertiary: #f8f9fa;
  --lv-grid-text-muted: #999;
  --lv-grid-text-disabled: #aaa;
  --lv-grid-border-light: #f0f0f0;
  --lv-grid-danger: #f44336;
  --lv-grid-danger-bg: #ffebee;
  --lv-grid-success: #4caf50;
  --lv-grid-success-bg: #e8f5e9;
  --lv-grid-warning: #ff9800;
  --lv-grid-warning-bg: #fff3e0;
  --lv-grid-shadow: rgba(0,0,0,0.1);
  --lv-grid-input-bg: #ffffff;
  --lv-grid-input-border: #ddd;
}
```

### 4.3 하위 호환 전략

- `data-theme` 미지정 시 `:root` 변수 사용 → 기존 Light 테마 유지
- 기존 코드에서 `var(--lv-grid-*)` 사용하는 부분은 변경 불필요
- 하드코딩 색상만 변수로 교체

### 4.4 구현 단계

| Step | 내용 | 예상 소요 |
|------|------|----------|
| 1 | CSS 변수 확장 (Light 테마 정의) | 15min |
| 2 | 하드코딩 색상 → CSS 변수 교체 | 30min |
| 3 | Dark 테마 변수 정의 | 15min |
| 4 | GridComponent에 테마 지원 추가 | 15min |
| 5 | 데모 페이지에 테마 토글 UI | 10min |
| 6 | 컴파일 + 테스트 + 브라우저 검증 | 20min |

---

## 5. 리스크 및 대응

| 리스크 | 영향 | 대응 |
|--------|------|------|
| 하드코딩 색상 누락 | 중간 | 체계적 검색 후 교체, 브라우저에서 시각 확인 |
| Light 테마 시각 변경 | 높음 | 변수 값은 기존 하드코딩 값과 동일하게 유지 |
| Dark 모드 가독성 | 중간 | 충분한 대비비(contrast ratio) 확보 |

---

## 6. 테스트 시나리오

| ID | 시나리오 |
|----|---------:|
| T-01 | Light 테마: 기존과 시각적으로 동일 |
| T-02 | Dark 테마: 모든 요소 가독성 확인 |
| T-03 | 테마 토글: Light ↔ Dark 실시간 전환 |
| T-04 | 고급 필터 패널 Dark 모드 |
| T-05 | 셀 편집 모드 Dark 모드 |
| T-06 | Export 버튼 Dark 모드 |
| T-07 | 뱃지/렌더러 Dark 모드 |
| T-08 | 페이지네이션 Dark 모드 |
