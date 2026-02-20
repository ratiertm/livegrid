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
- **그리드 데모**: http://localhost:4000/grid
- **홈페이지**: http://localhost:4000

### 개발 환경

```bash
# 의존성 설치
mix deps.get

# 에셋 빌드
mix assets.setup

# 테스트 실행
mix test
```

## ✨ 현재 구현된 기능 (v0.1)

### 기본 기능
- [x] 테이블 렌더링
- [x] 컬럼 정렬 (오름차순/내림차순)
- [x] 행 선택 (체크박스)
- [x] 반응형 디자인 (Tailwind CSS)

### 데이터 표시
- [x] 커스텀 포맷팅 (숫자, 날짜 등)
- [x] 조건부 스타일링 (색상 표시)
- [x] 컬럼 정렬

## 🗺️ 개발 로드맵

### v0.2 - 필터링 & 검색 (1주)
- [ ] 텍스트 검색
- [ ] 컬럼별 필터
- [ ] 숫자 범위 필터

### v0.3 - 대용량 데이터 (2주)
- [ ] 가상 스크롤 (Virtual Scrolling)
- [ ] 페이징
- [ ] 서버 사이드 정렬/필터

### v0.4 - 편집 기능 (2주)
- [ ] 인라인 셀 편집
- [ ] 행 추가/삭제
- [ ] 변경 사항 저장

### v0.5 - 고급 기능 (3주)
- [ ] 컬럼 고정 (Freeze columns)
- [ ] 그룹핑
- [ ] 피벗 테이블

### v1.0 - 엔터프라이즈 (4주)
- [ ] 실시간 협업 (멀티 유저)
- [ ] Excel/CSV Export
- [ ] 테마 커스터마이징
- [ ] API 문서화

## 📁 프로젝트 구조

```
lib/
├── liveview_grid/          # 비즈니스 로직
│   └── application.ex
└── liveview_grid_web/      # 웹 레이어
    ├── live/
    │   ├── grid_live.ex    # 그리드 LiveView 컨트롤러
    │   └── grid_live.html.heex  # 그리드 템플릿
    ├── components/
    │   └── core_components.ex
    └── router.ex
```

## 🔧 기술 스택

- **Phoenix** 1.7+ - 웹 프레임워크
- **LiveView** - 실시간 UI 업데이트
- **Tailwind CSS** - 스타일링
- **Elixir** 1.16+ - 백엔드 언어

## 📝 사용 예시

```elixir
# 데이터 준비
data = [
  %{id: 1, name: "Apple", price: 150.25},
  %{id: 2, name: "Microsoft", price: 380.50},
]

# 컬럼 정의
columns = [
  %{key: :id, label: "ID", sortable: true},
  %{key: :name, label: "회사명", sortable: true},
  %{key: :price, label: "가격", align: "right"},
]

# LiveView에서 사용
assign(socket, data: data, columns: columns)
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
