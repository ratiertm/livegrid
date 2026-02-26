# LiveView Grid 프로젝트 가이드

## 기술 스택
- Language: Elixir
- Framework: Phoenix
- Frontend: Phoenix LiveView + TailwindCSS
- Database: PostgreSQL + Ecto
- 패키지 매니저: Mix + Hex

## 프로젝트 구조
```
liveview_grid/
├── lib/
│   ├── liveview_grid/                    # 비즈니스 로직
│   │   ├── grid.ex                       # Grid 상태 관리 핵심 (805줄)
│   │   ├── formatter.ex                  # 셀 값 포맷터
│   │   ├── export.ex                     # Excel/CSV 내보내기
│   │   ├── renderers.ex                  # 커스텀 렌더러 (badge, link, progress)
│   │   ├── data_source.ex                # DataSource 추상화
│   │   ├── data_source/
│   │   │   ├── ecto.ex                   # Ecto DB 어댑터
│   │   │   ├── rest.ex                   # REST API 어댑터
│   │   │   └── in_memory.ex              # InMemory 어댑터
│   │   └── operations/
│   │       ├── sorting.ex                # 정렬 (null 처리 포함)
│   │       ├── filter.ex                 # 필터 (컬럼/전체/고급)
│   │       ├── pagination.ex             # 페이지네이션
│   │       ├── grouping.ex               # 그룹핑 + 집계
│   │       ├── tree.ex                   # Tree Grid
│   │       └── pivot.ex                  # Pivot Table
│   ├── liveview_grid_web/                # 웹 레이어
│   │   ├── components/
│   │   │   └── grid_component.ex         # Grid LiveComponent (2,303줄 ⚠️)
│   │   ├── live/
│   │   │   ├── demo_live.ex              # InMemory 데모
│   │   │   ├── dbms_demo_live.ex         # DB 연동 데모
│   │   │   ├── api_demo_live.ex          # REST API 데모
│   │   │   ├── renderer_demo_live.ex     # 렌더러 데모
│   │   │   └── advanced_demo_live.ex     # 고급 기능 데모
│   │   └── router.ex
│   └── liveview_grid/
│       └── application.ex                # OTP Application
├── assets/
│   ├── js/app.js                         # JS Hooks (1,022줄)
│   └── css/liveview_grid.css             # Grid 스타일 (1,367줄)
├── test/                                 # 255개 테스트
├── config/
└── mix.exs
```

### ⚠️ 대형 파일 (리팩토링 대상)
- `grid_component.ex` (2,303줄) — 렌더링 + 이벤트 핸들러 + 헬퍼 전부 포함. 분할 필요
- `app.js` (1,022줄) — Hook 7개가 한 파일에 집중. 모듈 분리 검토

## 🔴 핵심 규칙 (항상 적용)
1. Phoenix Contexts 패턴 준수 — 웹 레이어에서 직접 Repo 호출 금지
2. Ecto Changeset으로만 데이터 유효성 검증 — 수동 검증 로직 금지
3. 패턴 매칭 우선 — if/else 중첩 대신 함수 클로즈, with, case 사용
4. 파이프 연산자(|>) 적극 활용 — 3단계 이상 중첩 함수 호출 금지
5. 기존 코드 삭제 전 반드시 영향 범위 확인 후 보고
6. dialyzer 타입스펙(@spec) 주요 공개 함수에 반드시 작성

## 📖 스킬 매뉴얼 (자동 참조)
작업 영역에 따라 아래 매뉴얼을 반드시 확인하세요:
- LiveView / 컴포넌트 작업 → `.claude/skills/liveview/INDEX.md` 먼저 읽기
- 컨텍스트 / Ecto / 비즈니스 로직 작업 → `.claude/skills/backend/INDEX.md` 먼저 읽기
- 공통 규칙 → `.claude/skills/common/` 하위 파일 참고

## 🔄 리팩토링 전용 규칙
- 한 번에 하나의 컨텍스트(Context)만 리팩토링할 것
- 리팩토링 전 기존 동작을 테스트로 먼저 고정할 것 (ExUnit)
- 기존 컨텍스트의 공개 API(함수 시그니처)는 가능한 유지할 것
- 변경 범위가 3개 모듈 이상이면 반드시 계획서부터 작성할 것
- 마이그레이션은 절대 수정 금지 — 새 마이그레이션으로만 변경

## 📋 작업 문서 위치
- 현재 진행 중인 작업 계획: `.claude/tasks/current/`
- 완료된 작업 기록: `.claude/tasks/done/`
- 문서 템플릿: `.claude/templates/`
