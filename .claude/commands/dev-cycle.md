---
description: "개발 사이클 실행 (계획→설계→개발→테스트→문서→검토)"
argument-hint: "<phase> <feature> (예: plan 가상스크롤, develop 필터링)"
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Task", "TodoWrite"]
---

# 개발 사이클 (Dev Cycle)

LiveView Grid 프로젝트에서 검증된 PDCA 기반 개발 워크플로우입니다.
v0.1~v0.7까지 7개 버전을 성공적으로 릴리스한 방법론을 재사용합니다.

## 입력 파싱

`$ARGUMENTS`를 파싱하여 **phase**와 **feature**를 추출하세요.

- 첫 번째 단어 = phase (plan | design | develop | test | docs | review)
- 나머지 = feature 이름

phase가 없으면 사용 가능한 phase 목록을 보여주세요.

---

## Phase별 실행 지침

### 1. plan (계획)

**목표**: 기능 요구사항을 분석하고 구현 계획서를 작성합니다.

수행 작업:
1. 기존 코드베이스 탐색 - 관련 모듈, 함수, 패턴 파악
2. 요구사항 목록 작성 (필수 / 선택 구분)
3. 아키텍처 결정 사항 정리 (접근법 2~3개 비교, 장단점 분석)
4. 구현 순서 계획 (의존성 기반 단계별)
5. 영향받는 파일 목록

**출력**: 계획서를 TodoWrite에 등록하고, 사용자에게 요약 보고

### 2. design (설계)

**목표**: API 인터페이스와 데이터 구조를 설계합니다.

수행 작업:
1. Public API 정의 (함수 시그니처, 타입, 반환값)
2. 데이터 구조 설계 (assigns, structs, maps)
3. 이벤트 흐름 정의 (LiveView handle_event 매핑)
4. 모듈 의존성 다이어그램
5. 기존 패턴과의 일관성 검증

**출력**: 설계 문서 (코드 예시 포함)

### 3. develop (개발)

**목표**: 설계를 기반으로 실제 코드를 구현합니다.

수행 작업:
1. 계획서/설계서 읽기 (이전 phase 산출물 확인)
2. 의존성 순서대로 구현 (하위 모듈 → 상위 모듈)
3. 각 모듈 구현 후 `mix compile` 확인
4. 기존 테스트 통과 확인 `mix test`
5. 데모 페이지 연동 (필요 시)

**규칙**:
- 기존 코드 패턴 따르기 (명명 규칙, 모듈 구조)
- LiveViewGrid 네임스페이스 유지 (Core 모듈)
- LiveviewGridWeb 네임스페이스 유지 (Web 모듈)
- @moduledoc, @doc 기본 문서화 포함

### 4. test (테스트)

**목표**: 구현된 기능을 검증합니다.

수행 작업:
1. 기능 테스트 (정상 동작 시나리오)
2. 엣지 케이스 테스트 (nil, 빈 값, 대용량)
3. 기존 기능 회귀 테스트 `mix test`
4. 브라우저 수동 테스트 가이드 작성 (필요 시)
5. 성능 체크 (1,000행 / 10,000행 기준)

**출력**: 테스트 결과 리포트 (통과/실패/발견된 버그)

### 5. docs (문서화)

**목표**: 코드 문서와 사용자 가이드를 업데이트합니다.

수행 작업:
1. @moduledoc 업데이트 (새/변경된 모듈)
2. @doc 함수 문서 (공개 API)
3. guides/ 가이드 문서 업데이트 (한국어 + 영어)
4. `mix docs` 실행하여 ex_doc 생성
5. README.md 업데이트 (필요 시)

**가이드 파일 위치**:
- `guides/getting-started.md` / `guides/getting-started-en.md`
- `guides/formatters.md` / `guides/formatters-en.md`
- `guides/data-sources.md` / `guides/data-sources-en.md`
- `guides/advanced-features.md` / `guides/advanced-features-en.md`

### 6. review (검토)

**목표**: 설계-구현 갭을 분석하고 다음 사이클을 계획합니다.

수행 작업:
1. 설계서 vs 구현 코드 비교 (누락/불일치 항목)
2. 코드 품질 분석 (중복, 복잡도, 네이밍)
3. 테스트 커버리지 확인
4. 개선점 목록 작성
5. 다음 버전 로드맵 제안

**출력**: 검토 리포트 (매치율, 개선 항목, 다음 계획)

---

## 전체 사이클 흐름

```
plan → design → develop → test → docs → review
  ↑                                         │
  └─────────── 다음 기능/개선 ──────────────┘
```

각 phase는 독립적으로 실행 가능합니다.
순서대로 진행하면 최고의 결과를 얻을 수 있습니다.
