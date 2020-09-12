defmodule Roomy.RoomStateTest do
  use ExUnit.Case

  alias Roomy.RoomState
  alias Roomy.TV

  describe "player_position/2" do
    test "returns nil for unknown player" do
      assert nil == RoomState.player_position(%RoomState{}, "1")
    end
  end

  describe "join/2" do
    test "adds player to player list when joining" do
      x = Enum.random(1..10)
      y = Enum.random(1..10)
      player_id = 1..10 |> Enum.random() |> to_string()

      assert state = RoomState.join(%RoomState{}, player_id, x, y)
      assert [^player_id] = RoomState.player_ids(state)
      assert {^x, ^y} = RoomState.player_position(state, player_id)
    end

    test "adds a new player to a room with a player already there" do
      initial_state = RoomState.join(%RoomState{}, "1", 0, 0)
      assert state = RoomState.join(initial_state, "2", 0, 0)
      assert ["1", "2"] = state |> RoomState.player_ids() |> Enum.sort()
    end

    test "players are unique" do
      assert %RoomState{}
             |> RoomState.join("1", 0, 0)
             |> RoomState.join("1", 0, 0)
             |> RoomState.player_ids()
             |> Enum.to_list() == ["1"]
    end
  end

  describe "leave/2" do
    test "removes leaving player" do
      initial_state = Enum.reduce(["1", "2", "3"], %RoomState{}, &RoomState.join(&2, &1, 0, 0))
      assert state = RoomState.leave(initial_state, "2")
      assert ["1", "3"] = state |> RoomState.player_ids() |> Enum.sort()
    end
  end

  describe "move/3" do
    for {dir, x, y} <- [{:east, 2, 1}, {:west, 0, 1}, {:north, 1, 2}, {:south, 1, 0}] do
      test "moves player to the #{dir}" do
        initial_state = RoomState.join(%RoomState{}, "1", 1, 1)

        assert {unquote(x), unquote(y)} =
                 initial_state
                 |> RoomState.move("1", unquote(dir))
                 |> RoomState.player_position("1")
      end
    end

    test "moves only the requested player" do
      initial_state = Enum.reduce(["1", "2", "3"], %RoomState{}, &RoomState.join(&2, &1, 1, 1))
      state = RoomState.move(initial_state, "2", :east)
      assert {1, 1} = RoomState.player_position(state, "1")
      assert {1, 1} = RoomState.player_position(state, "3")
    end

    test "cannot move into another player" do
      initial_state = %RoomState{} |> RoomState.join("1", 0, 0) |> RoomState.join("2", 0, 1)
      state = RoomState.move(initial_state, "1", :north)
      assert {0, 0} = RoomState.player_position(state, "1")
    end

    test "cannot walk into unwalkable places" do
      initial_state =
        %RoomState{walkable_map: [[0, 0, 0], [0, 1, 1], [0, 0, 0]]}
        |> RoomState.join("1", 1, 1)

      for dir <- ~w(north south west)a do
        assert {1, 1} =
                 initial_state |> RoomState.move("1", dir) |> RoomState.player_position("1")
      end

      assert {2, 1} =
               initial_state |> RoomState.move("1", :east) |> RoomState.player_position("1")
    end

    test "cannot walk into a TV" do
      assert {0, 0} =
               %RoomState{objects: [%TV{x: 0, y: 1}]}
               |> RoomState.join("1", 0, 0)
               |> RoomState.move("1", :north)
               |> RoomState.player_position("1")
    end
  end
end
