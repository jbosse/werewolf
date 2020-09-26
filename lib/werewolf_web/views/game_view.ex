defmodule WerewolfWeb.GameView do
  use WerewolfWeb, :view

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
end
