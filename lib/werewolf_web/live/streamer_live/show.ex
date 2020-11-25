defmodule WerewolfWeb.StreamerLive.Show do
  use WerewolfWeb, :live_view

  alias Werewolf.GameStore

  @impl true
  def render(assigns) do
    WerewolfWeb.StreamerView.render("show.html", assigns)
  end

  @impl true
  def mount(%{"code" => code}, _, socket) do
    if socket |> connected?, do: GameStore.subscribe(code)

    with {:ok, game} <- GameStore.get(code) do
      {:ok, assign(socket, game: game)}
    else
      _ ->
        {:ok,
         socket
         |> put_flash(:error, "That room does not exist.")
         |> push_redirect(to: Routes.game_path(socket, :index))}
    end
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
end
