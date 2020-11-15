defmodule Werewolf.Roles do
  @spec get(6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15) :: [
          :doctor | :seer | :villager | :werewolf,
          ...
        ]
  def get(6), do: [:seer, :doctor, :werewolf, :werewolf, :villager, :villager]
  def get(7), do: [:seer, :doctor, :werewolf, :werewolf, :villager, :villager, :villager]

  def get(8),
    do: [:seer, :doctor, :werewolf, :werewolf, :villager, :villager, :villager, :villager]

  def get(9),
    do: [
      :seer,
      :doctor,
      :werewolf,
      :werewolf,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager
    ]

  def get(10),
    do: [
      :seer,
      :doctor,
      :werewolf,
      :werewolf,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager
    ]

  def get(11),
    do: [
      :seer,
      :doctor,
      :werewolf,
      :werewolf,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager
    ]

  def get(12),
    do: [
      :seer,
      :doctor,
      :werewolf,
      :werewolf,
      :werewolf,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager
    ]

  def get(13),
    do: [
      :seer,
      :doctor,
      :werewolf,
      :werewolf,
      :werewolf,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager
    ]

  def get(14),
    do: [
      :seer,
      :doctor,
      :werewolf,
      :werewolf,
      :werewolf,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager
    ]

  def get(15),
    do: [
      :seer,
      :doctor,
      :werewolf,
      :werewolf,
      :werewolf,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager,
      :villager
    ]
end
