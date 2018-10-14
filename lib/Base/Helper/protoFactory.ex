defmodule Servus.ProtoFactory do
  require Logger

  def newMessage_authFunctions(module, func) do
    sendback = %LoadedProtobuf.ServusMessage{}
    sendback = %{sendback | value: nil}
    sendback = %{sendback | error: false}
    sendback = %{sendback | modul: module}
    sendback = %{sendback | functionID: {:authfunc, func}}
    sendback
  end

  def newMessage_authFunctions_VString(module, func, value) do
    sendback = %LoadedProtobuf.ServusMessage{}
    sendback = %{sendback | value: {:value_String, value}}
    sendback = %{sendback | error: false}
    sendback = %{sendback | modul: module}
    sendback = %{sendback | functionID: {:authfunc, func}}
    sendback
  end

  def newMessage_authFunctions_OnlyReturn(id, key) do
    sendback = %LoadedProtobuf.ServusMessage{}

    sendback = %{
      sendback
      | value: {:value_OnlyAuth, %LoadedProtobuf.ServusLogin_Only{id: id, key: key}}
    }

    sendback = %{sendback | error: false}
    sendback = %{sendback | modul: :AUTH_ONLY}
    sendback = %{sendback | functionID: {:authfunc, :AUTH_LOGIN}}
    sendback
  end

  def newMessage_authFunctions_SelfReg(nick, mail, pw) do
    sendback = %LoadedProtobuf.ServusMessage{}

    sendback = %{
      sendback
      | value:
          {:value_SelfAuth,
           %LoadedProtobuf.ServusLogin_Self{email: mail, nickname: nick, password: pw}}
    }

    sendback = %{sendback | error: false}
    sendback = %{sendback | modul: :AUTH_SELF}
    sendback = %{sendback | functionID: {:authfunc, :AUTH_REGISTER}}
    sendback
  end

  def newMessage_authFunctions_SelfLog(mail, pw) do
    sendback = %LoadedProtobuf.ServusMessage{}

    sendback = %{
      sendback
      | value: {:value_SelfAuth, %LoadedProtobuf.ServusLogin_Self{email: mail, password: pw}}
    }

    sendback = %{sendback | error: false}
    sendback = %{sendback | modul: :AUTH_SELF}
    sendback = %{sendback | functionID: {:authfunc, :AUTH_LOGIN}}
    sendback
  end

  def newMessage_authFunctions_FBReg(id, tok) do
    sendback = %LoadedProtobuf.ServusMessage{}

    sendback = %{
      sendback
      | value: {:value_FBAuth, %LoadedProtobuf.ServusLogin_FB{fb_id: id, token: tok}}
    }

    sendback = %{sendback | error: false}
    sendback = %{sendback | modul: :AUTH_FB}
    sendback = %{sendback | functionID: {:authfunc, :AUTH_REGISTER}}
    sendback
  end

  def newMessage_authFunctions_FBLog(id, tok) do
    sendback = %LoadedProtobuf.ServusMessage{}

    sendback = %{
      sendback
      | value: {:value_FBAuth, %LoadedProtobuf.ServusLogin_FB{fb_id: id, token: tok}}
    }

    sendback = %{sendback | error: false}
    sendback = %{sendback | modul: :AUTH_FB}
    sendback = %{sendback | functionID: {:authfunc, :AUTH_LOGIN}}
    sendback
  end

  def newMessage_testGame(gameID, func, value) do
    sendback = %LoadedProtobuf.ServusMessage{}
    sendback = %{sendback | value: {:value_String, value}}
    sendback = %{sendback | error: false}
    sendback = %{sendback | modul: :DIRECTGAME}
    sendback = %{sendback | gameID: "#{gameID}"}
    sendback = %{sendback | functionID: {:testGamefunc, func}}
    sendback
  end

  def newMessage_testModule(value) do
    sendback = %LoadedProtobuf.ServusMessage{}
    sendback = %{sendback | value: {:value_String, value}}
    sendback = %{sendback | error: false}
    sendback = %{sendback | modul: :TEST_ECHO}
    sendback = %{sendback | functionID: {:basicfunc, :BASIC_ECHO}}
    sendback
  end

  def newMessage_queueJoin(value) do
    sendback = %LoadedProtobuf.ServusMessage{}
    sendback = %{sendback | value: {:value_String, value}}
    sendback = %{sendback | error: false}
    sendback = %{sendback | modul: :QUEUE}
    sendback = %{sendback | functionID: {:queuefunc, :QUEUE_JOIN}}
    sendback
  end

  def newMessage_queueGameID(gameID) do
    sendback = %LoadedProtobuf.ServusMessage{}
    sendback = %{sendback | value: {:value_String, "#{gameID}"}}
    sendback = %{sendback | error: false}
    sendback = %{sendback | modul: :QUEUE}
    sendback = %{sendback | functionID: {:queuefunc, :QUEUE_GAMEID}}
    sendback
  end
end
