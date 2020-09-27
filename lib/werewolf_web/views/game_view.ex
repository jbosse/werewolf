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

  defp get_player(_session_id, []), do: nil
  defp get_player(session_id, [%Player{:uuid => session_id} = player | _]), do: player
  defp get_player(session_id, [_ | players]), do: get_player(session_id, players)
end
