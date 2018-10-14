defmodule TestGame_1P do
  use Servus.Game
  require Logger

  alias Servus.Serverutils
  alias Servus.ProtoFactory

  def init(args) do
    Logger.info("Initializing game state machine for testGame 1p")
    [player1] = args.players
    fsm_state = %{player1: player1, counter: 0, gameID: args.gameID}
    msg = ProtoFactory.newMessage_testGame("#{args.gameID}", :TG_BEGIN, player1.name)
    Serverutils.send(player1.socket, msg)
    {:ok, :redo, fsm_state}
  end

  @doc """
  FSM is in state `p1`. Player 1 puts.
  Outcome: p2 state
  """
  def redo({id, :TG_ECHO, data}, state) do
    Logger.info("Data: #{inspect(data)} from id: #{inspect(id)} and state #{inspect(state)}")
    msg = ProtoFactory.newMessage_testGame(state.gameID, :TG_ECHO, data)
    Serverutils.send(state.player1.socket, msg)
    {:next_state, :redo, state}
  end
end
