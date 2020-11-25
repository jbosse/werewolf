defmodule WerewolfWeb.GameLive.ShowTest do
  use WerewolfWeb.ConnCase
  use AssertHTML

  import Phoenix.LiveViewTest

  test "mount will redirect if game doesn't exists", %{conn: conn} do
    _game = Werewolf.Game.new("my_host") |> Werewolf.GameStore.save()
    {:error, {:live_redirect, %{to: "/"}}} = live(conn, Routes.game_show_path(conn, :show, "INVALID"))
  end

  test "mount", %{conn: conn} do
    game = Werewolf.Game.new("my_host") |> Werewolf.GameStore.save()
    {:ok, _view, html} = live(conn, Routes.game_show_path(conn, :show, game.code))
    html
      |> assert_html("title", "Werewolf")
      |> assert_html("form[phx-submit=\"join_game\"]")
      |> assert_html("input[name='player[screen_name]']")
      |> assert_html("button[type='submit']", text: "Join Game")
  end
end
