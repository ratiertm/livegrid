# LiveView Grid

**Phoenix LiveView 기반 엔터프라이즈 그리드 라이브러리**

한국어 | [English](README.md)

## 🎯 프로젝트 목표

한국 최초 Elixir/Phoenix 기반 상용 그리드 솔루션 개발

### 차별화 포인트
- ⚡ **실시간 동기화**: WebSocket 기반 멀티 유저 동시 편집
- 🚀 **대용량 처리**: Elixir 동시성 활용 (100만 행 이상)
- 🎨 **서버 렌더링**: JavaScript 최소화, 빠른 초기 로딩
- 🔒 **안정성**: Erlang VM 기반 무중단 운영

## 🏃 빠른 시작

### 서버 실행

```bash
cd liveview_grid
mix phx.server
```

브라우저에서 접속:
- **대시보드**: http://localhost:5001 (/demo로 리다이렉트)
- **DBMS 데모**: http://localhost:5001/dbms-demo
- **API 데모**: http://localhost:5001/api-demo
- **고급 데모**: http://localhost:5001/advanced-demo (그룹핑/트리/피벗)
- **Grid 설정 데모**: http://localhost:5001/grid-config-demo
- **Grid Builder**: http://localhost:5001/builder
- **API 문서**: http://localhost:5001/api-docs

### 개발 환경

```bash
# 의존성 설치
mix deps.get

# 에셋 빌드
mix assets.setup

# 테스트 실행
mix test

# API 문서 생성
mix docs
open doc/index.html
```

## ✨ 구현된 기능 (v0.1 ~ v0.10)

### v0.1 - 핵심 그리드
- [x] 테이블 렌더링 (LiveComponent 기반)
- [x] 컬럼 정렬 (오름차순/내림차순 토글, 정렬 아이콘)
- [x] 행 선택 (체크박스, 전체 선택/해제)
- [x] 컬럼 고정 (Frozen Columns)
- [x] 컬럼 너비 조절 (드래그 핸들, 최소/최대 너비)
- [x] 컬럼 드래그 순서 변경
- [x] 글로벌 텍스트 검색 (300ms 디바운스)
- [x] 컬럼별 필터 (텍스트/숫자 타입)
- [x] 가상 스크롤 - 보이는 행만 렌더링
- [x] 무한 스크롤 - 스크롤 시 추가 로드
- [x] 페이지네이션 (가상 스크롤 OFF 시)
- [x] 인라인 셀 편집 (더블클릭으로 진입)
- [x] 텍스트/숫자/드롭다운 편집기
- [x] 행 추가 / 행 삭제 / 변경 추적 (N/U/D 배지)
- [x] 일괄 저장 & 되돌리기
- [x] CSV 다운로드

### v0.2 - 검증 & 테마
- [x] 셀 검증 - 필수값, 숫자 범위, 형식 체크
- [x] 검증 오류 UI (셀 하이라이트, 툴팁 메시지)
- [x] 다중 조건 고급 필터 (AND/OR 조합, 텍스트/숫자 연산자)
- [x] 테마 시스템 (다크 모드, 커스텀 테마, CSS 변수 커스터마이저)

### v0.3 - DBMS 연동
- [x] Ecto/Repo 통합 - DataSource behaviour 어댑터 패턴
- [x] SQLite 지원 (`ecto_sqlite3`)
- [x] 서버 사이드 정렬/필터/페이징 (SQL ORDER BY, WHERE, LIMIT/OFFSET)
- [x] DB에 변경사항 저장 (INSERT/UPDATE/DELETE, Ecto Changeset)

