# UI/UX Improvements Planning Document

> **Summary**: Grid CSS/디자인 전면 개선 - P0~P2 총 24건 이슈 해결
>
> **Project**: LiveView Grid
> **Version**: v0.7
> **Author**: Claude (UI/UX 30년 경력 에이전트 리뷰 기반)
> **Date**: 2026-02-28
> **Status**: Draft

---

## 1. Overview

### 1.1 Purpose

LiveView Grid의 UI/UX 품질을 프로덕션 수준으로 끌어올린다.
현재 그리드는 기능적으로는 완성도가 높으나, CSS에 가독성/접근성/다크모드/반응형 이슈가 산재해 있어 사용자 경험이 저하된다.

### 1.2 Background

- UI/UX 전문 에이전트가 CSS 7개 파일 + 전체 화면 9개 상태를 캡처/분석 완료
- AG Grid 등 상용 그리드와 비교 분석 수행
- P0(치명) 4건, P1(중요) 10건, P2(개선) 10건 총 24건 식별
- 특히 Config Modal 다크모드 미지원, 가로 스크롤 불가 등은 즉시 수정 필요

### 1.3 Related Documents

- UI/UX 분석 결과: 이전 세션 화면별 캡처 + 이슈 리포트
- CSS 파일: `assets/css/grid/` 디렉토리 전체 (9개 파일)
- 참조: AG Grid, Handsontable 등 상용 그리드 UX 패턴

---

## 2. Scope

### 2.1 In Scope

- [x] P0: 가로 스크롤 (`overflow-x: hidden` → `auto`)
- [x] P0: max-width 1200px 제거
- [x] P0: 셀 텍스트 색상 가독성 개선
- [x] P0: Config Modal 다크모드 지원 (CSS 변수화)
- [ ] P1: 선택 행 border-left 레이아웃 시프트 수정
- [ ] P1: 숫자 컬럼 tabular-nums 적용
- [ ] P1: 헤더-본문 시각적 구분 강화
- [ ] P1: 편집 가능 셀 시각적 힌트
- [ ] P1: 필터 placeholder 크기 통일
- [ ] P1: 버튼 그룹핑 구분자 추가
- [ ] P1: 삭제 마킹 행 불투명도 조정
- [ ] P1: 도시 배지 다크모드 지원
- [ ] P1: 이메일 링크 다크모드 가독성
- [ ] P1: 디버그 바 프로덕션 조건 분기

### 2.2 Out of Scope

- Empty State 일러스트 디자인 (P2 — 별도 작업)
- 로딩 오버레이/스켈레톤 (P2 — 별도 작업)
- 컨텍스트 메뉴 키보드 네비게이션 (P2 — 별도 작업)
- 반응형 모바일 대응 (P2 — 별도 작업)
- 아이콘 시스템 통일 (P2 — 별도 작업)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | `overflow-x: hidden` → `auto`로 변경, 가로 스크롤 활성화 | **P0** | Pending |
| FR-02 | `max-width: 1200px` 제거 또는 `100%`로 변경 | **P0** | Pending |
| FR-03 | 셀 텍스트 색상 `--lv-grid-text-secondary` → `--lv-grid-text`로 변경 | **P0** | Pending |
| FR-04 | Config Modal 전체 하드코딩 색상 → CSS 변수로 교체 (다크모드 지원) | **P0** | Pending |
| FR-05 | 선택 행 `border-left: 3px` → `box-shadow: inset 3px 0 0` 변경 | P1 | Pending |
| FR-06 | 숫자 표시 컬럼에 `font-variant-numeric: tabular-nums` 적용 | P1 | Pending |
| FR-07 | 헤더 배경색 `#fafafa` → `#f0f0f0` 또는 하단 보더 강화 | P1 | Pending |
| FR-08 | 편집 가능 셀에 점선 하단 보더 또는 연필 아이콘 표시 | P1 | Pending |
| FR-09 | 필터 placeholder `font-size: 11px` → `12px` 통일 | P1 | Pending |
| FR-10 | 툴바 버튼 그룹 간 구분자 (separator) 추가 | P1 | Pending |
| FR-11 | 삭제 마킹 행 `opacity: 0.5` → `0.6` 조정 | P1 | Pending |
| FR-12 | 도시 배지 색상 다크모드 대응 (CSS 변수 기반) | P1 | Pending |
| FR-13 | 이메일 링크 다크모드 전용 색상 변수 추가 | P1 | Pending |
| FR-14 | 디버그 바 (노란색 info bar) 조건부 표시 (`dev` 환경만) | P1 | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Accessibility | WCAG 2.1 AA 색상 대비 (4.5:1 이상) | Chrome DevTools Contrast Checker |
| Performance | CSS 변경 후 렌더링 성능 저하 없음 | Lighthouse Performance Score 유지 |
| Compatibility | 라이트/다크 모드 모두 정상 표시 | 수동 검증 (캡처 비교) |
| Consistency | 모든 색상이 CSS 변수 참조 (하드코딩 0건) | `grep` 검증 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] P0 4건 전부 수정 완료
- [ ] P1 10건 전부 수정 완료
- [ ] 다크모드에서 Config Modal 정상 표시
- [ ] 가로 스크롤 동작 확인
- [ ] 기존 테스트 전부 통과 (428+ tests)
- [ ] 라이트/다크 양쪽 캡처로 시각 검증

