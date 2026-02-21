defmodule LiveviewGridWeb.PageControllerTest do
  use LiveviewGridWeb.ConnCase

  test "GET / redirects to /demo", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == "/demo"
  end
end
