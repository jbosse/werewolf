defmodule WerewolfWeb.GameControllerTest do
  use WerewolfWeb.ConnCase, async: true

  test "creates game and redirects", %{conn: conn} do
    conn = post(conn, Routes.game_path(conn, :create))
    {"location", location} = conn.resp_headers |> List.keyfind("location", 0)
    {"/games/", game_code} = location |> String.split_at(7)
    {:ok, game} = Werewolf.GameStore.get(game_code)
    session_id = Plug.Conn.get_session(conn, :session_id)
    assert redirected_to(conn) == Routes.game_show_path(conn, :show, game_code)
    assert game.host_id == session_id
    assert game.code == game_code
  end

end
