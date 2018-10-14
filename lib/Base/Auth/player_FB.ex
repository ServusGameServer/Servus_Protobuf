defmodule Servus.Player_FB do
  @moduledoc """

  """

  alias Servus.{Repo, PlayerLogin}
  alias Servus.{Repo, PlayerUserdata}
  use Servus.Module
  require Logger
  import Ecto.Query, only: [from: 2]

  @configFB Application.get_env(:servus, :facebook)
  @configPUD Application.get_env(:servus, :player_userdata)

  register(:AUTH_FB)

  @doc """
   Create SQL DB Connection
   Create Table Players @ Startup if needed
   Adds Fiels to Table if needed
  """
  def startup() do
    Logger.info("Player_FB module registered")
  end

  # @doc """
  # Check if given Facebook and ID are valid
  # Rund Facebook me with token
  # if token is valid check if id from request and id from functioncall are equal
  # """
  defp checkFBID(fb_id, token) do
    ffb_response = HTTPotion.get("https://graph.facebook.com/v3.1/me?fields=id&access_token=#{token}")
    Logger.info("https://graph.facebook.com/v3.1/me?fields=id&access_token=#{token}")
    Logger.info("Facebook response to token #{token} response #{inspect(ffb_response)}")

    case ffb_response do
      %{body: body, headers: _, status_code: _} ->
        try do
          poison_data = Poison.decode(body, keys: :atoms)

          case poison_data do
            {:ok, %{id: ffb_id}} ->
              if ffb_id == fb_id do
                Logger.info("Facebook identity check was sucessful")
                :ok
              else
                Logger.info("Not same ID #{fb_id} as fb_ID #{ffb_id}")
                :wrongFB
              end

            _ ->
              Logger.info("Problem with Json interpretation #{inspect(poison_data)}")
              :wrongFB
          end
        rescue
          e in ArgumentError ->
            Logger.info("Error with JSON Decoder #{inspect(e)}")
            :wrongFB
        end

      _ ->
        Logger.info("Error with FB ID Check resp: #{inspect(ffb_response)}")
        :wrongFB
    end
  end

  # @doc """
  # Run Facebook Debugtoken to get Token lifetime informations
  # """
  defp checkToken(token) do
    ffb_response = HTTPotion.get("https://graph.facebook.com/debug_token?input_token=#{token}&access_token=#{@configFB.app_token}")
    Logger.info("Facebook DEBUG TOKEN response to token #{token} response #{inspect(ffb_response)}")

    case ffb_response do
      %{body: body, headers: _, status_code: _} ->
        try do
          poison_data = Poison.decode(body, keys: :atoms)

          case poison_data do
            {:ok, %{data: data}} ->
              unixActTimeStamp = :os.system_time(:seconds)
              %{timeleft: data.expires_at - unixActTimeStamp, is_valid: data.is_valid, timestamp: data.expires_at}

            _ ->
              Logger.info("Unexpected Answer in JSON Format #{inspect(poison_data)}")
              :wrongFB
          end
        rescue
          e in ArgumentError ->
            Logger.info("Error with JSON Decoder #{inspect(e)}")
            :wrongFB

          e in KeyError ->
            Logger.info("Error in FB Return #{inspect(e)}")
            :wrongFB
        end

      _ ->
        Logger.info("Error with FB ID Check resp: #{inspect(ffb_response)}")
        :wrongFB
    end
  end

  # @doc """
  # Request a long living token from other clienttoken
  # """
  defp requestLongToken(token) do
    ffb_response = HTTPotion.get("https://graph.facebook.com/v3.1/oauth/access_token?grant_type=fb_exchange_token&client_id=#{@configFB.app_id}&client_secret=#{@configFB.app_secret}&fb_exchange_token=#{token}")

    Logger.info("Facebook Request new Token with token #{token} response #{inspect(ffb_response)}")

    case ffb_response do
      %{body: body, headers: _, status_code: _} ->
        try do
          poison_data = Poison.decode(body, keys: :atoms)

          case poison_data do
            {:ok, %{access_token: access_token, expires_in: expires_in, token_type: _}} ->
              unixActTimeStamp = :os.system_time(:seconds)
              expires_at = expires_in + unixActTimeStamp
              %{result: :ok, access_token: access_token, expires_at: expires_at}

            _ ->
              Logger.info("Unexpected Answer in JSON Format  #{inspect(poison_data)}")
              :wrongFB
          end
        rescue
          e in ArgumentError ->
            Logger.info("Error with JSON Decoder #{inspect(e)}")
            :wrongFB
        end

      _ ->
        Logger.info("Error with FB ID Check resp: #{inspect(ffb_response)}")
        :wrongFB
    end
  end

  # doc """
  # Run Facebook me to get clientinformation like name and mail
  # if id is not null then update the database with the new picture
  # """
  defp facebookME(token, id) do
    ffb_response = HTTPotion.get("https://graph.facebook.com/me?fields=name,email,picture&access_token=#{token}")
    Logger.info("Facebook ME response to token #{token} response #{inspect(ffb_response)}")

    case ffb_response do
      %{body: body, headers: _, status_code: _} ->
        try do
          poison_data = Poison.decode(body, keys: :atoms)

          case poison_data do
            {:ok, data} ->
              Logger.info("Facebook ME was sucessful #{inspect(data)}")

              if id == nil do
                # no update of database
                {:ok, data}
              else
                picture_response = HTTPotion.get(data.picture.data.url)

                case picture_response do
                  %{body: body, headers: _, status_code: _} ->
                    newPlayerUserdata = PlayerUserdata.add_PlayerUserdata(%PlayerUserdata{}, %{player_id: id, mainpicture: "main_#{id}"})
                    response = Repo.insert(newPlayerUserdata)
                    Logger.info("DB Response for register insert #{inspect(response)}")

                    case response do
                      {:ok, _} ->
                        Logger.info("Filepath for ProfilePic: #{@configPUD.picturepath}/main_#{id}")

                        case File.open("#{@configPUD.picturepath}/main_#{id}", [:write]) do
                          {:ok, file} ->
                            IO.binwrite(file, body)
                            File.close(file)
                            {:ok, %{data: data, picture: body}}

                          _ ->
                            Logger.info("Other Error: Filewriting?!?")
                            %{result_code: :error, result: nil}
                        end

                      {:error, responsePL} ->
                        Logger.info("SQL ERROR Happend: #{inspect(responsePL)}")
                        %{result_code: :error, result: responsePL.errors}

                      _ ->
                        Logger.info("Other Error?!?")
                        %{result_code: :error, result: nil}
                    end

                  _ ->
                    Logger.info("Problem FB picture loading #{inspect(picture_response)}")
                    :wrongFB
                end
              end

            _ ->
              Logger.info("Problem with Json interpretation #{inspect(poison_data)}")
              :wrongFB
          end
        rescue
          e in ArgumentError ->
            Logger.info("Error with JSON Decoder #{inspect(e)}")
            :wrongFB
        end

      _ ->
        Logger.info("Error with FB ME resp: #{inspect(ffb_response)}")
        :wrongFB
    end
  end

  # @doc """
  # Function combines FB functions
  # First check if generall answer is ok (given from function before)
  # if not pass value trough function
  # if :ok check Token for Information
  # if token lasts only less then 1 Month
  # then request new Long living Token
  # """
  defp checkRequestToken(checkAnswer, actToken) do
    case checkAnswer do
      :ok ->
        result = checkToken(actToken)

        case result do
          %{timeleft: tleft, is_valid: true, timestamp: expires_at} ->
            # Unix timestamp 1 Monat(30,44 DAYS) 2.629.743 Sekunden
            if tleft > 2_629_742 do
              Logger.info("Token last longer than one month")
              %{result: :ok, access_token: actToken, expires_at: expires_at}
            else
              Logger.info("Token last not longer than one month --> Regnerate")
              requestLongToken(actToken)
            end

          %{timeleft: _, is_valid: false, timestamp: _} ->
            :requestNewToken

          _ ->
            result
        end

      _ ->
        checkAnswer
    end
  end

  @doc """
   Register new Client with Facebook ID and token
   First Check if Token and ID ist valid
   Second Generate new Long Lifing Token
   Get Email and Name from Facebook for Insert
   Add everything to the Db
   Returns id and new Long Token for Login
  """
  react :AUTH_REGISTER, %{fb_id: _, token: _} = args, clientHandle, state do
    fb_resp = checkFBID(args.fb_id, args.token)
    fb_resp = checkRequestToken(fb_resp, args.token)

    case fb_resp do
      %{result: :ok, access_token: access_token, expires_at: expires_at} ->
        fb_me_resp = facebookME(access_token, nil)

        case fb_me_resp do
          {:ok, data} ->
            newPlayer =
              PlayerLogin.add_Player_FB(%PlayerLogin{}, %{
                nickname: data.name,
                email: data.email,
                facebook_id: args.fb_id,
                facebook_token: access_token,
                facebook_token_expires: expires_at
              })

            response = Repo.insert(newPlayer)
            Logger.debug("DB Response for register insert #{inspect(response)}")

            case response do
              {:ok, responsePL} ->
                Logger.info("Create new player #{data.name} with id #{responsePL.id} and mail #{data.email} and id #{args.fb_id}")
                # Update Picture for new Player
                fb_me_resp = facebookME(access_token, responsePL.id)

                case fb_me_resp do
                  {:ok, _} ->
                    %{result_code: :ok, value: {:value_FBAuth, %LoadedProtobuf.ServusLogin_FB{fb_id: Kernel.inspect(responsePL.id), token: access_token}}}

                  _ ->
                    Logger.info("FB Error response #{inspect(fb_me_resp)} adding picture")
                    %{result_code: :error, errorMessage: nil, errorType: :ERROR_NO_FB_PICTURE}
                end

              # {:error, [email: {"has already been taken", []}]} ->
              # TBD Update Look at Response --> One Layer deeper!!
              # Logger.info "Error Create new player #{data.name} and mail #{data.email} and id #{args.fb_id}"
              # %{result_code: :error, result: :already_taken} #Just Workarround --> Gernerall Error dispatching because of Poison decoder not possible
              {:error, responsePL} ->
                Logger.info("Error Create new player #{data.name} and mail #{data.email} and id #{args.fb_id} and #{inspect(responsePL)}")
                %{result_code: :error, errorMessage: nil, errorType: :ERROR_DB}

              # Just Workarround --> Gernerall Error dispatching because of Poison decoder not possible
              _ ->
                %{result_code: :error, errorMessage: nil, errorType: :ERROR_GENERIC}
            end

          _ ->
            Logger.info("FB Error response #{inspect(fb_me_resp)}")
            %{result_code: :error, errorMessage: nil, errorType: :ERROR_GENERIC}
        end

      :requestNewToken ->
        Logger.info("FB Error old Token #{inspect(fb_resp)}")
        %{result_code: :error, errorMessage: nil, errorType: :ERROR_GENERIC}

      :wrongFB ->
        Logger.info("FB Error response #{inspect(fb_resp)}")
        %{result_code: :error, errorMessage: nil, errorType: :ERROR_GENERIC}

      _ ->
        Logger.info("FB Error response #{inspect(fb_resp)}")
        %{result_code: :error, errorMessage: nil, errorType: :ERROR_GENERIC}
    end
  end

  @doc """
    Login with given Facebookid and Token --> From Register Process
    Look if Facebook id is already registerd
    Verify Token and id if valid
    Check if given Token is newer than oldone from DB
    #TBD Update DB with new token
    #TBD check if saved Token last longer than xxx --> otherwise renew!
    Creates Playerobj for Mainloop.
  """
  react :AUTH_LOGIN, %{fb_id: _, token: _} = args, clientHandle, state do
    Logger.info("Player module login_fb fb_id #{args.fb_id}")
    auth = Map.delete(clientHandle, :auth)

    query =
      from(
        p in PlayerLogin,
        where: p.facebook_id == ^args.fb_id,
        select: %{
          nickname: p.nickname,
          id: p.id,
          facebook_id: p.facebook_id,
          facebook_token: p.facebook_token,
          facebook_token_expires: p.facebook_token_expires
        }
      )

    response = Repo.one(query)
    Logger.debug("DB Response for login query #{inspect(response)}")

    case response do
      %{nickname: nickname, id: id, facebook_id: _, facebook_token: facebook_token, facebook_token_expires: facebook_token_expires} ->
        if checkFBID(args.fb_id, args.token) == :ok do
          auth_obj = %{
            name: nickname,
            # Right place for Socket .. Not Sure
            socket: clientHandle.socket,
            login_type: :facebook,
            id: id
          }

          Logger.info("Login new player #{nickname} with id #{id}")

          if args.token != facebook_token do
            resp = checkToken(args.token)

            if resp != :wrongFB && resp.timestamp > facebook_token_expires do
              # TBD UPDATE DB
            end
          end

          %{
            result_code: :ok,
            value: {:value_FBAuthResp, %LoadedProtobuf.ServusLogin_FB_Response{loginSucessful: true, reason: :FB_REASONS_UNKOWN}},
            clientHandle: Map.put(auth, :auth, auth_obj)
          }
        else
          %{
            result_code: :ok,
            value: {:value_FBAuthResp, %LoadedProtobuf.ServusLogin_FB_Response{loginSucessful: false, reason: :FB_REASONS_ID_NOT_MATCHED_TO_TOKEN}},
            clientHandle: auth
          }
        end

      nil ->
        Logger.info("No positive Login player fb_id #{args.fb_id}")

        %{
          result_code: :ok,
          value: {:value_FBAuthResp, %LoadedProtobuf.ServusLogin_FB_Response{loginSucessful: false, reason: :FB_REASONS_ID_NOT_FOUND}},
          clientHandle: auth
        }

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
