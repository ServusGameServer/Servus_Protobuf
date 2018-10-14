defmodule Servus.Module do
  @moduledoc """
  A macro for server modules. Modules can implement tasks other
  than game logic. For example storing hiscores.
  """
  require Logger

  defmacro __using__(_) do
    quote do
      use GenServer
      import Servus.Module

      def start_link(args) do
        GenServer.start_link(__MODULE__, [], args)
      end

      def init(args) do
        __register__
        {:ok, startup}
      end

      def terminate(reason, state) do
        shutdown(state)
        :ok
      end

      # ###############
      # Callbacks
      # ###############

      def startup() do
        # Override in user code
        []
      end

      def shutdown(_state) do
        # Override in user code
      end

      def __register__() do
        # Override or die
        raise "Did you forget to register module  #{__MODULE__}?"
      end

      defoverridable __register__: 0, startup: 0, shutdown: 1
    end
  end

  defmacro register(name) do
    quote do
      def __register__() do
        Servus.ModuleStore.register(unquote(name), self())
      end
    end
  end

  defmacro react(functionID, messageValue, clientHandle, state, handler) do
    handler_impl = Keyword.get(handler, :do, nil)
    # Normalize state
    # (let the user ignore the state with _ if he wants)
    state =
      case state do
        {:_, a, b} -> {:state, a, b}
        _ -> state
      end

    quote do
      def handle_call({unquote(functionID), unquote(messageValue), unquote(clientHandle), message}, _from, unquote(state)) do
        result = unquote(handler_impl)

        case result do
          %{result_code: :ok, value: _, clientHandle: _} ->
            message = %{message | value: result.value}
            # Just make sure that no error was given in orig msg
            message = %{message | error: false}
            message = %{message | errorMessage: nil}
            message = %{message | errorType: nil}
            {:reply, %{clientHandle: result.clientHandle, msg: message}, unquote(state)}

          %{result_code: :error, errorMessage: _, errorType: _, clientHandle: _} ->
            message = %{message | value: nil}
            message = %{message | error: true}
            message = %{message | errorMessage: result.errorMessage}
            message = %{message | errorType: result.errorType}
            {:reply, %{clientHandle: result.clientHandle, msg: message}, unquote(state)}

          %{result_code: :ok, value: _} ->
            message = %{message | value: result.value}
            # Just make sure that no error was given in orig msg
            message = %{message | error: false}
            message = %{message | errorMessage: nil}
            message = %{message | errorType: nil}
            {:reply, %{clientHandle: unquote(clientHandle), msg: message}, unquote(state)}

          %{result_code: :error, errorMessage: _, errorType: _} ->
            message = %{message | value: nil}
            message = %{message | error: true}
            message = %{message | errorMessage: result.errorMessage}
            message = %{message | errorType: result.errorType}
            {:reply, %{clientHandle: unquote(clientHandle), msg: message}, unquote(state)}

          _ ->
            message = %{message | value: nil}
            message = %{message | error: true}
            message = %{message | errorMessage: "Wrong GenserverCall result"}
            message = %{message | errorType: :ERROR_GENERIC}
            {:reply, %{clientHandle: unquote(clientHandle), msg: message}, unquote(state)}
        end
      end
    end
  end

  @doc """
  Handle a message that is sent to the module This implements
  a handler that is called with arguments. It takes a `state` argument
  (which may be ignored).
  """
  defmacro handle(action, args, client, state, handler) do
    handler_impl = Keyword.get(handler, :do, nil)
    # Normalize state
    # (let the user ignore the state with _ if he wants)
    state =
      case state do
        {:_, a, b} -> {:state, a, b}
        _ -> state
      end

    quote do
      def handle_call({unquote(action), unquote(args), unquote(client)}, _from, unquote(state)) do
        result = unquote(handler_impl)

        case result do
          # Resultcode handling and custom state changes e.g. add player / add friends etc....
          %{result_code: _, result: _, state: _} ->
            {:reply, result, unquote(state)}

          # Result handling but no change for state... entry state will be added
          %{result_code: _, result: _} ->
            {:reply, %{result_code: result.result_code, result: result.result, state: unquote(client)}, unquote(state)}

          _ ->
            # Default if no resultcode ist given --> Asume that action is always ok because of no explicit resultcode handling and entry sate will be added
            {:reply, %{result_code: :ok, result: result, state: unquote(client)}, unquote(state)}
        end
      end
    end
  end
end
