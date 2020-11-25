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
  alias Werewolf.Player

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

  def begin_game(game) do
    players =
      game.players
      |> Enum.count()
      |> Werewolf.Roles.get()
      |> Enum.shuffle()
      |> Enum.zip(game.players)
      |> Enum.map(fn {r, p} -> %Player{p | role: r} end)

    %Game{game | state: :night, players: players}
  end

  def werewolf_vote(game, werewolf_uuid, player_uuid) do
    werewolf = Enum.find(game.players, fn p -> p.uuid == werewolf_uuid end)
    player = Enum.find(game.players, fn p -> p.uuid == player_uuid end)
    cond do
      :dead == werewolf.state -> game
      nil == player ->
        votes = Enum.reject(game.werewolf_votes, fn {w, _p} -> w == werewolf_uuid end)
        %Game{game | werewolf_votes: votes}
      :dead == player.state -> game
      true ->
        case Enum.count(game.werewolf_votes, fn {w, _p} -> w == werewolf_uuid end) do
          0 -> %Game{game | werewolf_votes: [{werewolf_uuid, player_uuid} | game.werewolf_votes]}
          _ ->
            votes = Enum.map(game.werewolf_votes, fn {w, p} ->
              cond do
                w == werewolf_uuid -> {werewolf_uuid, player_uuid}
                true -> {w, p}
              end
            end)
            %Game{game | werewolf_votes: votes}
        end
    end
  end

  def werewolves_killed(game) do
    player_uuid = Enum.reduce(game.werewolf_votes, :none, fn {w, p}, current_player_uuid ->
      werewolf = Enum.find(game.players, fn p -> p.uuid == w end)
      cond do
        :dead == werewolf.state -> current_player_uuid
        :none == current_player_uuid -> p
        p == current_player_uuid -> current_player_uuid
        true -> nil
      end
    end)
    case player_uuid do
      nil -> :undecided
      _ -> {:ok, player_uuid}
    end
  end

  def check_for_eaten(game) do
    case  werewolves_killed(game) do
      {:ok, player_uuid} -> %Game{game | werewolves_eat: player_uuid}
      _ -> game
    end
  end

  def check_for_end_of_round(game) do
    cond do
      seer_has_seen?(game) && doctor_has_healed?(game) && game.werewolves_eat != nil ->
        game
          |> see_player()
          |> eat_player()
          |> sunrise()
      true -> game
    end
  end

  def eat_player(game) do
    players = Enum.map(game.players, fn p ->
          cond do
            p.uuid == game.werewolves_eat && p.uuid != game.doctor_heals ->
              %Player{p | state: :dead}
            true -> p
          end
        end)
    %Game{game | players: players}
  end

  def see_player(game) do
    players = Enum.map(game.players, fn p ->
          cond do
            p.uuid == game.seer_sees -> %Player{p | seen: p.role}
            true -> p
          end
        end)
    %Game{game | players: players}
  end

  def sunrise(game) do
    %Game{game | state: :day}
  end

  def seer_has_seen?(game) do
    seer = Enum.find(game.players, fn p -> p.role == :seer end)
    game.seer_sees != nil || seer.state == :dead
  end

  def doctor_has_healed?(game) do
    doctor = Enum.find(game.players, fn p -> p.role == :doctor end)
    game.doctor_heals != nil || doctor.state == :dead
  end

  def werewolf_votes_for(game, player_uuid) do
    Enum.count(game.werewolf_votes, fn {_, p} -> p == player_uuid end)
  end

  def check_for_winner(game) do
    alive = Enum.filter(game.players, fn p -> p.state != :dead end)
    werewolf_count = Enum.count(alive, fn p -> p.role == :werewolf end)
    villager_count = Enum.count(alive, fn p -> p.role != :werewolf end)
    cond do
      werewolf_count >= villager_count -> %Game{ game | winner: :werewolves}
      true -> game
    end
  end

  def protect(game, doctor_uuid, player_uuid) do
    doctor = Enum.find(game.players, fn p -> p.uuid == doctor_uuid && p.role == :doctor end)
    player = Enum.find(game.players, fn p -> p.uuid == player_uuid end)
    cond do
      doctor == nil -> game
      player == nil -> game
      doctor.state != :dead && player.state != :dead ->
        %Game{ game | doctor_heals: player_uuid }
      true -> game
    end
  end

  def divine(game, seer_uuid, player_uuid) do
    seer = Enum.find(game.players, fn p -> p.uuid == seer_uuid && p.role == :seer end)
    player = Enum.find(game.players, fn p -> p.uuid == player_uuid end)
    cond do
      seer == nil -> game
      player == nil -> game
      seer.state != :dead && player.state != :dead ->
        %Game{ game | seer_sees: player_uuid }
      true -> game
    end
  end
end
