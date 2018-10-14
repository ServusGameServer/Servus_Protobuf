defmodule Servus.Supervisor do
  @moduledoc """
  Servus entry point. Reads the configuration file and starts all configured
  game backends accordingly.
  """

  @modules Application.get_env(:servus, :modules)
  @auth Application.get_env(:servus, :authMethods)
  @adapters Application.get_env(:servus, :adapters)
  require Logger

  def start_link do
    import Supervisor.Spec
    alias Servus.PlayerQueue
    # Common services used by all backends
    children = [
      worker(Servus.PidStore, []),
      worker(Servus.ModuleStore, []),
      worker(Servus.Player_Userdata, [[name: Player_Userdata]]),
      supervisor(Task.Supervisor, [[name: :client_handler_base]], id: :client_handler_base),
      supervisor(Task.Supervisor, [[name: :game_handler]], id: :game_handler),
      supervisor(Servus.Repo, []),
      supervisor(Servus.Backend.Supervisor, [@adapters])
    ]

    children =
      children ++
        if Enum.member?(@auth, :AUTH_FB) do
          [worker(Servus.Player_FB, [[name: Player_FB]])]
        end

    children =
      children ++
        if Enum.member?(@auth, :AUTH_SELF) do
          [worker(Servus.Player_Self, [[name: Player_Self]])]
        end

    children =
      children ++
        if Enum.member?(@auth, :AUTH_ONLY) do
          [worker(Servus.Player_Only, [[name: Player_Only]])]
        end

    # Create a list of all the modules that have to be
    # started
    modules =
      Enum.map(@modules, fn module ->
        worker(module, [[name: module]])
      end)

    # Start the common services and all backends
    Supervisor.start_link(children ++ modules, strategy: :one_for_one)
  end
end
