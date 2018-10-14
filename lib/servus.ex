defmodule Servus do
  @moduledoc """
  The `Servus` Modulare Server
  A simple, modular and universal backend
  """

  use Application
  require Logger

  # Entry point
  def start(_type, _args) do
    Servus.Supervisor.start_link()
  end
end
