defmodule Werewolf.Player do
  defstruct uuid: nil,
            role: nil,
            screen_name: nil

  @type t() :: %__MODULE__{}

  alias Werewolf.Player

  def new() do
    %Player{
      uuid: UUID.uuid4()
    }
  end

  def new(uuid, screen_name) do
    %Player{
      uuid: uuid,
      screen_name: screen_name
    }
  end
end
