defmodule Servus.Serverutils.TCP do
  require Logger

  @moduledoc """
  Implementation of send/3 and recv/2 for TCP sockets
  """

  @doc """
  Returns IP address associated with a socket (usually the
  client socket)
  """
  def get_address(socket) do
    {:ok, {address, _}} = :inet.peername(socket)
    address |> Tuple.to_list() |> Enum.join(".")
  end

  @doc """
  Sends a message via TCP socket. The message will always have
  the form `{"target":target, "type": type,"value": value}`
  """
  def send(socket, msgByte) do
    send_size = byte_size(msgByte)
    byte_to_send = <<send_size::integer-size(32)>>
    Logger.debug("Send TCP Size: #{inspect(send_size)}")
    :gen_tcp.send(socket, byte_to_send)
    :gen_tcp.send(socket, msgByte)
  end

  @doc """
  Wait for a message on a TCP socket. A timeout can be passed
  in the `opts`. The default timeout should be `:infinity`. If
  `opts[:parse]` is true then a data will be parsed as JSON and
  returned as a `Servus.Message` struct. Otherwise the data will
  be returned as string.
  """
  def recv(socket, opts) do
    length_result = :gen_tcp.recv(socket, 4, opts[:timeout])

    case length_result do
      {:ok, length_binary} ->
        <<length::integer-size(32)>> = length_binary
        Logger.debug("Recieve TCP size: #{inspect(length)}")
        # TBD Change to more flexible
        data_result = :gen_tcp.recv(socket, length, opts[:timeout])
        data_result

      _ ->
        length_result
    end
  end
end

defmodule Servus.Serverutils.Web do
  require Logger

  @doc """
  Returns IP address associated with a socket (usually the
  client socket)
  """
  def get_address(socket) do
    Servus.Serverutils.TCP.get_address(socket)
  end

  @doc """
  Sends a message via WebSocket. The message will always have
  the form `{type": type,"value": value}`
  """
  def send(socket, msgBytes) do
    Socket.Web.send(socket, {:text, msgBytes})
  end

  @doc """
  Wait for a message on a WebSocket connection. Other than TCP sockets
  this does not have a `:timeout` option. The `:parse` option however
  is available.
  """
  def recv(socket, opts) do
    result = Socket.Web.recv(socket)

    case result do
      {:ok, {:text, data}} ->
        {:ok, data}

      {:error, _reason} ->
        result

      _ ->
        {:error, :unknown}
    end
  end
end

defmodule Servus.Serverutils do
  @moduledoc """
  A facade to hide all actual socket interactions and provide the
  same API for TCP and WebSockets (and more to come? UDP?)

  Also contains some utility functions (`get_unique_id/0`)
  """

  alias Servus.Serverutils.Web
  alias Servus.Serverutils.TCP
  alias Servus.ModuleStore
  require Logger

  # IDs
  # ###############################################
  def get_unique_id(count) do
    :crypto.strong_rand_bytes(count) |> :crypto.bytes_to_integer()
  end

  # Strings Base64
  # ###############################################
  def get_unique_base64_str(count) do
    :crypto.strong_rand_bytes(count) |> :base64.encode()
  end

  ## HELPER for md5
  def get_md5_hex(initalString) do
    :crypto.hash(:md5, initalString) |> Base.encode16()
  end

  # ###############################################

  # Addresses
  # ###############################################
  def get_address(%Socket.Web{socket: socket}) do
    Web.get_address(socket)
  end

  def get_address(socket) do
    TCP.get_address(socket)
  end

  # ###############################################

  # Send / Receive
  # ###############################################
  def send(socket, msg) do
    Logger.debug("Send TCP Protomessage: #{inspect(msg)}")
    msgByte = LoadedProtobuf.ServusMessage.encode(msg)

    case socket.type do
      :tcp -> TCP.send(socket.raw, msgByte)
      :web -> Web.send(socket.raw, msgByte)
    end
  end

  def recv(socket, opts \\ [timeout: :infinity]) do
    case socket.type do
      :tcp -> TCP.recv(socket.raw, opts)
      :web -> Web.recv(socket.raw, opts)
    end
  end

  # ###############################################
  # DB Error HELPER
  def flattenDBError(error) do
    errors =
      for {key, {message, _}} <- error do
        "#{key} #{message}"
      end
  end

  # Module call
  # ###############################################
  @doc """
  # call
  """
  def call(msg, clientHandle) do
    pid = ModuleStore.get(msg.modul)

    if pid != nil and Process.alive?(pid) do
      {_, clearedfunctionID} = msg.functionID

      clearedValue =
        if msg.value != nil do
          {_, clearedValue} = msg.value
          clearedValue
        end

      returnValue = GenServer.call(pid, {clearedfunctionID, clearedValue, clientHandle, msg})
    else
      sendback = %LoadedProtobuf.ServusMessage{} |> Map.merge(msg)
      sendback = %{sendback | value: nil}
      sendback = %{sendback | error: true}
      sendback = %{sendback | errorMessage: "Modul not Found"}
      sendback = %{sendback | errorType: :ERROR_GENERIC}
      %{clientHandle: clientHandle, msg: sendback}
    end
  end

  # ###############################################
end