### v0.4 - REST API & 내보내기
- [x] REST DataSource 어댑터 (base_url, endpoint, headers 설정)
- [x] 비동기 데이터 조회, 로딩 상태 & 응답 시간 추적
- [x] API 기반 CRUD (POST 생성, PUT 수정, PATCH 부분 수정, DELETE 삭제)
- [x] 오프셋 기반 페이지네이션 (page/page_size)
- [x] 인증 헤더 지원 (Bearer 토큰, 커스텀 헤더)
- [x] 에러 처리 & 재시도 로직 (지수 백오프)
- [x] Mock REST API 서버 (MockApiController)
- [x] API Key 관리 & 인증 (RequireApiKey plug)
- [x] Excel (.xlsx) / CSV Export (Elixlsx 기반)
- [x] 커스텀 셀 렌더러 (badge, link, progress 내장 프리셋)
- [x] API 문서 페이지
- [x] 사이드바 네비게이션 대시보드 레이아웃

### v0.5 - 고급 데이터 처리
- [x] 그룹핑 (다중 필드 그룹핑 + expand/collapse + 집계 함수)
- [x] 피벗 테이블 (행/열 차원 + 동적 컬럼 + sum/avg/count/min/max)
- [x] 트리 그리드 (parent-child 계층 + 깊이별 들여쓰기 + expand/collapse)
- [x] 포맷터 (16종: number, currency, percent, date, datetime, time, boolean, mask, phone, email, url, uppercase, lowercase, capitalize, truncate, custom)
- [x] ExDoc API 문서화 (한국어/영어 이중 가이드)

### v0.6 - 편집 & 입력
- [x] 조건부 셀 스타일 (규칙 기반 배경색)
- [x] 다중 헤더 (그룹 컬럼 헤더, parent-child 구조)
- [x] 클립보드 Excel 붙여넣기 (탭 구분 데이터 paste 이벤트)
- [x] Excel/CSV Import (파일 업로드 + 컬럼 매핑)
- [x] 셀 툴팁 (오버플로우 감지 + title 속성)
- [x] Null 정렬 (컬럼별 nil 값 앞/뒤 배치 옵션)
- [x] 행번호 컬럼 (자동 증가 행 인덱스 표시)
- [x] Checkbox 컬럼 (boolean 값 클릭 즉시 토글)
- [x] 입력 제한 (정규식 기반 입력 필터링 + 최대 길이)
- [x] 행 단위 편집 모드 (행 전체 셀 동시 편집)
- [x] Undo/Redo (Ctrl+Z/Y 편집 히스토리, 최대 50건 스택)

### v0.7 - Grid 설정 & 아키텍처
- [x] Grid 설정 모달 (컬럼 표시/순서/너비, 고정 컬럼, 포맷터, 검증기)
- [x] Grid 설정 탭 (페이지 크기, 가상 스크롤, 테마, 행 높이)
- [x] Grid Builder (동적 그리드 생성, 컬럼 정의 UI)
- [x] Raw Table DataSource 어댑터 (스키마 없는 직접 DB 테이블 접근)
- [x] Schema Registry & Table Inspector (Grid Builder용 DB 인트로스펙션)
- [x] 실시간 협업 (Phoenix Presence + PubSub 브리지)
- [x] 키보드 네비게이션 (방향키, Tab, Enter, Home/End, F2, Ctrl+C/Z/Y)
- [x] 컨텍스트 메뉴 (우클릭: 복사, 삽입, 복제, 행 삭제)
- [x] 셀 범위 선택 (Shift+Click, 드래그, Shift+Arrow)
- [x] 셀 범위 요약 (count, sum, avg, min, max)
- [x] 날짜 필터 (date/datetime 연산자: eq, before, after, between)
- [x] JS Hook 모듈 분리 (10개 개별 모듈)
- [x] CSS 모듈 분리 (9개 개별 스타일시트)
- [x] GridComponent 리팩토링 (EventHandlers + RenderHelpers 추출)
- [x] ExDoc 문서화 (전체 공개 모듈 @doc/@spec)

### v0.8 - 행 강화 & UI 컴포넌트
- [x] Row Pinning - 행 상단/하단 고정 (`pin_row/3`, `unpin_row/2`)
- [x] Status Bar - 하단 통계 표시 (`show_status_bar`, `status_bar_data/1`)
- [x] Overlay 시스템 - loading/no_data/error 오버레이 (`set_overlay/2`, `clear_overlay/1`)
- [x] 컬럼 리사이즈 잠금 - 컬럼별 `resizable: false` 옵션
- [x] 셀 텍스트 선택 - `enable_cell_text_selection` 옵션

