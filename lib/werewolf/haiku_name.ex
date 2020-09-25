defmodule Werewolf.HaikuName do
  @doc """
  Generates a unique, URL-friendly name such as "bold-frog-8249".
  """
  def generate do
    [
      Enum.random(adjectives()),
      Enum.random(nouns()),
      :rand.uniform(9999)
    ]
    |> Enum.join("-")
  end

  def code() do
    lists = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.split("", trim: true)

    1..6
    |> Enum.reduce([], fn _, acc -> [Enum.random(lists) | acc] end)
    |> Enum.join("")
  end

  defp adjectives do
    ~w(
      autumn hidden bitter misty silent empty dry dark summer
      icy delicate quiet white cool spring winter patient
      twilight dawn crimson wispy weathered blue billowing
      broken cold damp falling frosty green long late lingering
      bold little morning muddy old red rough still small
      sparkling blinking shy wandering dying wild black
      young holy solitary fragrant aged snowy proud floral
      restless divine shiny ancient purple lively nameless
    )
  end

  defp nouns do
    ~w(
      waterfall river breeze moon rain wind sea morning
      snow lake sunset pine shadow leaf dawn glitter forest
      hill cloud meadow sun glade bird brook butterfly
      bush dew dust field fire flower firefly feather grass
      haze mountain night pond darkness snowflake silence
      sound sky shape surf thunder violet water wildflower
      wave water resonance sun wood dream cherry tree fog
      frost voice paper frog smoke star
    )
  end
end
