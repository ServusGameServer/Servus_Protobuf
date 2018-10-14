defmodule PlayerFBTest do
  use ExUnit.Case
  require Logger
  alias Servus.Serverutils
  alias Servus.ProtoFactory

  alias Servus.{Repo, Servus.PlayerLogin}
  import Ecto.Query, only: [from: 2]

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

  test "integration test (TCP) for the Player FB Module with register and login", context do
    # Register new Account
    assert %{body: body, headers: _, status_code: _} = HTTPotion.get("https://graph.facebook.com/v3.1/1216077065136886/accounts/test-users?id=106019590338239&access_token=1216077065136886|0b2b0ff3fde4bbe08fe58cd012904427")

    assert {:ok, data} = Poison.decode(body, keys: :atoms)
    profile = Repo.get_by(Servus.PlayerLogin, %{email: "watdncyirl_1533595025@tfbnw.net"})

    if profile != nil do
      profile_UData = Repo.get_by(Servus.PlayerUserdata, %{player_id: profile.id})

      if profile_UData != nil do
        Repo.delete(profile_UData)
        Repo.delete(profile)
      end
    end

    resp = Repo.get_by(Servus.PlayerLogin, %{email: "watdncyirl_1533595025@tfbnw.net"})
    assert resp == nil
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_FBReg("106019590338239", "#{Enum.at(data.data, 0).access_token}"))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_FBAuth, %{fb_id: _, token: token}}} = data

    # Login test with new account
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_FBLog("106019590338239", token))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_FBAuthResp, %{loginSucessful: true, reason: :FB_REASONS_UNKOWN}}} = data

    # Login test with wrong id account
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_FBLog("00000000000000", token))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_FBAuthResp, %{loginSucessful: false, reason: :FB_REASONS_ID_NOT_FOUND}}} = data
    # Login test with wrong token
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_FBLog("106019590338239", "_"))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_FBAuthResp, %{loginSucessful: false, reason: :FB_REASONS_ID_NOT_MATCHED_TO_TOKEN}}} = data
    # #Login test with wrong id and token
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_FBLog("00000000000000", "_"))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_FBAuthResp, %{loginSucessful: false, reason: :FB_REASONS_ID_NOT_FOUND}}} = data
  end

  test "special Test because of C# Unittests", context do
    assert :ok == Serverutils.send(context.alice, ProtoFactory.newMessage_authFunctions_FBLog("FALSE", "_FALSE"))
    assert {:ok, returnMessage} = Serverutils.recv(context.alice)
    data = LoadedProtobuf.ServusMessage.decode(returnMessage)
    assert %LoadedProtobuf.ServusMessage{error: false, value: {:value_FBAuthResp, %{loginSucessful: false, reason: :FB_REASONS_ID_NOT_FOUND}}} = data
  end
end
