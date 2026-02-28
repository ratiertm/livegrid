# 🚀 빠른 시작 가이드 — LiveView Grid

## 이 파일들을 프로젝트에 적용하는 방법

### STEP 1: 파일 복사 (2분)

```bash
# liveview_grid 프로젝트 루트에서 실행
cp CLAUDE.md /path/to/liveview_grid/
cp -r .claude/ /path/to/liveview_grid/
```

### STEP 2: CLAUDE.md 커스터마이징 (10분)

`CLAUDE.md`를 열고 아래 항목을 실제 프로젝트에 맞게 수정하세요:

1. **프로젝트 구조** — `lib/liveview_grid/` 하위 실제 모듈 목록으로 변경
2. **핵심 규칙** — 프로젝트 고유 규칙 추가 (예: 특정 라이브러리 사용 패턴)
3. **기술 스택** — 추가 라이브러리 명시 (Oban, Absinthe, Guardian 등)

### STEP 3: 스킬 매뉴얼 커스터마이징 (15분)

`.claude/skills/` 안의 파일들을 프로젝트에 맞게 조정하세요:

- **좋은 예 / 나쁜 예** → 실제 liveview_grid 코드 패턴으로 교체
- **프로젝트 고유 패턴** → 자주 실수하는 패턴 추가
- **사용하지 않는 항목** → 삭제 또는 수정

> 💡 처음부터 완벽하게 만들지 마세요!
> 작업하면서 "이것도 매뉴얼에 넣어야겠다" 싶은 것들을 점진적으로 추가하세요.

### STEP 4: 첫 작업 시작 (바로!)

```
사용자 → Claude Code:
"liveview_grid의 [기능]을 만들려고 해.
먼저 .claude/templates/plan.md 템플릿을 참고해서
.claude/tasks/current/ 에 계획서를 작성해줘."
```

---

## 일상적인 사용 흐름

### 매일 작업 시작할 때
```
".claude/tasks/current/ 에 진행 중인 작업 있는지 확인하고,
있으면 체크리스트 읽고 이어서 진행해."
```

### 새 기능/리팩토링 시작할 때
```
"[작업 내용] 계획을 세워줘.
계획이 완성되면 바로 시작하지 말고
.claude/tasks/current/ 에 plan.md, context-notes.md, checklist.md 저장해."
```

### 작업 단계 완료할 때마다
```
"방금 한 작업 체크리스트에 체크하고, 다음 단계 뭔지 알려줘."
```

### 품질 검사
```
"mix compile --warnings-as-errors 하고 mix test 돌려봐.
에러 있으면 수정해."
```

### 코드 리뷰가 필요할 때
```
".claude/agents.md 의 코드 리뷰 에이전트 프롬프트로
방금 수정한 파일들 리뷰해줘."
```

### 작업 완료 시
```
"체크리스트 최종 검증 항목 전부 확인해.
완료되면 .claude/tasks/current/ 파일들을 .claude/tasks/done/ 으로 옮겨."
```

---

## 파일 구조 한눈에 보기

```
liveview_grid/
├── CLAUDE.md                              ← Claude가 가장 먼저 읽는 파일
└── .claude/
    ├── skills/                            ← 시스템 ①: 자동 매뉴얼
    │   ├── liveview/
    │   │   ├── INDEX.md                   ← LiveView/웹 목차
    │   │   ├── liveview-rules.md          ← LiveView 작성 규칙
    │   │   ├── component-rules.md         ← Phoenix Component 규칙
    │   │   └── styling-guide.md           ← HEEx + TailwindCSS
    │   ├── backend/
    │   │   ├── INDEX.md                   ← 백엔드 목차
    │   │   ├── context-design.md          ← Phoenix Context 설계
    │   │   ├── ecto-patterns.md           ← Ecto 스키마/쿼리/마이그레이션
    │   │   └── error-handling.md          ← 에러 처리 패턴
    │   └── common/
    │       ├── git-conventions.md         ← Git 커밋 규칙
    │       ├── naming-rules.md            ← Elixir 네이밍 컨벤션
    │       ├── security-checklist.md      ← 보안 체크리스트
    │       └── testing-conventions.md     ← ExUnit 테스트 규칙
    ├── templates/                         ← 시스템 ②: 작업 기억 템플릿
    │   ├── plan.md                        ← 계획서 템플릿
    │   ├── context-notes.md               ← 맥락 노트 템플릿
    │   └── checklist.md                   ← 체크리스트 템플릿
    ├── tasks/                             ← 시스템 ②: 실제 작업 문서
    │   ├── current/                       ← 진행 중 (AI가 매번 읽음)
    │   └── done/                          ← 완료됨 (참고용)
    ├── hooks/                             ← 시스템 ③: 자동 품질 검사
    │   └── SETUP.md                       ← 훅 설정 가이드
    └── agents.md                          ← 시스템 ④: 전문 에이전트 프롬프트
```

---

## 자주 쓰는 명령어 치트시트

| 상황 | Claude Code에 입력할 내용 |
|------|--------------------------|
| 작업 시작 | `계획부터 세워줘. 바로 시작하지 마.` |
| 계획 승인 | `승인. 문서 저장하고, 1단계만 시작해.` |
| 단계 완료 | `체크리스트 업데이트하고 다음 단계 진행.` |
| 새 대화 시작 | `.claude/tasks/current/ 읽고 이어서 작업해.` |
| 품질 검사 | `mix compile --warnings-as-errors && mix test 돌려.` |
| 코드 리뷰 | `코드 리뷰 에이전트로 방금 수정한 파일 리뷰해.` |
| 테스트 작성 | `테스트 에이전트로 이 기능 테스트 작성해.` |
| 작업 완료 | `최종 검증 후 tasks/done 으로 이동.` |
| 매뉴얼 추가 | `방금 겪은 실수를 skills에 규칙으로 추가해.` |

---

## Elixir 품질 도구 체크 명령어

```bash
mix compile --warnings-as-errors   # 컴파일 + 경고 체크
mix format --check-formatted       # 코드 포맷 체크
mix test                           # 테스트 실행
mix test --cover                   # 테스트 + 커버리지
mix credo --strict                 # 정적 분석 (credo 설치 시)
mix dialyzer                       # 타입 체크 (dialyxir 설치 시)
mix ecto.migrate                   # 마이그레이션 실행
mix ecto.rollback                  # 마이그레이션 롤백
```
