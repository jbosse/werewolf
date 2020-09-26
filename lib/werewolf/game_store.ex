defmodule Werewolf.GameStore do
  use Werewolf.Store
  alias Werewolf.Game

  def save(%Game{code: code} = game) do
    persist(code, game)
    broadcast(:game_saved, game)
  end

  @spec subscribe(binary) :: :ok | {:error, {:already_registered, pid}}
  def subscribe(code) do
    Phoenix.PubSub.subscribe(Werewolf.PubSub, "game:" <> code)
  end

  defp broadcast(event, game) do
    Phoenix.PubSub.broadcast(Werewolf.PubSub, "game:" <> game.code, {event, game})
  end
end
