defmodule RoomyWeb.PlayerAvatarComponent do
  @moduledoc """
  Renders one player in the map with a circular video inside of it.
  """
  use RoomyWeb, :live_component

  def render(assigns) do
    ~L"""
      <svg>
        <defs>
          <clipPath id="avatar">
            <circle cx="20" cy="20" r="20" fill="#FFFFFF" />
          </clipPath>
        </defs>
        <circle
          cx="25"
          cy="25"
          r="20"
          fill="<%= if @player.id == @self.id, do: ~s(black), else: ~s(red) %>"
          stroke="black">
        </circle>
        <g transform="<%= if @player.id == @self.id, do: ~s{scale(-1, -1) translate(-45 -45)}, else: ~s{scale(1, -1) translate(5 -45)} %>">
          <foreignObject width="40" height="40" clip-path="url(#avatar)">
            <div style="width: 100%; height: 100%">
                <video
                  xmlns="http://www.w3.org/1999/xhtml"
                  id="avatar-<%= @player.id %>--video"
                  style="object-fit: cover; width: 100%; height: 100%"
                  height="100"
                  width="100"
                  data-player-id="<%= @player.id %>"
                  data-volume="<%= volume_for(@self.x, @self.y, @player.x, @player.y) %>"
                  data-initiator="<%= @player.id > @self.id %>"
                  phx-hook="<%= if @player.id != @self.id, do: ~s(VideoChat), else: ~s(VideoAvatar) %>"
                >
            </div>
          </foreignObject>
        </g>
      </svg>
    """
  end

  defp volume_for(my_x, my_y, their_x, their_y) do
    distance =
      max(
        0,
        :math.sqrt(:math.pow(abs(my_x - their_x), 2) + :math.pow(abs(my_y - their_y), 2)) - 3
      )

    floor(100.0 * :math.pow(0.8, distance))
  end
end
