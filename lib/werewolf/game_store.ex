defmodule Werewolf.GameStore do
  use Werewolf.Store
  alias Werewolf.Game

  def save(%Game{code: code} = game) do
    persist(code, game)
  end
end
