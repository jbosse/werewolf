defmodule WerewolfWeb.GameLive.PlayerComponent do
  use WerewolfWeb, :live_component

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("player.html", assigns)
  end
end
