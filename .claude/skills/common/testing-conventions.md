# 테스트 컨벤션 (ExUnit / Phoenix)

## MUST (반드시)
- Context 공개 함수마다 최소 1개 이상 테스트
- Happy path + 에러 케이스 + 엣지 케이스 포함
- 테스트 데이터는 Factory 또는 Fixture로 생성 — 직접 Repo.insert 최소화
- `async: true` 가능한 테스트는 비동기로 실행
- `describe` 블록으로 함수/시나리오별 그룹핑

## 패턴

### Context 테스트
```elixir
defmodule ContentFlow.ContentsTest do
  use ContentFlow.DataCase, async: true

  alias ContentFlow.Contents

  describe "create_post/1" do
    test "유효한 속성으로 게시글 생성 성공" do
      user = insert(:user)
      attrs = %{title: "테스트 제목", body: "내용", author_id: user.id}

      assert {:ok, post} = Contents.create_post(attrs)
      assert post.title == "테스트 제목"
      assert post.status == :draft
    end

    test "제목 없이 생성 시 에러 반환" do
      attrs = %{body: "내용만"}

      assert {:error, changeset} = Contents.create_post(attrs)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
```

### LiveView 테스트
```elixir
defmodule ContentFlowWeb.PostLive.IndexTest do
  use ContentFlowWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "게시글 목록 페이지" do
    test "게시글 목록이 표시된다", %{conn: conn} do
      post = insert(:post, title: "테스트 게시글")

      {:ok, view, html} = live(conn, ~p"/posts")

      assert html =~ "테스트 게시글"
    end

    test "삭제 버튼 클릭 시 게시글이 삭제된다", %{conn: conn} do
      post = insert(:post)

      {:ok, view, _html} = live(conn, ~p"/posts")

      assert view
             |> element("[data-test='delete-#{post.id}']")
             |> render_click() =~ "삭제되었습니다"

      refute view |> has_element?("[data-test='post-#{post.id}']")
    end
  end
end
```

## NEVER
- 테스트 간 상태 공유 금지 — 각 테스트는 독립적
- `sleep`으로 비동기 대기 금지 → `assert_receive`, `eventually` 패턴 사용
- 프로덕션 외부 서비스 직접 호출 금지 → Mock/Stub 사용 (Mox 추천)
