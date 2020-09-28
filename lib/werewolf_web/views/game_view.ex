defmodule WerewolfWeb.GameView do
  use WerewolfWeb, :view

  alias Werewolf.Game
  alias Werewolf.Player

  def player_css(session_id, player) do
    cond do
      session_id == player.uuid -> "my player"
      true -> "player"
    end
  end

  def may_join(_session_id, players) when length(players) == 15, do: false
  def may_join(_session_id, []), do: true
  def may_join(session_id, [%Player{:uuid => session_id}]), do: false
  def may_join(session_id, [%Player{:uuid => session_id} | _players]), do: false
  def may_join(session_id, [_ | players]), do: may_join(session_id, players)

  def may_begin(_session_id, %Game{state: :started}), do: false

  def may_begin(_session_id, %Game{state: :not_started, players: players})
      when length(players) < 6,
      do: false

  def may_begin(session_id, %Game{host_id: session_id, state: :not_started, players: players})
      when length(players) >= 6,
      do: true

  def may_begin(_session_id, _game), do: false

  def get_role(session_id, game) do
    case session_id |> get_player(game.players) do
      nil -> "?"
      player -> player.role
    end
  end

  def get_player_name(session_id, game) do
    case session_id |> get_player(game.players) do
      nil -> "?"
      player -> player.screen_name
    end
  end

  defp get_player(_session_id, []), do: nil
  defp get_player(session_id, [%Player{:uuid => session_id} = player | _]), do: player
  defp get_player(session_id, [_ | players]), do: get_player(session_id, players)

  def may_mark(session_id, game) do
    case Enum.find(game.werewolf_votes, fn {id, _} -> session_id == id end) do
      nil -> true
      _ -> false
    end
  end

  def may_unmark(session_id, game, uuid) do
    case Enum.find(game.werewolf_votes, fn {s, p} -> s == session_id && p == uuid end) do
      nil -> false
      _ -> true
    end
  end

  def may_vote(session_id, game) do
    case Enum.find(game.village_votes, fn {id, _} -> session_id == id end) do
      nil -> true
      _ -> false
    end
  end

  def is_dead(session_id, game) do
    case session_id |> get_player(game.players) do
      nil -> true
      player -> player.state == :dead
    end
  end

  defp get_votes(uuid, game) do
    game.werewolf_votes
    |> Enum.filter(fn {_, p} -> p == uuid end)
    |> Enum.map(fn {s, _} -> get_player(s, game.players).screen_name end)
    |> Enum.join(", ")
  end

  defp has_votes(uuid, game) do
    case game.werewolf_votes |> Enum.find(fn {_, p} -> p == uuid end) do
      nil -> false
      _ -> true
    end
  end

  defp get_village_votes(uuid, game) do
    game.village_votes
    |> Enum.filter(fn {_, p} -> p == uuid end)
    |> Enum.map(fn {s, _} -> get_player(s, game.players).screen_name end)
    |> Enum.join(", ")
  end

  defp has_village_votes(uuid, game) do
    case game.village_votes |> Enum.find(fn {_, p} -> p == uuid end) do
      nil -> false
      _ -> true
    end
  end
end
