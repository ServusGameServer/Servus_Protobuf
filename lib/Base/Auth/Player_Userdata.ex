defmodule Servus.Player_Userdata do
  @moduledoc """

  """
  alias Servus.{Repo, PlayerUserdata}
  use Servus.Module
  require Logger
  import Ecto.Query, only: [from: 2]
  @configPUD Application.get_env(:servus, :player_userdata)
  # No Testmode memory for player
  register(:AUTH_USERDATA)

  @doc """
   Create SQL DB Connection
   Create Table Players @ Startup if needed
   Adds Fiels to Table if needed
  """
  def startup() do
    Logger.info("Player_userdata module registered")
  end

  react :AUTH_PICTURE, args, clientHandle, state do
    Logger.info("FB_Picutre for id #{args}")

    query =
      from(
        pU in PlayerUserdata,
        where: pU.player_id == ^args,
        select: %{mainpicture: pU.mainpicture, player_id: pU.player_id}
      )

    response = Repo.one(query)
    Logger.debug("DB Response for player_userdata query #{inspect(response)}")

    case response do
      %{mainpicture: mainpicture, player_id: id} ->
        case File.read("#{@configPUD.picturepath}/#{mainpicture}") do
          {:ok, fileRawValue} ->
            Logger.info("Fileread complete")
            %{result_code: :ok, value: {:value_UDataPicture, %LoadedProtobuf.Userdata_GetPicture{id: args, value_Bytes: fileRawValue}}}

          _ ->
            Logger.info("Other Error: Filereading?!?")
            %{result_code: :error, errorMessage: nil, errorType: :ERROR_NOT_FOUND}
        end

      nil ->
        %{result_code: :ok, value: {:value_UData, %LoadedProtobuf.Userdata_GetPicture{id: args, reason: :USERDATA_REASONS_NO_PIC}}}

      _ ->
        %{result_code: :error, errorMessage: nil, errorType: :ERROR_GENERIC}
    end
  end

  @doc """
    Generic Error Handler
  """
  react _, _ = args, clientHandle, state do
    %{result_code: :error, errorMessage: nil, errorType: :ERROR_WRONGMETHOD}
  end
end
