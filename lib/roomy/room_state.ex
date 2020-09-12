defmodule Roomy.RoomState do
  @moduledoc """
  Holds the state for a particular room and ensures invariants are not violated.
  """

  alias Roomy.Player
  alias Roomy.RoomState
  alias Roomy.TicTacToe
  alias Roomy.TicTacToeTable
  alias Roomy.TV

  @sample_walkable_map Enum.reverse([
                         [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0],
                         [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0],
                         [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
                       ])

  @sample_tiles Enum.reverse([
                  [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2],
                  [2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 3, 2],
                  [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
                ])

  @directions %{north: {0, 1}, south: {0, -1}, east: {1, 0}, west: {-1, 0}}

  defstruct players: %{},
            walkable_map: [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
            tiles: [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
            objects: []

  def with_sample_map do
    %__MODULE__{
      walkable_map: @sample_walkable_map,
      tiles: @sample_tiles,
      objects: [
        %TV{x: 1, y: 13, name: "TV 1"},
        %TV{x: 2, y: 13, name: "TV 2"},
        %TicTacToeTable{x: 4, y: 4, name: "XOXOXO"}
      ]
    }
  end

  def join(%RoomState{players: players} = state, player_id, x, y) do
    %RoomState{
      state
      | players: Map.put(players, player_id, %Player{id: player_id, x: x, y: y})
    }
  end

  def leave(%RoomState{players: players} = state, player_id) do
    %RoomState{state | players: Map.delete(players, player_id)}
  end

  def player_ids(%RoomState{players: players}) do
    for {_, %{id: id}} <- players, do: id
  end

  def player_position(%RoomState{players: players}, player_id) do
    with %{x: x, y: y} <- Map.get(players, player_id) do
      {x, y}
    end
  end

  def move(%RoomState{players: players} = state, player_id, dir) do
    with {:ok, {dx, dy}} <- Map.fetch(@directions, dir),
         {:ok, %{x: x, y: y} = player} <- Map.fetch(players, player_id),
         true <- can_walk?(state, x + dx, y + dy) do
      %RoomState{
        state
        | players: Map.put(players, player_id, %Player{player | x: x + dx, y: y + dy})
      }
    else
      _ ->
        state
    end
  end

  defp can_walk?(%RoomState{players: players, objects: objects, walkable_map: walkable_map}, x, y) do
    has_entity_in_position =
      Enum.any?(Map.values(players) ++ objects, fn
        %{x: ^x, y: ^y} -> true
        _ -> false
      end)

    walkable =
      with {:ok, row} <- Enum.fetch(walkable_map, y),
           {:ok, 1} <- Enum.fetch(row, x) do
        true
      else
        _ -> false
      end

    walkable && !has_entity_in_position
  end

  def players(%RoomState{players: players}) do
    Map.values(players)
  end

  def get_player(%RoomState{players: players}, id) do
    Map.get(players, id)
  end

  def get_object(%RoomState{objects: objects}, id) do
    Enum.at(objects, id)
  end

  def change_tv_channel(%RoomState{objects: objects} = state, object_id, player_id, channel) do
    with %TV{} = tv <- get_object(state, object_id),
         true <- can_change_tv?(state, player_id, object_id) do
      %RoomState{state | objects: List.replace_at(objects, object_id, %TV{tv | channel: channel})}
    else
      _ -> state
    end
  end

  def can_change_tv?(%RoomState{} = state, player_id, object_id) do
    with %TV{x: tv_x, y: tv_y} <- get_object(state, object_id),
         {player_x, player_y} <- player_position(state, player_id) do
      abs(player_x - tv_x) <= 1 && abs(player_y - tv_y) <= 1
    else
      _ ->
        false
    end
  end

  def restart_table(%RoomState{objects: objects} = state, object_id, player_id) do
    with %TicTacToeTable{game: game} = table <- get_object(state, object_id),
         true <- TicTacToe.ended?(game),
         player when not is_nil(player) <- table_player(state, player_id, object_id) do
      new_table = %TicTacToeTable{table | game: TicTacToe.new(player)}
      %RoomState{state | objects: List.replace_at(objects, object_id, new_table)}
    else
      _ -> state
    end
  end

  def play_table(%RoomState{objects: objects} = state, object_id, player_id, pos) do
    with %TicTacToeTable{game: game} = table <- get_object(state, object_id),
         player when not is_nil(player) <- table_player(state, player_id, object_id) do
      new_game = TicTacToe.play(game, pos, player)
      new_table = %TicTacToeTable{table | game: new_game}
      %RoomState{state | objects: List.replace_at(objects, object_id, new_table)}
    else
      _ -> state
    end
  end

  def table_player(%RoomState{} = state, player_id, object_id) do
    with %TicTacToeTable{x: table_x, y: table_y} <- get_object(state, object_id),
         {player_x, player_y} <- player_position(state, player_id) do
      case {player_x - table_x, player_y - table_y} do
        {-1, 0} ->
          :x

        {1, 0} ->
          :o

        _ ->
          nil
      end
    else
      _ ->
        nil
    end
  end
end
