defmodule WebSocketServer do
  @moduledoc """
  Same as socket_server but fur web- instead of tcp sockets.
  """

  require Logger
  alias Servus.ClientHandler_Base_Proto
  alias Servus.Serverutils

  def start_link(port) do
    socket = Socket.Web.listen!(port)

    Logger.info("Accepting websocket connections on port #{port}")

    {:ok, spawn_link(fn -> accept(socket) end)}
  end

  def accept(socket) do
    client = Socket.Web.accept!(socket)
    Socket.Web.accept!(client)

    Logger.info("Incomming WebSocket connection from #{Serverutils.get_address(client)}")

    # Start a new client listener thread for the incoming connection
    Task.Supervisor.start_child(:client_handler_base, ClientHandler_Base_Proto, :run, [
      %{socket: %{raw: client, type: :web}}
    ])

    # Wait for the next connection
    accept(socket)
  end
end
