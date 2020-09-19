defmodule Werewolf.RolesTest do
  use ExUnit.Case

  alias Werewolf.Roles

  doctest Roles

  test "will get roles for 6 players" do
    result = Roles.get(6)
    assert Enum.count(result) == 6
    assert result == [:seer, :doctor, :werewolf, :villager, :villager, :villager]
  end

  test "will get roles for 7 players" do
    result = Roles.get(7)
    assert Enum.count(result) == 7
    assert result == [:seer, :doctor, :werewolf, :villager, :villager, :villager, :villager]
  end

  test "will get roles for 8 players" do
    result = Roles.get(8)
    assert Enum.count(result) == 8

    assert result == [
             :seer,
             :doctor,
             :werewolf,
             :villager,
             :villager,
             :villager,
             :villager,
             :villager
           ]
  end

  test "will get roles for 9 players" do
    result = Roles.get(9)
    assert Enum.count(result) == 9

    assert result == [
             :seer,
             :doctor,
             :werewolf,
             :villager,
             :villager,
             :villager,
             :villager,
             :villager,
             :villager
           ]
  end

  test "will get roles for 10 players" do
    result = Roles.get(10)
    assert Enum.count(result) == 10

    assert result == [
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
  end

  test "will get roles for 11 players" do
    result = Roles.get(11)
    assert Enum.count(result) == 11

    assert result == [
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
  end

  test "will get roles for 12 players" do
    result = Roles.get(12)
    assert Enum.count(result) == 12

    assert result == [
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
             :villager,
             :villager
           ]
  end

  test "will get roles for 13 players" do
    result = Roles.get(13)
    assert Enum.count(result) == 13

    assert result == [
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
             :villager,
             :villager,
             :villager
           ]
  end

  test "will get roles for 14 players" do
    result = Roles.get(14)
    assert Enum.count(result) == 14

    assert result == [
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
  end

  test "will get roles for 15 players" do
    result = Roles.get(15)
    assert Enum.count(result) == 15

    assert result == [
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
end
