defmodule Servus.ModuleStore do
  @moduledoc """
  Stores the pids of running modules.
  """
  def start_link do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  def register(module, pid) do
    Agent.update(__MODULE__, fn dict -> Map.put(dict, module, pid) end)
  end

  def get(module) do
    Agent.get(__MODULE__, fn dict -> Map.get(dict, module) end)
  end

  def getAll() do
    Agent.get(__MODULE__, fn dict -> dict end)
  end
end
