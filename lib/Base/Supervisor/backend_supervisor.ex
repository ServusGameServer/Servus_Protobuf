defmodule Servus.Backend.Supervisor do
  @moduledoc """
  Entry point for a single game backend. This is used by the main
  supervisor to start the backends.
  """
  @backends Application.get_env(:servus, :backends)
  require Logger
  def adapter_for(:tcp), do: SocketServer
  def adapter_for(:web), do: WebSocketServer

  def start_link(adapters) do
    import Supervisor.Spec

    children =
      Enum.map(adapters, fn {type, port} ->
        worker(adapter_for(type), [port])
      end)

    queues =
      Enum.map(@backends, fn backend ->
        backend = Application.get_env(:servus, backend)
        players = backend[:players_per_game]
        logic = backend[:implementation]
        # TBD
        queueImpl = backend[:queue_impl]
        queueName = backend[:queue_name]
        Servus.PlayerQueue.start_link(players, logic, queueName)
      end)

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
