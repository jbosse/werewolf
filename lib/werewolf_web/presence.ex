defmodule WerewolfWeb.Presence do
  use Phoenix.Presence,
    otp_app: :werewolf,
    pubsub_server: Werewolf.PubSub
end
