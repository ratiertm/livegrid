# LiveView Grid

**Phoenix LiveView 기반 엔터프라이즈 그리드 라이브러리**

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
- **그리드 데모**: http://localhost:5001/demo
- **홈페이지**: http://localhost:5001

### 개발 환경

```bash
# 의존성 설치
mix deps.get

# 에셋 빌드
mix assets.setup

# 테스트 실행
mix test
```

## ✨ 현재 구현된 기능 (v0.1-alpha)

### 기본 기능
- [x] 테이블 렌더링 (LiveComponent 기반)
- [x] 컬럼 정렬 (오름차순/내림차순 토글, 정렬 아이콘 표시)
- [x] 행 선택 (체크박스, 전체 선택/해제)
- [x] 컬럼 고정 (Frozen Columns)
- [x] 컬럼 너비 조절 (드래그 리사이즈)

### 검색 & 필터
- [x] 글로벌 텍스트 검색 (디바운싱 300ms)
- [x] 컬럼별 필터 (텍스트/숫자 타입)
- [x] 필터 토글 버튼 (헤더 내장)
- [x] 필터 초기화 버튼

### 대용량 데이터
- [x] 가상 스크롤 (Virtual Scrolling) - 보이는 행만 렌더링
- [x] 무한 스크롤 (Infinite Scroll) - 스크롤 시 추가 로드
- [x] 데이터 건수 동적 변경 (50~10,000건)
- [x] 페이지네이션 (가상 스크롤 OFF 시)

### 편집 기능
- [x] 인라인 셀 편집 (더블클릭으로 진입)
- [x] 텍스트/숫자 편집기 (input)
- [x] 드롭다운 편집기 (select) - 고정 선택지 컬럼용
- [x] 행 추가 (맨 앞/맨 뒤)
- [x] 행 삭제 (선택 후 삭제, :deleted 마킹)
- [x] 변경 상태 추적 (N=신규, U=수정, D=삭제 배지)
- [x] 일괄 저장 / 되돌리기 (Save & Discard)

### 내보내기
- [x] CSV 다운로드 (전체 데이터)

## 🗺️ 개발 로드맵

### v0.2 - 데이터 검증 & 테마
- [ ] 셀 검증 (Validation) - 필수값, 숫자 범위, 형식 체크
- [ ] 검증 오류 UI (셀 하이라이트, 툴팁 메시지)
- [ ] 테마 시스템 (다크 모드, 커스텀 테마)

### v0.3 - 고급 데이터 처리
- [ ] 그룹핑 (Grouping)
- [ ] 피벗 테이블
- [ ] 트리 그리드

### v0.4 - 협업 & 실시간
- [ ] 실시간 동기화 (멀티 유저 동시 편집)
- [ ] 변경 이력 (Undo/Redo)
- [ ] 셀 잠금 (Lock)

### v1.0 - 엔터프라이즈
- [ ] Excel Export/Import
- [ ] 컬럼 드래그 순서 변경
- [ ] 컨텍스트 메뉴
- [ ] 키보드 내비게이션
- [ ] API 문서화 (HexDocs)

## 📁 프로젝트 구조

```
lib/
├── liveview_grid/              # 비즈니스 로직
│   ├── grid.ex                 # Grid 핵심 모듈 (데이터/상태 관리)
│   └── application.ex
└── liveview_grid_web/          # 웹 레이어
    ├── live/
    │   └── demo_live.ex        # 데모 페이지 (LiveView)
    ├── components/
    │   └── grid_component.ex   # Grid LiveComponent (렌더링/이벤트)
    └── router.ex

assets/
├── js/app.js                   # JS Hooks (VirtualScroll, CellEditor 등)
└── css/liveview_grid.css       # Grid 전용 스타일시트
```

## 🔧 기술 스택

- **Elixir** 1.16+ / **Phoenix** 1.7+
- **LiveView** 1.0+ - 실시간 UI (LiveComponent)
- **커스텀 CSS** - BEM 방식 (`lv-grid__*`)
- **JavaScript Hooks** - 가상 스크롤, 셀 편집, 컬럼 리사이즈

## 📝 사용 예시

```elixir
# LiveView에서 GridComponent 사용
<.live_component
  module={LiveviewGridWeb.GridComponent}
  id="users-grid"
  data={@users}
  columns={[
    %{field: :id, label: "ID", width: 80, sortable: true},
    %{field: :name, label: "이름", width: 150, sortable: true,
      filterable: true, filter_type: :text, editable: true},
    %{field: :age, label: "나이", width: 80, sortable: true,
      editable: true, editor_type: :number},
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

## 🎯 타겟 시장

### 1차 타겟
- 금융권 트레이딩 시스템
- ERP/MES 솔루션
- 데이터 분석 대시보드

### 2차 타겟
- SaaS 스타트업
- 공공기관 시스템
- 글로벌 시장 (영문 문서)

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
