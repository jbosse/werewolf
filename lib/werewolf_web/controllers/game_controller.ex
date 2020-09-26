defmodule WerewolfWeb.GameController do
  use WerewolfWeb, :controller

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "index.html")
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, _params) do
    game = Werewolf.Game.new()
    Werewolf.GameStore.save(game)
    redirect(conn, to: Routes.game_show_path(conn, :show, game.code))
  end
end
