defmodule TestGame_2P do
  use Servus.Game
  require Logger

  alias Servus.Serverutils
  alias Servus.ProtoFactory

  def init(args) do
    Logger.info("Initializing game state machine for testGame 2p")
    [player1, player2] = args.players
    fsm_state = %{player1: player1, player2: player2, counter: 0, gameID: args.gameID}
    msg = ProtoFactory.newMessage_testGame("#{args.gameID}", :TG_BEGIN, player2.name)
    Serverutils.send(player1.socket, msg)
    msg = ProtoFactory.newMessage_testGame("#{args.gameID}", :TG_BEGIN, player1.name)
    Serverutils.send(player2.socket, msg)
    {:ok, :send, fsm_state}
  end

  @doc """
  FSM is in state `p1`. Player 1 puts.
  Outcome: p2 state
  """
  def send({id, :TG_ECHO, data}, state) do
    Logger.info("Data: #{inspect(data)} from id: #{inspect(id)} and state #{inspect(state)}")
    msg = ProtoFactory.newMessage_testGame(state.gameID, :TG_ECHO, data)

    if id == state.player1.id do
      Serverutils.send(state.player2.socket, msg)
    else
      Serverutils.send(state.player1.socket, msg)
    end

    {:next_state, :send, state}
  end
end
