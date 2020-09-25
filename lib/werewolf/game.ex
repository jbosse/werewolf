defmodule Werewolf.Game do
  defstruct code: nil,
            players: [],
            state: :not_started

  @type t() :: %__MODULE__{}

  alias Werewolf.Game

  def new(player) do
    %Game{
      code: code(),
      players: [player]
    }
  end

  defp code() do
    lists = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.split("", trim: true)

    1..6
    |> Enum.reduce([], fn _, acc -> [Enum.random(lists) | acc] end)
    |> Enum.join("")
  end

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
