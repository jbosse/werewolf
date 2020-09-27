defmodule WerewolfWeb.GameLive.Night.WerewolfComponent do
  use WerewolfWeb, :live_component

  alias Werewolf.Game

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("night/werewolf.html", assigns)
  end
end
