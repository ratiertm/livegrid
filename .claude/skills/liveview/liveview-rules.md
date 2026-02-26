# LiveView 작성 규칙

## MUST (반드시)
- `mount/3`에서 초기 assigns 전부 설정 — 이후 단계에서 nil assign 접근 방지
- `handle_params/3`로 URL 파라미터 처리 — mount에서 params 직접 사용 금지
- `handle_event/3` 는 Context 호출 + assign 갱신만 — 비즈니스 로직 넣지 말 것
- 긴 작업은 `Task.async` + `handle_info`로 비동기 처리 — 사용자 블로킹 금지
- 모든 LiveView 모듈에 `@impl true` 명시

## NEVER (금지)
- LiveView에서 직접 `Repo.insert/update/delete` 호출 금지
- `handle_event`에서 복잡한 비즈니스 로직 작성 금지
- HEEx 안에서 DB 쿼리 함수 호출 금지
- socket.assigns를 직접 Map.put으로 수정 금지 → `assign/3` 사용
- LiveView 모듈 하나에 500줄 이상 금지 → 컴포넌트로 분리

## 패턴

### ✅ 좋은 예
```elixir
defmodule ContentFlowWeb.PostLive.Index do
  use ContentFlowWeb, :live_view

  alias ContentFlow.Contents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, posts: [], loading: true, page: 1)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = String.to_integer(params["page"] || "1")
    posts = Contents.list_posts(page: page)
    {:noreply, assign(socket, posts: posts, page: page, loading: false)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Contents.delete_post(id) do
      {:ok, _post} ->
        posts = Contents.list_posts(page: socket.assigns.page)
        {:noreply, assign(socket, posts: posts) |> put_flash(:info, "삭제되었습니다.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "삭제에 실패했습니다.")}
    end
  end
end
```

### ❌ 나쁜 예
```elixir
defmodule ContentFlowWeb.PostLive.Index do
  use ContentFlowWeb, :live_view

  # ❌ Repo 직접 호출
  alias ContentFlow.Repo
  alias ContentFlow.Contents.Post

  def mount(_params, _session, socket) do
    # ❌ assigns 누락 (loading, page 없음)
    posts = Repo.all(Post)  # ❌ Context 우회, 직접 Repo 호출
    {:ok, assign(socket, posts: posts)}
  end

  # ❌ @impl true 누락
  def handle_event("delete", %{"id" => id}, socket) do
    # ❌ LiveView에서 직접 비즈니스 로직
    post = Repo.get!(Post, id)
    Repo.delete(post)
    {:noreply, assign(socket, posts: Repo.all(Post))}
  end
end
```

## LiveView 라이프사이클 참고
```
mount/3 → (connected?) → handle_params/3 → render
                                              ↑
handle_event/3 ─────────────────────────────→ │
handle_info/2 ──────────────────────────────→ │
```

## 리팩토링 시 주의
- LiveView의 assign 키를 변경하면 해당 HEEx 템플릿 전부 확인
- `handle_event` 이름 변경 시 HEEx의 `phx-click`, `phx-submit` 등 전부 수정
- PubSub 구독이 있는 LiveView는 broadcast 발행처도 함께 확인
