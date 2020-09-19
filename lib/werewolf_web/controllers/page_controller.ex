defmodule WerewolfWeb.PageController do
  use WerewolfWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
