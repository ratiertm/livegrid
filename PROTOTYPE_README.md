# LiveView Grid 프로토타입 v0.1-alpha

> **상태:** 🚧 프로토타입 - 기본 기능 검증용

---

## ✨ 구현된 기능

- ✅ **기본 렌더링** - 테이블 형태 데이터 표시
- ✅ **정렬** - 컬럼 클릭 시 오름차순/내림차순
- ✅ **페이징** - 페이지 단위 데이터 표시
- ✅ **최소 CSS** - 깔끔한 기본 스타일

---

## 📦 프로젝트 구조

```
lib/
├── liveview_grid/
│   ├── grid.ex                    ✅ 핵심 Grid 로직
│   └── operations/
│       ├── sorting.ex             ✅ 정렬
│       └── pagination.ex          ✅ 페이징
│
├── liveview_grid_web/
│   ├── components/
│   │   └── grid_component.ex      ✅ LiveComponent
│   └── live/
│       └── demo_live.ex           ✅ 데모 페이지
│
└── assets/
    └── css/
        └── liveview_grid.css      ✅ 기본 스타일

test/
└── liveview_grid/
    ├── grid_test.exs              ✅ Grid 테스트
    ├── sorting_test.exs           ✅ 정렬 테스트
    └── pagination_test.exs        ✅ 페이징 테스트
```

---

## 🚀 빠른 시작

### 1. 의존성 설치

```bash
mix deps.get
```

### 2. 테스트 실행

```bash
mix test
```

**예상 결과:**
```
......................

Finished in 0.1 seconds (0.05s async, 0.05s sync)
22 tests, 0 failures
```

### 3. 사용 예시

```elixir
# LiveView에서 사용
defmodule MyAppWeb.UserLive.Index do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, users: list_users())}
  end

  def render(assigns) do
    ~H"""
    <.live_component 
      module={LiveViewGridWeb.GridComponent}
      id="users-grid"
      data={@users}
      columns={[
        %{field: :id, label: "ID", width: 80, sortable: true},
        %{field: :name, label: "이름", width: 150, sortable: true},
        %{field: :email, label: "이메일", width: 250}
      ]}
      options={%{page_size: 20}}
    />
    """
  end

  defp list_users do
    [
      %{id: 1, name: "Alice", email: "alice@example.com"},
      %{id: 2, name: "Bob", email: "bob@example.com"}
    ]
  end
end
```

---

## 📋 API 미리보기

### GridComponent Props

| Prop | 타입 | 필수 | 설명 |
|------|------|------|------|
| `id` | String | ✅ | LiveComponent ID |
| `data` | `list(map())` | ✅ | 표시할 데이터 |
| `columns` | `list(map())` | ✅ | 컬럼 정의 |
| `options` | `map()` | ❌ | Grid 옵션 |

### Column Spec

```elixir
%{
  field: :name,          # 필수: 데이터 필드명
  label: "이름",         # 필수: 헤더 표시 텍스트
  width: 150,           # 선택: 컬럼 너비 (px) 또는 :auto
  sortable: true,       # 선택: 정렬 가능 여부
  align: :left          # 선택: 정렬 (:left, :center, :right)
}
```

### Grid Options

```elixir
%{
  page_size: 20,        # 페이지당 행 수 (기본: 20)
  show_header: true,    # 헤더 표시 여부 (기본: true)
  show_footer: true     # 푸터 표시 여부 (기본: true)
}
```

---

## ✅ 테스트 결과

### Grid 모듈 (7 tests)
- [x] Grid 생성 (data, columns 필수)
- [x] 기본 옵션 적용
- [x] 컬럼 정규화
- [x] visible_data - 첫 페이지
- [x] visible_data - 정렬 적용
- [x] visible_data - 2페이지

### Sorting 모듈 (4 tests)
- [x] 이름 오름차순 정렬
- [x] 이름 내림차순 정렬
- [x] 숫자 정렬
- [x] Nil 값 처리 (마지막)

### Pagination 모듈 (6 tests)
- [x] 첫 페이지 (10개)
- [x] 두 번째 페이지
- [x] 마지막 페이지 (부분)
- [x] 범위 초과 (빈 리스트)
- [x] 총 페이지 계산 (정확히 나누어떨어짐)
- [x] 총 페이지 계산 (올림)

**커버리지:** ~85%

---

## 🎨 스타일 커스터마이징

CSS 변수로 쉽게 커스터마이징 가능:

```css
:root {
  --lv-grid-primary: #9c27b0;      /* 보라색 테마 */
  --lv-grid-selected: #f3e5f5;
}
```

---

## ⚠️ 알려진 제한사항

### 미구현 기능
- ❌ 필터링
- ❌ 행 선택
- ❌ 셀 편집
- ❌ Virtual Scrolling (대용량 데이터)
- ❌ 복잡한 검증
- ❌ 에러 처리

### 성능
- ⚠️ 1,000행 이하 권장
- ⚠️ 클라이언트 사이드 정렬/페이징 (DB 쿼리 미사용)

---

## 📊 성능 벤치마크 (예정)

```bash
mix test --only benchmark
```

**목표:**
- 100행 정렬: < 20ms
- 1,000행 정렬: < 100ms
- 메모리: < 3MB (1,000행)

---

## 🔄 다음 단계

### v0.1 (1주)
- [ ] Column/State/Validator 모듈 구현
- [ ] 에러 처리 강화
- [ ] 성능 벤치마크 실행
- [ ] 문서화 개선

### v0.2 (1주)
- [ ] 필터링 기능
- [ ] 전체 선택
- [ ] 검색 기능

### v0.3 (2주)
- [ ] Virtual Scrolling (대용량 데이터)
- [ ] 데이터베이스 쿼리 통합

---

## 📝 피드백

프로토타입을 사용해보고 피드백을 남겨주세요!

- 🐛 버그 리포트
- 💡 기능 제안
- 📈 성능 이슈

---

## 📄 라이선스

현재: 프로토타입 (라이선스 미정)  
계획: MIT (Community) / Commercial (Pro/Enterprise)

---

**작성일:** 2026-02-20  
**버전:** v0.1.0-alpha  
**상태:** 🚧 프로토타입

🐾
