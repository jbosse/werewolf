defmodule WerewolfWeb.GameController do
  use WerewolfWeb, :controller

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create(conn, _params) do
    redirect(conn, to: Routes.game_path(conn, :show, "snazzy-jet-lab"))
  end
end
