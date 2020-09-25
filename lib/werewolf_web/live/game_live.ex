defmodule WerewolfWeb.GameLive do
  use WerewolfWeb, :live_view

  @impl true
  def mount(%{"name" => name}, _session, socket) do
    with {:ok, game} <- Werewolf.GameStore.get(name) do
      {:ok, assign(socket, game: game)}
    else
      _ -> {:error, assign(socket, game: %{})}
    end
  end

  def handle_params(_unsigned_params, uri, socket) do
    parsed = URI.parse(uri)

    {:noreply,
     assign(socket, uri: "#{parsed.scheme}://#{parsed.host}:#{parsed.port}#{parsed.path}")}
  end
end
