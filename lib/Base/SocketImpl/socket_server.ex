defmodule SocketServer do
  @moduledoc """
  Manages the connections on a socket for a single game
  backend. Each game backend has it's own SocketServer
  """

  require Logger
  alias Servus.Serverutils
  alias Servus.ClientHandler_Base_Proto

  def start_link(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :raw,
        active: false,
        reuseaddr: true
      ])

    Logger.info("Accepting tcp connections on port #{port}")

    {:ok, spawn_link(fn -> accept(socket) end)}
  end

  def accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("Incomming TCP connection from #{Serverutils.get_address(client)}")

    # Start a new client listener thread for the incoming connection
    Task.Supervisor.start_child(:client_handler_base, ClientHandler_Base_Proto, :run, [
      %{socket: %{raw: client, type: :tcp}}
    ])

    # Wait for the next connection
    accept(socket)
  end
end
