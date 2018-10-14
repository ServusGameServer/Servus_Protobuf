defmodule Servus.ClientHandler_Base_Proto do
  @moduledoc """
  Handles the socket connection of a client (player). All messages are
  received via tcp and interpreted as JSON.
  """
  alias Servus.PidStore
  alias Servus.PlayerQueue
  alias Servus.Serverutils
  require Logger
  @auth Application.get_env(:servus, :authMethods)

  def run(clientHandle) do
    case Serverutils.recv(clientHandle.socket) do
      {:ok, message} ->
        decodedProtobuf = LoadedProtobuf.ServusMessage.decode(message)
        Logger.debug("Decode ProtobufMessage: #{inspect(decodedProtobuf)}")

        case decodedProtobuf do
          %LoadedProtobuf.ServusMessage{} ->
            case decodedProtobuf.modul do
              :DIRECT ->
                run(handleDirectCall(clientHandle, decodedProtobuf))

              modul when modul in @auth ->
                %{clientHandle: newClientHandle, msg: msg} = Serverutils.call(decodedProtobuf, clientHandle)
                Serverutils.send(clientHandle.socket, msg)
                run(newClientHandle)

              _ ->
                run(Servus.ClientHandler_AfterAuth.run(clientHandle, decodedProtobuf))
            end

          _ ->
            Logger.warn("Invalid protobuf format: #{message}")
            run(clientHandle)
        end

      {:error, err} ->
        # Client has aborted the connection
        # De-register it's ID from the pid store
        if Map.has_key?(clientHandle, :player) do
          # Remove him from the queue in case he's still there
          PlayerQueue.remove(clientHandle.queue, clientHandle.player)

          pid = PidStore.get(clientHandle.player.id)

          if pid != nil do
            # Notify the game logic about the player disconnect
            :gen_fsm.send_all_state_event(pid, {:abort, clientHandle.player})

            # Remove the player from the registry
            PidStore.remove(clientHandle.player.id)

            Logger.info("Removed player from pid store")
          end
        end

        Logger.warn("Unexpected clientside abort Error: #{inspect(err)}")

      _ ->
        Logger.warn("Unexpeted Return from recv func")
    end
  end

  defp handleDirectCall(clientHandle, msg) do
    clientHandle
  end
end
