# Claude AI 기반 LiveView Grid 개발 가이드

> **프로젝트**: LiveView Grid - Phoenix LiveView 기반 상용 그리드 컴포넌트  
> **AI 파트너**: Claude (Anthropic)  
> **작성일**: 2026-02-20

---

## 📋 목차

1. [개발 방법론](#개발-방법론)
2. [SubAgent 패턴](#subagent-패턴)
3. [BKIT PDCA 사이클](#bkit-pdca-사이클)
4. [Sequential Think](#sequential-think)
5. [실전 적용 예시](#실전-적용-예시)
6. [Claude 프롬프트 템플릿](#claude-프롬프트-템플릿)

---

## 🎯 개발 방법론

LiveView Grid 프로젝트는 **3가지 핵심 방법론**을 조합하여 개발합니다:

| 방법론 | 역할 | 적용 시점 |
|--------|------|----------|
| **SubAgent** | 역할별 전문가 시뮬레이션 | 설계/구현/검증 단계 |
| **BKIT PDCA** | 반복적 개선 사이클 | 전체 개발 프로세스 |
| **Sequential Think** | 단계별 논리적 사고 | 복잡한 문제 해결 |

---

## 🤖 SubAgent 패턴

### 정의

**SubAgent**는 Claude가 여러 전문가 역할을 순차적으로 수행하며 프로젝트를 다각도로 분석하는 패턴입니다.

### 역할 정의

#### 1. 아키텍트 (Architect)
**책임:** 시스템 전체 구조 설계

**질문 예시:**
- "Elixir + Phoenix LiveView 환경에서 최적의 그리드 아키텍처는?"
- "WebSocket 기반 실시간 동기화 vs. HTTP Polling 중 어떤 방식이 적합한가?"
- "대용량 데이터 처리를 위한 Virtual Scrolling 구조는?"

**출력 형식:**
```markdown
## 아키텍처 제안

### 전체 구조
- LiveView assigns (서버 상태)
- WebSocket 양방향 통신
- CSS Grid 기반 레이아웃

### 데이터 흐름
Client (HEEx) → Event → LiveView → Elixir Logic → Assigns → Re-render

### 주요 의사결정
1. **상태 관리**: LiveView assigns (서버 사이드)
2. **렌더링**: HEEx 템플릿 (동적 바인딩)
3. **동기화**: WebSocket (Phoenix Channels)
```

---

#### 2. 설계자 (Designer)
**책임:** 모듈 설계 및 API 인터페이스 정의

**질문 예시:**
- "Grid 컴포넌트의 Public API는 어떻게 설계해야 하는가?"
- "컬럼 정의 구조는 어떤 형식이 직관적인가?"
- "필터링/정렬 기능의 인터페이스는?"

**출력 형식:**
```elixir
# API 설계 예시
defmodule LiveViewGrid do
  @moduledoc """
  Phoenix LiveView 기반 Grid 컴포넌트
  """

  @doc """
  Grid 초기화

  ## Examples
      grid = LiveViewGrid.new(
        data: users,
        columns: [
          %{field: :name, label: "이름", sortable: true},
          %{field: :email, label: "이메일", width: 200}
        ],
        options: %{
          page_size: 20,
          frozen_columns: 1
        }
      )
  """
  def new(opts), do: ...
end
```

---

#### 3. 개발자 (Developer)
**책임:** 실제 코드 구현

**질문 예시:**
- "정렬 기능을 Elixir Enum으로 어떻게 구현하는가?"
- "무한 스크롤을 LiveView에서 구현하는 방법은?"
- "셀 편집 이벤트 처리 로직은?"

**출력 형식:**
```elixir
# 구현 예시
def handle_event("sort_column", %{"field" => field}, socket) do
  sorted_data = 
    socket.assigns.data
    |> Enum.sort_by(&Map.get(&1, String.to_atom(field)))
  
  {:noreply, assign(socket, data: sorted_data, sort_field: field)}
end
```

---

#### 4. QA (Quality Assurance)
**책임:** 품질 검증 및 테스트 시나리오 작성

**질문 예시:**
- "정렬 기능의 엣지 케이스는 무엇인가?"
- "동시에 10,000명이 Grid를 사용할 때 문제는?"
- "브라우저 호환성 테스트 항목은?"

**출력 형식:**
```markdown
## 테스트 체크리스트

### 기능 테스트
- [ ] 정렬: 오름차순/내림차순 토글
- [ ] 정렬: null 값 처리 (마지막 표시)
- [ ] 정렬: 숫자/문자열/날짜 타입별 동작

### 성능 테스트
- [ ] 1,000행 렌더링 시간 < 100ms
- [ ] 스크롤 부드러움 (60fps)
- [ ] 메모리 누수 없음

### 보안 테스트
- [ ] XSS 방지 (HTML 이스케이프)
- [ ] CSRF 토큰 검증
```

---

#### 5. 테스터 (Tester)
**책임:** 실제 테스트 실행 및 버그 리포트

**질문 예시:**
- "현재 구현에서 발견된 버그는?"
- "사용자 시나리오별 동작 검증 결과는?"

**출력 형식:**
```markdown
## 테스트 결과 리포트

### 🐛 발견된 버그
1. **정렬 토글 미동작**
   - 재현: 컬럼 헤더 2회 클릭 시 정렬 안 됨
   - 원인: `sort_direction` 상태 초기화 누락
   - 수정: `assign(socket, sort_direction: "asc")`

### ✅ 통과한 테스트
- 기본 렌더링
- 행 선택
- 페이지네이션
```

---

### SubAgent 워크플로우

```
1. Architect → 전체 구조 설계
2. Designer → API 및 모듈 설계
3. Developer → 구현
4. QA → 테스트 시나리오 작성
5. Tester → 실제 테스트 및 버그 리포트
6. (반복) Developer → 버그 수정
```

---

## 🔄 BKIT PDCA 사이클

### 정의

**BKIT PDCA**는 Plan-Do-Check-Act 사이클을 기반으로 한 반복적 개선 방법론입니다.

### 사이클 구조

```
┌─────────────┐
│  Plan (계획)  │  ← 목표 설정, 요구사항 분석
└──────┬──────┘
       ↓
┌─────────────┐
│  Do (실행)    │  ← 실제 개발, 구현
└──────┬──────┘
       ↓
┌─────────────┐
│ Check (검증) │  ← 테스트, 피드백 수집
└──────┬──────┘
       ↓
┌─────────────┐
│  Act (개선)  │  ← 문제 해결, 최적화
└──────┬──────┘
       ↓
   (다음 사이클)
```

### LiveView Grid 적용 예시

#### Phase 1: 기본 렌더링

**Plan (계획)**
- 목표: 정적 데이터를 테이블로 렌더링
- 요구사항: 헤더 + 바디 구조, 기본 스타일

**Do (실행)**
```elixir
def render(assigns) do
  ~H"""
  <table>
    <thead>
      <tr>
        <%= for col <- @columns do %>
          <th><%= col.label %></th>
        <% end %>
      </tr>
    </thead>
    <tbody>
      <%= for row <- @data do %>
        <tr>
          <%= for col <- @columns do %>
            <td><%= Map.get(row, col.field) %></td>
          <% end %>
        </tr>
      <% end %>
    </tbody>
  </table>
  """
end
```

**Check (검증)**
- ✅ 렌더링 성공
- ⚠️ 스타일 없음
- ❌ 성능 문제 (1000행 이상 시 느림)

**Act (개선)**
- 다음 사이클 목표: CSS 스타일 추가, Virtual Scrolling 도입

---

#### Phase 2: 정렬 기능

**Plan (계획)**
- 목표: 컬럼 헤더 클릭 시 정렬
- 요구사항: 오름차순/내림차순 토글

**Do (실행)**
```elixir
def handle_event("sort", %{"field" => field}, socket) do
  direction = toggle_direction(socket.assigns.sort_direction)
  sorted = Enum.sort_by(socket.assigns.data, &Map.get(&1, String.to_atom(field)))
  sorted = if direction == "desc", do: Enum.reverse(sorted), else: sorted
  
  {:noreply, assign(socket, data: sorted, sort_field: field, sort_direction: direction)}
end
```

**Check (검증)**
- ✅ 정렬 동작
- ⚠️ 헤더에 정렬 방향 표시 없음
- ✅ 성능 양호

**Act (개선)**
- 다음 사이클: 정렬 아이콘 추가 (▲/▼)

---

### PDCA 반복 규칙

1. **작은 단위로 반복** (1주일 이하 사이클)
2. **Check 단계에서 반드시 측정 가능한 지표 사용**
3. **Act 단계에서 명확한 다음 목표 설정**

---

## 🧠 Sequential Think

### 정의

**Sequential Think**는 복잡한 문제를 **단계별로 분해**하여 논리적으로 해결하는 사고 패턴입니다.

### 적용 방법

#### Step 1: 문제 정의
```
❓ 문제: Virtual Scrolling을 LiveView에서 어떻게 구현하는가?
```

#### Step 2: 전제 조건 나열
```
✓ LiveView는 서버 사이드 렌더링
✓ 클라이언트는 스크롤 이벤트만 감지
✓ 전체 데이터는 서버에 존재
```

#### Step 3: 가능한 접근법 나열
```
1. 클라이언트 스크롤 이벤트 → 서버로 전송 → 부분 데이터 렌더링
2. 초기 로드 시 전체 데이터 전송 → 클라이언트에서 JavaScript로 처리
3. Hybrid: 첫 100행만 렌더링 → 스크롤 시 추가 로드
```

#### Step 4: 각 접근법 평가
```
접근법 1:
  장점: 서버 메모리 효율적
  단점: 네트워크 왕복 시간 (100~200ms)

접근법 2:
  장점: 빠른 스크롤
  단점: LiveView 철학과 맞지 않음 (서버 중심)

접근법 3:
  장점: 균형잡힌 성능
  단점: 구현 복잡도 증가
```

#### Step 5: 최적 솔루션 선택
```
선택: 접근법 3 (Hybrid)

이유:
1. LiveView의 강점(서버 로직) 유지
2. 사용자 경험 개선 (빠른 초기 렌더링)
3. 확장 가능 (나중에 캐싱 추가 가능)
```

#### Step 6: 구현 계획
```
1. 초기 렌더링: 0~99 행
2. 스크롤 이벤트 감지 (JavaScript Hook)
3. 스크롤 80% 도달 시 서버에 다음 100행 요청
4. 서버 응답 → assigns 업데이트 → 자동 렌더링
```

---

### Sequential Think 템플릿

```markdown
## 문제
[명확하고 구체적으로 기술]

## 전제 조건
- [ ] 조건 1
- [ ] 조건 2

## 접근법
### 옵션 A
- 장점:
- 단점:

### 옵션 B
- 장점:
- 단점:

## 결정
**선택:** [옵션 X]

**이유:**
1. ...
2. ...

## 실행 계획
1. Step 1
2. Step 2
```

---

## 💡 실전 적용 예시

### 예제: "컬럼 필터링 기능 구현"

#### 1단계: SubAgent - Architect

**프롬프트:**
```
너는 Elixir/Phoenix LiveView 전문 아키텍트다.
LiveView Grid에 컬럼별 필터링 기능을 추가하려고 한다.
전체 아키텍처를 설계하라.

제약 조건:
- 서버 사이드 필터링 (Elixir Enum 사용)
- 실시간 업데이트 (WebSocket)
- 다중 컬럼 필터 지원
```

**Claude 응답 예상:**
```markdown
## 아키텍처 설계

### 데이터 구조
```elixir
assigns = %{
  data: [%{name: "Alice", age: 30}, ...],
  filters: %{
    name: "Ali",
    age: "> 25"
  }
}
```

### 필터 적용 로직
1. 사용자 입력 → `handle_event("filter", ...)`
2. assigns.filters 업데이트
3. `apply_filters(data, filters)` → 필터링된 데이터
4. 자동 리렌더링
```

---

#### 2단계: SubAgent - Designer

**프롬프트:**
```
컬럼 필터링 API를 설계하라.
개발자가 쉽게 사용할 수 있어야 한다.
```

**Claude 응답 예상:**
```elixir
# 사용 예시
columns = [
  %{
    field: :name,
    label: "이름",
    filter: %{
      type: :text,
      placeholder: "이름 검색..."
    }
  },
  %{
    field: :age,
    label: "나이",
    filter: %{
      type: :number,
      operators: [:gt, :lt, :eq]
    }
  }
]
```

---

#### 3단계: PDCA Cycle 1

**Plan:**
- 텍스트 필터만 구현 (숫자 필터는 다음 사이클)
- 대소문자 구분 없음

**Do:**
```elixir
def apply_filters(data, %{name: filter_text}) do
  Enum.filter(data, fn row ->
    String.contains?(
      String.downcase(row.name),
      String.downcase(filter_text)
    )
  end)
end
```

**Check:**
- ✅ 기본 필터링 동작
- ❌ 빈 문자열 처리 안 됨
- ⚠️ 성능 (10,000행에서 느림)

**Act:**
- 빈 문자열 체크 추가
- 다음 사이클: 성능 최적화 (인덱싱)

---

#### 4단계: Sequential Think

**문제:** "10,000행에서 필터링이 느리다"

**전제:**
- LiveView는 매 필터링마다 전체 리렌더링
- Elixir Enum.filter는 O(n)

**옵션:**
1. 클라이언트 사이드 필터링 (JavaScript)
2. 데이터베이스 쿼리로 이동
3. 디바운싱 (300ms 대기 후 필터링)
4. 가상 스크롤과 결합 (보이는 부분만 필터링)

**평가:**
- 옵션 1: LiveView 철학 위배 ❌
- 옵션 2: 최상의 성능, 하지만 데이터 소스 제한 ⚠️
- 옵션 3: 구현 간단, UX 개선 ✅
- 옵션 4: 복잡하지만 최적 ✅✅

**결정:** 옵션 3 (단기) + 옵션 4 (장기)

**실행:**
```javascript
// JavaScript Hook
let filterTimeout;
this.el.addEventListener("input", (e) => {
  clearTimeout(filterTimeout);
  filterTimeout = setTimeout(() => {
    this.pushEvent("filter", {value: e.target.value});
  }, 300);
});
```

---

#### 5단계: SubAgent - QA/Tester

**프롬프트:**
```
컬럼 필터링 기능의 테스트 시나리오를 작성하고 실제 테스트하라.
```

**Claude 응답:**
```markdown
## 테스트 시나리오

### 기능 테스트
1. 빈 필터 → 전체 데이터 표시
2. "Ali" 검색 → "Alice", "Alison" 표시
3. 대소문자 무관 → "ali" = "ALI"
4. 특수문자 처리 → "O'Brien" 검색 가능

### 성능 테스트
1. 10,000행 필터링 < 500ms
2. 타이핑 중 디바운싱 동작

### 버그 리포트
- [ ] 필터 초기화 버튼 없음
- [ ] 여러 필터 동시 적용 시 AND 조건 미구현
```

---

## 📝 Claude 프롬프트 템플릿

### 템플릿 1: SubAgent 역할 부여

```
# 역할 설정
너는 [역할명]이다. (예: Phoenix LiveView 전문 개발자)

# 목표
[구체적 목표]를 달성하라.

# 제약 조건
- 조건 1
- 조건 2

# 출력 형식
[Markdown/Code/JSON]
```

---

### 템플릿 2: PDCA 사이클 진행

```
현재 Phase: [Plan/Do/Check/Act]

# Plan 단계일 때
목표: [이번 사이클 목표]
요구사항:
- [ ] 기능 1
- [ ] 기능 2

# Do 단계일 때
위 계획을 Elixir/Phoenix LiveView로 구현하라.

# Check 단계일 때
구현된 코드를 검증하라. 다음 항목을 확인:
- 기능 동작 여부
- 성능
- 버그

# Act 단계일 때
발견된 문제를 분석하고 다음 사이클 계획을 세워라.
```

---

### 템플릿 3: Sequential Think 실행

```
# 문제
[해결할 문제]

# 단계별 분석
1. 전제 조건 나열
2. 가능한 접근법 3가지 이상 제시
3. 각 접근법의 장단점 비교
4. 최적 솔루션 선택 및 이유 설명
5. 구현 계획 작성
```

---

## 🎓 학습 자료 분석 예시

### Toast UI Grid 분석

**프롬프트:**
```
너는 Grid 컴포넌트 전문가다.
Toast UI Grid의 소스코드를 분석하여 LiveView Grid에 적용할 수 있는
아이디어를 추출하라.

분석 대상:
- Virtual Scrolling 구현
- 컬럼 필터링
- 정렬 로직

출력:
1. 핵심 아이디어
2. LiveView 적용 방법
3. 코드 예시
```

---

### 넥사크로 Grid 분석

**프롬프트:**
```
넥사크로 Grid의 Dataset 개념을 분석하라.
LiveView assigns와 어떻게 대응시킬 수 있는가?

비교 항목:
- 데이터 바인딩
- 그룹화/집계
- 이벤트 처리
```

---

## 🚀 프로젝트 진행 체크리스트

### Phase 1: v0.1 (기본 기능)
- [ ] SubAgent - Architect: 전체 구조 설계
- [ ] SubAgent - Designer: API 설계
- [ ] SubAgent - Developer: 기본 렌더링 구현
- [ ] PDCA Cycle 1: Plan → Do → Check → Act
- [ ] SubAgent - QA: 테스트 시나리오 작성
- [ ] SubAgent - Tester: 실제 테스트 실행

### Phase 2: v0.2 (필터/정렬)
- [ ] Sequential Think: 필터링 아키텍처 결정
- [ ] SubAgent - Developer: 구현
- [ ] PDCA Cycle 2: 성능 최적화
- [ ] SubAgent - Tester: 버그 검증

### Phase 3: v0.3 (가상 스크롤)
- [ ] Sequential Think: Virtual Scrolling 방식 결정
- [ ] SubAgent - Architect: Toast UI Grid 분석
- [ ] PDCA Cycle 3: 구현 및 개선
- [ ] 성능 벤치마크 (10,000행)

---

## 📚 참고 자료

- **넥사크로 Grid 분석**: `nexacrogrid_function.md`
- **Toast UI Grid 분석**: `toastgrid_function.md`
- **프로젝트 README**: `README.md`
- **개발 가이드**: `DEVELOPMENT.md`

---

## 🐾 마무리

이 문서는 **살아있는 문서**입니다.  
프로젝트 진행 중 새로운 패턴이나 인사이트가 생기면 계속 업데이트하세요!

**작성자**: Claude (Anthropic) & MB  
**라이선스**: MIT (프로젝트와 동일)
