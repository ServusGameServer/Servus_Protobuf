defmodule Servus.Game do
  require Logger
  alias Servus.Serverutils
  alias Servus.ProtoFactory

  @moduledoc """
  A macro to be used with game state-machines. Will automatically
  start the state machine via the provided `start` function.
  """
  defmacro __using__(options) do
    quote do
      def start(args) do
        {:ok, pid} = :gen_fsm.start(__MODULE__, args, [])
        msg = ProtoFactory.newMessage_queueGameID("#{args.gameID}")
        Enum.each(args.players, fn x -> Serverutils.send(x.socket, msg) end)
        pid
      end

      @doc """
      Forward all abort events (player aborts connection) to the
      appropriate handler function (abort).
      """
      def handle_event({:abort, player}, _, state) do
        abort(player, state)
      end

      @doc """
      Default empty `terminate` implementation to allow game
      state machines to shutdown gracefully.
      """
      def terminate(_reason, _stateName, _stateData) do
        # This function intentionally left blank
      end

      @doc """
      Overridable by user. Will be invoked when one of the players
      aborts the connection.
      """
      def abort(player, state) do
        # Default: stop game state machine on connection abort
        {:stop, :shutdown, state}
      end
    end
  end
end
