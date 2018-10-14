defmodule Servus.PidStore do
  @moduledoc """
  Stores the currently running game logic pids per player.
  """
  require Logger

  def start_link do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  def put(player, pid) do
    Agent.update(__MODULE__, fn dict -> Map.put(dict, player, pid) end)
  end

  def get(player) do
    Agent.get(__MODULE__, fn dict -> Map.get(dict, player) end)
  end

  def remove(player) do
    Agent.update(__MODULE__, fn dict -> Map.delete(dict, player) end)
  end
end
