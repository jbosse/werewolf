defmodule Werewolf.PlayerStore do
  use Werewolf.Store
  alias Werewolf.Player

  def save(%Player{uuid: uuid} = player) do
    persist(uuid, player)
  end
end
