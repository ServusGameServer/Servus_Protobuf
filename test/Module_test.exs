defmodule ServusModuleTest do
  use ExUnit.Case
  alias Servus.Serverutils
  alias Servus.ProtoFactory
  require Logger

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
       alice: %{raw: socket_alice, type: :tcp, socket: socket_alice}
     ]}
  end

  test "integration test (TCP) for ModuleEcho", context do
    # Register  Account
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_VString(:AUTH_ONLY, :AUTH_REGISTER, "John Doe"))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_OnlyAuth, %{id: id, key: key}}} = data
    # Login test with  account
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_OnlyReturn(id, key))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_Bool, true}} = data

    randomString = Serverutils.get_unique_base64_str(15)
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_testModule(randomString))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_String, randomStringReturn}} = data
    assert randomString == randomStringReturn
  end
end
