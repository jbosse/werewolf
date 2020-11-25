defmodule Werewolf do
  alias Werewolf.Game
  alias Werewolf.GameStore

  def new_game(host_id) do
    Game.new(host_id)
  end

  def begin_game(game) do
    game
      |> Game.begin_game()
      |> GameStore.save()
  end

  def mark(game, session_id, player_id) do
    game
      |> Game.werewolf_vote(session_id, player_id)
      |> Game.check_for_eaten()
      |> Game.check_for_end_of_night()
      |> Game.check_for_winner()
      |> GameStore.save()
  end

  def unmark(game, session_id) do
    game
      |> Game.werewolf_vote(session_id, nil)
      |> Game.check_for_end_of_night()
      |> Game.check_for_winner()
      |> GameStore.save()
  end

  def protect(game, session_id, player_id) do
    game
      |> Game.protect(session_id, player_id)
      |> Game.check_for_end_of_night()
      |> Game.check_for_winner()
      |> GameStore.save()
  end

  def divine(game, session_id, player_id) do
    game
      |> Game.divine(session_id, player_id)
      |> Game.check_for_end_of_night()
      |> Game.check_for_winner()
      |> GameStore.save()
  end

  def vote(game, session_id, player_id) do
    game
      |> Game.vote(session_id, player_id)
      |> Game.check_for_village_kill()
      |> Game.check_for_end_of_day()
      |> Game.check_for_winner()
      |> GameStore.save()
  end
end
