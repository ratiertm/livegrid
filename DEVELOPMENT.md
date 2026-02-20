# LiveView Grid 개발 가이드

## 📚 참고 자료 (Reference)

### Toast UI Grid (MIT License)

**위치:** `/reference/toast-ui-grid/`

Toast UI Grid는 NHN에서 만든 MIT 라이선스 오픈소스 그리드입니다.  
우리는 이 코드를 **아이디어 참고용**으로만 사용합니다.

#### ✅ 합법적 참고 범위

**OK - 아이디어 차용:**
- 아키텍처 패턴 (Store, Renderer, Dispatcher)
- 기능 목록 (어떤 기능이 필요한지)
- UI/UX 컨셉
- 성능 최적화 전략

**NG - 직접 복사 금지:**
- 소스 코드 그대로 복붙
- 함수 이름/변수명 동일하게 복제
- 알고리즘 그대로 이식

#### 📂 Toast UI Grid 구조 분석

```
packages/toast-ui.grid/src/
├── grid.tsx              # 메인 그리드 컴포넌트 (82KB!)
├── store/                # 상태 관리 (17개 모듈)
├── view/                 # 렌더링 레이어 (41개 뷰)
├── dispatch/             # 이벤트 처리 (22개 디스패처)
├── dataSource/           # 데이터 관리
├── editor/               # 셀 편집기
├── renderer/             # 커스텀 렌더러
├── query/                # 데이터 쿼리
├── helper/               # 유틸리티
└── theme/                # 테마 시스템
```

**핵심 인사이트:**
- **Store 중심 아키텍처** → LiveView의 `assign`과 유사
- **View/Dispatch 분리** → LiveView는 템플릿/이벤트 핸들러로 대응
- **대용량 최적화** → 가상 스크롤 구현 방식 참고

---

## 🏗️ LiveView Grid 아키텍처 (독자 설계)

### Phoenix LiveView 기반 재설계

```
lib/liveview_grid_web/live/
├── grid_live.ex          # 메인 LiveView (Elixir)
├── grid_live.html.heex   # 템플릿 (HEEx)
└── components/
    ├── grid_header.ex    # 헤더 컴포넌트
    ├── grid_row.ex       # 행 컴포넌트
    └── grid_cell.ex      # 셀 컴포넌트

lib/liveview_grid/
├── grid/
│   ├── data_source.ex    # 데이터 소스 추상화
│   ├── virtual_scroll.ex # 가상 스크롤 로직
│   ├── sorter.ex         # 정렬 엔진
│   ├── filter.ex         # 필터 엔진
│   └── formatter.ex      # 셀 포맷터
└── grid.ex               # 공개 API
```

### 차이점 (Toast UI vs LiveView Grid)

| 기능 | Toast UI Grid | LiveView Grid |
|------|---------------|---------------|
| 상태 관리 | Redux-like Store | LiveView assigns |
| 렌더링 | Virtual DOM (Preact) | 서버 사이드 HTML |
| 이벤트 | JavaScript 리스너 | Phoenix PubSub |
| 동시성 | 단일 스레드 | Erlang 프로세스 |
| 대용량 | 클라이언트 메모리 | 서버 스트리밍 |

---

## 🎯 개발 원칙

### 1. 독자적 구현
Toast UI Grid를 **참고만** 하고, 코드는 처음부터 작성합니다.

### 2. LiveView 네이티브
Phoenix/Elixir의 강점을 살린 설계:
- WebSocket 기반 실시간 업데이트
- OTP로 대용량 데이터 처리
- GenServer로 상태 관리

### 3. 성능 우선
- 가상 스크롤 (100만 행)
- Lazy loading
- Incremental rendering

### 4. 개발자 친화적
```elixir
# 이런 간결한 API 제공
Grid.new(data, columns: columns)
  |> Grid.sort_by(:price, :desc)
  |> Grid.filter(:ticker, "AAPL")
  |> Grid.paginate(page: 1, per_page: 50)
```

---

## 📖 참고 학습 가이드

### Toast UI Grid에서 배울 점

1. **가상 스크롤 구현** (`view/bodyArea.tsx`)
   - 뷰포트 계산 로직
   - 렌더링 최적화 전략
   
2. **정렬/필터 알고리즘** (`store/data.ts`)
   - 다중 컬럼 정렬
   - 복합 필터 조건

3. **셀 편집기 패턴** (`editor/`)
   - 타입별 에디터 (텍스트, 숫자, 날짜)
   - 검증 로직

4. **테마 시스템** (`theme/`)
   - CSS 변수 활용
   - 런타임 테마 전환

### 읽어볼 파일 (우선순위)

1. ⭐ `grid.tsx` - 전체 구조 파악
2. ⭐ `store/data.ts` - 데이터 관리
3. `view/bodyArea.tsx` - 가상 스크롤
4. `dispatch/sort.ts` - 정렬 로직
5. `helper/pagination.ts` - 페이징

---

## 🚀 다음 단계

### v0.2 개발 계획

```elixir
# lib/liveview_grid/grid/virtual_scroll.ex
defmodule LiveviewGrid.Grid.VirtualScroll do
  @doc """
  Toast UI Grid 아이디어 참고:
  - 뷰포트 높이 계산
  - 렌더링 범위 결정
  - 스크롤 오프셋 처리
  
  구현은 Elixir 네이티브로 새로 작성
  """
  def calculate_viewport(total_rows, row_height, viewport_height) do
    # 독자적 구현
  end
end
```

---

## ⚖️ 라이선스 준수

### MIT 라이선스 의무사항

Toast UI Grid를 참고했으므로:

1. **저작권 표시**
   - README.md에 명시
   - 소스 코드 주석에 표기

2. **라이선스 텍스트**
   - LICENSE 파일에 Toast UI Grid MIT 라이선스 포함

3. **독립성 유지**
   - 우리 코드는 독자적 저작물
   - Toast UI 코드 직접 사용 안 함

### 우리 라이선스

- Community Edition: MIT (Toast UI 영향 없음)
- Professional/Enterprise: 상용 (우리가 작성한 코드)

---

**참고:**  
Toast UI Grid는 학습/아이디어 차용 목적이며,  
LiveView Grid는 Phoenix 생태계를 위한 독자적 구현입니다.
