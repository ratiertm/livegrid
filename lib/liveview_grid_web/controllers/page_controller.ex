defmodule LiveviewGridWeb.PageController do
  use LiveviewGridWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: "/demo")
  end
end
