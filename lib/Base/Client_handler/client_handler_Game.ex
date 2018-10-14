defmodule Servus.ClientHandler_Game do
  @moduledoc """
  Handles the socket connection of a client (player). All messages are
  received via tcp and interpreted as JSON.
  """
  alias Servus.PidStore
  alias Servus.Serverutils
  alias Servus.PlayerQueue
  require Logger

  def run(clientHandle, decodedProtobuf) do
    pid = PidStore.get(decodedProtobuf.gameID)

    if(decodedProtobuf.gameID != "" and pid != nil) do
      # Call Game
      {_, clearedfunctionID} = decodedProtobuf.functionID
      {_, clearedValue} = decodedProtobuf.value
      :gen_fsm.send_event(pid, {clientHandle.auth.id, clearedfunctionID, clearedValue})
    else
      # not Logged in --> ERROR
      sendback = %LoadedProtobuf.ServusMessage{} |> Map.merge(decodedProtobuf)
      sendback = %{sendback | value: nil}
      sendback = %{sendback | error: true}
      sendback = %{sendback | errorMessage: nil}
      sendback = %{sendback | errorType: :ERROR_NO_GAME_FOUND}
      Logger.warn("GameId not found")
      Serverutils.send(clientHandle.socket, sendback)
    end
  end
end
