defmodule WerewolfWeb.GameLive.Show do
  use WerewolfWeb, :live_view

  alias Werewolf.GameStore
  alias Werewolf.Game
  alias Werewolf.Player
  alias Werewolf.PubSub
  alias WerewolfWeb.Presence
  alias Phoenix.Socket.Broadcast

  def render(assigns) do
    WerewolfWeb.GameView.render("show.html", assigns)
  end

  @impl true
  def mount(%{"code" => code}, %{"session_id" => session_id}, socket) do
    topic = "game:" <> code
    if socket |> connected?, do: GameStore.subscribe(code)

    Phoenix.PubSub.subscribe(PubSub, topic)
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
  def handle_event("join_game", %{"player" => %{"screen_name" => screen_name}}, socket) do
    connect_to_players(
      socket.assigns.connected_uuids,
      socket.assigns.session_id,
      socket.assigns.game
    )

    player = Player.new(socket.assigns.session_id, screen_name)
    game = socket.assigns.game
    new_game = %Game{game | players: [player | game.players]}
    GameStore.save(new_game)
    {:noreply, assign(socket, game: new_game, may_join: false)}
  end

  defp connect_to_players(connected_uuids, session_id, game) do
    for user <- connected_uuids do
      send_direct_message(
        game.code,
        user,
        "request_offers",
        %{
          from_user: session_id
        }
      )
    end
  end

  defp already_joined(session_id, game) do
    case game.players |> Enum.find(fn p -> session_id == p.uuid end) do
      nil -> false
      _ -> true
    end
  end

  @impl true
  def handle_event("begin_game", _params, socket) do
    game = socket.assigns.game
    new_game = begin_game(game)
    GameStore.save(new_game)
    {:noreply, assign(socket, game: new_game, may_join: false)}
  end

  @impl true
  def handle_event("mark", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    game = socket.assigns.game

    new_game =
      %Game{game | werewolf_votes: [{session_id, player_id} | game.werewolf_votes]}
      |> check_for_death()
      |> check_for_end_of_round()
      |> check_for_winner()

    GameStore.save(new_game)
    {:noreply, assign(socket, game: new_game, may_join: false)}
  end

  def handle_event("unmark", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    game = socket.assigns.game

    new_votes =
      game.werewolf_votes |> Enum.reject(fn {s, p} -> s == session_id && p == player_id end)

    new_game =
      %Game{game | werewolf_votes: new_votes}
      |> check_for_death()
      |> check_for_end_of_round()
      |> check_for_winner()

    GameStore.save(new_game)
    {:noreply, assign(socket, game: new_game, may_join: false)}
  end

  @impl true
  def handle_event("protect", %{"player-id" => player_id}, socket) do
    game = socket.assigns.game

    new_game =
      %Game{game | doctor_heals: player_id}
      |> check_for_end_of_round()
      |> check_for_winner()

    GameStore.save(new_game)
    {:noreply, assign(socket, game: new_game, may_join: false)}
  end

  @impl true
  def handle_event("divine", %{"player-id" => player_id}, socket) do
    game = socket.assigns.game

    new_game =
      %Game{game | seer_sees: player_id}
      |> divine_players()
      |> check_for_end_of_round()
      |> check_for_winner()

    GameStore.save(new_game)
    {:noreply, assign(socket, game: new_game, may_join: false)}
  end

  @impl true
  def handle_event("vote", %{"session-id" => session_id, "player-id" => player_id}, socket) do
    game = socket.assigns.game

    new_game =
      %Game{game | village_votes: [{session_id, player_id} | game.village_votes]}
      |> check_for_end_of_day()
      |> check_for_winner()

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

  defp begin_game(game) do
    players =
      game.players
      |> Enum.count()
      |> Werewolf.Roles.get()
      |> Enum.shuffle()
      |> Enum.zip(game.players)
      |> Enum.map(fn {role, player} -> %Player{player | role: role} end)

    %Game{game | state: :night, players: players}
  end

  defp check_for_death(game) do
    number_of_werewolves =
      Enum.count(game.players, fn p -> p.state == :alive && p.role == :werewolf end)

    number_of_werewolf_votes = Enum.count(game.werewolf_votes)

    cond do
      number_of_werewolves == number_of_werewolf_votes -> kill_villager(game)
      true -> game
    end
  end

  defp kill_villager(game) do
    number_of_werewolves =
      Enum.count(game.players, fn p -> p.state == :alive && p.role == :werewolf end)

    votes = game.werewolf_votes
    tally = Enum.reduce(votes, %{}, fn {_, uuid}, acc -> Map.update(acc, uuid, 1, &(&1 + 1)) end)

    {winner, votes} =
      Enum.reduce(tally, {:a, 0}, fn {k, v}, {acc_k, acc_v} ->
        cond do
          v > acc_v -> {k, v}
          true -> {acc_k, acc_v}
        end
      end)

    cond do
      number_of_werewolves == votes ->
        %Game{game | werewolves_eat: winner}

      true ->
        game
    end
  end

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

  defp check_for_end_of_round(game) do
    doctor_had_turn = game.doctor_heals != nil || get_doctor(game).state == :dead
    seer_had_turn = game.seer_sees != nil || get_seer(game).state == :dead
    werewolves_voted = game.werewolves_eat != nil

    cond do
      doctor_had_turn && seer_had_turn && werewolves_voted ->
        players =
          game.players
          |> Enum.map(fn p ->
            cond do
              p.uuid == game.werewolves_eat && game.doctor_heals != p.uuid ->
                Map.put(p, :state, :dead)

              true ->
                p
            end
          end)

        %Game{
          game
          | players: players,
            state: :day
        }

      true ->
        game
    end
  end

  defp check_for_winner(game) do
    number_of_werewolves =
      Enum.count(game.players, fn p -> p.state == :alive && p.role == :werewolf end)

    number_of_villagers =
      Enum.count(game.players, fn p -> p.state == :alive && p.role != :werewolf end)

    cond do
      number_of_werewolves == 0 ->
        %Game{game | winner: :villagers}

      number_of_werewolves == number_of_villagers ->
        %Game{game | winner: :werewolves}

      true ->
        game
    end
  end

  defp get_doctor(game) do
    game.players |> Enum.find(fn p -> p.role == :doctor end)
  end

  defp get_seer(game) do
    game.players |> Enum.find(fn p -> p.role == :seer end)
  end

  defp divine_players(game) do
    players =
      game.players
      |> Enum.map(fn p ->
        cond do
          p.uuid == game.seer_sees && p.role == :werewolf -> Map.put(p, :seen, :werewolf)
          p.uuid == game.seer_sees && p.role != :werewolf -> Map.put(p, :seen, :not_a_werewolf)
          true -> p
        end
      end)

    %Game{game | players: players}
  end

  @impl true
  @doc """
  When an offer request has been received, add it to the `@offer_requests` list.
  """
  def handle_info(%Broadcast{event: "request_offers", payload: request}, socket) do
    {:noreply,
     socket
     |> assign(:offer_requests, socket.assigns.offer_requests ++ [request])}
  end

  defp send_direct_message(code, to_user, event, payload) do
    WerewolfWeb.Endpoint.broadcast_from(
      self(),
      "game:" <> code <> ":" <> to_user,
      event,
      payload
    )
  end

  @impl true
  def handle_event("new_ice_candidate", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.session_id})

    send_direct_message(socket.assigns.game.code, payload["toUser"], "new_ice_candidate", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("new_sdp_offer", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.session_id})

    send_direct_message(socket.assigns.game.code, payload["toUser"], "new_sdp_offer", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("ensure_connected", _payload, socket) do
    if already_joined(socket.assigns.session_id, socket.assigns.game),
      do:
        connect_to_players(
          list_present(socket.assigns.game.code),
          socket.assigns.session_id,
          socket.assigns.game
        )

    {:noreply, socket}
  end

  @impl true
  def handle_event("new_answer", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.session_id})

    send_direct_message(socket.assigns.game.code, payload["toUser"], "new_answer", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%Broadcast{event: "new_ice_candidate", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:ice_candidate_offers, socket.assigns.ice_candidate_offers ++ [payload])}
  end

  @impl true
  def handle_info(%Broadcast{event: "new_sdp_offer", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:sdp_offers, socket.assigns.ice_candidate_offers ++ [payload])}
  end

  @impl true
  def handle_info(%Broadcast{event: "new_answer", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:answers, socket.assigns.answers ++ [payload])}
  end
end
