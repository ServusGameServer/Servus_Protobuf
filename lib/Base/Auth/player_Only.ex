defmodule Servus.Player_Only do
  @moduledoc """

  """
  alias Servus.Serverutils
  alias Servus.{Repo, PlayerLogin}
  use Servus.Module
  require Logger
  import Ecto.Query, only: [from: 2]

  register(:AUTH_ONLY)

  @doc """
   Create SQL DB Connection
   Create Table Players @ Startup if needed
  """
  def startup() do
    Logger.info("Player_only module registered")
  end

  @doc """
   Register new Client with nickanme
   Returns unique key and id for Logins etc --> Key should be saved in APP
  """
  react :AUTH_REGISTER, args, clientHandle, state do
    playerKey = Serverutils.get_unique_id(7)
    newPlayer = PlayerLogin.add_Player_Only(%PlayerLogin{}, %{nickname: args, internalPlayerKey: playerKey})
    response = Repo.insert(newPlayer)
    Logger.debug("DB Response for register insert #{inspect(response)}")

    case response do
      {:ok, responsePL} ->
        Logger.info("Create new player #{args} with id #{responsePL.id} and internalPlayerKey #{playerKey}")
        %{result_code: :ok, value: {:value_OnlyAuth, %LoadedProtobuf.ServusLogin_Only{id: responsePL.id, key: playerKey}}}

      {:error, responsePL} ->
        Logger.warn("Error Create new player #{args} and internalPlayerKey #{playerKey}")
        %{result_code: :error, errorMessage: Serverutils.flattenDBError(responsePL.errors), errorType: :ERROR_DB}

      _ ->
        %{result_code: :error, errorMessage: nil, errorType: :ERROR_GENERIC}
    end
  end

  @doc """
    Login with given ID(Account) and key --> From Register Process
    Creates Playerobj for Mainloop.
  """
  react :AUTH_LOGIN, %{id: _, key: _} = args, clientHandle, state do
    Logger.info("Player module login_only id #{args.id} and key #{args.key}")
    # Always delete if second Login false...
    auth = Map.delete(clientHandle, :auth)

    query =
      from(
        p in PlayerLogin,
        where: p.id == ^args.id and p.internalPlayerKey == ^args.key,
        select: %{nickname: p.nickname, id: p.id}
      )

    response = Repo.one(query)
    Logger.debug("DB Response for login query #{inspect(response)}")

    case response do
      %{id: id, nickname: nickname} ->
        auth_obj = %{
          name: nickname,
          # Right place for Socket .. Not Sure
          socket: clientHandle.socket,
          login_type: :self,
          id: id
        }

        Logger.info("Login new player #{nickname} with id #{id}")
        %{result_code: :ok, value: {:value_Bool, true}, clientHandle: Map.put(auth, :auth, auth_obj)}

      nil ->
        Logger.info("No positive Login player #{args.id} with key #{args.key}")
        %{result_code: :ok, value: {:value_Bool, false}, clientHandle: auth}

      _ ->
        %{result_code: :error, errorMessage: nil, errorType: :ERROR_GENERIC, clientHandle: auth}
    end
  end

  @doc """
    Generic Error Handler
  """
  react _, _ = args, clientHandle, state do
    %{result_code: :error, errorMessage: nil, errorType: :ERROR_WRONGMETHOD}
  end
end