### v0.9 - 상태 관리 & 다국어
- [x] Grid 상태 저장/복원 - 전체 그리드 상태 영속화 (`get_state/1`, `restore_state/2`, `GridStatePersist` JS Hook)
- [x] Column 상태 저장/복원 - 컬럼 순서/너비/표시 영속화 (`get_column_state/1`, `apply_column_state/2`)
- [x] Value Getters/Setters - 계산 컬럼 (`value_getter`, `value_setter` 컬럼 옵션)
- [x] 행 애니메이션 - 행 진입/퇴장 CSS 애니메이션 (`animate_rows` 옵션)
- [x] 다국어 (i18n) - `Locale` 모듈, ko/en/ja 3개 언어, `grid_t/2` 헬퍼

### v0.10 - 엔터프라이즈 기능 (현재)
- [x] Side Bar - 사이드바 토글 (columns/filters 탭)
- [x] Batch Edit - 셀 범위 일괄 편집 (`batch_update_cells/3`)
- [x] Find & Highlight - 그리드 내 검색 + 매치 내비게이션 (`find_in_grid/2`, `find_next/prev`)
- [x] Full-Width Rows - 전체 너비 행 (`add_full_width_row/3`)
- [x] Large Text Editor - 긴 텍스트용 textarea 모달 편집
- [x] Radio Button Column - 라디오 버튼 단일 선택 렌더러
- [x] Empty Area Fill - 빈 영역 채우기 옵션
- [x] Column Hover Highlight - 컬럼 마우스 호버 하이라이트
- [x] Grid Builder JSON Export/Import - 그리드 설정 JSON 파일 저장/불러오기

## 📊 구현 현황

| 항목 | 수치 |
|------|------|
| 전체 기능 | 84개 |
| 구현 완료 | 84개 (100%) |
| 구현 버전 | v0.1 ~ v0.10 |
| 테스트 | 578개 |
| AG Grid 기능 커버리지 | ~91/200+ (완전 매칭 ~68, 부분 매칭 ~13) |

## 🗺️ 로드맵 (미구현)

### P0 - 접근성
- [ ] WCAG 2.1 AA - ARIA role/속성 (`role="grid"`, `aria-*`)

### P1 - 핵심 미구현 기능
- [ ] Column Menu (헤더 드롭다운: 정렬/필터/숨기기/고정)
- [ ] Set Filter (고유값 체크박스 필터)
- [ ] Cell Fill Handle (Excel 자동채움 드래그)
- [ ] Master-Detail (행 확장 디테일 그리드)
- [ ] Date Editor (날짜 컬럼용 datepicker)
- [ ] Printing (인쇄 버튼 + `print_data/1` API)

### P2 - 엔터프라이즈 확장
- [ ] Rich Select Editor (검색 가능 드롭다운)
- [ ] Sparklines (셀 내 미니 차트)
- [ ] Integrated Charts (데이터 기반 차트)
- [ ] 셀 수식/표현식
- [ ] 멀티 DB 드라이버 (PostgreSQL, MySQL, MSSQL, Oracle)
- [ ] GraphQL 데이터 소스
- [ ] RTL 지원 (우→좌 언어)
- [ ] 터치 디바이스 지원

## 📁 프로젝트 구조

