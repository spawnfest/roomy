defmodule RoomyWeb.RoomLive do
  @moduledoc """
  Renders the room the player is currently in.

  This also represents currently the "player session" and the "player" itself.
  In the future we'll likely move the player control to another process to implement things such as movement speed and
  the ability to switch between rooms without having the same user in multiple rooms.
  """

  use RoomyWeb, :live_view

  alias Roomy.RoomServer
  alias Roomy.RoomState
  alias Roomy.TV
  alias RoomyWeb.MapComponent
  alias RoomyWeb.TTTTComponent
  alias RoomyWeb.TVComponent

  def render(assigns) do
    ~L"""
      <div style="height: 100vh; width: <%= if @open_objects == [], do: 100, else: (if @expanded_object, do: 160, else: 120) %>vw; position: fixed; right: 0; top: 0">
        <%= live_component(@socket, MapComponent, room_state: @room_state, player_id: @player_id, id: @player_id) %>
      </div>
      <%= unless @open_objects == [] do %>
        <div style="width: <%= if @expanded_object, do: 60, else: 20 %>vw; padding: 2rem; overflow-y: auto; position: fixed; right: 0; max-height: 100vh">
          <%= for {object_kind, object_id} <- @open_objects do %>
            <div class="card" style="margin-bottom: 2rem; display: <%= if is_nil(@expanded_object) || @expanded_object == {object_kind, object_id}, do: :block, else: :none %>">
              <%= if object_kind == TV do %>
                <%= live_component(@socket, TVComponent, room_state: @room_state, player_id: @player_id, id: object_id, tv_id: object_id) %>
              <% else %>
                <%= live_component(@socket, TTTTComponent, room_state: @room_state, player_id: @player_id, id: object_id, object_id: object_id) %>
              <% end %>
              <footer class="card-footer">
                <%= if @expanded_object do %>
                  <a href="#" class="card-footer-item" phx-click="minimize-object">Minimize</a>
                <% else %>
                  <a href="#" class="card-footer-item" phx-value-id="<%= object_id %>" phx-click="expand-object">Expand</a>
                <% end %>
                <a href="#" class="card-footer-item" phx-value-id="<%= object_id %>" phx-click="close-object">Close</a>
              </footer>
            </div>
          <% end %>
        </div>
      <% end %>
    """
  end

  @spec mount(any, any, Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    player_id = :crypto.strong_rand_bytes(16) |> Base.encode64()

    room_state =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Roomy.PubSub, "room")
        Phoenix.PubSub.subscribe(Roomy.PubSub, "voice:#{player_id}")
        RoomServer.join(player_id)
      else
        RoomServer.get_room_state()
      end

    socket =
      socket
      |> assign(:player_id, player_id)
      |> assign(:room_state, room_state)
      |> assign(:open_objects, [])
      |> assign(:expanded_object, nil)

    {:ok, socket}
  end

  def handle_event("signal", %{"data" => data, "playerId" => player_id}, socket) do
    Phoenix.PubSub.broadcast!(
      Roomy.PubSub,
      "voice:#{player_id}",
      {:signal, data, socket.assigns.player_id}
    )

    {:noreply, socket}
  end

  def handle_event("click-object", %{"id" => object_id}, socket) do
    socket =
      with {object_id, ""} <- Integer.parse(object_id),
           %kind{} <- RoomState.get_object(socket.assigns.room_state, object_id) do
        open_objects = [
          {kind, object_id}
          | Enum.reject(socket.assigns.open_objects, &match?({_, ^object_id}, &1))
        ]

        assign(socket, :open_objects, open_objects)
      else
        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("close-object", %{"id" => object_id}, socket) do
    object_id =
      case Integer.parse(object_id) do
        {id, _} -> id
        _ -> nil
      end

    expanded_object = with {_, ^object_id} <- socket.assigns.expanded_object, do: nil
    open_objects = Enum.reject(socket.assigns.open_objects, &match?({_, ^object_id}, &1))

    socket =
      socket
      |> assign(:open_objects, open_objects)
      |> assign(:expanded_object, expanded_object)

    {:noreply, socket}
  end

  def handle_event("expand-object", %{"id" => object_id}, socket) do
    object = Enum.find(socket.assigns.open_objects, fn {_, id} -> to_string(id) == object_id end)

    {:noreply, assign(socket, :expanded_object, object)}
  end

  def handle_event("minimize-object", _, socket) do
    {:noreply, assign(socket, :expanded_object, nil)}
  end

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  def handle_info(%RoomState{} = room_state, socket) do
    {:noreply, assign(socket, :room_state, room_state)}
  end

  def handle_info({:signal, data, player_id}, socket) do
    {:noreply, push_event(socket, "signal", %{"data" => data, "playerId" => player_id})}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end
end
