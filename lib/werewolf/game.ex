defmodule Werewolf.Game do
  @spec start(non_neg_integer) :: Map
  def start(number_of_players) do
    build_game(number_of_players, %{players: []})
  end

  @spec build_game(non_neg_integer, map) :: Map
  def build_game(0, game), do: game

  def build_game(number_of_players, game) do
    build_game(number_of_players - 1, %{game | players: [%{} | game.players]})
  end
end
