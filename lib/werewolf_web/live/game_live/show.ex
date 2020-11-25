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
    game = socket.assigns.game |> Game.begin_game() |> GameStore.save()
    {:noreply, assign(socket, game: game, may_join: false)}
  end

  @impl true
  def handle_event("mark", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    game = socket.assigns.game
      |> Game.werewolf_vote(session_id, player_id)
      |> Game.check_for_eaten()
      |> Game.check_for_end_of_round()
      |> Game.check_for_winner()
      |> GameStore.save()
    {:noreply, assign(socket, game: game, may_join: false)}
  end

  def handle_event("unmark", %{"session-id" => session_id}, socket) do
    game = socket.assigns.game
      |> Game.werewolf_vote(session_id, nil)
      |> Game.check_for_end_of_round()
      |> Game.check_for_winner()
      |> GameStore.save()
    {:noreply, assign(socket, game: game, may_join: false)}
  end

  @impl true
  def handle_event("protect", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    game = socket.assigns.game
      |> Game.protect(session_id, player_id)
      |> Game.check_for_end_of_round()
      |> Game.check_for_winner()
      |> GameStore.save()
    {:noreply, assign(socket, game: game, may_join: false)}
  end

  @impl true
  def handle_event("divine", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    game = socket.assigns.game
      |> Game.divine(session_id, player_id)
      |> Game.check_for_end_of_round()
      |> Game.check_for_winner()
      |> GameStore.save()
    {:noreply, assign(socket, game: game, may_join: false)}
  end

  @impl true
  def handle_event("vote", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    game = socket.assigns.game

    new_game =
      %Game{game | village_votes: [{session_id, player_id} | game.village_votes]}
      |> check_for_end_of_day()
      |> Game.check_for_winner()

    GameStore.save(new_game)
    {:noreply, assign(socket, game: new_game, may_join: false)}
  end

  defp list_present(code) do
    Presence.list("game:" <> code)
    # Phoenix Presence provides nice metadata, but we don't need it.
    |> Enum.map(fn {uuid, _} -> uuid end)
  end

  defp check_for_end_of_day(game) do
    number_of_villagers = Enum.count(game.players, fn p -> p.state == :alive end)
    number_of_votes = Enum.count(game.village_votes)

    cond do
      number_of_villagers == number_of_votes -> kill_werewolf(game)
      true -> game
    end
  end

  defp may_join(_session_id, players) when length(players) == 15, do: false
  defp may_join(_session_id, []), do: true
  defp may_join(session_id, [session_id]), do: false
  defp may_join(session_id, [session_id | _players]), do: false
  defp may_join(session_id, [_ | players]), do: may_join(session_id, players)

  defp kill_werewolf(game) do
    votes = game.village_votes
    tally = Enum.reduce(votes, %{}, fn {_, uuid}, acc -> Map.update(acc, uuid, 1, &(&1 + 1)) end)

    {winner, _} =
      Enum.reduce(tally, {:a, 0}, fn {k, v}, {acc_k, acc_v} ->
        cond do
          v > acc_v -> {k, v}
          true -> {acc_k, acc_v}
        end
      end)

    players =
      game.players
      |> Enum.map(fn p ->
        cond do
          p.uuid == winner -> Map.put(p, :state, :dead)
          true -> p
        end
      end)

    %Game{
      game
      | state: :night,
        players: players,
        villagers_kill: winner,
        werewolves_eat: nil,
        werewolf_votes: [],
        village_votes: [],
        doctor_heals: nil,
        seer_sees: nil
    }
  end
end
