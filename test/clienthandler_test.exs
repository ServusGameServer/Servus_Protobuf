defmodule ClientHandlerTests do
  use ExUnit.Case
  alias Servus.Serverutils
  alias Servus.ProtoFactory

  setup_all do
    connect_opts = [
      :binary,
      packet: :raw,
      active: false,
      reuseaddr: true
    ]

    {:ok, socket_alice} = :gen_tcp.connect('localhost', 3334, connect_opts)

    {:ok,
     [
       alice: %{raw: socket_alice, type: :tcp, socket: "dummy"}
     ]}
  end

  test "Wrong ModuleName without Auth", context do
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions(:UNKNOWN, :AUTH_REGISTER))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: true, errorType: :ERROR_NO_AUTH} = data
  end

  test "Wrong ModuleName with Auth", context do
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_VString(:AUTH_ONLY, :AUTH_REGISTER, "JOHN DOE"))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_OnlyAuth, _}} = data
    # Logged in now
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions(:UNKNOWN, :AUTH_REGISTER))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: true, errorType: :ERROR_NO_AUTH} = data
  end

  test "Wrong FunctionName", context do
    # Wrong first Account
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions(:AUTH_SELF, :AUTH_UNKOWN))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: true, errorType: :ERROR_WRONGMETHOD} = data
  end
end
