defmodule RoomyWeb.TTTTComponent do
  @moduledoc """
  Renders the TicTacToeTable control component.

  We are using the SVG from https://en.wikipedia.org/wiki/File:Tic_tac_toe.svg
  The page says it is in public domain
  """
  use RoomyWeb, :live_component

  alias Roomy.RoomServer
  alias Roomy.RoomState
  alias Roomy.TicTacToe

  def render(assigns) do
    ~L"""
      <div class="card-content">
          <svg
            style="height: 100%; width: 100%; max-height: 80vh;"
            preserveAspectRatio="xMidYMin meet"
            shape-rendering="crispEdges"
            viewBox="0 0 3 3"
          >
            <line x1="1" y1="0" x2="1" y2="3" stroke="black" stroke-width="0.05" />
            <line x1="0" y1="1" x2="3" y2="1" stroke="black" stroke-width="0.05" />
            <line x1="2" y1="0" x2="2" y2="3" stroke="black" stroke-width="0.05" />
            <line x1="0" y1="2" x2="3" y2="2" stroke="black" stroke-width="0.05" />
            <%= for x <- 0..2 do %>
              <%= for y <- 0..2 do %>
                <g transform="translate(<%= x %> <%= y %>)">
                  <rect
                    fill="transparent"
                    width="0.9"
                    height="0.9"
                    x="0.05"
                    y="0.05"
                    phx-target="<%= @myself %>"
                    phx-click="play"
                    phx-value-x="<%= x %>"
                    phx-value-y="<%= y %>"
                  />

                  <%= if TicTacToe.mark_at(@tic_tac_toe_table.game, {x, y}) == :x do %>
                    <line x1="0.1" y1="0.1" x2="0.9" y2="0.9" stroke="black" stroke-width="0.1" />
                    <line x1="0.1" y1="0.9" x2="0.9" y2="0.1" stroke="black" stroke-width="0.1" />
                  <% end %>

                  <%= if TicTacToe.mark_at(@tic_tac_toe_table.game, {x, y}) == :o do %>
                    <circle cx="0.5" cy="0.5" r="0.4" stroke-width="0.1" fill="transparent" stroke="black"></circle>
                  <% end %>
                </g>
              <% end %>
            <% end %>
          </svg>

          <%= if TicTacToe.ended?(@tic_tac_toe_table.game) do %>
            <h2><%= end_game_message(@tic_tac_toe_table.game) %></h2>
            <div class="field is-grouped">
              <div class="control">
                <button
                  class="button is-link"
                  phx-click="restart"
                  phx-target="<%= @myself %>"
                >
                  Restart
                </button>
              </div>
            </div>
          <% end %>
      </div>
    """
  end

  def update(assigns, socket) do
    table = RoomState.get_object(assigns.room_state, assigns.object_id)

    socket =
      socket
      |> assign(:player_id, assigns.player_id)
      |> assign(:room_state, assigns.room_state)
      |> assign(:object_id, assigns.object_id)
      |> assign(:tic_tac_toe_table, table)

    {:ok, socket}
  end

  def handle_event("play", %{"x" => x, "y" => y}, socket) do
    with {x, ""} <- Integer.parse(x),
         {y, ""} <- Integer.parse(y) do
      RoomServer.play_table(socket.assigns.object_id, socket.assigns.player_id, {x, y})
    end

    {:noreply, socket}
  end

  def handle_event("restart", _, socket) do
    RoomServer.restart_table(socket.assigns.object_id, socket.assigns.player_id)
    {:noreply, socket}
  end

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  defp end_game_message({:draw, _}), do: "Draw!"

  defp end_game_message({{:won, player}, _}),
    do: "#{player |> to_string() |> String.upcase()} Won!"

  defp end_game_message(_), do: "-"
end
