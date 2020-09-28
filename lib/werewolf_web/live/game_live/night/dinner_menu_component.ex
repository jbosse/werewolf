defmodule WerewolfWeb.GameLive.Night.DinnerMenuComponent do
  use WerewolfWeb, :live_component

  alias Werewolf.Game

  @spec render(any) :: any
  def render(assigns) do
    WerewolfWeb.GameView.render("night/dinner_menu.html", assigns)
  end

  @impl true
  def handle_event("nominate", params, socket) do
    IO.inspect(params)
    IO.inspect(socket.assigns)

    {:noreply,
     assign(socket, nominated: [params["screen-name"] | Map.get(socket.assigns, :nominated, [])])}
  end
end
