defmodule WerewolfWeb.GameLive.Day.DoctorComponent do
  use WerewolfWeb, :live_component

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("day/doctor.html", assigns)
  end
end
