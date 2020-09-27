defmodule WerewolfWeb.GameLive.Day.VillagerComponent do
  use WerewolfWeb, :live_component

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("day/villager.html", assigns)
  end
end
