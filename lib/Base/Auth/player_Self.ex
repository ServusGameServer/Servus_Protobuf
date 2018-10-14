defmodule Servus.Player_Self do
  @moduledoc """

  """
  alias Servus.Serverutils
  alias Servus.{Repo, PlayerLogin}
  use Servus.Module
  require Logger
  import Ecto.Query, only: [from: 2]

  register(:AUTH_SELF)

  @doc """
   Create SQL DB Connection
   Create Table Players @ Startup if needed
   Adds Fiels to Table if needed
  """
  def startup() do
    Logger.info("Player_self module registered")
  end

  @doc """
   Register new Client with email and password and nickname
   Returns id for Login
  """
  react :AUTH_REGISTER, %{email: _, nickname: _, password: _} = args, clientHandle, state do
    newPlayer = PlayerLogin.add_Player_Self(%PlayerLogin{}, %{nickname: args.nickname, email: args.email, passwortMD5Hash: args.password})
    response = Repo.insert(newPlayer)
    Logger.debug("DB Response for register insert #{inspect(response)}")

    case response do
      {:ok, responsePL} ->
        Logger.info("Create new player #{args.nickname} with id #{responsePL.id} and mail #{args.email}")
        %{result_code: :ok, value: {:value_Int, responsePL.id}}

      {:error, responsePL} ->
        Logger.warn("Error Create new player #{args.nickname} and mail #{args.email}")
        %{result_code: :error, errorMessage: Serverutils.flattenDBError(responsePL.errors), errorType: :ERROR_DB}

      _ ->
        %{result_code: :error, errorMessage: nil, errorType: :ERROR_GENERIC}
    end
  end

  @doc """
    Login with given email and Password --> From Register Process
    Creates Playerobj for Mainloop.
  """
  react :AUTH_LOGIN, %{email: _, password: _} = args, clientHandle, state do
    Logger.info("Player module login_self email #{args.email}")
    # Always delete if second Login false...
    auth = Map.delete(clientHandle, :auth)

    query =
      from(
        p in PlayerLogin,
        where: p.email == ^args.email and p.passwortMD5Hash == ^args.password,
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
        Logger.info("No positive Login player #{args.email}")
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
