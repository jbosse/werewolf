defmodule WerewolfWeb.GameLive.Night.SeerComponent do
  use WerewolfWeb, :live_component

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("night/seer.html", assigns)
  end
end
