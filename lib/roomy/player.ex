defmodule Roomy.Player do
  @moduledoc """
  A player has an id and have a position on the map.
  """
  defstruct [:id, :x, :y]

  @type t() :: %__MODULE__{
          id: term(),
          x: integer(),
          y: integer()
        }
end
