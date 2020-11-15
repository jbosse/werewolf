defmodule Werewolf.Game do
  defstruct code: nil,
            host_id: nil,
            players: [],
            werewolf_votes: [],
            village_votes: [],
            doctor_heals: nil,
            seer_sees: nil,
            werewolves_eat: nil,
            villagers_kill: nil,
            state: :not_started,
            winner: nil

  @type t() :: %__MODULE__{}

  alias Werewolf.Game

  def new(host_id) do
    %Game{
      code: code(),
      host_id: host_id,
      players: []
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

  @spec add_player(Werewolf.Game.t(), Werewolf.Player.t()) :: Werewolf.Game.t()
  def add_player(game, player) do
    %Game{game | players: [player | game.players]}
  end
end
