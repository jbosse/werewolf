defmodule WerewolfWeb.Plug.EnsureSessionUuid do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    case conn |> get_session(:session_id) do
      nil -> conn |> put_session(:session_id, UUID.uuid4())
      _ -> conn
    end
  end
end
