# Phoenix Component 작성 규칙

## MUST (반드시)
- 재사용 가능한 UI는 Function Component로 분리
- `attr/3`로 Props 명시적 선언 — 타입, 필수 여부, 기본값 포함
- slot은 `slot/2`로 선언
- 컴포넌트 파일은 `content_flow_web/components/` 에 배치
- 한 모듈에 관련 컴포넌트만 모아서 배치 (예: `table_components.ex`)

## NEVER (금지)
- 컴포넌트 안에서 DB 조회 / 외부 API 호출 금지
- 컴포넌트에 socket이나 LiveView 상태 직접 전달 금지 → 필요한 데이터만 attr로
- HEEx 안에 복잡한 Elixir 로직(Enum, 조건 분기 등) 직접 작성 금지 → 헬퍼 함수 사용

## 패턴

### ✅ 좋은 예
```elixir
defmodule ContentFlowWeb.Components.Card do
  use Phoenix.Component

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :class, :string, default: ""
  slot :inner_block, required: true
  slot :actions

  def card(assigns) do
    ~H"""
    <div class={["rounded-lg border bg-white p-6 shadow-sm", @class]}>
      <h3 class="text-lg font-semibold text-gray-900"><%= @title %></h3>
      <%= if @subtitle do %>
        <p class="mt-1 text-sm text-gray-500"><%= @subtitle %></p>
      <% end %>
      <div class="mt-4">
        <%= render_slot(@inner_block) %>
      </div>
      <%= if @actions != [] do %>
        <div class="mt-4 flex gap-2">
          <%= render_slot(@actions) %>
        </div>
      <% end %>
    </div>
    """
  end
end
```

### ❌ 나쁜 예
```elixir
# ❌ attr 선언 없음, 타입 불명
def card(assigns) do
  ~H"""
  <div>
    <!-- ❌ assigns에 뭐가 오는지 모름 -->
    <%= @data.title %>
    <!-- ❌ 컴포넌트에서 DB 조회 -->
    <%= ContentFlow.Repo.get(User, @user_id).name %>
  </div>
  """
end
```

## CoreComponents 활용
- Phoenix 기본 `core_components.ex`의 `.button`, `.input`, `.modal` 등을 우선 활용
- 커스터마이징이 필요하면 CoreComponents를 수정하거나, 별도 컴포넌트 모듈 생성
- CoreComponents 함수를 덮어쓰지 말 것 — 새 이름으로 별도 생성

## 리팩토링 시 주의
- 컴포넌트의 attr 이름 변경 시 호출하는 모든 HEEx 수정 필요
- slot 구조 변경 시 render_slot 호출부 전부 확인
