# Context 설계 규칙

## Phoenix Context란?
- 관련된 비즈니스 로직을 하나의 모듈로 묶는 경계(boundary)
- 웹 레이어와 데이터 레이어 사이의 공개 API 역할
- 예: `ContentFlow.Accounts`, `ContentFlow.Contents`

## MUST (반드시)
- Context 모듈은 해당 도메인의 유일한 공개 인터페이스
- 외부에서는 Context 함수만 호출 — 내부 스키마/쿼리 모듈 직접 접근 금지
- CRUD 함수 네이밍 규칙 준수 (아래 표 참고)
- 복잡한 로직은 Context 내부의 private 함수 또는 별도 서비스 모듈로 분리
- Multi(Ecto.Multi)는 여러 DB 작업을 묶을 때 반드시 사용

## NEVER (금지)
- Context 모듈에 Phoenix/웹 관련 코드 넣기 금지 (conn, socket, params 등)
- 하나의 Context가 500줄 이상 금지 → 서브 모듈로 분리
- Context 간 직접 Repo 호출로 우회 금지 → 다른 Context의 공개 API 사용

## CRUD 네이밍 규칙

| 함수명 | 동작 | 반환 |
|--------|------|------|
| `list_posts/0,1` | 목록 조회 | `[%Post{}]` |
| `get_post/1` | 단건 조회 | `%Post{}` 또는 `nil` |
| `get_post!/1` | 단건 조회 (없으면 raise) | `%Post{}` |
| `create_post/1` | 생성 | `{:ok, %Post{}}` 또는 `{:error, %Changeset{}}` |
| `update_post/2` | 수정 | `{:ok, %Post{}}` 또는 `{:error, %Changeset{}}` |
| `delete_post/1` | 삭제 | `{:ok, %Post{}}` 또는 `{:error, %Changeset{}}` |
| `change_post/1,2` | Changeset 반환 (폼용) | `%Changeset{}` |

## 패턴

### ✅ 좋은 예
```elixir
defmodule ContentFlow.Contents do
  @moduledoc "콘텐츠 관련 비즈니스 로직"

  alias ContentFlow.Repo
  alias ContentFlow.Contents.Post
  alias ContentFlow.Contents.Queries.PostQuery

  @doc "게시글 목록 조회 (필터링/페이지네이션 지원)"
  @spec list_posts(keyword()) :: [Post.t()]
  def list_posts(opts \\ []) do
    PostQuery.base()
    |> PostQuery.filter(opts)
    |> PostQuery.paginate(opts)
    |> Repo.all()
  end

  @doc "게시글 생성"
  @spec create_post(map()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def create_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc "게시글 생성 + 연관 작업 (트랜잭션)"
  @spec publish_post(map()) :: {:ok, map()} | {:error, atom(), any(), map()}
  def publish_post(attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:post, Post.changeset(%Post{}, attrs))
    |> Ecto.Multi.run(:notify, fn _repo, %{post: post} ->
      notify_subscribers(post)
    end)
    |> Repo.transaction()
  end
end
```

### ❌ 나쁜 예
```elixir
defmodule ContentFlow.Contents do
  # ❌ 웹 관련 코드가 Context에 있음
  def create_post(conn, params) do
    # ❌ conn이 Context에 들어옴
    user = conn.assigns.current_user

    # ❌ Changeset 없이 직접 삽입
    Repo.insert(%Post{title: params["title"], user_id: user.id})
  end
end
```

## Context 분리 기준
- 서로 다른 도메인 개념 → 별도 Context
- 같은 Context 내에서도 복잡한 로직 → 서브 모듈로 분리
  - 예: `Contents.Posts`, `Contents.Categories`, `Contents.Tags`
- 쿼리가 복잡해지면 → `Contents.Queries.PostQuery` 별도 모듈

## 리팩토링 시 주의
- Context 공개 함수의 시그니처 변경 시 호출하는 모든 LiveView/컨트롤러 수정
- Context 모듈명 변경 시 alias 전부 검색/수정
- Ecto.Multi 도입 시 기존 개별 Repo 호출을 하나씩 옮길 것 (한번에 전부 X)
