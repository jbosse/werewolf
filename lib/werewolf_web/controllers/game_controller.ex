defmodule WerewolfWeb.GameController do
  use WerewolfWeb, :controller

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "index.html")
  end

  @spec join(Plug.Conn.t(), map) :: Plug.Conn.t()
  def join(conn, %{"code" => code}) do
    redirect(conn, to: Routes.game_show_path(conn, :show, code))
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, _params) do
    session_id = Plug.Conn.get_session(conn, :session_id)
    game = Werewolf.Game.new(session_id)
    Werewolf.GameStore.save(game)
    redirect(conn, to: Routes.game_show_path(conn, :show, game.code))
  end
end
