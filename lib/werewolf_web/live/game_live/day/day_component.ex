defmodule WerewolfWeb.GameLive.Day.DayComponent do
  use WerewolfWeb, :live_component

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("day/day.html", assigns)
  end
end
