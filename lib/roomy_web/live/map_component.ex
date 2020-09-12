defmodule RoomyWeb.MapComponent do
  @moduledoc """
  Renders the room map by rendering the tiles, tvs and players.

  It also serves as the "input driver" by capturing user input and sending to game server.
  """
  use RoomyWeb, :live_component

  alias Roomy.RoomServer
  alias Roomy.RoomState
  alias Roomy.TicTacToeTable
  alias Roomy.TV
  alias RoomyWeb.PlayerAvatarComponent

  def render(assigns) do
    ~L"""
      <%= if @player do %>
        <svg
          phx-window-keydown="keydown"
          phx-target="<%= @myself %>"
          style="height: 100%; width: 100%"
          preserveAspectRatio="xMidYMin meet"
          shape-rendering="crispEdges"
          viewBox="<%= @player.x * 50 - 400 %> <%= @player.y * -50 - 300 %> 800 600"
        >
          <g transform="scale(1, -1)">
            <%= for row <- @tiles, tile <- row do %>
              <rect x="<%= tile.x * 50 %>" y="<%= tile.y * 50 %>" width="50" height="50" fill="<%= tile.fill %>"/>
            <% end %>

            <%= for {tv = %TV{}, id} <- @objects do %>
              <g transform="translate(<%= tv.x * 50 + 10 %> <%= tv.y * 50 + 10 %>)">
                <rect phx-click="click-object" phx-value-id="<%= id %>" width="30" height="30" fill="black"/>
              </g>
            <% end %>

            <%= for {table = %TicTacToeTable{}, id} <- @objects do %>
              <g transform="translate(<%= table.x * 50 + 10 %> <%= table.y * 50 + 10 %>)">
                <rect phx-click="click-object" phx-value-id="<%= id %>" width="30" height="30" fill="white"/>
                <line x1="10" y1="0" x2="10" y2="30" stroke="black" />
                <line x1="0" y1="10" x2="30" y2="10" stroke="black" />
                <line x1="20" y1="0" x2="20" y2="30" stroke="black" />
                <line x1="0" y1="20" x2="30" y2="20" stroke="black" />
              </g>
            <% end %>

            <%= for player <- @players do %>
              <g transform="translate(<%= player.x * 50 %> <%= player.y * 50 %>)" shape-rendering="geometricPrecision">
                <%= live_component(@socket, PlayerAvatarComponent, self: @player, player: player, id: player.id) %>
              </g>
            <% end %>
          </g>
        </svg>
      <% end %>
    """
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:player_id, assigns.player_id)
      |> assign(:room_state, assigns.room_state)
      |> assign(:tiles, render_tiles(assigns.room_state.tiles))
      |> assign(:objects, Enum.with_index(assigns.room_state.objects))
      |> assign(:players, RoomState.players(assigns.room_state))
      |> assign(:player, RoomState.get_player(assigns.room_state, assigns.player_id))

    {:ok, socket}
  end

  def handle_event("keydown", %{"key" => "Arrow" <> key_dir}, socket)
      when key_dir in ~w(Right Left Up Down) do
    RoomServer.move(
      socket.assigns.player_id,
      case key_dir do
        "Right" -> :east
        "Left" -> :west
        "Up" -> :north
        "Down" -> :south
      end
    )

    {:noreply, socket}
  end

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  defp render_tiles(rows) do
    for {row, y} <- Enum.with_index(rows) do
      for {tile, x} <- Enum.with_index(row) do
        %{
          x: x,
          y: y,
          fill: fill_for(tile)
        }
      end
    end
  end

  defp fill_for(1) do
    "lightgrey"
  end

  defp fill_for(2) do
    "darkgrey"
  end

  defp fill_for(3) do
    "peru"
  end

  defp fill_for(4) do
    "blue"
  end
end