```
lib/
├── liveview_grid/              # 비즈니스 로직
│   ├── grid.ex                 # Grid 핵심 모듈 (데이터/상태 관리)
│   ├── grid_definition.ex      # Grid 정의 구조체
│   ├── locale.ex               # 다국어 지원 (ko/en/ja) (v0.9)
│   ├── data_source.ex          # DataSource behaviour (어댑터 패턴)
│   ├── data_source/
│   │   ├── in_memory.ex        # InMemory 어댑터
│   │   ├── ecto.ex             # Ecto/DB 어댑터
│   │   ├── ecto/
│   │   │   └── query_builder.ex # SQL 쿼리 빌더
│   │   ├── rest.ex             # REST API 어댑터
│   │   └── raw_table.ex        # Raw Table 어댑터
│   ├── operations/
│   │   ├── sorting.ex          # 정렬 엔진
│   │   ├── filter.ex           # 필터 엔진 (기본+고급)
│   │   ├── pagination.ex       # 페이지네이션
│   │   ├── grouping.ex         # 다중 필드 그룹핑
│   │   ├── tree.ex             # 트리 그리드 계층
│   │   └── pivot.ex            # 피벗 테이블 변환
│   ├── renderers.ex            # 커스텀 셀 렌더러 프리셋
│   ├── formatter.ex            # 16종 데이터 포맷터
│   ├── export.ex               # Excel/CSV Export
│   ├── sample_data.ex          # 샘플 데이터 생성기
│   ├── schema_registry.ex      # Grid Builder용 스키마 레지스트리
│   ├── table_inspector.ex      # DB 테이블 인트로스펙션
│   ├── grid_presence.ex        # 실시간 협업 Phoenix Presence
│   └── pub_sub_bridge.ex       # 실시간 동기화 PubSub 브리지
└── liveview_grid_web/          # 웹 레이어
    ├── live/
    │   ├── demo_live.ex         # InMemory 데모
    │   ├── dbms_demo_live.ex    # DBMS 데모 (SQLite)
    │   ├── api_demo_live.ex     # REST API 데모
    │   ├── renderer_demo_live.ex # 렌더러 데모
    │   ├── advanced_demo_live.ex # 고급 기능 데모
    │   ├── builder_live.ex      # Grid Builder 페이지
    │   └── api_doc_live.ex      # API 문서
    ├── components/
    │   ├── grid_component.ex    # Grid LiveComponent (핵심)
    │   ├── grid_component/
    │   │   ├── event_handlers.ex  # 이벤트 핸들러 콜백
    │   │   └── render_helpers.ex  # 렌더 헬퍼 함수
    │   ├── grid_config/
    │   │   └── config_modal.ex    # Grid 설정 모달
    │   └── grid_builder/
    │       ├── builder_modal.ex   # Grid Builder 모달
    │       ├── builder_helpers.ex # Builder 헬퍼 함수
    │       └── builder_data_source.ex # Builder 데이터 소스 로직
    └── router.ex

assets/
├── js/
│   ├── app.js                     # JS 진입점 + Hook 레지스트리
│   └── hooks/                     # 모듈화된 JS Hooks (12개 모듈)
│       ├── virtual-scroll.js      # 가상 스크롤
│       ├── cell-editor.js         # 셀 편집
│       ├── cell-editable.js       # 셀 편집 가능 동작
│       ├── column-resize.js       # 컬럼 리사이즈
│       ├── column-reorder.js      # 컬럼 순서 변경
│       ├── grid-scroll.js         # 그리드 스크롤 동기화
│       ├── keyboard-nav.js        # 키보드 네비게이션
│       ├── row-edit-save.js       # 행 편집/저장
│       ├── file-import.js         # 파일 임포트
│       ├── config-sortable.js     # 설정 정렬 드래그
│       ├── grid-state-persist.js  # 그리드 상태 영속화 (v0.9)
│       └── json-import.js         # JSON 설정 임포트 (v0.10)
└── css/
    ├── liveview_grid.css          # CSS 진입점 (imports)
    └── grid/                      # 모듈화된 CSS (10개 파일)
        ├── variables.css          # CSS 변수 & 테마 (z-index 체계)
        ├── layout.css             # 그리드 레이아웃 + 렌더러
        ├── header.css             # 헤더 스타일
        ├── body.css               # 바디 & 셀 스타일
        ├── toolbar.css            # 툴바 스타일
        ├── interactions.css       # 인터랙션 (선택, 편집)
        ├── advanced.css           # 고급 기능 (그룹핑, 트리, 피벗)
        ├── config-modal.css       # 설정 모달 스타일
        ├── context-menu.css       # 컨텍스트 메뉴 스타일
        └── print.css              # 인쇄 미디어 스타일 (v0.10)
```

