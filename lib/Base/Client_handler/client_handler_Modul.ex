defmodule Servus.ClientHandler_Modul do
  @moduledoc """
  Handles the socket connection of a client (player). All messages are
  received via tcp and interpreted as JSON.
  """
  alias Servus.PidStore
  alias Servus.Serverutils
  alias Servus.PlayerQueue
  require Logger

  def run(clientHandle, decodedProtobuf) do
    %{clientHandle: newClientHandle, msg: msg} = Serverutils.call(decodedProtobuf, clientHandle)
    Serverutils.send(clientHandle.socket, msg)
    newClientHandle
  end
end
