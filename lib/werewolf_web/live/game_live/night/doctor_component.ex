defmodule WerewolfWeb.GameLive.Night.DoctorComponent do
  use WerewolfWeb, :live_component

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("night/doctor.html", assigns)
  end
end