## 🔧 기술 스택

- **Elixir** 1.16+ / **Phoenix** 1.7+
- **LiveView** 1.0+ - 실시간 UI (LiveComponent)
- **Ecto** + **SQLite** (`ecto_sqlite3`) - 데이터베이스 연동
- **Elixlsx** - Excel Export
- **커스텀 CSS** - BEM 방식 (`lv-grid__*`)
- **JavaScript Hooks** - 가상 스크롤, 셀 편집, 컬럼 리사이즈

## 📝 사용 예시

### 기본 그리드

```elixir
# LiveView에서 GridComponent 사용
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="users-grid"
  data={@users}
  columns={[
    %{field: :id, label: "ID", width: 80, sortable: true},
    %{field: :name, label: "이름", width: 150, sortable: true,
      filterable: true, filter_type: :text, editable: true,
      validators: [{:required, "필수 입력"}]},
    %{field: :salary, label: "급여", width: 120, sortable: true,
      formatter: :currency, align: :right},
    %{field: :city, label: "도시", width: 120, sortable: true,
      editable: true, editor_type: :select,
      editor_options: [{"서울", "서울"}, {"부산", "부산"}, {"대구", "대구"}]}
  ]}
  options={%{
    page_size: 20,
    virtual_scroll: true,
    row_height: 40,
    frozen_columns: 1
  }}
/>
```

### DataSource 연동

```elixir
# Ecto (DB) 연동
grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.Ecto,
    %{repo: MyApp.Repo, query: from(u in User)}}
)

# REST API 연동
grid = Grid.new(
  columns: columns,
  data_source: {LiveViewGrid.DataSource.Rest,
    %{base_url: "https://api.example.com/users"}}
)
```

## 📖 API 문서

- **API 스펙**: [한국어](docs/API_SPEC.ko.md) | [English](docs/API_SPEC.md)
- **라이브 API 문서**: http://localhost:5001/api-docs (서버 실행 시)

API는 6개 카테고리, 26개 엔드포인트를 제공합니다:
1. **Grid 세팅** - 설정, 컬럼, 옵션
2. **데이터 CRUD** - 단건/배치 생성, 조회, 수정, 삭제
3. **테마** - 내장 테마, 커스텀 테마 생성
4. **정렬 & 페이지네이션** - 정렬, 페이징, 가상 스크롤 설정
5. **DBMS 연결** - 데이터베이스 어댑터 설정
6. **렌더러** - 내장 및 커스텀 셀 렌더러

## 🎯 타겟 시장

### 1차 타겟
- 금융권 트레이딩 시스템
- ERP/MES 솔루션
- 데이터 분석 대시보드

### 2차 타겟
- SaaS 스타트업
- 공공기관 시스템
- 글로벌 시장

## 💰 라이선스 전략

- **Community Edition**: MIT (무료, 기본 기능)
- **Professional**: 상용 라이선스 ($999/년, 고급 기능)
- **Enterprise**: 맞춤형 ($협의, 협업/커스터마이징)

## 📚 참고 자료

이 프로젝트는 [Toast UI Grid](https://github.com/nhn/tui.grid) (MIT License)의 **아이디어를 참고**하여 Phoenix LiveView로 독자 개발되었습니다.

- Toast UI Grid는 학습 목적으로만 참조
- 모든 코드는 Elixir/Phoenix 네이티브로 새로 작성
- 자세한 내용: [DEVELOPMENT.md](./DEVELOPMENT.md)

## 📞 문의

프로젝트 관련 문의: [추후 추가]

---

**Made with ❤️ using Phoenix LiveView**

*Inspired by Toast UI Grid • Built for Elixir/Phoenix community*
