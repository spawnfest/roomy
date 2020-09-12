defmodule Roomy.RoomServer do
  @moduledoc """
  Keeps the state in memory and allow multiple players to interact with the same state.

  It keeps all players updated through PubSub

  Right now we have one single genserver for the room and all other "things" in the room,
  but the idea was that things that hold internal state could have their own GenServer and
  players would interact directly with these servers.

  Later we will probably improve the process structure and have more process for diferrent
  parts of the system.

  Also, things are pretty "specialized" (tvs are being stored in `:tvs`). We will probably
  introduce a few protocols to allow some sort of generalization and polymorphism.
  """

  use GenServer

  alias Roomy.RoomState

  defstruct [:room_state, :ids_by_pid]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %__MODULE__{room_state: RoomState.with_sample_map(), ids_by_pid: %{}}}
  end

  def join(player_id) do
    GenServer.call(__MODULE__, {:join, player_id, self()})
  end

  def move(player_id, direction) when direction in ~w(north south east west)a do
    GenServer.cast(__MODULE__, {:move, player_id, direction})
  end

  def change_tv_channel(tv_id, player_id, {:twitch, channel}) do
    GenServer.cast(__MODULE__, {:change_tv_channel, tv_id, player_id, {:twitch, channel}})
  end

  def change_tv_channel(tv_id, player_id, nil) do
    GenServer.cast(__MODULE__, {:change_tv_channel, tv_id, player_id, nil})
  end

  def play_table(table_id, player_id, pos) do
    GenServer.cast(__MODULE__, {:play_table, table_id, player_id, pos})
  end

  def restart_table(table_id, player_id) do
    GenServer.cast(__MODULE__, {:restart_table, table_id, player_id})
  end

  def get_room_state do
    GenServer.call(__MODULE__, :get_room_state)
  end

  def handle_call(:get_room_state, _from, state) do
    {:reply, state.room_state, state}
  end

  def handle_call({:join, player_id, pid}, _from, state) do
    new_room_state = RoomState.join(state.room_state, player_id, 1, 1)

    Process.monitor(pid)

    Phoenix.PubSub.broadcast!(Roomy.PubSub, "room", new_room_state)

    new_state = %__MODULE__{
      room_state: new_room_state,
      ids_by_pid: Map.put(state.ids_by_pid, pid, player_id)
    }

    {:reply, new_room_state, new_state}
  end

  def handle_cast({:move, player_id, direction}, state) do
    new_room_state = RoomState.move(state.room_state, player_id, direction)
    Phoenix.PubSub.broadcast!(Roomy.PubSub, "room", new_room_state)
    {:noreply, %__MODULE__{state | room_state: new_room_state}}
  end

  def handle_cast({:change_tv_channel, tv_id, player_id, channel}, state) do
    new_room_state = RoomState.change_tv_channel(state.room_state, tv_id, player_id, channel)
    Phoenix.PubSub.broadcast!(Roomy.PubSub, "room", new_room_state)
    {:noreply, %__MODULE__{state | room_state: new_room_state}}
  end

  def handle_cast({:play_table, table_id, player_id, pos}, state) do
    new_room_state = RoomState.play_table(state.room_state, table_id, player_id, pos)
    Phoenix.PubSub.broadcast!(Roomy.PubSub, "room", new_room_state)
    {:noreply, %__MODULE__{state | room_state: new_room_state}}
  end

  def handle_cast({:restart_table, table_id, player_id}, state) do
    new_room_state = RoomState.restart_table(state.room_state, table_id, player_id)
    Phoenix.PubSub.broadcast!(Roomy.PubSub, "room", new_room_state)
    {:noreply, %__MODULE__{state | room_state: new_room_state}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_room_state = RoomState.leave(state.room_state, Map.get(state.ids_by_pid, pid))
    Phoenix.PubSub.broadcast!(Roomy.PubSub, "room", new_room_state)
    {:noreply, %__MODULE__{state | room_state: new_room_state}}
  end
end
