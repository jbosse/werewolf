defmodule WerewolfWeb.GameLive.Day.TribunalComponent do
  use WerewolfWeb, :live_component

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("day/tribunal.html", assigns)
  end
end
