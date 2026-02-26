# 에러 처리 규칙 (Elixir / Phoenix)

## Elixir 에러 처리 철학
- "Let it crash" — 예상 불가능한 오류는 OTP Supervisor가 처리
- 예상 가능한 오류는 `{:ok, result}` / `{:error, reason}` 튜플로 처리
- `raise`/`throw`는 정말 예외적인 상황에서만

## MUST (반드시)
- Context 공개 함수는 `{:ok, result}` / `{:error, reason}` 반환
- `with` 구문으로 연쇄 작업의 에러를 깔끔하게 처리
- `Ecto.Changeset` 에러는 그대로 전파 — 웹 레이어에서 사용자 메시지로 변환
- 외부 API 호출 시 반드시 타임아웃 설정 + 에러 처리
- `Repo.get!` 는 LiveView/컨트롤러에서만 사용 (자동 404 변환)

## NEVER (금지)
- 빈 rescue 블록 금지 — 에러 삼키기 금지
- Context에서 `raise` 사용 금지 → `{:error, reason}` 반환
- 에러 메시지에 내부 구현 상세 노출 금지 (SQL 쿼리, 스택 트레이스 등)
- `try/rescue`로 흐름 제어 금지 — 패턴 매칭/with 사용

## 패턴

### ✅ with 구문 — 좋은 예
```elixir
def publish_post(post_id, user_id) do
  with {:ok, post} <- get_owned_post(post_id, user_id),
       :ok <- validate_publishable(post),
       {:ok, published} <- do_publish(post) do
    {:ok, published}
  else
    {:error, :not_found} -> {:error, :not_found}
    {:error, :not_owner} -> {:error, :unauthorized}
    {:error, :already_published} -> {:error, :already_published}
    {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
  end
end
```

### ✅ LiveView에서 에러 처리 — 좋은 예
```elixir
def handle_event("publish", %{"id" => id}, socket) do
  case Contents.publish_post(id, socket.assigns.current_user.id) do
    {:ok, _post} ->
      {:noreply,
       socket
       |> put_flash(:info, "게시글이 발행되었습니다.")
       |> push_navigate(to: ~p"/posts")}

    {:error, :not_found} ->
      {:noreply, put_flash(socket, :error, "게시글을 찾을 수 없습니다.")}

    {:error, :unauthorized} ->
      {:noreply, put_flash(socket, :error, "권한이 없습니다.")}

    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, changeset: changeset)}
  end
end
```

### ✅ 커스텀 에러 모듈 (선택적)
```elixir
defmodule ContentFlow.Error do
  @type t :: {:error, reason()}
  @type reason :: :not_found | :unauthorized | :forbidden | :validation_failed | atom()

  def not_found(resource), do: {:error, {:not_found, resource}}
  def unauthorized, do: {:error, :unauthorized}
  def forbidden, do: {:error, :forbidden}
end
```

### ❌ 나쁜 예
```elixir
# ❌ 빈 rescue — 에러 삼킴
def get_post(id) do
  try do
    Repo.get!(Post, id)
  rescue
    _ -> nil  # 에러가 뭔지도 모르고 삼킴
  end
end

# ❌ Context에서 raise
def create_post(attrs) do
  case Repo.insert(Post.changeset(%Post{}, attrs)) do
    {:ok, post} -> post
    {:error, _} -> raise "게시글 생성 실패"  # ❌ raise 대신 {:error, reason} 반환
  end
end
```

## Phoenix ErrorView / Fallback
- `ErrorJSON`과 `ErrorHTML`에서 상태코드별 에러 응답 정의
- API 컨트롤러는 FallbackController 활용하여 `{:error, reason}` → HTTP 응답 자동 변환
