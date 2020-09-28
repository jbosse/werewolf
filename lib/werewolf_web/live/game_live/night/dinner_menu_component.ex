defmodule WerewolfWeb.GameLive.Night.DinnerMenuComponent do
  use WerewolfWeb, :live_component

  alias Werewolf.Game

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("night/dinner_menu.html", assigns)
  end
end
