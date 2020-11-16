defmodule WerewolfWeb.GameControllerTest do
  use WerewolfWeb.ConnCase, async: true
  use AssertHTML

  test "it will render the page ot choose your path", %{conn: conn} do
    conn = get(conn, Routes.game_path(conn, :index))

    html_response(conn, 200)
    |> assert_html("title", "Werewolf")
    |> assert_html("form[action='#{Routes.game_path(conn, :join)}'][method='post]")
    |> assert_html("input[name='code']")
    |> assert_html("button[type='submit']:nth-child(4)", text: "Join a Game")
    |> assert_html("form[action='#{Routes.game_path(conn, :create)}'][method='post]")
    |> assert_html("button[type='submit']:nth-child(3)", text: "Create a Game")
  end

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

  test "redirects", %{conn: conn} do
    conn = post(conn, Routes.game_path(conn, :join), [code: "ABCDEFG"])
    assert redirected_to(conn) == Routes.game_show_path(conn, :show, "ABCDEFG")
  end

end
