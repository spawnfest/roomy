defmodule RoomyWeb.TVComponent do
  @moduledoc """
  Renders the TV control component.

  This contains the actual TV "stream" and the controls that show up when user is close to TV.
  """
  use RoomyWeb, :live_component

  alias Roomy.RoomServer
  alias Roomy.RoomState

  def render(assigns) do
    ~L"""
      <%= if @tv.channel do %>
        <div class="card-image">
        <figure class="image is-16by9">
          <iframe
            src="<%= iframe_url(@tv.channel) %>"
            style="position: absolute; top: 0; left: 0;"
            height="100%"
            width="100%"
            frameborder="no"
            scrolling="no"
            allowfullscreen="yes">
          </iframe>
          </figure>
        </div>
      <% end %>
      <div class="card-content">
        <div class="media">
          <div class="media-content">
            <p class="title is-4"><%= @tv.name %></p>
            <p class="subtitle is-6"><%= render_channel(@tv.channel) %></p>
          </div>
        </div>

        <%= if @can_change_tv? do %>
          <div class="content">
            <%= if @editing? do %>
              <form phx-submit="edit-complete" phx-target="<%= @myself %>">
                <div class="field">
                  <label class="label">Twitch Username</label>
                  <div class="control">
                    <input class="input" name="username" type="text" placeholder="Text input" value="<%= username(@tv.channel) %>">
                  </div>
                </div>

                <div class="field is-grouped">
                  <div class="control">
                    <button class="button is-link">Submit</button>
                  </div>
                  <div class="control">
                    <button
                    class="button is-link is-light"
                    phx-click="edit-cancel"
                    type="button"
                    phx-target="<%= @myself %>"
                  >
                    Cancel
                  </button>
                  </div>
                </div>
              </form>
            <% else %>
              <%= if @tv.channel do %>
                <div class="field is-grouped">
                  <div class="control">
                    <button
                      class="button is-link"
                      phx-click="edit"
                      phx-target="<%= @myself %>"
                    >
                      Change Channel
                    </button>
                  </div>
                  <div class="control">
                    <button
                      class="button is-link is-danger"
                      phx-click="turn-off"
                      phx-target="<%= @myself %>"
                    >
                      Turn Off
                    </button>
                  </div>
                </div>
              <% else %>
                <div class="field is-grouped">
                  <div class="control">
                    <button
                      class="button is-link"
                      phx-click="edit"
                      phx-target="<%= @myself %>"
                    >
                      Turn On
                    </button>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        <% end %>
      </div>
    """
  end

  def mount(socket) do
    socket =
      socket
      |> assign(:editing?, false)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:player_id, assigns.player_id)
      |> assign(:room_state, assigns.room_state)
      |> assign(:tv_id, assigns.tv_id)
      |> assign(
        :can_change_tv?,
        RoomState.can_change_tv?(assigns.room_state, assigns.player_id, assigns.tv_id)
      )
      |> assign(:tv, RoomState.get_object(assigns.room_state, assigns.tv_id))

    {:ok, socket}
  end

  def handle_event("edit", _, socket) do
    {:noreply, assign(socket, :editing?, true)}
  end

  def handle_event("edit-complete", %{"username" => username}, socket) do
    RoomServer.change_tv_channel(
      socket.assigns.tv_id,
      socket.assigns.player_id,
      {:twitch, sanitize_username(username)}
    )

    {:noreply, assign(socket, :editing?, false)}
  end

  def handle_event("edit-cancel", _, socket) do
    {:noreply, assign(socket, :editing?, false)}
  end

  def handle_event("turn-off", _, socket) do
    RoomServer.change_tv_channel(socket.assigns.tv_id, socket.assigns.player_id, nil)
    {:noreply, socket}
  end

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  defp render_channel({:twitch, channel}) do
    "Twitch: @#{channel}"
  end

  defp render_channel(_) do
    "Off"
  end

  defp username({:twitch, channel}), do: URI.decode(channel)
  defp username(_), do: ""

  defp iframe_url({:twitch, channel}),
    do:
      "https://player.twitch.tv/?channel=#{channel}&parent=localhost&parent=f824511dcf3d.ngrok.io"

  defp iframe_url(_), do: ""

  defp sanitize_username(username) do
    URI.encode(username)
  end
end
