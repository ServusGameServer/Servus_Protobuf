defmodule Servus.ClientHandler_AfterAuth do
  @moduledoc """
  Handles the socket connection of a client (player). All messages are
  received via tcp and interpreted as JSON.
  """
  alias Servus.Serverutils
  require Logger

  def run(clientHandle, decodedProtobuf) do
    if Map.has_key?(clientHandle, :auth) do
      case decodedProtobuf.modul do
        :DIRECTGAME ->
          Servus.ClientHandler_Game.run(clientHandle, decodedProtobuf)
          clientHandle

        :QUEUE ->
          Servus.ClientHandler_Queue.run(clientHandle, decodedProtobuf)

        _ ->
          Servus.ClientHandler_Modul.run(clientHandle, decodedProtobuf)
      end
    else
      # not Logged in --> ERROR
      sendback = %LoadedProtobuf.ServusMessage{} |> Map.merge(decodedProtobuf)
      sendback = %{sendback | value: nil}
      sendback = %{sendback | error: true}
      sendback = %{sendback | errorMessage: nil}
      sendback = %{sendback | errorType: :ERROR_NO_AUTH}
      Logger.warn("Call from Module but No Auth performed")
      Serverutils.send(clientHandle.socket, sendback)
      clientHandle
    end
  end
end
