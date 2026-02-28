defmodule LiveviewGridWeb.BuilderLiveTest do
  use LiveviewGridWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "BuilderLive page" do
    test "renders empty state", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/builder")

      assert html =~ "Grid Builder"
      assert html =~ "No grids created yet"
      assert html =~ "Create New Grid"
    end

    test "opens builder modal on button click", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/builder")

      view |> element("button", "Create New Grid") |> render_click()
      html = render(view)

      assert html =~ "Grid Builder -"
      assert html =~ "기본 설정"
    end

    test "closes modal on cancel click", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/builder")
      view |> element("button", "Create New Grid") |> render_click()

      view |> element("button", "취소") |> render_click()
      html = render(view)

      refute html =~ "Grid Builder -"
      assert html =~ "No grids created yet"
    end
  end

  describe "BuilderLive - Grid creation integration" do
    test "creates grid and renders GridComponent", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/builder")
      view |> element("button", "Create New Grid") |> render_click()

      # Set grid name via blur
      view
      |> element("input[phx-blur=\"update_grid_name\"]")
      |> render_blur(%{"value" => "Test Grid"})

      # Switch to columns tab
      view |> element("button", "컬럼 정의") |> render_click()

      # Add a column
      view |> element("button", "+ 컬럼 추가") |> render_click()

      # Fill field name - find the input for field name
      view
      |> element("input[phx-blur=\"update_column_field\"][phx-value-id=\"col_1\"]")
      |> render_blur(%{"value" => "name"})

      # Fill label
      view
      |> element("input[phx-blur=\"update_column_label\"][phx-value-id=\"col_1\"]")
      |> render_blur(%{"value" => "이름"})

      # Create grid
      view |> element("button", "그리드 생성") |> render_click()

      html = render(view)

      # Modal should close, grid should be rendered
      assert html =~ "Test Grid"
      assert html =~ "1 grid(s) created"
      assert html =~ "lv-grid"
    end

    test "shows validation error when name is missing", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/builder")
      view |> element("button", "Create New Grid") |> render_click()

      # Don't set grid name, just click create
      view |> element("button", "그리드 생성") |> render_click()

      html = render(view)
      assert html =~ "그리드 이름을 입력하세요"
    end

    test "deletes created grid", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/builder")
      view |> element("button", "Create New Grid") |> render_click()

      # Quick create
      view |> element("input[phx-blur=\"update_grid_name\"]") |> render_blur(%{"value" => "Del Grid"})
      view |> element("button", "컬럼 정의") |> render_click()
      view |> element("button", "+ 컬럼 추가") |> render_click()
      view |> element("input[phx-blur=\"update_column_field\"][phx-value-id=\"col_1\"]") |> render_blur(%{"value" => "x"})
      view |> element("input[phx-blur=\"update_column_label\"][phx-value-id=\"col_1\"]") |> render_blur(%{"value" => "X"})
      view |> element("button", "그리드 생성") |> render_click()

      # Verify created
      assert render(view) =~ "Del Grid"

      # Delete
      view |> element("button", "Delete") |> render_click()
      html = render(view)

      assert html =~ "No grids created yet"
    end
  end

  describe "BuilderLive - Tab navigation" do
    test "switches between tabs", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/builder")
      view |> element("button", "Create New Grid") |> render_click()

      # Default: info tab
      html = render(view)
      assert html =~ "Grid 기본 설정"

      # Switch to columns
      view |> element("button", "컬럼 정의") |> render_click()
      html = render(view)
      assert html =~ "컬럼 정의"

      # Switch to preview
      view |> element("button", "미리보기") |> render_click()
      html = render(view)
      assert html =~ "미리보기"
    end
  end
end
