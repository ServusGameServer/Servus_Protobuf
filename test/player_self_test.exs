defmodule PlayerSelfTest do
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

  test "integration test (TCP) for the Player Self Module with register and login", context do
    mail = Serverutils.get_unique_base64_str(15) <> "@test.de"
    # Register new Account
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_SelfReg("John Doe", mail, Serverutils.get_md5_hex("Hello1234!")))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_Int, _}} = data
    # Login test with new account
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_SelfLog(mail, Serverutils.get_md5_hex("Hello1234!")))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_Bool, true}} = data
    # Login test with new account but wrong id
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_SelfLog("wrong@wrong.de", Serverutils.get_md5_hex("Hello1234!")))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_Bool, false}} = data
    # Login test with new account but wrong key
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_SelfLog(mail, Serverutils.get_md5_hex("Wrong!")))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_Bool, false}} = data
    # Login test with new account but wrong id and key
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_SelfLog("wrong@wrong.de", Serverutils.get_md5_hex("Wrong!")))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_Bool, false}} = data
  end
end
