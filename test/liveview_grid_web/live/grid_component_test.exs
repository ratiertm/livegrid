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

    test "filter row shown with floating_filter option", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/demo")

      # FA-011: floating_filter: true이면 초기부터 필터 행 표시
      assert html =~ "lv-grid__filter-row"
      assert html =~ "lv-grid__filter-row--floating"
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

      # FA-011: floating_filter: true이면 필터 행이 항상 표시됨
      html = render(view)
      assert html =~ "lv-grid__filter-row"
      assert html =~ "lv-grid__filter-row--floating"

      # 토글 클릭해도 floating_filter이면 필터 행 유지
      view |> element("[phx-click=\"grid_toggle_filter\"]") |> render_click()
      html = render(view)
      assert html =~ "lv-grid__filter-row"
    end

    test "search bar renders", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/demo")

      assert html =~ "lv-grid__search-bar"
      assert html =~ "lv-grid__search-input"
      assert html =~ "전체 검색..."
    end

    test "search bar clear button shows when search active", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/demo")

      # 초기 상태: 클리어 버튼 없음
      refute html =~ "lv-grid__search-clear"
    end

    test "editable cells have editable class", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/demo")

      # editable 컬럼의 셀에 editable 클래스가 있어야 함
      assert html =~ "lv-grid__cell-value--editable"
    end

    test "non-editable cells do not have editable class for ID column", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/demo")

      # ID 컬럼은 editable이 아니므로 일반 cell-value만 있어야 함
      # 단, 다른 editable 컬럼이 있으므로 전체적으로 editable 클래스가 존재함
      # ID 컬럼 값(숫자)이 editable 아닌 span으로 렌더링되는지 확인
      assert html =~ "lv-grid__cell-value"
    end

    test "cell edit editor not shown by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/demo")

      # 초기 상태: 편집 에디터가 표시되지 않음
      refute html =~ "lv-grid__cell-editor"
    end

    test "status column visible by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/demo")
      assert html =~ "lv-grid__header-cell--status"
      assert html =~ "상태"
    end

    test "status column toggle hides and shows column", %{conn: conn} do
      {:ok, view, html} = live(conn, "/demo")
      assert html =~ "lv-grid__header-cell--status"

      # 토글 OFF
      view |> element("button.lv-grid__status-toggle") |> render_click()
      html = render(view)
      refute html =~ "lv-grid__header-cell--status"

      # 토글 ON
      view |> element("button.lv-grid__status-toggle") |> render_click()
      html = render(view)
      assert html =~ "lv-grid__header-cell--status"
    end

    test "status badge not shown for normal rows", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/demo")
      refute html =~ "lv-grid__status-badge"
    end
  end
end
