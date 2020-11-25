defmodule WerewolfWeb.GameLive.Show do
  use WerewolfWeb, :live_view

  alias Werewolf.GameStore
  alias Werewolf.Game
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
      {:ok,
       assign(socket,
         game: game,
         session_id: session_id,
         connected_uuids: [],
         offer_requests: [],
         ice_candidate_offers: [],
         sdp_offers: [],
         answers: []
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
     |> assign(connected_uuids: list_present(socket.assigns.game.code))}
  end

  @impl true
  def handle_info({:game_saved, game}, socket) do
    {:noreply, socket |> update(:game, fn _ -> game end)}
  end

  @impl true
  def handle_event("begin_game", _params, socket) do
    game = socket.assigns.game
      |> Game.begin_game()
      |> GameStore.save()
    {:noreply, assign(socket, game: game, may_join: false)}
  end

  @impl true
  def handle_event("mark", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    game = socket.assigns.game
      |> Game.werewolf_vote(session_id, player_id)
      |> Game.check_for_eaten()
      |> Game.check_for_end_of_night()
      |> Game.check_for_winner()
      |> GameStore.save()
    {:noreply, assign(socket, game: game, may_join: false)}
  end

  def handle_event("unmark", %{"session-id" => session_id}, socket) do
    game = socket.assigns.game
      |> Game.werewolf_vote(session_id, nil)
      |> Game.check_for_end_of_night()
      |> Game.check_for_winner()
      |> GameStore.save()
    {:noreply, assign(socket, game: game, may_join: false)}
  end

  @impl true
  def handle_event("protect", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    game = socket.assigns.game
      |> Game.protect(session_id, player_id)
      |> Game.check_for_end_of_night()
      |> Game.check_for_winner()
      |> GameStore.save()
    {:noreply, assign(socket, game: game, may_join: false)}
  end

  @impl true
  def handle_event("divine", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    game = socket.assigns.game
      |> Game.divine(session_id, player_id)
      |> Game.check_for_end_of_night()
      |> Game.check_for_winner()
      |> GameStore.save()
    {:noreply, assign(socket, game: game, may_join: false)}
  end

  @impl true
  def handle_event("vote", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    game = socket.assigns.game
      |> Game.vote(session_id, player_id)
      |> Game.check_for_village_kill()
      |> Game.check_for_end_of_day()
      |> Game.check_for_winner()
      |> GameStore.save()
    {:noreply, assign(socket, game: game, may_join: false)}
  end

  defp list_present(code) do
    Presence.list("game:" <> code)
    # Phoenix Presence provides nice metadata, but we don't need it.
    |> Enum.map(fn {uuid, _} -> uuid end)
  end
end
