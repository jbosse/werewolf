defmodule WerewolfWeb.GameLive.Show do
  use WerewolfWeb, :live_view

  alias Werewolf.GameStore
  alias Werewolf.PubSub
  alias WerewolfWeb.Presence
  alias Phoenix.Socket.Broadcast

  @impl true
  def render(assigns) do
    WerewolfWeb.GameView.render("show.html", assigns)
  end

  @impl true
  def mount(%{"code" => code}, %{"session_id" => session_id}, socket) do
    topic = "game:" <> code
    if socket |> connected?, do: GameStore.subscribe(code)

    {:ok, _} = Presence.track(self(), topic, session_id, %{})

    Phoenix.PubSub.subscribe(PubSub, "game:" <> code <> ":" <> session_id)

    with {:ok, game} <- GameStore.get(code) do
      {:ok, assign(socket, game: game, session_id: session_id, connected_uuids: [])}
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
     |> assign(connected_uuids: list_present(socket.assigns.game.code))}
  end

  @impl true
  def handle_info({:game_saved, game}, socket) do
    session_id = socket.assigns.session_id
    host_id = socket.assigns.game.host_id
    cond do
      session_id == host_id -> IO.inspect(game)
      true -> IO.puts(nil)
    end
    {:noreply, socket |> update(:game, fn _ -> game end)}
  end

  @impl true
  def handle_event("join_game",
      %{"player" => %{"screen_name" => screen_name}},
      %{assigns: %{session_id: session_id, game: game}} = socket
    ) do
    {:noreply, assign(socket, game: Werewolf.join_game(game, session_id, screen_name), may_join: false)}
  end

  @impl true
  def handle_event("begin_game", _params, socket) do
    socket.assigns.game
      |> Werewolf.begin_game()
      |> no_reply(socket)
  end

  @impl true
  def handle_event("mark", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    socket.assigns.game
      |> Werewolf.mark(session_id, player_id)
      |> no_reply(socket)
  end

  def handle_event("unmark", %{"session-id" => session_id}, socket) do
    socket.assigns.game
      |> Werewolf.unmark(session_id)
      |> no_reply(socket)
  end

  @impl true
  def handle_event("protect", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    socket.assigns.game
      |> Werewolf.protect(session_id, player_id)
      |> no_reply(socket)
  end

  @impl true
  def handle_event("divine", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    socket.assigns.game
      |> Werewolf.divine(session_id, player_id)
      |> no_reply(socket)
  end

  @impl true
  def handle_event("vote", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    socket.assigns.game
      |> Werewolf.vote(session_id, player_id)
      |> no_reply(socket)
  end

  defp no_reply(game, socket) do
    {:noreply, assign(socket, game: game)}
  end

  defp list_present(code) do
    Presence.list("game:" <> code)
    # Phoenix Presence provides nice metadata, but we don't need it.
    |> Enum.map(fn {uuid, _} -> uuid end)
  end
end
