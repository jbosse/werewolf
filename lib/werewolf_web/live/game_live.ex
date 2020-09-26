defmodule WerewolfWeb.GameLive do
  use WerewolfWeb, :live_view

  alias Werewolf.GameStore
  alias Werewolf.PlayerStore
  alias Werewolf.Game
  alias Werewolf.Player
  alias Werewolf.PubSub
  alias WerewolfWeb.Presence
  alias Phoenix.Socket.Broadcast

  def render(assigns) do
    WerewolfWeb.GameView.render("game_live.html", assigns)
  end

  @impl true
  def mount(%{"name" => name}, %{"session_id" => session_id}, socket) do
    IO.inspect(session_id)
    Phoenix.PubSub.subscribe(PubSub, "game:" <> name)
    {:ok, _} = Presence.track(self(), "game:" <> name, session_id, %{})

    with {:ok, game} <- GameStore.get(name) do
      {:ok,
       assign(socket,
         game: game,
         session_id: session_id,
         connected_uuids: [session_id],
         may_join: may_join(session_id, game.players)
       )}
    else
      _ ->
        {:ok,
         socket
         |> put_flash(:error, "That room does not exist.")
         |> push_redirect(to: Routes.game_path(socket, :index))}
    end
  end

  @impl true
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply,
     socket
     |> assign(connected_uuids: list_present(socket))}
  end

  @impl true
  def handle_event("join_game", %{"player" => %{"screen_name" => screen_name}}, socket) do
    player = Player.new(socket.assigns.session_id, screen_name)
    game = socket.assigns.game
    new_game = %Game{game | players: [player | game.players]}
    GameStore.save(new_game)
    {:noreply, assign(socket, game: new_game, may_join: false)}
  end

  defp list_present(socket) do
    Presence.list("game:" <> socket.assigns.game.code)
    # Phoenix Presence provides nice metadata, but we don't need it.
    |> Enum.map(fn {uuid, _} -> uuid end)
  end

  defp may_join(_session_id, players) when length(players) == 15, do: false
  defp may_join(_session_id, []), do: true
  defp may_join(session_id, [session_id]), do: false
  defp may_join(session_id, [session_id | _players]), do: false
  defp may_join(session_id, [_ | players]), do: may_join(session_id, players)
end
