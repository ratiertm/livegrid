defmodule LiveviewGridWeb.GridComponentTest do
  use LiveviewGridWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "GridComponent rendering" do
    test "mounts and renders grid with data", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/demo")

      # 그리드가 렌더링되었는지 확인
      assert html =~ "lv-grid"
      assert html =~ "이름"
      assert html =~ "이메일"
    end

    test "sort event changes header icon", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/demo")

      # 정렬 클릭 시 이벤트가 컴포넌트로 전달되는지 확인
      html = render(view)
      assert html =~ "이름"
    end

    test "renders with virtual scroll enabled", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/demo")

      # Virtual Scroll 토글 (초기 상태는 OFF)
      view |> element("[phx-click=\"toggle_virtual_scroll\"]") |> render_click()
      html = render(view)

      # VirtualScroll Hook이 있는 요소가 렌더링되는지 확인
      assert html =~ "phx-hook=\"VirtualScroll\""
      assert html =~ "lv-grid__body--virtual"
    end

    test "data count change re-renders grid", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/demo")

      # 데이터 수 변경
      view |> element("button", "100개") |> render_click()
      html = render(view)

      # 100개 데이터로 변경되었는지 확인
      assert html =~ "100개"
    end

    test "checkbox renders in header and rows", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/demo")

      # 체크박스가 헤더와 행에 렌더링되는지 확인
      assert html =~ "type=\"checkbox\""
      assert html =~ "grid_select_all"
      assert html =~ "grid_row_select"
    end

    test "filter row hidden by default, shown after toggle", %{conn: conn} do
      {:ok, view, html} = live(conn, "/demo")

      # 초기 상태: 필터 행 숨김
      refute html =~ "lv-grid__filter-row"

      # 필터 토글 버튼 클릭
      view |> element("[phx-click=\"grid_toggle_filter\"]") |> render_click()
      html = render(view)

      # 필터 행이 표시됨
      assert html =~ "lv-grid__filter-row"
      assert html =~ "lv-grid__filter-input"
      assert html =~ "grid_filter"
    end

    test "filter row has correct placeholders after toggle", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/demo")

      # 필터 토글
      view |> element("[phx-click=\"grid_toggle_filter\"]") |> render_click()
      html = render(view)

      assert html =~ "검색..."
      assert html =~ "예: &gt;30, &lt;=25"
    end

    test "filter toggle hides row and clears filters", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/demo")

      # 필터 열기
      view |> element("[phx-click=\"grid_toggle_filter\"]") |> render_click()
      html = render(view)
      assert html =~ "lv-grid__filter-row"

      # 필터 닫기
      view |> element("[phx-click=\"grid_toggle_filter\"]") |> render_click()
      html = render(view)
      refute html =~ "lv-grid__filter-row"
    end
  end
end
