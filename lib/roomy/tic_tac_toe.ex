defmodule Roomy.TicTacToe do
  @moduledoc """
  Implements the logic behind a TicTacToe game.
  """

  @type mark :: :x | :o
  @type cell :: mark | nil
  @type row :: {cell(), cell(), cell()}
  @type board :: {row(), row(), row()}
  @type state :: {:playing, mark()} | {:won, mark()} | :draw
  @type game :: {state(), board()}
  @type t :: game()
  @type pos_component :: 0 | 1 | 2
  @type position :: {pos_component(), pos_component()}

  @empty_board {
    {nil, nil, nil},
    {nil, nil, nil},
    {nil, nil, nil}
  }

  @spec new(mark()) :: game()
  def new(start_with \\ :x) do
    {{:playing, start_with}, @empty_board}
  end

  @spec play(game(), position(), mark()) :: game()
  def play({{:playing, mark}, board} = game, {x, y}, mark)
      when mark in ~w(x o)a and x in [0, 1, 2] and y in [0, 1, 2] do
    case elem(elem(board, x), y) do
      nil ->
        board =
          :erlang.setelement(
            x + 1,
            board,
            :erlang.setelement(y + 1, elem(board, x), mark)
          )

        state = state_for(board, mark)

        {state, board}

      _ ->
        game
    end
  end

  def play(game, _, _), do: game

  def ended?({{:playing, _}, _}), do: false
  def ended?(_), do: true

  def mark_at({_, board}, {x, y}) do
    elem(elem(board, x), y)
  end

  @cross_positions [Enum.zip(0..2, 0..2), Enum.zip(0..2, 2..0)]
  @row_positions 0..2 |> Enum.map(fn x -> Enum.map(0..2, fn y -> {x, y} end) end)
  @col_positions 0..2 |> Enum.map(fn y -> Enum.map(0..2, fn x -> {x, y} end) end)

  @winning_positions @cross_positions ++ @row_positions ++ @col_positions

  def state_for(board, mark) do
    won =
      Enum.any?(@winning_positions, fn positions ->
        Enum.all?(positions, fn {x, y} ->
          elem(elem(board, x), y) == mark
        end)
      end)

    if won do
      {:won, mark}
    else
      room_left =
        board
        |> Tuple.to_list()
        |> Enum.flat_map(&Tuple.to_list/1)
        |> Enum.any?(&is_nil/1)

      if room_left do
        {:playing, next_player(mark)}
      else
        :draw
      end
    end
  end

  defp next_player(:x), do: :o
  defp next_player(:o), do: :x
end
