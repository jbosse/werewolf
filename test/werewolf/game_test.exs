defmodule Werewolf.GameTest do
  use ExUnit.Case

  alias Werewolf.Game

  test "will make a new game" do
    session_id = "blah"
    game = Game.new(session_id)
    assert game.code |> String.length == 6
    assert game.code |> String.match?(~r/[A-Z][A-Z][A-Z][A-Z][A-Z][A-Z]/)
    assert game.host_id == session_id
    assert game.players |> Enum.count == 0
  end

  test "will start a game with 6 players" do
    game = Game.start(6)
    assert Enum.count(game.players) == 6
  end
end
