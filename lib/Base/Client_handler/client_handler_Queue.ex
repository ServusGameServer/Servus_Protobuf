defmodule Servus.ClientHandler_Queue do
  @moduledoc """
  Handles the socket connection of a client (player). All messages are
  received via tcp and interpreted as JSON.
  """
  alias Servus.PidStore
  alias Servus.Serverutils
  alias Servus.PlayerQueue
  alias Servus.ModuleStore
  require Logger

  def run(clientHandle, decodedProtobuf) do
    {_, clearedfunctionID} = decodedProtobuf.functionID

    case clearedfunctionID do
      :QUEUE_JOIN ->
        # TBD double join.... 
        pid =
          if decodedProtobuf.value != nil do
            {_, clearedValue} = decodedProtobuf.value
            ModuleStore.get(clearedValue)
          end

        if pid != nil do
          result = PlayerQueue.push(pid, clientHandle.auth)
          message = %{decodedProtobuf | value: {:value_String, "#{result}"}}
          # Just make sure that no error was given in orig msg
          message = %{decodedProtobuf | error: false}
          message = %{message | errorMessage: nil}
          message = %{message | errorType: nil}
          Serverutils.send(clientHandle.socket, message)
        else
          sendback = %LoadedProtobuf.ServusMessage{} |> Map.merge(decodedProtobuf)
          sendback = %{sendback | value: nil}
          sendback = %{sendback | error: true}
          sendback = %{sendback | errorMessage: nil}
          sendback = %{sendback | errorType: :ERROR_NO_GAME_QUEUE_FOUND}
          Logger.warn("Queue not found")
          Serverutils.send(clientHandle.socket, sendback)
        end

      :QUEUE_LEAVE ->
        pid = ModuleStore.get(:queue)
        PlayerQueue.remove(pid, clientHandle.auth)
        message = %{decodedProtobuf | value: {:value_String, "left"}}
        # Just make sure that no error was given in orig msg
        message = %{decodedProtobuf | error: false}
        message = %{message | errorMessage: nil}
        message = %{message | errorType: nil}
        Serverutils.send(clientHandle.socket, message)

      _ ->
        sendback = %LoadedProtobuf.ServusMessage{} |> Map.merge(decodedProtobuf)
        sendback = %{sendback | value: nil}
        sendback = %{sendback | error: true}
        sendback = %{sendback | errorMessage: nil}
        sendback = %{sendback | errorType: :ERROR_WRONGMETHOD}
        Logger.warn("Function not found for Queue")
        Serverutils.send(clientHandle.socket, sendback)
    end

    clientHandle
  end
end
