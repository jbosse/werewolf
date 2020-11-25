defmodule Werewolf.GameTest do
  use ExUnit.Case

  alias Werewolf.Game
  alias Werewolf.Player

  describe "Game" do
    test "will make a new game" do
      session_id = "blah"
      game = Game.new(session_id)
      assert game.code |> String.length == 6
      assert game.code |> String.match?(~r/[A-Z][A-Z][A-Z][A-Z][A-Z][A-Z]/)
      assert game.host_id == session_id
      assert game.players |> Enum.count == 0
    end

    test "will begin game" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        players: [
          %Player{uuid: "player1"},
          %Player{uuid: "player2"},
          %Player{uuid: "player3"},
          %Player{uuid: "player4"},
          %Player{uuid: "player5"},
          %Player{uuid: "player6"}
        ]
      }

      result = Game.begin_game(game)

      assert result.state == :night
      Enum.each(result.players, fn p -> assert p.role != nil end)
      assert Enum.count(result.players, fn p -> p.role == :seer end) == 1
      assert Enum.count(result.players, fn p -> p.role == :doctor end) == 1
      assert Enum.count(result.players, fn p -> p.role == :werewolf end) == 2
      assert Enum.count(result.players, fn p -> p.role == :villager end) == 2
    end
  end

  describe "Game.werewolf_vote" do
    test "will allow vote when no existing vote" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [],
      }

      result = Game.werewolf_vote(game, "player3", "player1")

      assert Enum.count(result.werewolf_votes) == 1
      assert Enum.count(result.werewolf_votes, fn {w, _p} -> w == "player3" end) == 1
      assert Game.werewolf_votes_for(result, "player1") == 1
    end

    test "will allow others to vote" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [{"player3", "player1"}],
      }

      result = Game.werewolf_vote(game, "player4", "player2")

      assert Enum.count(result.werewolf_votes) == 2
      assert Enum.count(result.werewolf_votes, fn {w, _p} -> w == "player3" end) == 1
      assert Enum.count(result.werewolf_votes, fn {w, _p} -> w == "player4" end) == 1
      assert Game.werewolf_votes_for(result, "player1") == 1
      assert Game.werewolf_votes_for(result, "player2") == 1
    end

    test "will not allow you to vote twice" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [{"player3", "player1"}],
      }

      result = Game.werewolf_vote(game, "player3", "player1")

      assert Enum.count(result.werewolf_votes) == 1
      assert Enum.count(result.werewolf_votes, fn {w, _p} -> w == "player3" end) == 1
      assert Game.werewolf_votes_for(result, "player1") == 1
    end

    test "will not allow you to vote for a dead player" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor, state: :dead},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [],
      }

      result = Game.werewolf_vote(game, "player3", "player2")

      assert Enum.count(result.werewolf_votes) == 0
    end

    test "will not allow you to vote if dead" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf, state: :dead},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [],
      }

      result = Game.werewolf_vote(game, "player3", "player2")

      assert Enum.count(result.werewolf_votes) == 0
    end

    test "will allow you to change your vote" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [{"player3", "player1"}, {"player4", "player1"}],
      }

      result = Game.werewolf_vote(game, "player3", "player2")

      assert Enum.count(result.werewolf_votes) == 2
      assert Enum.count(result.werewolf_votes, fn {w, _p} -> w == "player3" end) == 1
      assert Enum.count(result.werewolf_votes, fn {w, _p} -> w == "player4" end) == 1
      assert Game.werewolf_votes_for(result, "player1") == 1
      assert Game.werewolf_votes_for(result, "player2") == 1
    end

    test "will allow you to remove your vote" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [{"player4", "player1"}],
      }

      result = Game.werewolf_vote(game, "player3", nil)

      assert Enum.count(result.werewolf_votes) == 1
      assert Enum.count(result.werewolf_votes, fn {w, _p} -> w == "player3" end) == 0
      assert Enum.count(result.werewolf_votes, fn {w, _p} -> w == "player4" end) == 1
      assert Game.werewolf_votes_for(result, "player1") == 1
      assert Game.werewolf_votes_for(result, "player2") == 0
    end

    test "only werewolves vote" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [],
      }

      result = Game.werewolf_vote(game, "player5", "player1")

      assert Enum.count(result.werewolf_votes) == 0
    end
  end

  describe "Game.werewolves_killed" do
    test "when the werewolf vote is unanimous then return 'winner'" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [{"player3", "player1"}, {"player4", "player1"}],
      }

      assert {:ok, "player1"} == Game.werewolves_killed(game)
    end

    test "dead werewolves can't vote" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf, state: :dead},
          %Player{uuid: "player4", role: :werewolf, state: :alive},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [{"player4", "player2"}],
      }

      assert {:ok, "player2"} == Game.werewolves_killed(game)
    end

    test "when the werewolf vote is not unanimous then return undecided'" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [{"player3", "player1"}, {"player4", "player2"}],
      }

      assert :undecided == Game.werewolves_killed(game)
    end

    test "when the werewolf vote is not finished then return undecided'" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [{"player3", "player1"},],
      }

      assert :undecided == Game.werewolves_killed(game)
    end
  end

  describe "Game.check_for_eaten" do
    test "unanamous vote marks played as eaten" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [{"player3", "player1"}, {"player4", "player1"}],
      }

      result = Game.check_for_eaten(game)

      assert "player1" == result.werewolves_eat
    end

    test "undecied vote marks noone as eaten" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        werewolf_votes: [{"player3", "player1"}, {"player4", "player2"}],
      }

      result = Game.check_for_eaten(game)

      assert nil == result.werewolves_eat
    end
  end

  describe "Game.check_for_end_of_night" do
    test "round is not over if doctor hasn't healed" do

      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        seer_sees: "player2",
        doctor_heals: nil,
        werewolves_eat: "player6",
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.check_for_end_of_night(game)

      assert :night == result.state
    end

    test "round is not over if seer hasn't seen" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        seer_sees: nil,
        doctor_heals: "player2",
        werewolves_eat: "player6",
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.check_for_end_of_night(game)

      assert :night == result.state
    end

    test "round is not over if werewolves haven't eaten" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        seer_sees: "player2",
        doctor_heals: "player6",
        werewolves_eat: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.check_for_end_of_night(game)

      assert :night == result.state
    end

    test "round is over if seer sees, doctor heals, werewolves eat" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        seer_sees: "player2",
        doctor_heals: "player6",
        werewolves_eat: "player2",
        village_votes: [1,2,3],
        villagers_kill: "A",
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.check_for_end_of_night(game)

      assert :day == result.state
      assert result.village_votes == []
      assert result.villagers_kill == nil
    end

    test "round is over if seer is dead, doctor heals, werewolves eat" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        seer_sees: nil,
        doctor_heals: "player6",
        werewolves_eat: "player2",
        players: [
          %Player{uuid: "player1", role: :seer, state: :dead},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.check_for_end_of_night(game)

      assert :day == result.state
    end

    test "round is over if seer sees, doctor is dead, werewolves eat" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        seer_sees: "player6",
        doctor_heals: nil,
        werewolves_eat: "player2",
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor, state: :dead},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.check_for_end_of_night(game)

      assert :day == result.state
    end

    test "player eaten is dead when round is over" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        seer_sees: "player6",
        doctor_heals: "player2",
        werewolves_eat: "player5",
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.check_for_end_of_night(game)

      assert :dead == Enum.at(result.players, 4).state
    end

    test "player is seen when round is over" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        seer_sees: "player6",
        doctor_heals: "player2",
        werewolves_eat: "player5",
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.check_for_end_of_night(game)

      assert :villager == Enum.at(result.players, 5).seen
    end

    test "healed player is not eaten when round is over" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        seer_sees: "player6",
        doctor_heals: "player5",
        werewolves_eat: "player5",
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.check_for_end_of_night(game)

      assert :alive == Enum.at(result.players, 4).state
    end

    test "doctor cannot heal already dead" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        seer_sees: "player6",
        doctor_heals: "player5",
        werewolves_eat: "player6",
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager, state: :dead},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.check_for_end_of_night(game)

      assert :dead == Enum.at(result.players, 4).state
    end
  end

  describe "Game.check_for_winner" do
    test "werewolves win if two werewolves alive and only two others left" do
      game = %Game{
        winner: nil,
        players: [
          %Player{uuid: "player1", role: :seer, state: :dead},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager, state: :dead},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.check_for_winner(game)

      assert :werewolves == result.winner
    end

    test "werewolves win if one werewolves alive and only one other left" do
      game = %Game{
        winner: nil,
        players: [
          %Player{uuid: "player1", role: :seer, state: :dead},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf, state: :dead},
          %Player{uuid: "player5", role: :villager, state: :dead},
          %Player{uuid: "player6", role: :villager, state: :dead}
        ]
      }

      result = Game.check_for_winner(game)

      assert :werewolves == result.winner
    end

    test "werewolves win if more werewolves alive then others" do
      game = %Game{
        winner: nil,
        players: [
          %Player{uuid: "player1", role: :seer, state: :dead},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager, state: :dead},
          %Player{uuid: "player6", role: :villager, state: :dead}
        ]
      }

      result = Game.check_for_winner(game)

      assert :werewolves == result.winner
    end

    test "villagers win if all werewolves are dead" do
      game = %Game{
        winner: nil,
        players: [
          %Player{uuid: "player1", role: :seer, state: :dead},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf, state: :dead},
          %Player{uuid: "player4", role: :werewolf, state: :dead},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager, state: :dead}
        ]
      }

      result = Game.check_for_winner(game)

      assert :villagers == result.winner
    end

    test "no winner if werewolf lives and there are more villagers" do
      game = %Game{
        winner: nil,
        players: [
          %Player{uuid: "player1", role: :seer, state: :dead},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf, state: :dead},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager, state: :dead}
        ]
      }

      result = Game.check_for_winner(game)

      assert nil == result.winner
    end
  end

  describe "Game.protect" do
    test "doctor selects who is healed" do
      game = %Game{
        doctor_heals: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.protect(game, "player2", "player1")

      assert "player1" == result.doctor_heals
    end

    test "only doctor heals" do
      game = %Game{
        doctor_heals: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.protect(game, "player1", "player1")

      assert nil == result.doctor_heals
    end

    test "only living doctor heals" do
      game = %Game{
        doctor_heals: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor, state: :dead},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.protect(game, "player2", "player1")

      assert nil == result.doctor_heals
    end

    test "doctor only heals living" do
      game = %Game{
        doctor_heals: nil,
        players: [
          %Player{uuid: "player1", role: :seer, state: :dead},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.protect(game, "player2", "player1")

      assert nil == result.doctor_heals
    end

    test "doctor only heals player" do
      game = %Game{
        doctor_heals: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.protect(game, "player2", "player7")

      assert nil == result.doctor_heals
    end
  end

  describe "Game.divine" do
    test "seer selects who is seen" do
      game = %Game{
        seer_sees: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.divine(game, "player1", "player2")

      assert "player2" == result.seer_sees
    end

    test "only seer sees" do
      game = %Game{
        seer_sees: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.divine(game, "player2", "player1")

      assert nil == result.seer_sees
    end

    test "only living seer sees" do
      game = %Game{
        seer_sees: nil,
        players: [
          %Player{uuid: "player1", role: :seer, state: :dead},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.divine(game, "player1", "player2")

      assert nil == result.seer_sees
    end

    test "seer only sees living" do
      game = %Game{
        seer_sees: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor, state: :dead},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.divine(game, "player1", "player2")

      assert nil == result.seer_sees
    end

    test "seer only sees player" do
      game = %Game{
        seer_sees: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ]
      }

      result = Game.divine(game, "player1", "player7")

      assert nil == result.seer_sees
    end
  end

  describe "Game.vote" do
    test "will allow vote when no existing vote" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [],
      }

      result = Game.vote(game, "player3", "player1")

      assert Enum.count(result.village_votes) == 1
      assert Enum.count(result.village_votes, fn {v, _p} -> v == "player3" end) == 1
      assert Game.village_votes_for(result, "player1") == 1
    end

    test "will allow others to vote" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [{"player3", "player1"}],
      }

      result = Game.vote(game, "player4", "player2")

      assert Enum.count(result.village_votes) == 2
      assert Enum.count(result.village_votes, fn {v, _p} -> v == "player3" end) == 1
      assert Enum.count(result.village_votes, fn {v, _p} -> v == "player4" end) == 1
      assert Game.village_votes_for(result, "player1") == 1
      assert Game.village_votes_for(result, "player2") == 1
    end

    test "will not allow you to vote twice" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [{"player3", "player1"}],
      }

      result = Game.vote(game, "player3", "player1")

      assert Enum.count(result.village_votes) == 1
      assert Enum.count(result.village_votes, fn {v, _p} -> v == "player3" end) == 1
      assert Game.village_votes_for(result, "player1") == 1
    end

    test "will not allow you to vote for a dead player" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor, state: :dead},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [],
      }

      result = Game.vote(game, "player3", "player2")

      assert Enum.count(result.village_votes) == 0
    end

    test "will not allow you to vote if dead" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf, state: :dead},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [],
      }

      result = Game.vote(game, "player3", "player2")

      assert Enum.count(result.village_votes) == 0
    end

    test "will allow you to change your vote" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [{"player3", "player1"}, {"player4", "player1"}],
      }

      result = Game.vote(game, "player3", "player2")

      assert Enum.count(result.village_votes) == 2
      assert Enum.count(result.village_votes, fn {v, _p} -> v == "player3" end) == 1
      assert Enum.count(result.village_votes, fn {v, _p} -> v == "player4" end) == 1
      assert Game.village_votes_for(result, "player1") == 1
      assert Game.village_votes_for(result, "player2") == 1
    end

    test "will allow you to remove your vote" do
      game = %Game{
        code: "AAAAAA",
        host_id: "player1",
        state: :night,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [{"player4", "player1"}],
      }

      result = Game.vote(game, "player3", nil)

      assert Enum.count(result.village_votes) == 1
      assert Enum.count(result.village_votes, fn {v, _p} -> v == "player3" end) == 0
      assert Enum.count(result.village_votes, fn {v, _p} -> v == "player4" end) == 1
      assert Game.village_votes_for(result, "player1") == 1
      assert Game.village_votes_for(result, "player2") == 0
    end
  end

  describe "Game.villagers_killed" do
    test "vote isn't certified until all votes are cast even if majority" do
      game = %Game{
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [
          {"player3", "player1"},
          {"player4", "player1"},
          {"player5", "player1"},
          {"player6", "player1"}
        ],
      }

      assert :voting == Game.villagers_killed(game)
    end

    test "when the village vote is a majortiy then return 'winner'" do
      game = %Game{
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [
          {"player1", "player2"},
          {"player2", "player2"},
          {"player3", "player1"},
          {"player4", "player1"},
          {"player5", "player1"},
          {"player6", "player1"}
        ],
      }

      assert {:ok, "player1"} == Game.villagers_killed(game)
    end

    test "dead villagers can't stop the vote" do
      game = %Game{
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor, state: :dead},
          %Player{uuid: "player3", role: :werewolf, state: :dead},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager, state: :dead},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [
          {"player1", "player4"},
          {"player4", "player1"},
          {"player6", "player1"}
        ],
      }

      assert {:ok, "player1"} = Game.villagers_killed(game)
    end

    test "dead villagers votes dont count" do
      game = %Game{
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor, state: :dead},
          %Player{uuid: "player3", role: :werewolf, state: :dead},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager, state: :dead},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [
          {"player1", "player6"},
          {"player2", "player6"},
          {"player3", "player6"},
          {"player4", "player1"},
          {"player5", "player6"},
          {"player6", "player1"}
        ],
      }

      assert {:ok, "player1"} == Game.villagers_killed(game)
    end

    test "villagers don't choose a majority" do
      game = %Game{
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [
          {"player1", "player2"},
          {"player2", "player3"},
          {"player3", "player4"},
          {"player4", "player5"},
          {"player5", "player6"},
          {"player6", "player1"}
        ]
      }

      assert :undecided == Game.villagers_killed(game)
    end
  end

  describe "Game.check_for_village_kill" do
    test "majority vote marks player as killed" do
      game = %Game{
        villagers_kill: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor, state: :dead},
          %Player{uuid: "player3", role: :werewolf, state: :dead},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager, state: :dead},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [
          {"player1", "player6"},
          {"player2", "player6"},
          {"player3", "player6"},
          {"player4", "player1"},
          {"player5", "player6"},
          {"player6", "player1"}
        ],
      }

      result = Game.check_for_village_kill(game)

      assert "player1" == result.villagers_kill
    end

    test "still voting marks noone as killed" do
      game = %Game{
        villagers_kill: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [{"player3", "player1"}, {"player4", "player2"}],
      }

      result = Game.check_for_village_kill(game)

      assert nil == result.villagers_kill
    end

    test "no majority marks noone as killed" do
      game = %Game{
        villagers_kill: nil,
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
        village_votes: [
          {"player1", "player2"},
          {"player2", "player3"},
          {"player3", "player4"},
          {"player4", "player5"},
          {"player5", "player6"},
          {"player6", "player1"}
        ],
      }

      result = Game.check_for_village_kill(game)

      assert :undecided == result.villagers_kill
    end
  end

  describe "Game.check_for_end_of_day" do
    test "round is not over villager vote is not complete" do
      game = %Game{
        state: :day,
        villagers_kill: nil
      }

      result = Game.check_for_end_of_day(game)

      assert :day == result.state
    end

    test "round is over if villager vote is undecided" do
      game = %Game{
        state: :day,
        villagers_kill: :undecided
      }

      result = Game.check_for_end_of_day(game)

      assert :night == result.state
    end

    test "round is over if villagers kill" do
      game = %Game{
        state: :day,
        villagers_kill: "player1",
        werewolf_votes: [1,2,3],
        doctor_heals: "A",
        seer_sees: "B",
        werewolves_eat: "C",
        players: [
          %Player{uuid: "player1", role: :seer},
          %Player{uuid: "player2", role: :doctor},
          %Player{uuid: "player3", role: :werewolf},
          %Player{uuid: "player4", role: :werewolf},
          %Player{uuid: "player5", role: :villager},
          %Player{uuid: "player6", role: :villager}
        ],
      }

      result = Game.check_for_end_of_day(game)

      assert :night == result.state
      assert Enum.at(result.players, 0).state == :dead
      assert result.werewolf_votes == []
      assert result.doctor_heals == nil
      assert result.seer_sees == nil
      assert result.werewolves_eat == nil
    end
  end
end
