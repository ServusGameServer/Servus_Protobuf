defmodule ServusGameTest do
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
    {:ok, socket_bob} = :gen_tcp.connect('localhost', 3334, connect_opts)

    {:ok,
     [
       alice: %{raw: socket_alice, type: :tcp, socket: socket_alice},
       bob: %{raw: socket_bob, type: :tcp, socket: socket_bob}
     ]}
  end

  test "integration test (TCP) for 2P Game", context do
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
    # Join Queue P1
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_queueJoin("testGame_2p"))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:queuefunc, :QUEUE_JOIN}, value: {:value_String, "testGame_2p"}} = data
    # Register second  Account
    assert :ok == Serverutils.send(context.bob, ProtoFactory.newMessage_authFunctions_VString(:AUTH_ONLY, :AUTH_REGISTER, "Jane Doe"))
    assert {:ok, returnMessage} = Serverutils.recv(context.bob)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_OnlyAuth, %{id: id, key: key}}} = data
    # Login test second new account
    assert :ok == Serverutils.send(context.bob, ProtoFactory.newMessage_authFunctions_OnlyReturn(id, key))
    assert {:ok, returnMessage} = Serverutils.recv(context.bob)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_Bool, true}} = data
    # JOIN Queue P2
    assert :ok == Serverutils.send(context.bob, ProtoFactory.newMessage_queueJoin("testGame_2p"))
    assert {:ok, returnMessage} = Serverutils.recv(context.bob)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:testGamefunc, :TG_BEGIN}, value: {:value_String, "John Doe"}} = data
    assert {:ok, returnMessage} = Serverutils.recv(context.bob)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:queuefunc, :QUEUE_GAMEID}, value: {:value_String, gameID1}} = data
    assert {:ok, returnMessage} = Serverutils.recv(context.bob)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:queuefunc, :QUEUE_JOIN}, value: {:value_String, "testGame_2p"}} = data
    # StartGame P1
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:testGamefunc, :TG_BEGIN}, value: {:value_String, "Jane Doe"}} = data
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:queuefunc, :QUEUE_GAMEID}, value: {:value_String, gameID2}} = data
    assert gameID1 == gameID2
    # TestSend
    toSendValueP1 = Serverutils.get_unique_base64_str(15)
    toSendValueP2 = Serverutils.get_unique_base64_str(15)
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_testGame(gameID1, :TG_ECHO, toSendValueP1))
    assert :ok == Serverutils.send(context.bob, ProtoFactory.newMessage_testGame(gameID2, :TG_ECHO, toSendValueP2))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:testGamefunc, :TG_ECHO}, value: {:value_String, recievedValue}} = data
    assert toSendValueP2 == recievedValue
    assert {:ok, returnMessage} = Serverutils.recv(context.bob)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:testGamefunc, :TG_ECHO}, value: {:value_String, recievedValue}} = data
    assert toSendValueP1 == recievedValue
  end

  test "integration test (TCP) for 1P Game", context do
    toSendValue = Serverutils.get_unique_base64_str(15)
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
    # JOIN Queue
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_queueJoin("testGame_1p"))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:testGamefunc, :TG_BEGIN}, value: {:value_String, "John Doe"}} = data
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:queuefunc, :QUEUE_GAMEID}, value: {:value_String, gameID}} = data
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:queuefunc, :QUEUE_JOIN}, value: {:value_String, "testGame_1p"}} = data
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_testGame(gameID, :TG_ECHO, toSendValue))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, functionID: {:testGamefunc, :TG_ECHO}, value: {:value_String, recievedValue}} = data
    assert recievedValue == toSendValue
  end
end
