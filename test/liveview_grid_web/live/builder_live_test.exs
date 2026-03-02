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

      # Sample columns are auto-generated on mount, so just create directly
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

      # Set grid name - sample columns auto-generated
      view |> element("input[phx-blur=\"update_grid_name\"]") |> render_blur(%{"value" => "Del Grid"})
      view |> element("button", "그리드 생성") |> render_click()

      # Verify created
      assert render(view) =~ "Del Grid"

      # Delete
      view |> element("button", "Delete") |> render_click()
      html = render(view)

      assert html =~ "No grids created yet"
    end
  end

  describe "BuilderLive - Export/Import" do
    test "export button renders in modal footer", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/builder")
      view |> element("button", "Create New Grid") |> render_click()

      html = render(view)
      assert html =~ "Export"
      assert html =~ "Import"
      assert html =~ "컬럼 6개 정의됨"
    end

    test "export from modal triggers download event", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/builder")
      view |> element("button", "Create New Grid") |> render_click()

      # Set name first
      view |> element("input[phx-blur=\"update_grid_name\"]") |> render_blur(%{"value" => "Export Test"})

      # Click export - should not crash
      view |> element("button[phx-click=\"export_grid_json\"]") |> render_click()
      html = render(view)

      # Modal should still be open (export doesn't close it)
      assert html =~ "Grid Builder -"
    end

    test "import hook element renders with correct attributes", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/builder")
      view |> element("button", "Create New Grid") |> render_click()

      html = render(view)

      # Verify JsonImport hook element is rendered with correct attributes
      assert html =~ "id=\"builder-json-import\""
      assert html =~ "phx-hook=\"JsonImport\""
      assert html =~ "Import"
    end

    test "export button renders on grid cards", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/builder")
      view |> element("button", "Create New Grid") |> render_click()

      view |> element("input[phx-blur=\"update_grid_name\"]") |> render_blur(%{"value" => "Card Export"})
      view |> element("button", "그리드 생성") |> render_click()

      html = render(view)
      assert html =~ "Export"
      assert html =~ "export_dynamic_grid"
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
