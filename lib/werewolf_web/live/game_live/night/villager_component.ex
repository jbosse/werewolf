defmodule WerewolfWeb.GameLive.Night.VillagerComponent do
  use WerewolfWeb, :live_component

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("night/villager.html", assigns)
  end
end
