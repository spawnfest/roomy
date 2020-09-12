defmodule Roomy.TV do
  @moduledoc """
  Keeps a reference to a video stream that can be watched together
  """

  defstruct [:channel, :x, :y, name: "Main Room"]
  @type channel() :: nil | {:twitch, String.t()}
  @type t() :: %__MODULE__{
          channel: channel(),
          x: integer(),
          y: integer(),
          name: String.t()
        }
end
