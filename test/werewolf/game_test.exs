defmodule Werewolf.GameTest do
  use ExUnit.Case

  alias Werewolf.Game

  test "will start a game with 6 players" do
    game = Game.start(6)
    assert Enum.count(game.players) == 6
  end
end
