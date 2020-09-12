defmodule Roomy.TicTacToeTable do
  @moduledoc """
  Keeps a reference to a video stream that can be watched together
  """

  alias Roomy.TicTacToe

  defstruct [:x, :y, name: "Main Table", game: TicTacToe.new()]

  @type t() :: %__MODULE__{
          game: TicTacToe.t(),
          x: integer(),
          y: integer(),
          name: String.t()
        }
end
