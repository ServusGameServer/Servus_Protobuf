defmodule PlayerOnlyTest do
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

  test "integration test (TCP) for the Player Only Module with register and login", context do
    # Register new Account
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_VString(:AUTH_ONLY, :AUTH_REGISTER, "John Doe"))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_OnlyAuth, %{id: id, key: key}}} = data
    # Login test with new account
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_OnlyReturn(id, key))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_Bool, true}} = data
    # Login test with new account but wrong id
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_OnlyReturn(6000, key))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_Bool, false}} = data
    # Login test with new account but wrong key
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_OnlyReturn(id, 44444))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_Bool, false}} = data
    # Login test with new account but wrong id and key
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_OnlyReturn(6000, 44444))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_Bool, false}} = data
  end
end
