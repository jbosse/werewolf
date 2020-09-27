defmodule WerewolfWeb.GameLive.Day.WerewolfComponent do
  use WerewolfWeb, :live_component

  alias Werewolf.Game

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("day/werewolf.html", assigns)
  end
end