### 4.2 Quality Criteria

- [ ] Config Modal에 하드코딩 색상 0건
- [ ] `overflow-x: hidden` 사용처 0건 (body.css)
- [ ] WCAG AA 색상 대비 기준 충족
- [ ] 기존 테스트 0 failures

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| CSS 변수 변경으로 기존 테마 깨짐 | High | Medium | 라이트/다크 양쪽 캡처 비교 |
| overflow-x 변경으로 레이아웃 의도치 않은 변화 | Medium | Low | 각 데모 페이지별 검증 |
| Config Modal CSS 변수화 시 누락 항목 | Medium | Medium | `grep '#[0-9a-fA-F]'` 로 하드코딩 잔여 검출 |
| border-left → box-shadow 변경 시 시각적 차이 | Low | Low | A/B 캡처 비교 |

---

## 6. Architecture Considerations

### 6.1 Project Level

| Level | Selected |
|-------|:--------:|
| **Dynamic** | **O** |

> Phoenix LiveView + Elixir 기반, BEM CSS 아키텍처

### 6.2 Key Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| CSS 변수 네이밍 | 기존 `--lv-grid-*` 유지 | `--lv-grid-*` 유지 | 이미 확립된 패턴 |
| Config Modal 다크모드 | 1) CSS 변수화 2) 별도 다크 시트 | CSS 변수화 | 유지보수 용이, 일관성 |
| 셀 텍스트 색상 | 1) `--text` 2) `--text-secondary` | `--text` | WCAG AA 충족, 가독성 |

### 6.3 수정 대상 파일

```
assets/css/grid/
  ├── variables.css       # 변수 추가/조정 (다크모드 링크 색상 등)
  ├── layout.css          # max-width 제거
  ├── body.css            # overflow-x, 셀 색상, 선택 행 보더, 삭제 행 투명도
  ├── header.css          # 헤더 배경, 필터 placeholder 크기
  ├── toolbar.css         # 버튼 그룹 구분자
  └── config-modal.css    # 전면 CSS 변수화 (가장 큰 변경)
```

---

## 7. 구현 전략

### Phase A: P0 Quick Wins (즉시 적용)

| 순서 | 파일 | 변경 | 예상 시간 |
|------|------|------|----------|
| 1 | `body.css:9` | `overflow-x: hidden` → `auto` | 1분 |
| 2 | `layout.css:14` | `max-width: 1200px` 제거 | 1분 |
| 3 | `body.css:46` | `color: var(--lv-grid-text-secondary)` → `var(--lv-grid-text)` | 1분 |
| 4 | `config-modal.css` | 전면 CSS 변수화 (~30개 하드코딩 색상) | 20분 |

### Phase B: P1 Refinements

| 순서 | 파일 | 변경 | 예상 시간 |
|------|------|------|----------|
| 5 | `body.css:31` | `border-left` → `box-shadow: inset` | 3분 |
| 6 | `body.css` | 숫자 셀에 `tabular-nums` 클래스 추가 | 5분 |
| 7 | `header.css:8` | 헤더 배경 `--lv-grid-bg-secondary` 조정 | 3분 |
| 8 | `body.css` | 편집 가능 셀에 점선 보더 추가 | 5분 |
| 9 | `header.css:159` | 필터 placeholder `11px` → `12px` | 1분 |
| 10 | `toolbar.css` | 버튼 그룹 간 구분자 CSS 추가 | 5분 |
| 11 | `body.css:308` | 삭제 행 `opacity: 0.5` → `0.6` | 1분 |
| 12 | `variables.css` + HEEx | 도시 배지 다크모드 변수 | 10분 |
| 13 | `variables.css` | 다크모드 링크 색상 변수 추가 | 3분 |
| 14 | `demo_live.ex` 또는 HEEx | 디버그 바 조건부 표시 | 5분 |

### Phase C: 검증

| 순서 | 작업 | 도구 |
|------|------|------|
| 15 | 기존 테스트 실행 (428+) | `mix test` |
| 16 | 라이트 모드 전체 화면 캡처 비교 | Chrome Preview |
| 17 | 다크 모드 전체 화면 캡처 비교 | Chrome Preview |
| 18 | Config Modal 다크모드 캡처 | Chrome Preview |

---

## 8. Next Steps

1. [ ] Design 문서 작성 (`ui-ux-improvements.design.md`) — CSS 변경 명세서
2. [ ] Phase A (P0) 구현
3. [ ] Phase B (P1) 구현
4. [ ] Phase C 검증 + Gap Analysis

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-28 | Initial draft — 24건 이슈 정리, 3-Phase 구현 전략 | Claude |
