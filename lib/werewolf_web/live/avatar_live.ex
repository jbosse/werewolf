defmodule WerewolfWeb.AvatarLive do
  use WerewolfWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       hair: :hair_1,
       hair_color: "#353547",
       face_color: "#FFC5B3",
       shirt_color: "#28914F"
     )}
  end
end
