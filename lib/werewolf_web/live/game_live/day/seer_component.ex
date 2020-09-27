defmodule WerewolfWeb.GameLive.Day.SeerComponent do
  use WerewolfWeb, :live_component

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("day/seer.html", assigns)
  end
end
