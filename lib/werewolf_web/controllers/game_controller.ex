defmodule WerewolfWeb.GameController do
  use WerewolfWeb, :controller

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "index.html")
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"screen_name" => screen_name}) do
    game = Werewolf.Game.new(screen_name)
    Werewolf.GameStore.save(game)
    redirect(conn, to: Routes.game_path(conn, :show, game.code))
  end
end
